import Foundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private let audioEngine = AudioEngine()
    private var cancellables = Set<AnyCancellable>()

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
}