import SwiftUI

/// アプリ全体のテーマカラーを管理する構造体
struct AppTheme {
    struct Colors {
        // MARK: - 背景
        /// ContentViewの背景グラデーション
        static let backgroundGradient = [
            // #1A1A1A (RGB: 0.1, 0.1, 0.1) → H:0, S:0, B:0.1
            Color(UIColor(hue: 0.0, saturation: 0.0, brightness: 0.1, alpha: 1.0)),
            // #0D0D0D (RGB: 0.05, 0.05, 0.05) → H:0, S:0, B:0.05
            Color(UIColor(hue: 0.0, saturation: 0.0, brightness: 0.05, alpha: 1.0))
        ]

        // MARK: - 波形表示
        struct Waveform {
            /// メイン波形のグラデーション
            /// #33FF4D (RGB:0.2,1.0,0.3) → H:0.365, S:0.8, B:1.0
            /// #00CC33 (RGB:0.0,0.8,0.2) → H:0.375, S:1.0, B:0.8
            static let gradient = [
                Color(UIColor(hue: 0.365, saturation: 0.8, brightness: 1.0, alpha: 1.0)), // 明るい緑
                Color(UIColor(hue: 0.365, saturation: 1.0, brightness: 0.8, alpha: 1.0))  // 暗い緑
            ]

            /// 波形のグロー効果
            /// #00FF33 (RGB:0.0,1.0,0.2) → H:0.37, S:1.0, B:1.0
            static let glow = Color(UIColor(hue: 0.37, saturation: 1.0, brightness: 1.0, alpha: 0.6))

            /// グリッド線の色
            static let grid = Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.15))

            /// ミニ波形の背景色（非再生時）
            static let miniBackground = Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.2))

            /// ミニ波形のアクティブ色（再生時の暗い部分）
            static let miniActive = Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.1))
        }

        // MARK: - ボタン
        struct Button {
            /// Playボタンの背景グラデーション（停止中・暗い緑）
            /// #1A6633 (RGB:0.1,0.4,0.2) → H:0.375, S:0.75, B:0.4
            /// #0D4D1A (RGB:0.05,0.3,0.1) → H:0.375, S:0.833, B:0.3
            static let playBackgroundGradient = [
                Color(UIColor(hue: 0.333, saturation: 0.75, brightness: 0.4, alpha: 1.0)),
                Color(UIColor(hue: 0.333, saturation: 0.75, brightness: 0.3, alpha: 1.0))
            ]

            /// Stopボタンの背景グラデーション（再生中・明るい緑）
            /// #1AB333 (RGB:0.1,0.7,0.2) → H:0.375, S:0.857, B:0.7
            /// #0D991A (RGB:0.05,0.6,0.1) → H:0.375, S:0.917, B:0.6
            static let stopBackgroundGradient = [
                Color(UIColor(hue: 0.333, saturation: 0.857, brightness: 0.6, alpha: 1.0)),
                Color(UIColor(hue: 0.333, saturation: 0.857, brightness: 0.7, alpha: 1.0))
            ]

            /// Playボタンのボーダー
            static let playBorder = [
                Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.5)),
                Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.2))
            ]

            /// Stopボタンのボーダー
            static let stopBorder = [
                Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.7)),
                Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 0.3))
            ]

            /// Playボタンの影
            /// #004D0D (RGB:0.0,0.3,0.05) → H:0.388, S:1.0, B:0.3
            static let playShadow = Color(UIColor(hue: 0.388, saturation: 1.0, brightness: 0.3, alpha: 0.3))

            /// Stopボタンの影
            /// #00801A (RGB:0.0,0.5,0.1) → H:0.367, S:1.0, B:0.5
            static let stopShadow = Color(UIColor(hue: 0.367, saturation: 1.0, brightness: 0.5, alpha: 0.3))

            /// 通常ボタンの背景グラデーション
            static let normalBackgroundGradient = [
                Color(UIColor(hue: 0.333, saturation: 0.357, brightness: 0.3, alpha: 1.0)),
                Color(UIColor(hue: 0.333, saturation: 0.357, brightness: 0.4, alpha: 1.0))
            ]
            
            /// 通常ボタンの発音状態背景グラデーション
            static let normalHighlightBackgroundGradient = [
                Color(UIColor(hue: 0.333, saturation: 0.857, brightness: 0.6, alpha: 1.0)),
                Color(UIColor(hue: 0.333, saturation: 0.857, brightness: 0.7, alpha: 1.0))
            ]
        }

        // MARK: - スライダー
        struct Slider {
            /// #33E64D (RGB:0.2,0.9,0.3) → H:0.37, S:0.78, B:0.9
            static let tint = Color(UIColor(hue: 0.37, saturation: 0.78, brightness: 0.9, alpha: 1.0))
        }

        // MARK: - トラックタブ
        struct TrackTab {
            /// 再生中インジケーター: Color.green
            static let playingIndicator = Color(UIColor(hue: 0.333, saturation: 1.0, brightness: 0.5, alpha: 1.0))
        }
    }
}
