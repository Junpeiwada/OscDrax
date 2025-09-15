import AVFoundation
import Foundation

class AudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var oscillatorNodes: [Int: OscillatorNode] = [:]
    private let sampleRate: Double = 44100.0
    private let mixerVolume: Float = 0.5  // Master volume to prevent clipping with 4 tracks

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
            print("Failed to setup audio session: \(error)")
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
            print("Failed to start audio engine: \(error)")
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

    // Portamento parameters
    private var targetFrequency: Float = 440.0
    private var currentFrequency: Float = 440.0
    private var portamentoTime: Float = 0.0  // in seconds
    private var portamentoRate: Float = 0.0
    private var isPortamentoActive = false

    var frequency: Float = 440.0 {
        didSet {
            parameterQueue.async(flags: .barrier) {
                self.targetFrequency = self.frequency
                if self.portamentoTime > 0 {
                    self.isPortamentoActive = true
                    // Calculate rate based on log scale for musical perception
                    let logDiff = log2(self.targetFrequency / self.currentFrequency)
                    self.portamentoRate = logDiff / (self.portamentoTime * Float(self.sampleRate))
                } else {
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
        self.portamentoTime = track.portamentoTime / 1000.0  // Convert ms to seconds

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

            if self.isPlaying && !self.waveformTable.isEmpty {
                for frame in 0..<Int(frameCount) {
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
                        self.phaseIncrement = self.currentFrequency / Float(self.sampleRate)
                    }

                    // Linear interpolation for smooth waveform
                    let tableIndex = self.phase * Float(self.tableSize)
                    let index0 = Int(tableIndex) % self.tableSize
                    let index1 = (index0 + 1) % self.tableSize
                    let fraction = tableIndex - Float(index0)

                    let sample0 = self.waveformTable[index0]
                    let sample1 = self.waveformTable[index1]
                    let interpolatedSample = sample0 + fraction * (sample1 - sample0)

                    // Apply volume and soft clipping
                    let rawSample = interpolatedSample * self.volume
                    data[frame] = tanh(rawSample * 0.9)  // Soft clipping to prevent distortion

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
        portamentoTime = time / 1000.0  // Convert ms to seconds
    }

    func start() {
        isPlaying = true
    }

    func stop() {
        isPlaying = false
    }
}