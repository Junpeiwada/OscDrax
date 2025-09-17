import Foundation

/// 母音シミュレーション用のフォルマント設定を表す列挙体。
/// UI やオーディオエンジンから選択して利用します。
public enum FormantType: String, CaseIterable, Codable {
    case none = "None"
    case vowelA = "A"
    case vowelI = "I"
    case vowelU = "U"
    case vowelE = "E"
    case vowelO = "O"

    /// UI 表示用の名称を返します。
    public var displayName: String { rawValue }

    /// フォルマント周波数 (Hz) を返します。
    public var formantFrequencies: [Float] {
        switch self {
        case .none:
            return []
        case .vowelA:
            return [700, 1_200, 2_500]
        case .vowelI:
            return [300, 2_300, 3_200]
        case .vowelU:
            return [300, 700, 2_500]
        case .vowelE:
            return [500, 1_800, 2_700]
        case .vowelO:
            return [500, 900, 2_500]
        }
    }

    /// 各フォルマント帯域の Q 値を返します。
    public var formantQFactors: [Float] {
        switch self {
        case .none:
            return []
        case .vowelA, .vowelI, .vowelU, .vowelE, .vowelO:
            return [10, 12, 8]
        }
    }

    /// 各フォルマント帯域のゲイン (dB) を返します。
    public var formantGains: [Float] {
        switch self {
        case .none:
            return []
        case .vowelA:
            return [12, 10, 6]
        case .vowelI:
            return [10, 12, 8]
        case .vowelU:
            return [12, 8, 4]
        case .vowelE:
            return [11, 10, 6]
        case .vowelO:
            return [12, 9, 5]
        }
    }

    /// クリッピングを抑えるための出力ゲイン (dB) を返します。
    public var outputGain: Float {
        switch self {
        case .none:
            return 0.0
        case .vowelA, .vowelI, .vowelU, .vowelE, .vowelO:
            return -3.0
        }
    }
}
