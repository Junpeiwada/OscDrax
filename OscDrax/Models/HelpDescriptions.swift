import Foundation

struct HelpDescriptions {
    enum HelpItem {
        case frequency
        case scale
        case volume
        case portamento
        case harmony
        case vibrato
        case chord
        case formant
        case waveform

        var title: String {
            let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false

            switch self {
            case .frequency:
                return isJapanese ? "周波数" : "Frequency"
            case .scale:
                return isJapanese ? "スケール" : "Scale"
            case .volume:
                return isJapanese ? "音量" : "Volume"
            case .portamento:
                return isJapanese ? "ポルタメント" : "Portamento"
            case .harmony:
                return isJapanese ? "ハーモニー" : "Harmony"
            case .vibrato:
                return isJapanese ? "ビブラート" : "Vibrato"
            case .chord:
                return isJapanese ? "コード" : "Chord"
            case .formant:
                return isJapanese ? "フォルマント" : "Formant"
            case .waveform:
                return isJapanese ? "波形" : "Waveform"
            }
        }

        var description: String {
            let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false

            switch self {
            case .frequency:
                return isJapanese
                    ? "音の高さを調整します。\n20Hzから20,000Hzの範囲で設定できます。低い値は低音、高い値は高音になります。"
                    : "Controls the pitch of the sound.\nRange: 20Hz to 20,000Hz. Lower values produce bass tones, higher values produce treble tones."

            case .scale:
                return isJapanese
                    ? "選択したスケールに音程をクオンタイズ（自動補正）します。\nメジャー、マイナー、ペンタトニック、日本音階などが選択できます。"
                    : "Quantizes pitch to the selected musical scale.\nOptions include Major, Minor, Pentatonic, and Japanese scales."

            case .volume:
                return isJapanese
                    ? "音の大きさを調整します。\n0%（無音）から100%（最大音量）まで設定できます。"
                    : "Adjusts the loudness of the sound.\nRange: 0% (silent) to 100% (maximum volume)."

            case .portamento:
                return isJapanese
                    ? "音程が変化する際の滑らかさを調整します。\n0msで即座に変化、1000msで1秒かけてゆっくり変化します。"
                    : "Controls the smoothness of pitch changes.\n0ms for instant change, up to 1000ms for a 1-second glide."

            case .harmony:
                return isJapanese
                    ? "他のトラックと自動的にハーモニーを作ります。\nマスタートラックの周波数に追従して和音を形成します。"
                    : "Automatically creates harmony with other tracks.\nFollows the master track's frequency to form chords."

            case .vibrato:
                return isJapanese
                    ? "音程を周期的に揺らして表現力を加えます。\n周波数が安定してから500ms後に自動的に開始されます。"
                    : "Adds periodic pitch fluctuation for expression.\nAutomatically starts 500ms after frequency stabilizes."

            case .chord:
                return isJapanese
                    ? "ハーモニーの種類を選択します。\nMajor（明るい）、Minor（暗い）、7th（ジャズ風）、Power（力強い）、Detune（厚い）など。"
                    : "Selects harmony type.\nMajor (bright), Minor (dark), 7th (jazzy), Power (strong), Detune (thick), etc."

            case .formant:
                return isJapanese
                    ? "音色に母音の特性を加えます。\n人間の声の「あ」「い」「う」「え」「お」の共鳴特性をシミュレートします。"
                    : "Adds vowel characteristics to the sound.\nSimulates the resonance of human vowels A, I, U, E, O."

            case .waveform:
                return isJapanese
                    ? "基本となる波形を選択または描画します。\nSin（純音）、Triangle（柔らかい）、Square（硬い）、Saw（明るい）、Custom（手描き）。"
                    : "Select or draw the base waveform.\nSine (pure), Triangle (soft), Square (hard), Saw (bright), Custom (hand-drawn)."
            }
        }
    }
}