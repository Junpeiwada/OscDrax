import Foundation

/// 合成器で扱う波形種別を表す列挙体。
public enum WaveformType: String, CaseIterable, Codable {
    case sine
    case triangle
    case square
    case sawtooth
    case custom

    /// UI 表示やログ用の名称を返します。
    public var displayName: String {
        switch self {
        case .sine: return "Sin"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .sawtooth: return "Saw"
        case .custom: return "Custom"
        }
    }
}

public extension WaveformType {
    /// 指定したサンプル数でデフォルト波形を生成します。
    /// - Parameter sampleCount: 波形テーブルのサンプル数。
    /// - Returns: 生成された波形テーブル。
    func defaultSamples(sampleCount: Int = SynthConstants.defaultWaveformSampleCount) -> [Float] {
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
                return 2.0 * phase - 1.0
            }
        case .custom:
            return Array(repeating: 0, count: sampleCount)
        }
    }
}

/// ハーモニー生成時に利用するコード種別。
public enum ChordType: String, CaseIterable, Codable {
    case major = "Major"
    case minor = "Minor"
    case seventh = "7th"
    case minorSeventh = "m7"
    case power = "Power"
    case detune = "Detune"
}

/// ハーモニーで割り当てる音程ラベルを表す構造体。
public struct HarmonyInterval: RawRepresentable, Codable, Equatable {
    public let rawValue: String

    /// 生の文字列からイニシャライザ。
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// 表示用の名称を返します。
    public var displayName: String { rawValue }

    public static let root = HarmonyInterval(rawValue: "Root")
    public static let majorThird = HarmonyInterval(rawValue: "3rd")
    public static let minorThird = HarmonyInterval(rawValue: "m3")
    public static let fourth = HarmonyInterval(rawValue: "4th")
    public static let fifth = HarmonyInterval(rawValue: "5th")
    public static let flatFifth = HarmonyInterval(rawValue: "b5")
    public static let flatSeventh = HarmonyInterval(rawValue: "b7")
    public static let doubleFlatSeventh = HarmonyInterval(rawValue: "bb7")
    public static let seventh = HarmonyInterval(rawValue: "7th")
    public static let octave = HarmonyInterval(rawValue: "Oct")
    public static let doubleOctave = HarmonyInterval(rawValue: "2Oct")
}

/// ピッチクオンタイズに使用するスケール種別。
public enum ScaleType: String, CaseIterable, Codable {
    case none = "None"
    case major = "Major"
    case majorPenta = "Major Penta"
    case minorPenta = "Minor Penta"
    case japanese = "Japanese"

    /// UI 表示用の名称を返します。
    public var displayName: String { rawValue }

    private var allowedPitchClasses: [Int]? {
        switch self {
        case .none:
            return nil
        case .major:
            return [0, 2, 4, 5, 7, 9, 11]
        case .majorPenta:
            return [0, 2, 4, 7, 9]
        case .minorPenta:
            return [0, 3, 5, 7, 10]
        case .japanese:
            return [0, 1, 5, 7, 10]
        }
    }

    /// 入力周波数をスケールに合わせてクオンタイズします。
    /// - Parameter frequency: 元の周波数。
    /// - Returns: スケール上に丸めた周波数。
    public func quantizeFrequency(_ frequency: Float) -> Float {
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
