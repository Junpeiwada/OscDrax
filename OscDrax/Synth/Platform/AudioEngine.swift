import AVFoundation
import Foundation
import Combine

/// `AVAudioEngine` を用いて実際の音声出力を行うクラス。
class AudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var oscillatorNodes: [Int: OscillatorNode] = [:]
    private let sampleRateValue: Double = 44_100.0
    private let preferredBufferFrameCount: Double = 512.0
    private let mixerVolume: Float = 0.3  // Master volume to prevent clipping with 4 tracks
    private var masterVolume: Float = SynthConstants.defaultMasterVolume
    private let formantFilter = FormantFilter()

    init() {
        setupEngine()
    }

    private func setupEngine() {
        engine.attach(mixer)
        engine.attach(formantFilter.node)

        // Connect: mixer -> formantFilter -> mainMixerNode
        engine.connect(mixer, to: formantFilter.node, format: nil)
        engine.connect(formantFilter.node, to: engine.mainMixerNode, format: nil)

        applyMixerVolume()

        // Initially set formant to none
        formantFilter.setFormantType(.none)

        startEngineIfNeeded()
    }

    /// 推奨サンプルレート。
    var preferredSampleRate: Double { sampleRateValue }

    /// 推奨 IO バッファ時間 (秒)。
    var preferredIOBufferDuration: TimeInterval { preferredBufferFrameCount / sampleRateValue }

    /// エンジンが稼働中かどうか。
    var isRunning: Bool { engine.isRunning }

    /// 必要に応じてエンジンを起動します。
    func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            // Silent failure - audio engine start error
            _ = error
        }
    }

    /// エンジンを停止します。
    func stopEngine() {
        if engine.isRunning {
            engine.stop()
        }
    }

    /// トラックパラメータを元にオシレータノードを生成します。
    func createOscillator(with parameters: SynthTrackParameters) {
        let oscillator = OscillatorNode(sampleRate: sampleRateValue, parameters: parameters)
        oscillatorNodes[parameters.id] = oscillator

        engine.attach(oscillator.sourceNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRateValue, channels: 1)
        engine.connect(oscillator.sourceNode, to: mixer, format: format)

        if parameters.isPlaying {
            oscillator.start()
        }
    }

    /// 指定 ID のオシレータを開始します。
    func startOscillator(trackId: Int) {
        oscillatorNodes[trackId]?.start()
    }

    /// 指定 ID のオシレータを停止します。
    func stopOscillator(trackId: Int) {
        oscillatorNodes[trackId]?.stop()
    }

    /// 周波数を更新します。
    func updateFrequency(trackId: Int, frequency: Float) {
        oscillatorNodes[trackId]?.frequency = frequency
    }

    /// 音量を更新します。
    func updateVolume(trackId: Int, volume: Float) {
        oscillatorNodes[trackId]?.volume = volume
    }

    /// 波形テーブルを更新します。
    func updateWaveform(trackId: Int, waveformData: [Float]) {
        oscillatorNodes[trackId]?.updateWaveformTable(waveformData)
    }

    /// ポルタメント時間を更新します。
    func updatePortamentoTime(trackId: Int, time: Float) {
        oscillatorNodes[trackId]?.updatePortamentoTime(time)
    }

    /// ビブラートの有効・無効を切り替えます。
    func updateVibratoEnabled(trackId: Int, enabled: Bool) {
        oscillatorNodes[trackId]?.vibratoEnabled = enabled
    }

    /// 現在のフォルマントを即時適用します。
    func setFormantType(_ type: FormantType) {
        formantFilter.setFormantType(type)
    }

    /// フォルマントを滑らかに遷移させます。
    func smoothFormantTransition(to type: FormantType) {
        formantFilter.smoothTransition(to: type)
    }

    /// マスターボリュームを更新します（0.0〜1.0）。
    func updateMasterVolume(_ volume: Float) {
        masterVolume = max(0.0, min(1.0, volume))
        applyMixerVolume()
    }

    private func applyMixerVolume() {
        mixer.outputVolume = mixerVolume * masterVolume
    }

    deinit {
        engine.stop()
    }
}

/// 個々のトラック音声を生成するオシレータノード。
class OscillatorNode {
    var sourceNode: AVAudioSourceNode!
    private let sampleRate: Double
    private var phase: Float = 0.0
    private var phaseIncrement: Float = 0.0

    /// レンダリング時に共有する状態値。
    private struct RenderContext {
        let isPlaying: Bool
        let volume: Float
        let targetFrequency: Float
        let vibratoEnabled: Bool
    }
    
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
    
    /// 現在設定されている周波数。
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
    
    /// 現在設定されている音量。
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
    
    /// ビブラートを適用するかどうか。
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
    
    /// 演奏中かどうか。
    var isPlaying: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _isPlaying
    }
    
    /// 指定したトラックパラメータからノードを構築します。
    init(sampleRate: Double, parameters: SynthTrackParameters) {
        self.sampleRate = sampleRate
        self._frequency = parameters.frequency
        self.currentFrequency = parameters.frequency
        self._volume = parameters.volume
        self.waveformBuffer.write(parameters.waveformData)
        self._portamentoTime = parameters.portamentoTime / 1_000.0

        // Initialize phase increment before creating source node
        self.phaseIncrement = parameters.frequency / Float(sampleRate)
        
        // Create AVAudioSourceNode with proper format
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            fatalError("Failed to create AVAudioFormat for sampleRate=\(sampleRate), channels=1")
        }

        self.sourceNode = AVAudioSourceNode(
            format: format,
            renderBlock: makeRenderBlock()
        )
    }
    
    private func makeRenderBlock() -> AVAudioSourceNodeRenderBlock {
        { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let buffer = audioBufferList.pointee.mBuffers
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            let context = self.currentRenderContext()
            let waveformTable = self.waveformBuffer.read()
            let totalFrames = Int(frameCount)
            let fadeSamples = max(1, Int(self.fadeTime * Float(self.sampleRate)))

            guard context.isPlaying, !waveformTable.isEmpty else {
                self.fillSilence(data, frameCount: totalFrames)
                return noErr
            }

            for frame in 0..<totalFrames {
                self.updateFade(totalSamples: fadeSamples)
                self.updateFrequencyTowardsTarget(context.targetFrequency)

                let actualFrequency = self.modulatedFrequency(
                    baseFrequency: self.currentFrequency,
                    vibratoOn: context.vibratoEnabled
                )

                self.phaseIncrement = actualFrequency / Float(self.sampleRate)
                let sample = self.interpolatedSample(from: waveformTable)
                data[frame] = self.processedSample(sample, volume: context.volume)
                self.advancePhase()
            }

            return noErr
        }
    }

    private func currentRenderContext() -> RenderContext {
        stateLock.lock()
        defer { stateLock.unlock() }
        return RenderContext(
            isPlaying: _isPlaying,
            volume: _volume,
            targetFrequency: _frequency,
            vibratoEnabled: _vibratoEnabled
        )
    }

    private func updateFade(totalSamples: Int) {
        guard totalSamples > 0 else {
            currentAmplitude = fadeState == .fadingOut ? 0.0 : 1.0
            return
        }

        let increment = 1.0 / Float(totalSamples)

        switch fadeState {
        case .fadingIn:
            fadeProgress += increment
            if fadeProgress >= 1.0 {
                fadeProgress = 1.0
                fadeState = .active
            }
            currentAmplitude = fadeProgress * fadeProgress

        case .fadingOut:
            fadeProgress -= increment
            if fadeProgress <= 0.0 {
                fadeProgress = 0.0
                fadeState = .idle
                stateLock.lock()
                _isPlaying = false
                stateLock.unlock()
                phase = 0.0
            }
            currentAmplitude = fadeProgress * fadeProgress

        case .active:
            currentAmplitude = 1.0

        case .idle:
            currentAmplitude = 0.0
        }
    }

    private func updateFrequencyTowardsTarget(_ targetFrequency: Float) {
        if isPortamentoActive {
            let freqRatio = targetFrequency / currentFrequency
            if abs(freqRatio - 1.0) < 0.001 {
                currentFrequency = targetFrequency
                isPortamentoActive = false
            } else {
                currentFrequency *= pow(2.0, portamentoRate)
            }
            frequencyStableTime = 0.0
        } else {
            frequencyStableTime += 1.0 / Float(sampleRate)
        }
    }

    private func modulatedFrequency(baseFrequency: Float, vibratoOn: Bool) -> Float {
        guard vibratoOn,
              frequencyStableTime >= vibratoDelayTime,
              !isPortamentoActive else {
            vibratoPhase = 0.0
            return baseFrequency
        }

        let vibratoModulation = sin(vibratoPhase * 2.0 * Float.pi)
        let modulatedFrequency = baseFrequency * (1.0 + vibratoModulation * vibratoDepth)

        vibratoPhase += vibratoRate / Float(sampleRate)
        if vibratoPhase >= 1.0 {
            vibratoPhase -= 1.0
        }

        return modulatedFrequency
    }

    private func interpolatedSample(from waveformTable: [Float]) -> Float {
        guard !waveformTable.isEmpty else { return 0.0 }

        let tableCount = waveformTable.count
        let tableIndex = phase * Float(tableCount)
        let index0 = Int(tableIndex) % tableCount
        let index1 = (index0 + 1) % tableCount
        let fraction = tableIndex - Float(index0)

        if index0 < tableCount && index1 < tableCount {
            let sample0 = waveformTable[index0]
            let sample1 = waveformTable[index1]
            return sample0 + (sample1 - sample0) * fraction
        }

        return 0.0
    }

    private func processedSample(_ sample: Float, volume: Float) -> Float {
        let rawSample = sample * volume * currentAmplitude
        return tanh(rawSample * 0.7)
    }

    private func advancePhase() {
        phase += phaseIncrement
        if phase >= 1.0 {
            phase -= 1.0
        }
    }

    private func fillSilence(_ data: UnsafeMutablePointer<Float>, frameCount: Int) {
        for frame in 0..<frameCount {
            data[frame] = 0.0
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
