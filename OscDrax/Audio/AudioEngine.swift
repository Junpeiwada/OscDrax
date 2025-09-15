import AVFoundation
import Foundation

class AudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var oscillatorNodes: [Int: OscillatorNode] = [:]
    private let sampleRate: Double = 44100.0

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

    var frequency: Float = 440.0 {
        didSet {
            updatePhaseIncrement()
        }
    }

    var volume: Float = 0.5

    init(sampleRate: Double, track: Track) {
        self.sampleRate = sampleRate
        self.track = track
        self.frequency = track.frequency
        self.volume = track.volume
        self.waveformTable = track.waveformData

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
                    // Linear interpolation for smooth waveform
                    let tableIndex = self.phase * Float(self.tableSize)
                    let index0 = Int(tableIndex) % self.tableSize
                    let index1 = (index0 + 1) % self.tableSize
                    let fraction = tableIndex - Float(index0)

                    let sample0 = self.waveformTable[index0]
                    let sample1 = self.waveformTable[index1]
                    let interpolatedSample = sample0 + fraction * (sample1 - sample0)

                    data[frame] = interpolatedSample * self.volume

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

    func start() {
        isPlaying = true
    }

    func stop() {
        isPlaying = false
    }
}