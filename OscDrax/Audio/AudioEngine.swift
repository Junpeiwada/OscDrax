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
    private var waveformTable: [Float] = []
    private let tableSize = 512
    private var isPlaying = false
    private weak var track: Track?
    private let parameterQueue = DispatchQueue(label: "com.oscdraw.parameter", attributes: .concurrent)
    
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
    private var targetFrequency: Float = 440.0
    private var currentFrequency: Float = 440.0
    private var portamentoTime: Float = 0.0
    private var portamentoRate: Float = 0.0
    private var isPortamentoActive = false
    
    // Vibrato parameters
    var vibratoEnabled: Bool = false
    private let vibratoRate: Float = 5.0     // Hz
    private let vibratoDepth: Float = 0.01   // 1% frequency modulation
    private var vibratoPhase: Float = 0.0
    private var frequencyStableTime: Float = 0.0
    private let vibratoDelayTime: Float = 0.5  // 500ms delay before vibrato starts
    
    var frequency: Float = 440.0 {
        didSet {
            parameterQueue.async(flags: .barrier) {
                self.targetFrequency = self.frequency
                if self.portamentoTime > 0 {
                    // Calculate exponential portamento rate for 90% target in specified time
                    let targetRatio = log2(self.targetFrequency / self.currentFrequency)
                    self.portamentoRate = targetRatio * 0.9 / (self.portamentoTime * Float(self.sampleRate))
                    self.isPortamentoActive = true
                    self.frequencyStableTime = 0.0  // Reset stability timer
                } else {
                    // Instant frequency change
                    self.currentFrequency = self.frequency
                    self.updatePhaseIncrement()
                }
            }
        }
    }
    
    var volume: Float = 0.5
    
    init(sampleRate: Double, track: Track) {
        self.sampleRate = sampleRate
        self.track = track
        self.frequency = track.frequency
        self.currentFrequency = track.frequency
        self.targetFrequency = track.frequency
        self.volume = track.volume
        self.waveformTable = track.waveformData
        self.portamentoTime = track.portamentoTime / 1_000.0  // Convert ms to seconds
        
        // Initialize phase increment before creating source node
        self.phaseIncrement = frequency / Float(sampleRate)
        
        // Create AVAudioSourceNode with proper format
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        self.sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let buffer = audioBufferList.pointee.mBuffers
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            let fadeSamples = Int(self.fadeTime * Float(self.sampleRate))
            
            if self.isPlaying && !self.waveformTable.isEmpty {
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
                            self.isPlaying = false
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
                        let freqRatio = self.targetFrequency / self.currentFrequency
                        if abs(freqRatio - 1.0) < 0.001 {
                            // Close enough to target
                            self.currentFrequency = self.targetFrequency
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
                    if self.vibratoEnabled && self.frequencyStableTime >= self.vibratoDelayTime && !self.isPortamentoActive {
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

                    if !self.waveformTable.isEmpty {
                        let tableIndex = self.phase * Float(self.waveformTable.count)
                        let index0 = Int(tableIndex) % self.waveformTable.count
                        let index1 = (index0 + 1) % self.waveformTable.count
                        let fraction = tableIndex - Float(index0)

                        if index0 < self.waveformTable.count && index1 < self.waveformTable.count {
                            let sample0 = self.waveformTable[index0]
                            let sample1 = self.waveformTable[index1]
                            interpolatedSample = sample0 + (sample1 - sample0) * fraction
                        }
                    }
                    
                    // Apply volume and fade amplitude with soft clipping
                    let rawSample = interpolatedSample * self.volume * self.currentAmplitude
                    data[frame] = tanh(rawSample * 0.7)  // Soft clipping as per spec.md
                    
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
        phaseIncrement = frequency / Float(sampleRate)
    }
    
    func updateWaveformTable(_ newTable: [Float]) {
        waveformTable = newTable
    }
    
    func updatePortamentoTime(_ time: Float) {
        portamentoTime = time / 1_000.0  // Convert ms to seconds
    }
    
    func start() {
        isPlaying = true
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
