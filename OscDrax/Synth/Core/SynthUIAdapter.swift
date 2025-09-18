import Foundation
import Combine

/// SwiftUI など UI 層から音声エンジンを操作するためのアダプタ。
/// `SynthEngineService` をラップし、双方向データバインディングを提供します。
final class SynthUIAdapter: ObservableObject {
    /// 共有インスタンス。
    static let shared = SynthUIAdapter()

    private let engine: SynthEngineProtocol
    /// Combine の購読保持用セット。
    var cancellables = Set<AnyCancellable>()

    /// UI からバインドされるフォルマント種別。
    @Published var formantType: FormantType {
        didSet {
            guard oldValue != formantType else { return }
            engine.formantType = formantType
        }
    }

    /// マスターボリューム（0.0〜1.0）。
    @Published var masterVolume: Float {
        didSet {
            guard oldValue != masterVolume else { return }
            engine.masterVolume = masterVolume
        }
    }

    /// サイレントスイッチの扱い。
    var silentModePolicy: SynthSilentModePolicy = .ignoresMuteSwitch {
        didSet {
            guard oldValue != silentModePolicy else { return }
            engine.silentModePolicy = silentModePolicy
            engine.configureAudioSession()
        }
    }

    /// 内部用イニシャライザ。通常は `shared` を利用します。
    private init(engine: SynthEngineProtocol = SynthEngineService.shared) {
        self.engine = engine
        self.formantType = engine.formantType
        self.masterVolume = engine.masterVolume
        self.silentModePolicy = engine.silentModePolicy
        engine.silentModePolicy = silentModePolicy

        engine.formantTypePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, self.formantType != value else { return }
                self.formantType = value
            }
            .store(in: &cancellables)

        engine.masterVolumePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, self.masterVolume != value else { return }
                self.masterVolume = value
            }
            .store(in: &cancellables)
    }

    // MARK: - Session Management

    /// オーディオセッションを設定します。
    func configureAudioSession() {
        engine.configureAudioSession()
    }

    /// オーディオセッションを無効化します。
    func deactivateAudioSession() {
        engine.deactivateAudioSession()
    }

    /// アプリが非アクティブになる際のハンドラです。
    func handleWillResignActive() {
        engine.handleWillResignActive()
    }

    /// バックグラウンド遷移時のハンドラです。
    func handleDidEnterBackground() {
        engine.handleDidEnterBackground()
    }

    /// フォアグラウンド復帰直前のハンドラです。
    func handleWillEnterForeground() {
        engine.handleWillEnterForeground()
    }

    /// アクティブ復帰後のハンドラです。
    func handleDidBecomeActive() {
        engine.handleDidBecomeActive()
    }

    /// 必要であればエンジンを起動します。
    func startEngineIfNeeded() {
        engine.startEngineIfNeeded()
    }

    // MARK: - Track Wiring

    /// トラックを SynthEngine に登録し、必要な Combine 監視を設定します。
    func setupTrack(_ track: Track) {
        engine.registerTrack(track.synthParameters)
        observePlaybackChanges(for: track)
        observeFrequencyChanges(for: track)
        observeVolumeChanges(for: track)
        observeWaveformChanges(for: track)
        observePortamentoChanges(for: track)
        observeVibratoChanges(for: track)
        observeHarmonyFlags(for: track)
    }

    private func observePlaybackChanges(for track: Track) {
        track.$isPlaying
            .removeDuplicates()
            .sink { [weak self] isPlaying in
                self?.engine.setTrackIsPlaying(track.id, isPlaying: isPlaying)
            }
            .store(in: &cancellables)
    }

    private func observeFrequencyChanges(for track: Track) {
        track.$frequency
            .removeDuplicates()
            .debounce(for: .milliseconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)
    }

    private func observeVolumeChanges(for track: Track) {
        track.$volume
            .removeDuplicates()
            .debounce(for: .milliseconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)
    }

    private func observeWaveformChanges(for track: Track) {
        track.$waveformData
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] data in
                guard !data.isEmpty else { return }
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)
    }

    private func observePortamentoChanges(for track: Track) {
        track.$portamentoTime
            .removeDuplicates()
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)
    }

    private func observeVibratoChanges(for track: Track) {
        track.$vibratoEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)
    }

    private func observeHarmonyFlags(for track: Track) {
        track.$harmonyEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)

        track.$isHarmonyLead
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.engine.updateTrack(track.synthParameters)
            }
            .store(in: &cancellables)
    }

    // MARK: - Harmony Helpers

    /// ハーモニー構成を更新し、UI 上のトラックへ結果を反映します。
    func updateHarmonyFrequencies(
        leadTrack: Track,
        allTracks: [Track],
        chordType: ChordType
    ) {
        let leadParameters = leadTrack.synthParameters
        let trackParameters = allTracks.map { $0.synthParameters }

        let updates = engine.updateHarmonyFrequencies(
            leadTrack: leadParameters,
            allTracks: trackParameters,
            chordType: chordType
        )

        if leadTrack.assignedInterval != HarmonyInterval.root {
            leadTrack.assignedInterval = HarmonyInterval.root
        }

        for update in updates {
            guard let track = allTracks.first(where: { $0.id == update.trackID }) else { continue }
            track.apply(update: update)
        }
    }
}
