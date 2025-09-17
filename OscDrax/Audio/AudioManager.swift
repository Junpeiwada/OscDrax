import Foundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private let audioEngine = AudioEngine()
    var cancellables = Set<AnyCancellable>()

    private init() {}

    func setupTrack(_ track: Track) {
        // Create oscillator for the track
        audioEngine.createOscillator(for: track)

        // Observe track changes with appropriate debouncing

        // Immediate response for play/stop (no debounce)
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

        // Debounced frequency updates (5ms for smooth slider response)
        track.$frequency
            .removeDuplicates()
            .debounce(for: .milliseconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] frequency in
                self?.audioEngine.updateFrequency(trackId: track.id, frequency: frequency)
            }
            .store(in: &cancellables)

        // Debounced volume updates (5ms for smooth slider response)
        track.$volume
            .removeDuplicates()
            .debounce(for: .milliseconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] volume in
                self?.audioEngine.updateVolume(trackId: track.id, volume: volume)
            }
            .store(in: &cancellables)

        // Slightly longer debounce for waveform data (10ms)
        track.$waveformData
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] waveformData in
                if !waveformData.isEmpty {
                    self?.audioEngine.updateWaveform(trackId: track.id, waveformData: waveformData)
                }
            }
            .store(in: &cancellables)

        // Debounced portamento time updates (10ms)
        track.$portamentoTime
            .removeDuplicates()
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] time in
                self?.audioEngine.updatePortamentoTime(trackId: track.id, time: time)
            }
            .store(in: &cancellables)

        // Immediate response for vibrato toggle
        track.$vibratoEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.audioEngine.updateVibratoEnabled(trackId: track.id, enabled: enabled)
            }
            .store(in: &cancellables)
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
        case .majorSeventh:
            return [(.root, 1.0), (.majorThird, 1.25), (.fifth, 1.5), (.seventh, 1.875)]
        case .sus4:
            return [(.root, 1.0), (.fourth, 1.333), (.fifth, 1.5), (.octave, 2.0)]
        case .diminished:
            return [(.root, 1.0), (.minorThird, 1.2), (.flatFifth, 1.414), (.doubleFlatSeventh, 1.68)]
        case .power:
            return [(.root, 1.0), (.fifth, 1.5), (.octave, 2.0), (.doubleOctave, 4.0)]
        }
    }

    func assignIntervalsToTracks(masterTrack: Track, harmonizedTracks: [Track], chordType: ChordType) {
        let intervals = getChordIntervals(for: chordType)

        // Master track always gets the first interval (Root)
        masterTrack.assignedInterval = intervals[0].interval

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

    func calculateFrequencyForInterval(masterFrequency: Float, interval: HarmonyInterval, chordType: ChordType) -> Float {
        let intervals = getChordIntervals(for: chordType)

        // Find the ratio for the given interval name
        let ratio = intervals.first(where: { $0.interval == interval })?.ratio ?? 1.0
        return masterFrequency * ratio
    }

    func updateHarmonyFrequencies(masterTrack: Track, allTracks: [Track], chordType: ChordType) {
        // Collect tracks with harmony enabled (excluding master)
        let harmonizedTracks = allTracks.filter { $0.id != masterTrack.id && $0.harmonyEnabled }

        // Assign intervals to tracks
        assignIntervalsToTracks(masterTrack: masterTrack, harmonizedTracks: harmonizedTracks, chordType: chordType)

        // Update frequencies based on assigned intervals
        for track in harmonizedTracks {
            if let interval = track.assignedInterval {
                let newFrequency = calculateFrequencyForInterval(
                    masterFrequency: masterTrack.frequency,
                    interval: interval,
                    chordType: chordType
                )
                track.frequency = track.scaleType.quantizeFrequency(newFrequency)
            }
        }
    }
}
