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

class Track: ObservableObject, Identifiable, Codable {
    let id: Int
    @Published var waveformType: WaveformType = .sine
    @Published var waveformData: [Float] = []
    @Published var frequency: Float = 440.0
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    @Published var portamentoTime: Float = 20.0  // Fixed at 20ms for smooth transitions

    init(id: Int) {
        self.id = id
        generateDefaultWaveform()
    }

    enum CodingKeys: String, CodingKey {
        case id, waveformType, waveformData, frequency, volume, isPlaying, portamentoTime
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
