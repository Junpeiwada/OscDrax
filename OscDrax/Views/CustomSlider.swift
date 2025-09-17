import SwiftUI

struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let onChanged: ((Float) -> Void)?
    let useLiquidGlassStyle: Bool

    init(
        value: Binding<Float>,
        in range: ClosedRange<Float> = 0...1,
        onChanged: ((Float) -> Void)? = nil,
        useLiquidGlassStyle: Bool = true
    ) {
        self._value = value
        self.range = range
        self.onChanged = onChanged
        self.useLiquidGlassStyle = useLiquidGlassStyle
    }

    var body: some View {
        ZStack {
            // 標準のSliderを表示
            if useLiquidGlassStyle {
                Slider(value: $value, in: range)
                    .liquidglassSliderStyle()
                    .allowsHitTesting(false)  // タッチイベントを通過させる
            } else {
                Slider(value: $value, in: range)
                    .tint(AppTheme.Colors.Slider.tint)
                    .allowsHitTesting(false)  // タッチイベントを通過させる
            }

            // タッチ可能な透明レイヤー
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)  // minimumDistance: 0で即座に反応
                            .onChanged { drag in
                                let normalizedValue = Float(drag.location.x / geometry.size.width)
                                let rangeWidth = range.upperBound - range.lowerBound
                                let scaledValue = range.lowerBound + (normalizedValue * rangeWidth)
                                let clampedValue = max(range.lowerBound, min(range.upperBound, scaledValue))
                                value = clampedValue
                                onChanged?(clampedValue)
                            }
                    )
            }
        }
        .frame(height: 30)  // 標準Sliderと同じ高さ
    }
}
