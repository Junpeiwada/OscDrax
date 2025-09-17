import Foundation
import Combine

class Track: ObservableObject, Identifiable, Codable {
    static let waveformSampleCount = SynthConstants.defaultWaveformSampleCount

    let id: Int
    @Published var waveformType: WaveformType = .sine
    @Published var waveformData: [Float] = []
    @Published var frequency: Float = 440.0
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    @Published var portamentoTime: Float = 0.0  // 0-1000ms range
    @Published var harmonyEnabled: Bool = true
    @Published var assignedInterval: HarmonyInterval?  // Automatically assigned interval
    @Published var isHarmonyLead: Bool = false
    @Published var vibratoEnabled: Bool = false  // Enable vibrato after 500ms of stable frequency
    @Published var scaleType: ScaleType = .none {
        didSet {
            guard scaleType != oldValue else { return }
            if scaleType != .none {
                let quantized = scaleType.quantizeFrequency(frequency)
                if abs(quantized - frequency) > 0.01 {
                    frequency = quantized
                }
            }
        }
    }

    init(id: Int) {
        self.id = id
        generateDefaultWaveform()
    }

    enum CodingKeys: String, CodingKey {
        case id, waveformType, waveformData, frequency, volume, isPlaying, portamentoTime
        case harmonyEnabled, assignedInterval, isHarmonyLead, scaleType, vibratoEnabled
        case legacyHarmonyFlag = "isHarmonyMaster"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        waveformType = try container.decode(WaveformType.self, forKey: .waveformType)
        waveformData = try container.decode([Float].self, forKey: .waveformData)
        frequency = try container.decode(Float.self, forKey: .frequency)
        volume = try container.decode(Float.self, forKey: .volume)
        isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
        portamentoTime = try container.decode(Float.self, forKey: .portamentoTime)
        harmonyEnabled = try container.decodeIfPresent(Bool.self, forKey: .harmonyEnabled) ?? false
        assignedInterval = try container.decodeIfPresent(HarmonyInterval.self, forKey: .assignedInterval)
        isHarmonyLead = try container.decodeIfPresent(Bool.self, forKey: .isHarmonyLead)
            ?? container.decodeIfPresent(Bool.self, forKey: .legacyHarmonyFlag)
            ?? false
        scaleType = try container.decodeIfPresent(ScaleType.self, forKey: .scaleType) ?? .none
        vibratoEnabled = try container.decodeIfPresent(Bool.self, forKey: .vibratoEnabled) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(waveformType, forKey: .waveformType)
        try container.encode(waveformData, forKey: .waveformData)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(volume, forKey: .volume)
        try container.encode(isPlaying, forKey: .isPlaying)
        try container.encode(portamentoTime, forKey: .portamentoTime)
        try container.encode(harmonyEnabled, forKey: .harmonyEnabled)
        try container.encode(assignedInterval, forKey: .assignedInterval)
        try container.encode(isHarmonyLead, forKey: .isHarmonyLead)
        try container.encode(scaleType, forKey: .scaleType)
        try container.encode(vibratoEnabled, forKey: .vibratoEnabled)
    }

    func generateDefaultWaveform() {
        waveformData = waveformType.defaultSamples(sampleCount: Track.waveformSampleCount)
    }

    func setWaveformType(_ type: WaveformType) {
        waveformType = type
        if type != .custom {
            generateDefaultWaveform()
        }
    }

    func clearCustomWaveform() {
        // Generate a default flat line at center
        waveformData = Array(repeating: 0, count: Track.waveformSampleCount)
    }
}

extension Track {
    var synthParameters: SynthTrackParameters {
        SynthTrackParameters(
            id: id,
            waveformType: waveformType,
            waveformData: waveformData,
            frequency: frequency,
            volume: volume,
            isPlaying: isPlaying,
            portamentoTime: portamentoTime,
            harmonyEnabled: harmonyEnabled,
            assignedInterval: assignedInterval,
            isHarmonyLead: isHarmonyLead,
            vibratoEnabled: vibratoEnabled,
            scaleType: scaleType
        )
    }

    func apply(update: SynthTrackFrequencyUpdate) {
        if abs(frequency - update.frequency) > 0.001 {
            frequency = update.frequency
        }
        if assignedInterval != update.assignedInterval {
            assignedInterval = update.assignedInterval
        }
    }
}
