//
//  FormantType.swift
//  OscDrax
//
//  Formant filter types for vowel simulation
//

import Foundation

enum FormantType: String, CaseIterable, Codable {
    case none = "None"
    case vowelA = "A"
    case vowelI = "I"
    case vowelU = "U"
    case vowelE = "E"
    case vowelO = "O"

    var displayName: String { rawValue }

    // Formant frequencies in Hz
    var formantFrequencies: [Float] {
        switch self {
        case .none:
            return []
        case .vowelA:
            return [700, 1200, 2500]
        case .vowelI:
            return [300, 2300, 3200]
        case .vowelU:
            return [300, 700, 2500]
        case .vowelE:
            return [500, 1800, 2700]
        case .vowelO:
            return [500, 900, 2500]
        }
    }

    // Q factors (bandwidth) for each formant
    var formantQFactors: [Float] {
        switch self {
        case .none:
            return []
        case .vowelA, .vowelI, .vowelU, .vowelE, .vowelO:
            return [10, 12, 8]
        }
    }

    // Gain for each formant band (in dB)
    var formantGains: [Float] {
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

    // Overall mix level to prevent clipping
    var outputGain: Float {
        switch self {
        case .none:
            return 0.0  // No change when disabled
        case .vowelA, .vowelI, .vowelU, .vowelE, .vowelO:
            return -3.0  // Slight reduction for vowels
        }
    }
}