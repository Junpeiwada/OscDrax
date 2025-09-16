import AVFoundation
import Foundation

class AudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var oscillatorNodes: [Int: OscillatorNode] = [:]
    private let sampleRate: Double = 44_100.0
    private let mixerVolume: Float = 0.3  // Master volume to prevent clipping with 4 tracks

    init() {
        setupEngine()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            try session.setPreferredSampleRate(sampleRate)
            try session.setPreferredIOBufferDuration(512.0 / sampleRate) // ~11.6ms latency
        } catch {
            // Silent failure - audio session setup error
            _ = error
        }
    }

    private func setupEngine() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)

        // Set mixer volume to prevent clipping when multiple tracks play
        mixer.outputVolume = mixerVolume

        do {
            try engine.start()
        } catch {
            // Silent failure - audio engine start error
            _ = error
        }
    }

    func createOscillator(for track: Track) {
        let oscillator = OscillatorNode(sampleRate: sampleRate, track: track)
        oscillatorNodes[track.id] = oscillator

        engine.attach(oscillator.sourceNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(oscillator.sourceNode, to: mixer, format: format)
    }

    func startOscillator(trackId: Int) {
        oscillatorNodes[trackId]?.start()
    }

    func stopOscillator(trackId: Int) {
        oscillatorNodes[trackId]?.stop()
    }

    func updateFrequency(trackId: Int, frequency: Float) {
        oscillatorNodes[trackId]?.frequency = frequency
    }

    func updateVolume(trackId: Int, volume: Float) {
        oscillatorNodes[trackId]?.volume = volume
    }

    func updateWaveform(trackId: Int, waveformData: [Float]) {
        oscillatorNodes[trackId]?.updateWaveformTable(waveformData)
    }

    func updatePortamentoTime(trackId: Int, time: Float) {
        oscillatorNodes[trackId]?.updatePortamentoTime(time)
    }

    func updateVibratoEnabled(trackId: Int, enabled: Bool) {
        oscillatorNodes[trackId]?.vibratoEnabled = enabled
    }

    deinit {
        engine.stop()
    }
}

class OscillatorNode {
    var sourceNode: AVAudioSourceNode!
    private let sampleRate: Double
    private var phase: Float = 0.0
    private var phaseIncrement: Float = 0.0
    
    // Thread-safe waveform data with double buffering
    private class WaveformBuffer {
        private var current: [Float] = []
        private var next: [Float]?
        private let lock = NSLock()
        
        func read() -> [Float] {
            lock.lock()
            defer { lock.unlock() }
            if let next = next {
                current = next
                self.next = nil
            }
            return current
        }
        
        func write(_ data: [Float]) {
            lock.lock()
            defer { lock.unlock() }
            next = data
        }
    }
    
    private let waveformBuffer = WaveformBuffer()
    private let tableSize = 512
    
    // Thread-safe properties using NSLock
    private let stateLock = NSLock()
    private var _isPlaying = false
    private var _volume: Float = 0.5
    private var _frequency: Float = 440.0
    private var _portamentoTime: Float = 0.0
    private var _vibratoEnabled = false
    
    private weak var track: Track?
    
    // Fade-in/out parameters
    private var fadeState: FadeState = .idle
    private var fadeProgress: Float = 0.0
    private let fadeTime: Float = 0.05  // 50ms fade time
    private var currentAmplitude: Float = 0.0
    
    private enum FadeState {
        case idle
        case fadingIn
        case active
        case fadingOut
    }
    
    // Frequency with portamento
    private var currentFrequency: Float = 440.0
    private var portamentoRate: Float = 0.0
    private var isPortamentoActive = false
    
    // Vibrato parameters
    private let vibratoRate: Float = 5.0     // Hz
    private let vibratoDepth: Float = 0.01   // 1% frequency modulation
    private var vibratoPhase: Float = 0.0
    private var frequencyStableTime: Float = 0.0
    private let vibratoDelayTime: Float = 0.5  // 500ms delay before vibrato starts
    
    var frequency: Float {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _frequency
        }
        set {
            stateLock.lock()
            let oldValue = _frequency
            _frequency = newValue
            let portTime = _portamentoTime
            stateLock.unlock()
            
            // Calculate portamento if needed
            if portTime > 0 && oldValue != newValue {
                let targetRatio = log2(newValue / currentFrequency)
                portamentoRate = targetRatio * 0.9 / (portTime * Float(sampleRate))
                isPortamentoActive = true
                frequencyStableTime = 0.0
            } else {
                currentFrequency = newValue
                updatePhaseIncrement()
            }
        }
    }
    
    var volume: Float {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _volume
        }
        set {
            stateLock.lock()
            _volume = newValue
            stateLock.unlock()
        }
    }
    
    var vibratoEnabled: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _vibratoEnabled
        }
        set {
            stateLock.lock()
            _vibratoEnabled = newValue
            stateLock.unlock()
        }
    }
    
    var isPlaying: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _isPlaying
    }
    
    init(sampleRate: Double, track: Track) {
        self.sampleRate = sampleRate
        self.track = track
        self._frequency = track.frequency
        self.currentFrequency = track.frequency
        self._volume = track.volume
        self.waveformBuffer.write(track.waveformData)
        self._portamentoTime = track.portamentoTime / 1_000.0
        
        // Initialize phase increment before creating source node
        self.phaseIncrement = track.frequency / Float(sampleRate)
        
        // Create AVAudioSourceNode with proper format
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        self.sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let buffer = audioBufferList.pointee.mBuffers
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            // Get current values thread-safely
            self.stateLock.lock()
            let isCurrentlyPlaying = self._isPlaying
            let currentVolume = self._volume
            let targetFreq = self._frequency
            let vibratoOn = self._vibratoEnabled
            self.stateLock.unlock()
            
            let waveformTable = self.waveformBuffer.read()
            
            let fadeSamples = Int(self.fadeTime * Float(self.sampleRate))
            
            if isCurrentlyPlaying && !waveformTable.isEmpty {
                for frame in 0..<Int(frameCount) {
                    // Update fade state
                    switch self.fadeState {
                    case .fadingIn:
                        self.fadeProgress += 1.0 / Float(fadeSamples)
                        if self.fadeProgress >= 1.0 {
                            self.fadeProgress = 1.0
                            self.fadeState = .active
                        }
                        self.currentAmplitude = self.fadeProgress * self.fadeProgress  // Quadratic fade-in
                        
                    case .fadingOut:
                        self.fadeProgress -= 1.0 / Float(fadeSamples)
                        if self.fadeProgress <= 0.0 {
                            self.fadeProgress = 0.0
                            self.fadeState = .idle
                            self.stateLock.lock()
                            self._isPlaying = false
                            self.stateLock.unlock()
                            self.phase = 0.0  // Reset phase when fully stopped
                        }
                        self.currentAmplitude = self.fadeProgress * self.fadeProgress  // Quadratic fade-out
                        
                    case .active:
                        self.currentAmplitude = 1.0
                        
                    case .idle:
                        self.currentAmplitude = 0.0
                    }
                    
                    // Update frequency with portamento
                    if self.isPortamentoActive {
                        let freqRatio = targetFreq / self.currentFrequency
                        if abs(freqRatio - 1.0) < 0.001 {
                            // Close enough to target
                            self.currentFrequency = targetFreq
                            self.isPortamentoActive = false
                        } else {
                            // Apply exponential portamento
                            self.currentFrequency *= pow(2.0, self.portamentoRate)
                        }
                        // Reset vibrato timer during portamento
                        self.frequencyStableTime = 0.0
                    } else {
                        // Update frequency stable time when not in portamento
                        self.frequencyStableTime += 1.0 / Float(self.sampleRate)
                    }
                    
                    // Calculate actual frequency with vibrato if enabled
                    var actualFrequency = self.currentFrequency
                    if vibratoOn && self.frequencyStableTime >= self.vibratoDelayTime && !self.isPortamentoActive {
                        // Apply vibrato after 500ms of stable frequency
                        let vibratoModulation = sin(self.vibratoPhase * 2.0 * Float.pi)
                        actualFrequency = self.currentFrequency * (1.0 + vibratoModulation * self.vibratoDepth)
                        
                        // Update vibrato phase
                        self.vibratoPhase += self.vibratoRate / Float(self.sampleRate)
                        if self.vibratoPhase >= 1.0 {
                            self.vibratoPhase -= 1.0
                        }
                    } else {
                        // Reset vibrato phase when not active
                        self.vibratoPhase = 0.0
                    }
                    
                    // Update phase increment with actual frequency (including vibrato)
                    self.phaseIncrement = actualFrequency / Float(self.sampleRate)
                    
                    // Linear interpolation for smooth waveform
                    var interpolatedSample: Float = 0.0

                    if !waveformTable.isEmpty {
                        let tableIndex = self.phase * Float(waveformTable.count)
                        let index0 = Int(tableIndex) % waveformTable.count
                        let index1 = (index0 + 1) % waveformTable.count
                        let fraction = tableIndex - Float(index0)

                        if index0 < waveformTable.count && index1 < waveformTable.count {
                            let sample0 = waveformTable[index0]
                            let sample1 = waveformTable[index1]
                            interpolatedSample = sample0 + (sample1 - sample0) * fraction
                        }
                    }
                    
                    // Apply volume and fade amplitude with soft clipping
                    let rawSample = interpolatedSample * currentVolume * self.currentAmplitude
                    data[frame] = tanh(rawSample * 0.7)  // Soft clipping
                    
                    // Update phase
                    self.phase += self.phaseIncrement
                    if self.phase >= 1.0 {
                        self.phase -= 1.0
                    }
                }
            } else {
                // Fill with silence when not playing
                for frame in 0..<Int(frameCount) {
                    data[frame] = 0.0
                }
            }
            
            return noErr
        }
    }
    
    private func updatePhaseIncrement() {
        phaseIncrement = currentFrequency / Float(sampleRate)
    }
    
    func updateWaveformTable(_ newTable: [Float]) {
        waveformBuffer.write(newTable)
    }
    
    func updatePortamentoTime(_ time: Float) {
        stateLock.lock()
        _portamentoTime = time / 1_000.0
        stateLock.unlock()
    }
    
    func start() {
        stateLock.lock()
        _isPlaying = true
        stateLock.unlock()
        fadeState = .fadingIn
        fadeProgress = 0.0
    }
    
    func stop() {
        if fadeState == .active || fadeState == .fadingIn {
            fadeState = .fadingOut
            fadeProgress = 1.0
        }
    }
}
