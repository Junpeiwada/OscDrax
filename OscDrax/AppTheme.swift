import SwiftUI

/// アプリ全体のテーマカラーを管理する構造体
struct AppTheme {

    struct Colors {

        // MARK: - 背景
        /// ContentViewの背景グラデーション
        static let backgroundGradient = [
            Color(red: 0.1, green: 0.1, blue: 0.1),    // 開始色（左上）
            Color(red: 0.05, green: 0.05, blue: 0.05)  // 終了色（右下）
        ]

        // MARK: - 波形表示
        struct Waveform {
            /// メイン波形のグラデーション
            /// 使用箇所: WaveformDisplayView、MiniWaveformView
            static let gradient = [
                Color(red: 0.2, green: 1.0, blue: 0.3),   // 明るい緑
                Color(red: 0.0, green: 0.8, blue: 0.2)    // 暗い緑
            ]

            /// 波形のグロー効果
            /// 使用箇所: WaveformDisplayViewの影
            static let glow = Color(red: 0.0, green: 1.0, blue: 0.2).opacity(0.6)

            /// グリッド線の色
            /// 使用箇所: WaveformDisplayViewの10x8グリッド
            static let grid = Color.green.opacity(0.15)

            /// ミニ波形の背景色（非再生時）
            /// 使用箇所: MiniWaveformView
            static let miniBackground = Color.green.opacity(0.2)

            /// ミニ波形のアクティブ色（再生時の暗い部分）
            /// 使用箇所: MiniWaveformView
            static let miniActive = Color.green.opacity(0.1)
        }

        // MARK: - ボタン
        struct Button {
            /// Playボタンの背景グラデーション（停止中・暗い緑）
            /// 使用箇所: PlayStopButtonStyle（isStop = false）
            static let playBackgroundGradient = [
                Color(red: 0.05, green: 0.3, blue: 0.1),
                Color(red: 0.02, green: 0.25, blue: 0.05)
            ]

            /// Stopボタンの背景グラデーション（再生中・明るい緑）
            /// 使用箇所: PlayStopButtonStyle（isStop = true）
            static let stopBackgroundGradient = [
                Color(red: 0.1, green: 0.7, blue: 0.2),
                Color(red: 0.05, green: 0.6, blue: 0.1)
            ]

            /// 通常ボタンの背景グラデーション
            /// 使用箇所: LiquidglassButtonStyle（プリセット選択など）
            static let normalBackgroundGradient = [
                Color(red: 0.1, green: 0.4, blue: 0.2),
                Color(red: 0.05, green: 0.3, blue: 0.1)
            ]

            /// Playボタンのボーダー
            /// 使用箇所: PlayStopButtonStyleのストローク（停止中）
            static let playBorder = [
                Color.green.opacity(0.5),
                Color.green.opacity(0.2)
            ]

            /// Stopボタンのボーダー
            /// 使用箇所: PlayStopButtonStyleのストローク（再生中）
            static let stopBorder = [
                Color.green.opacity(0.7),
                Color.green.opacity(0.3)
            ]

            /// Playボタンの影
            /// 使用箇所: PlayStopButtonStyleのシャドウ（停止中）
            static let playShadow = Color(red: 0.0, green: 0.3, blue: 0.05).opacity(0.3)

            /// Stopボタンの影
            /// 使用箇所: PlayStopButtonStyleのシャドウ（再生中）
            static let stopShadow = Color(red: 0.0, green: 0.5, blue: 0.1).opacity(0.3)
        }

        // MARK: - スライダー
        struct Slider {
            /// スライダーのティント色
            /// 使用箇所: LiquidglassSliderStyle
            static let tint = Color(red: 0.2, green: 0.9, blue: 0.3)
        }

        // MARK: - トラックタブ
        struct TrackTab {
            /// 再生中インジケーター
            /// 使用箇所: TrackTabButtonの緑の点
            static let playingIndicator = Color.green
        }
    }
}