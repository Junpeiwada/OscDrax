import SwiftUI

struct CustomFrequencySlider: View {
    @Binding var value: Float  // 0...1の正規化された値
    let onChanged: (Float) -> Void

    var body: some View {
        CustomSlider(
            value: $value,
            in: 0...1,
            onChanged: onChanged,
            useLiquidGlassStyle: false
        )
    }
}
