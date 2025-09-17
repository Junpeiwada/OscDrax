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
                    ? [
                        "音の高さを調整します。",
                        "20Hzから20,000Hzの範囲で設定できます。低い値は低音、高い値は高音になります。"
                    ].joined(separator: "\n")
                    : [
                        "Controls the pitch of the sound.",
                        "Range: 20Hz to 20,000Hz. Lower values produce bass tones, higher values produce treble tones."
                    ].joined(separator: "\n")

            case .scale:
                return isJapanese
                    ? [
                        "選択したスケールに音程をクオンタイズ（自動補正）します。",
                        "メジャー、マイナー、ペンタトニック、日本音階などが選択できます。"
                    ].joined(separator: "\n")
                    : [
                        "Quantizes pitch to the selected musical scale.",
                        "Options include Major, Minor, Pentatonic, and Japanese scales."
                    ].joined(separator: "\n")

            case .volume:
                return isJapanese
                    ? [
                        "音の大きさを調整します。",
                        "0%（無音）から100%（最大音量）まで設定できます。"
                    ].joined(separator: "\n")
                    : [
                        "Adjusts the loudness of the sound.",
                        "Range: 0% (silent) to 100% (maximum volume)."
                    ].joined(separator: "\n")

            case .portamento:
                return isJapanese
                    ? [
                        "音程が変化する際の滑らかさを調整します。",
                        "0msで即座に変化、1000msで1秒かけてゆっくり変化します。"
                    ].joined(separator: "\n")
                    : [
                        "Controls the smoothness of pitch changes.",
                        "0ms for instant change, up to 1000ms for a 1-second glide."
                    ].joined(separator: "\n")

            case .harmony:
                return isJapanese
                    ? [
                        "他のトラックと自動的にハーモニーを作ります。",
                        "リードトラックの周波数に追従して和音を形成します。"
                    ].joined(separator: "\n")
                    : [
                        "Automatically creates harmony with other tracks.",
                        "Follows the harmony lead track's frequency to form chords."
                    ].joined(separator: "\n")

            case .vibrato:
                return isJapanese
                    ? [
                        "音程を周期的に揺らして表現力を加えます。",
                        "周波数が安定してから500ms後に自動的に開始されます。"
                    ].joined(separator: "\n")
                    : [
                        "Adds periodic pitch fluctuation for expression.",
                        "Automatically starts 500ms after frequency stabilizes."
                    ].joined(separator: "\n")

            case .chord:
                return isJapanese
                    ? [
                        "ハーモニーの種類を選択します。",
                        "Major（明るい）、Minor（暗い）、7th（ジャズ風）、Power（力強い）、Detune（厚い）など。"
                    ].joined(separator: "\n")
                    : [
                        "Selects harmony type.",
                        "Major (bright), Minor (dark), 7th (jazzy), Power (strong), Detune (thick), etc."
                    ].joined(separator: "\n")

            case .formant:
                return isJapanese
                    ? [
                        "音色に母音の特性を加えます。",
                        "人間の声の「あ」「い」「う」「え」「お」の共鳴特性をシミュレートします。"
                    ].joined(separator: "\n")
                    : [
                        "Adds vowel characteristics to the sound.",
                        "Simulates the resonance of human vowels A, I, U, E, O."
                    ].joined(separator: "\n")

            case .waveform:
                return isJapanese
                    ? [
                        "基本となる波形を選択または描画します。",
                        "Sin（純音）、Triangle（柔らかい）、Square（硬い）、Saw（明るい）、Custom（手描き）。"
                    ].joined(separator: "\n")
                    : [
                        "Select or draw the base waveform.",
                        "Sine (pure), Triangle (soft), Square (hard), Saw (bright), Custom (hand-drawn)."
                    ].joined(separator: "\n")
            }
        }
    }
}
