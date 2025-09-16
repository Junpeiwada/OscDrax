import Foundation
import SwiftUI

enum WaveformType: String, CaseIterable, Codable {
    case sine
    case triangle
    case square
    case custom

    var displayName: String {
        switch self {
        case .sine: return "Sin"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .custom: return "Custom"
        }
    }
}

enum ChordType: String, CaseIterable, Codable {
    case major = "Major"
    case minor = "Minor"
    case seventh = "7th"
    case minorSeventh = "m7"
    case majorSeventh = "Maj7"
    case sus4 = "Sus4"
    case diminished = "Dim"
    case power = "Power"
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
    let id: Int
    @Published var waveformType: WaveformType = .sine
    @Published var waveformData: [Float] = []
    @Published var frequency: Float = 440.0
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    @Published var portamentoTime: Float = 0.0  // 0-1000ms range
    @Published var harmonyEnabled: Bool = true
    @Published var assignedInterval: String?  // Automatically assigned interval
    @Published var isHarmonyMaster: Bool = false
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
        case harmonyEnabled, assignedInterval, isHarmonyMaster, scaleType, vibratoEnabled
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
        assignedInterval = try container.decodeIfPresent(String.self, forKey: .assignedInterval)
        isHarmonyMaster = try container.decodeIfPresent(Bool.self, forKey: .isHarmonyMaster) ?? false
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
        try container.encode(isHarmonyMaster, forKey: .isHarmonyMaster)
        try container.encode(scaleType, forKey: .scaleType)
        try container.encode(vibratoEnabled, forKey: .vibratoEnabled)
    }

    func generateDefaultWaveform() {
        waveformData = Array(repeating: 0, count: 512)
        switch waveformType {
        case .sine:
            for index in 0..<512 {
                let angle = Float(index) / 512.0 * Float.pi * 2
                waveformData[index] = sin(angle)
            }
        case .triangle:
            for index in 0..<512 {
                let phase = Float(index) / 512.0
                if phase < 0.25 {
                    waveformData[index] = phase * 4
                } else if phase < 0.75 {
                    waveformData[index] = 2 - phase * 4
                } else {
                    waveformData[index] = phase * 4 - 4
                }
            }
        case .square:
            for index in 0..<512 {
                waveformData[index] = index < 256 ? 1.0 : -1.0
            }
        case .custom:
            break
        }
    }

    func setWaveformType(_ type: WaveformType) {
        waveformType = type
        if type != .custom {
            generateDefaultWaveform()
        }
    }

    func clearCustomWaveform() {
        // Generate a default flat line at center
        waveformData = Array(repeating: 0, count: 512)
    }
}
