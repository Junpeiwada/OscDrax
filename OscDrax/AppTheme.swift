import SwiftUI

/// アプリ全体のテーマカラーを管理する構造体
struct AppTheme {
    struct Colors {
        private static func hsb(_ hue: Double,
                                _ saturation: Double,
                                _ brightness: Double,
                                _ opacity: Double = 1.0) -> Color {
            Color(hue: hue, saturation: saturation, brightness: brightness, opacity: opacity)
        }

        // MARK: - 背景
        /// ContentViewの背景グラデーション
        static let backgroundGradient = [
            // #1A1A1A (RGB: 0.1, 0.1, 0.1) → H:0, S:0, B:0.1
            hsb(0.0, 0.0, 0.1),
            // #0D0D0D (RGB: 0.05, 0.05, 0.05) → H:0, S:0, B:0.05
            hsb(0.0, 0.0, 0.05)
        ]

        // MARK: - 波形表示
        struct Waveform {
            /// メイン波形のグラデーション
            /// #33FF4D (RGB:0.2,1.0,0.3) → H:0.365, S:0.8, B:1.0
            /// #00CC33 (RGB:0.0,0.8,0.2) → H:0.375, S:1.0, B:0.8
            static let gradient = [
                hsb(0.365, 0.8, 1.0), // 明るい緑
                hsb(0.365, 1.0, 0.8)  // 暗い緑
            ]

            /// 波形のグロー効果
            /// #00FF33 (RGB:0.0,1.0,0.2) → H:0.37, S:1.0, B:1.0
            static let glow = hsb(0.37, 1.0, 1.0, 0.6)

            /// グリッド線の色
            static let grid = hsb(0.333, 1.0, 0.5, 0.15)

            /// ミニ波形の背景色（非再生時）
            static let miniBackground = hsb(0.333, 1.0, 0.5, 0.2)

            /// ミニ波形のアクティブ色（再生時の暗い部分）
            static let miniActive = hsb(0.333, 1.0, 0.5, 0.1)
        }

        // MARK: - ボタン
        struct Button {
            /// 通常ボタンの背景グラデーション
            static let normalBackgroundGradient = [
                hsb(0.383, 0.357, 0.4),
                hsb(0.383, 0.357, 0.3)
            ]
            
            /// 通常ボタンの発音状態背景グラデーション
            static let normalHighlightBackgroundGradient = [
                hsb(0.333, 0.857, 0.5),
                hsb(0.333, 0.857, 0.4)
            ]
        }

        // MARK: - スライダー
        struct Slider {
            /// #33E64D (RGB:0.2,0.9,0.3) → H:0.37, S:0.78, B:0.9
            static let tint = hsb(0.37, 0.78, 0.9)
        }

        // MARK: - トラックタブ
        struct TrackTab {
            /// 再生中インジケーター: Color.green
            static let playingIndicator = hsb(0.333, 1.0, 0.5)
        }
    }
}
