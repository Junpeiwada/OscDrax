import Foundation
import SwiftUI
import Combine

enum WaveformType: String, CaseIterable, Codable {
    case sine
    case triangle
    case square
    case sawtooth
    case custom

    var displayName: String {
        switch self {
        case .sine: return "Sin"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .sawtooth: return "Saw"
        case .custom: return "Custom"
        }
    }
}

extension WaveformType {
    func defaultSamples(sampleCount: Int = Track.waveformSampleCount) -> [Float] {
        guard sampleCount > 0 else { return [] }

        switch self {
        case .sine:
            return (0..<sampleCount).map { index in
                let angle = Float(index) / Float(sampleCount) * Float.pi * 2
                return sin(angle)
            }
        case .triangle:
            return (0..<sampleCount).map { index in
                let phase = Float(index) / Float(sampleCount)
                if phase < 0.25 {
                    return phase * 4
                } else if phase < 0.75 {
                    return 2 - phase * 4
                } else {
                    return phase * 4 - 4
                }
            }
        case .square:
            let half = sampleCount / 2
            return (0..<sampleCount).map { index in
                index < half ? 1.0 : -1.0
            }
        case .sawtooth:
            return (0..<sampleCount).map { index in
                let phase = Float(index) / Float(sampleCount)
                return 2.0 * phase - 1.0  // Linear rise from -1 to 1
            }
        case .custom:
            return Array(repeating: 0, count: sampleCount)
        }
    }
}

enum ChordType: String, CaseIterable, Codable {
    case major = "Major"
    case minor = "Minor"
    case seventh = "7th"
    case minorSeventh = "m7"
    case power = "Power"
    case detune = "Detune"
}

struct HarmonyInterval: RawRepresentable, Codable, Equatable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var displayName: String { rawValue }

    static let root = HarmonyInterval(rawValue: "Root")
    static let majorThird = HarmonyInterval(rawValue: "3rd")
    static let minorThird = HarmonyInterval(rawValue: "m3")
    static let fourth = HarmonyInterval(rawValue: "4th")
    static let fifth = HarmonyInterval(rawValue: "5th")
    static let flatFifth = HarmonyInterval(rawValue: "b5")
    static let flatSeventh = HarmonyInterval(rawValue: "b7")
    static let doubleFlatSeventh = HarmonyInterval(rawValue: "bb7")
    static let seventh = HarmonyInterval(rawValue: "7th")
    static let octave = HarmonyInterval(rawValue: "Oct")
    static let doubleOctave = HarmonyInterval(rawValue: "2Oct")
}

enum ScaleType: String, CaseIterable, Codable {
    case none = "None"
    case major = "Major"
    case majorPenta = "Major Penta"
    case minorPenta = "Minor Penta"
    case japanese = "Japanese"

    var displayName: String { rawValue }

    private var allowedPitchClasses: [Int]? {
        switch self {
        case .none:
            return nil
        case .major:
            return [0, 2, 4, 5, 7, 9, 11] // Major scale (C, D, E, F, G, A, B)
        case .majorPenta:
            return [0, 2, 4, 7, 9] // Major Pentatonic (C, D, E, G, A)
        case .minorPenta:
            return [0, 3, 5, 7, 10] // Minor Pentatonic (C, Eb, F, G, Bb)
        case .japanese:
            return [0, 1, 5, 7, 10] // Japanese scale (C, Db, F, G, Bb)
        }
    }

    func quantizeFrequency(_ frequency: Float) -> Float {
        guard let allowedPitchClasses = allowedPitchClasses, frequency > 0 else {
            return frequency
        }

        let midiValue = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
        var bestNote = Int(round(midiValue))
        var bestDistance = Double.greatestFiniteMagnitude

        let searchRange = (bestNote - 36)...(bestNote + 36)
        for note in searchRange {
            let normalizedPitchClass = ((note % 12) + 12) % 12
            guard allowedPitchClasses.contains(normalizedPitchClass) else { continue }

            let distance = abs(Double(note) - midiValue)
            if distance < bestDistance {
                bestDistance = distance
                bestNote = note
            }
        }

        let quantizedFrequency = 440.0 * pow(2.0, (Double(bestNote) - 69.0) / 12.0)
        return Float(quantizedFrequency)
    }
}

class Track: ObservableObject, Identifiable, Codable {
    static let waveformSampleCount = 512

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
        waveformData = waveformType.defaultSamples()
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
