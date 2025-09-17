import Foundation
import Combine
import AVFoundation

/// `SynthEngineProtocol` を実装した、シングルトンの音声エンジンサービス。
/// UI 層からの要求を受け取り、`AudioEngine` を操作します。
final class SynthEngineService: ObservableObject, SynthEngineProtocol {
    /// 共有インスタンス。
    static let shared = SynthEngineService()

    private let audioEngine = AudioEngine()
    private var trackStates: [Int: SynthTrackParameters] = [:]
    private var suspendedTrackIDs: Set<Int> = []
    private let formantSubject = CurrentValueSubject<FormantType, Never>(.none)

    @Published private var formantStorage: FormantType = .none

    /// フォルマント変更を購読するためのパブリッシャ。
    var formantTypePublisher: AnyPublisher<FormantType, Never> {
        formantSubject.eraseToAnyPublisher()
    }

    /// 現在のフォルマント種別。
    var formantType: FormantType {
        get { formantStorage }
        set {
            guard formantStorage != newValue else { return }
            formantStorage = newValue
            formantSubject.send(newValue)
            audioEngine.smoothFormantTransition(to: newValue)
        }
    }

    /// サイレントスイッチへの追従ポリシー。
    var silentModePolicy: SynthSilentModePolicy = .ignoresMuteSwitch {
        didSet {
            configureAudioSession()
        }
    }

    private init() {
        configureAudioSession()
        audioEngine.startEngineIfNeeded()
    }

    // MARK: - Audio Session

    /// オーディオセッションを現在のポリシーで構成します。
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        let category: AVAudioSession.Category = {
            switch silentModePolicy {
            case .ignoresMuteSwitch:
                return .playback
            case .respectsMuteSwitch:
                return .ambient
            }
        }()

        do {
            try session.setCategory(category, mode: .default, options: [])
            try session.setPreferredSampleRate(audioEngine.preferredSampleRate)
            try session.setPreferredIOBufferDuration(audioEngine.preferredIOBufferDuration)
            try session.setActive(true)
        } catch {
            // セッション構成時のエラーは致命的ではないため握り潰す
            _ = error
        }
    }

    /// オーディオセッションを非アクティブ化します。
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            _ = error
        }
    }

    /// アプリが非アクティブになる直前に呼び出し、演奏中トラックを停止します。
    func handleWillResignActive() {
        suspendedTrackIDs = Set(trackStates.compactMap { $0.value.isPlaying ? $0.key : nil })
        suspendedTrackIDs.forEach { audioEngine.stopOscillator(trackId: $0) }
        audioEngine.stopEngine()
    }

    /// バックグラウンド遷移時に呼び出し、オーディオセッションを無効化します。
    func handleDidEnterBackground() {
        deactivateAudioSession()
    }

    /// フォアグラウンド復帰直前に呼び出し、セッションを再構成します。
    func handleWillEnterForeground() {
        configureAudioSession()
    }

    /// アクティブ復帰後に呼び出し、セッション再構築と演奏再開を行います。
    func handleDidBecomeActive() {
        configureAudioSession()
        audioEngine.startEngineIfNeeded()
        resumeSuspendedTracks()
    }

    /// 必要に応じてオーディオエンジンを起動します。
    func startEngineIfNeeded() {
        audioEngine.startEngineIfNeeded()
    }

    private func resumeSuspendedTracks() {
        guard !suspendedTrackIDs.isEmpty else { return }
        for id in suspendedTrackIDs {
            guard trackStates[id]?.isPlaying == true else { continue }
            audioEngine.startOscillator(trackId: id)
        }
        suspendedTrackIDs.removeAll()
    }

    // MARK: - Track Lifecycle

    /// 新しいトラックを登録し、必要に応じて発音を開始します。
    func registerTrack(_ parameters: SynthTrackParameters) {
        if trackStates[parameters.id] != nil {
            updateTrack(parameters)
            return
        }

        trackStates[parameters.id] = parameters
        audioEngine.createOscillator(with: parameters)

        if parameters.isPlaying {
            audioEngine.startOscillator(trackId: parameters.id)
        }
    }

    /// 既存トラックのパラメータを更新します。
    func updateTrack(_ parameters: SynthTrackParameters) {
        guard let current = trackStates[parameters.id] else {
            registerTrack(parameters)
            return
        }

        if current.waveformData != parameters.waveformData {
            audioEngine.updateWaveform(trackId: parameters.id, waveformData: parameters.waveformData)
        }

        if current.frequency != parameters.frequency {
            audioEngine.updateFrequency(trackId: parameters.id, frequency: parameters.frequency)
        }

        if current.volume != parameters.volume {
            audioEngine.updateVolume(trackId: parameters.id, volume: parameters.volume)
        }

        if current.portamentoTime != parameters.portamentoTime {
            audioEngine.updatePortamentoTime(trackId: parameters.id, time: parameters.portamentoTime)
        }

        if current.vibratoEnabled != parameters.vibratoEnabled {
            audioEngine.updateVibratoEnabled(trackId: parameters.id, enabled: parameters.vibratoEnabled)
        }

        trackStates[parameters.id] = parameters
    }

    /// トラックの再生状態を切り替えます。
    func setTrackIsPlaying(_ trackID: Int, isPlaying: Bool) {
        var state = trackStates[trackID] ?? SynthTrackParameters(
            id: trackID,
            waveformType: .sine,
            waveformData: [],
            frequency: 440.0,
            volume: 0.5,
            isPlaying: isPlaying,
            portamentoTime: 0,
            harmonyEnabled: false,
            assignedInterval: nil,
            isHarmonyLead: false,
            vibratoEnabled: false,
            scaleType: .none
        )

        guard state.isPlaying != isPlaying else { return }

        state.isPlaying = isPlaying
        trackStates[trackID] = state

        if isPlaying {
            audioEngine.startOscillator(trackId: trackID)
        } else {
            audioEngine.stopOscillator(trackId: trackID)
        }
    }

    // MARK: - Harmony

    /// ハーモニー構成を計算し、周波数更新結果を返します。
    func updateHarmonyFrequencies(
        leadTrack: SynthTrackParameters,
        allTracks: [SynthTrackParameters],
        chordType: ChordType
    ) -> [SynthTrackFrequencyUpdate] {
        let harmonizedTracks = allTracks.filter { $0.id != leadTrack.id && $0.harmonyEnabled }
        guard !harmonizedTracks.isEmpty else { return [] }

        let intervals = getChordIntervals(for: chordType)
        var updates: [SynthTrackFrequencyUpdate] = []

        // Update lead track interval state
        if var leadState = trackStates[leadTrack.id] {
            leadState.assignedInterval = intervals.first?.interval
            leadState.isHarmonyLead = true
            trackStates[leadTrack.id] = leadState
        }

        let availableIntervals = Array(intervals.dropFirst())
        guard !availableIntervals.isEmpty else { return updates }

        for (index, track) in harmonizedTracks.enumerated() {
            let interval = availableIntervals[index % availableIntervals.count].interval
            let newFrequency = calculateFrequencyForInterval(
                leadFrequency: leadTrack.frequency,
                interval: interval,
                chordType: chordType
            )
            let quantized = track.scaleType.quantizeFrequency(newFrequency)

            audioEngine.updateFrequency(trackId: track.id, frequency: quantized)

            if var stored = trackStates[track.id] {
                stored.frequency = quantized
                stored.assignedInterval = interval
                stored.isHarmonyLead = false
                trackStates[track.id] = stored
            }

            updates.append(
                SynthTrackFrequencyUpdate(
                    trackID: track.id,
                    frequency: quantized,
                    assignedInterval: interval
                )
            )
        }

        return updates
    }

    /// コード種別に応じて、使用する音程と周波数比を返します。
    private func getChordIntervals(for chordType: ChordType) -> [(interval: HarmonyInterval, ratio: Float)] {
        switch chordType {
        case .major:
            return [(.root, 1.0), (.majorThird, 1.25), (.fifth, 1.5), (.octave, 2.0)]
        case .minor:
            return [(.root, 1.0), (.minorThird, 1.2), (.fifth, 1.5), (.octave, 2.0)]
        case .seventh:
            return [(.root, 1.0), (.majorThird, 1.25), (.fifth, 1.5), (.flatSeventh, 1.78)]
        case .minorSeventh:
            return [(.root, 1.0), (.minorThird, 1.2), (.fifth, 1.5), (.flatSeventh, 1.78)]
        case .power:
            return [(.root, 1.0), (.fifth, 1.5), (.octave, 2.0), (.doubleOctave, 4.0)]
        case .detune:
            return [
                (.root, 1.0),
                (HarmonyInterval(rawValue: "+10c"), pow(2.0, 10.0 / 1_200.0)),
                (HarmonyInterval(rawValue: "-10c"), pow(2.0, -10.0 / 1_200.0)),
                (HarmonyInterval(rawValue: "+20c"), pow(2.0, 20.0 / 1_200.0))
            ]
        }
    }

    /// 指定した音程に応じた周波数を算出します。
    private func calculateFrequencyForInterval(
        leadFrequency: Float,
        interval: HarmonyInterval,
        chordType: ChordType
    ) -> Float {
        let intervals = getChordIntervals(for: chordType)
        let ratio = intervals.first(where: { $0.interval == interval })?.ratio ?? 1.0
        return leadFrequency * ratio
    }
}
