import Foundation
import Combine
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private let audioEngine = AudioEngine()
    var cancellables = Set<AnyCancellable>()

    // Global formant filter state
    @Published var formantType: FormantType = .none {
        didSet {
            audioEngine.smoothFormantTransition(to: formantType)
        }
    }
    
    enum SilentModePolicy {
        case ignoresMuteSwitch
        case respectsMuteSwitch
    }

    /// `.respectsMuteSwitch` に切り替えるとハードウェアのサイレントスイッチに従います（Next Step 2）。
    var silentModePolicy: SilentModePolicy = .ignoresMuteSwitch {
        didSet {
            configureAudioSession()
        }
    }

    private var trackedTracks: [Int: Track] = [:]
    private var suspendedTrackIDs: Set<Int> = []

    private init() {
        configureAudioSession()
        audioEngine.startEngineIfNeeded()
    }

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
            // Silent failure - session configuration error
            _ = error
        }
    }

    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Silent failure - session deactivation error
            _ = error
        }
    }

    func handleWillResignActive() {
        suspendedTrackIDs = stopActiveTracks()
        audioEngine.stopEngine()
    }

    func handleDidEnterBackground() {
        deactivateAudioSession()
    }

    func handleWillEnterForeground() {
        configureAudioSession()
    }

    func handleDidBecomeActive() {
        configureAudioSession()
        audioEngine.startEngineIfNeeded()
        resumeSuspendedTracks()
    }

    func startEngineIfNeeded() {
        audioEngine.startEngineIfNeeded()
    }

    func setupTrack(_ track: Track) {
        guard trackedTracks[track.id] == nil else { return }
        trackedTracks[track.id] = track

        // Create oscillator for the track
        audioEngine.createOscillator(for: track)

        // Observe track changes with appropriate debouncing
        observePlaybackChanges(for: track)
        observeFrequencyChanges(for: track)
        observeVolumeChanges(for: track)
        observeWaveformChanges(for: track)
        observePortamentoChanges(for: track)
        observeVibratoChanges(for: track)
    }

    private func observePlaybackChanges(for track: Track) {
        track.$isPlaying
            .removeDuplicates()
            .sink { [weak self] isPlaying in
                if isPlaying {
                    self?.audioEngine.startOscillator(trackId: track.id)
                } else {
                    self?.audioEngine.stopOscillator(trackId: track.id)
                }
            }
            .store(in: &cancellables)
    }

    private func observeFrequencyChanges(for track: Track) {
        track.$frequency
            .removeDuplicates()
            .debounce(for: .milliseconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] frequency in
                self?.audioEngine.updateFrequency(trackId: track.id, frequency: frequency)
            }
            .store(in: &cancellables)
    }

    private func observeVolumeChanges(for track: Track) {
        track.$volume
            .removeDuplicates()
            .debounce(for: .milliseconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] volume in
                self?.audioEngine.updateVolume(trackId: track.id, volume: volume)
            }
            .store(in: &cancellables)
    }

    private func observeWaveformChanges(for track: Track) {
        track.$waveformData
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] waveformData in
                guard !waveformData.isEmpty else { return }
                self?.audioEngine.updateWaveform(trackId: track.id, waveformData: waveformData)
            }
            .store(in: &cancellables)
    }

    private func observePortamentoChanges(for track: Track) {
        track.$portamentoTime
            .removeDuplicates()
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] time in
                self?.audioEngine.updatePortamentoTime(trackId: track.id, time: time)
            }
            .store(in: &cancellables)
    }

    private func observeVibratoChanges(for track: Track) {
        track.$vibratoEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.audioEngine.updateVibratoEnabled(trackId: track.id, enabled: enabled)
            }
            .store(in: &cancellables)
    }

    private func stopActiveTracks() -> Set<Int> {
        var activeTrackIDs: Set<Int> = []
        for (id, track) in trackedTracks where track.isPlaying {
            activeTrackIDs.insert(id)
            audioEngine.stopOscillator(trackId: id)
        }
        return activeTrackIDs
    }

    private func resumeSuspendedTracks() {
        guard !suspendedTrackIDs.isEmpty else { return }
        for id in suspendedTrackIDs {
            guard let track = trackedTracks[id], track.isPlaying else { continue }
            audioEngine.startOscillator(trackId: id)
        }
        suspendedTrackIDs.removeAll()
    }

    // MARK: - Harmony Functions

    func getChordIntervals(for chordType: ChordType) -> [(interval: HarmonyInterval, ratio: Float)] {
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
            // Detune: slight frequency variations for thickness
            // Track 1: unison (0 cents)
            // Track 2: +10 cents
            // Track 3: -10 cents
            // Track 4: +20 cents
            return [
                (HarmonyInterval(rawValue: "Root"), 1.0),
                (HarmonyInterval(rawValue: "+10c"), pow(2.0, 10.0 / 1_200.0)),
                (HarmonyInterval(rawValue: "-10c"), pow(2.0, -10.0 / 1_200.0)),
                (HarmonyInterval(rawValue: "+20c"), pow(2.0, 20.0 / 1_200.0))
            ]
        }
    }

    func assignIntervalsToTracks(leadTrack: Track, harmonizedTracks: [Track], chordType: ChordType) {
        let intervals = getChordIntervals(for: chordType)

        // Harmony lead track always gets the first interval (Root)
        leadTrack.assignedInterval = intervals[0].interval

        // Skip the first interval (Root) for other tracks
        let availableIntervals = Array(intervals.dropFirst())

        // Assign remaining intervals to harmonized tracks
        for (index, track) in harmonizedTracks.enumerated() {
            if index < availableIntervals.count {
                track.assignedInterval = availableIntervals[index].interval
            } else {
                // If more tracks than available intervals, cycle through
                let cycledIndex = index % availableIntervals.count
                track.assignedInterval = availableIntervals[cycledIndex].interval
            }
        }
    }

    func calculateFrequencyForInterval(leadFrequency: Float, interval: HarmonyInterval, chordType: ChordType) -> Float {
        let intervals = getChordIntervals(for: chordType)

        // Find the ratio for the given interval name
        let ratio = intervals.first(where: { $0.interval == interval })?.ratio ?? 1.0
        return leadFrequency * ratio
    }

    func updateHarmonyFrequencies(leadTrack: Track, allTracks: [Track], chordType: ChordType) {
        // Collect tracks with harmony enabled (excluding harmony lead)
        let harmonizedTracks = allTracks.filter { $0.id != leadTrack.id && $0.harmonyEnabled }

        // Assign intervals to tracks
        assignIntervalsToTracks(leadTrack: leadTrack, harmonizedTracks: harmonizedTracks, chordType: chordType)

        // Update frequencies based on assigned intervals
        for track in harmonizedTracks {
            if let interval = track.assignedInterval {
                let newFrequency = calculateFrequencyForInterval(
                    leadFrequency: leadTrack.frequency,
                    interval: interval,
                    chordType: chordType
                )
                track.frequency = track.scaleType.quantizeFrequency(newFrequency)
            }
        }
    }
}
