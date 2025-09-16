import SwiftUI

struct CustomFrequencySlider: View {
    @Binding var value: Float  // 0...1の正規化された値
    let onChanged: (Float) -> Void

    var body: some View {
        ZStack {
            // 標準のSliderを表示
            Slider(value: $value, in: 0...1)
                .tint(AppTheme.Colors.Slider.tint)
                .allowsHitTesting(false)  // タッチイベントを通過させる

            // タッチ可能な透明レイヤー
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)  // minimumDistance: 0で即座に反応
                            .onChanged { drag in
                                let newValue = Float(drag.location.x / geometry.size.width)
                                let clampedValue = max(0, min(1, newValue))
                                value = clampedValue
                                onChanged(clampedValue)
                            }
                    )
            }
        }
        .frame(height: 30)  // 標準Sliderと同じ高さ
    }
}