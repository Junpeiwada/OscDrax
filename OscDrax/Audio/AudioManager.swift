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

        // Observe track changes
        track.$isPlaying
            .sink { [weak self] isPlaying in
                if isPlaying {
                    self?.audioEngine.startOscillator(trackId: track.id)
                } else {
                    self?.audioEngine.stopOscillator(trackId: track.id)
                }
            }
            .store(in: &cancellables)

        track.$frequency
            .sink { [weak self] frequency in
                self?.audioEngine.updateFrequency(trackId: track.id, frequency: frequency)
            }
            .store(in: &cancellables)

        track.$volume
            .sink { [weak self] volume in
                self?.audioEngine.updateVolume(trackId: track.id, volume: volume)
            }
            .store(in: &cancellables)

        track.$waveformData
            .sink { [weak self] waveformData in
                if !waveformData.isEmpty {
                    self?.audioEngine.updateWaveform(trackId: track.id, waveformData: waveformData)
                }
            }
            .store(in: &cancellables)

        track.$portamentoTime
            .sink { [weak self] time in
                self?.audioEngine.updatePortamentoTime(trackId: track.id, time: time)
            }
            .store(in: &cancellables)
    }

    // MARK: - Harmony Functions

    func getChordIntervals(for chordType: ChordType) -> [(name: String, ratio: Float)] {
        switch chordType {
        case .major:
            return [("Root", 1.0), ("3rd", 1.25), ("5th", 1.5), ("Oct", 2.0)]
        case .minor:
            return [("Root", 1.0), ("m3", 1.2), ("5th", 1.5), ("Oct", 2.0)]
        case .seventh:
            return [("Root", 1.0), ("3rd", 1.25), ("5th", 1.5), ("b7", 1.78)]
        case .minorSeventh:
            return [("Root", 1.0), ("m3", 1.2), ("5th", 1.5), ("b7", 1.78)]
        case .majorSeventh:
            return [("Root", 1.0), ("3rd", 1.25), ("5th", 1.5), ("7th", 1.875)]
        case .sus4:
            return [("Root", 1.0), ("4th", 1.333), ("5th", 1.5), ("Oct", 2.0)]
        case .diminished:
            return [("Root", 1.0), ("m3", 1.2), ("b5", 1.414), ("bb7", 1.68)]
        case .power:
            return [("Root", 1.0), ("5th", 1.5), ("Oct", 2.0), ("2Oct", 4.0)]
        }
    }

    func assignIntervalsToTracks(masterTrack: Track, harmonizedTracks: [Track], chordType: ChordType) {
        let intervals = getChordIntervals(for: chordType)

        // Master track always gets the first interval (Root)
        masterTrack.assignedInterval = intervals[0].name

        // Skip the first interval (Root) for other tracks
        let availableIntervals = Array(intervals.dropFirst())

        // Assign remaining intervals to harmonized tracks
        for (index, track) in harmonizedTracks.enumerated() {
            if index < availableIntervals.count {
                track.assignedInterval = availableIntervals[index].name
            } else {
                // If more tracks than available intervals, cycle through
                let cycledIndex = index % availableIntervals.count
                track.assignedInterval = availableIntervals[cycledIndex].name
            }
        }
    }

    func calculateFrequencyForInterval(masterFrequency: Float, intervalName: String, chordType: ChordType, octaveOffset: Int) -> Float {
        let intervals = getChordIntervals(for: chordType)

        // Find the ratio for the given interval name
        let ratio = intervals.first(where: { $0.name == intervalName })?.ratio ?? 1.0

        // Apply octave offset
        let octaveMultiplier = pow(2.0, Float(octaveOffset))
        return masterFrequency * ratio * octaveMultiplier
    }

    func updateHarmonyFrequencies(masterTrack: Track, allTracks: [Track], chordType: ChordType) {
        // Collect tracks with harmony enabled (excluding master)
        let harmonizedTracks = allTracks.filter { $0.id != masterTrack.id && $0.harmonyEnabled }

        // Assign intervals to tracks
        assignIntervalsToTracks(masterTrack: masterTrack, harmonizedTracks: harmonizedTracks, chordType: chordType)

        // Update frequencies based on assigned intervals
        for track in harmonizedTracks {
            if let intervalName = track.assignedInterval {
                let newFrequency = calculateFrequencyForInterval(
                    masterFrequency: masterTrack.frequency,
                    intervalName: intervalName,
                    chordType: chordType,
                    octaveOffset: track.octaveOffset
                )
                track.frequency = newFrequency
            }
        }
    }
}
