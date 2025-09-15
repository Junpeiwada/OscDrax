import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var track: Track

    var body: some View {
        VStack(spacing: 25) {
            FrequencyControlView(frequency: $track.frequency)
            VolumeControlView(volume: $track.volume)
            PlayButtonView(isPlaying: $track.isPlaying)
        }
    }
}

struct FrequencyControlView: View {
    @Binding var frequency: Float
    private let minFreq: Float = 20
    private let maxFreq: Float = 20_000

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Hz")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(Int(frequency)) Hz")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }

            Slider(
                value: Binding(
                    get: { logScale(frequency) },
                    set: { frequency = expScale($0) }
                ),
                in: 0...1
            )
            .liquidglassSliderStyle()
        }
    }

    private func logScale(_ value: Float) -> Float {
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logValue = log10(max(minFreq, value))
        return (logValue - logMin) / (logMax - logMin)
    }

    private func expScale(_ value: Float) -> Float {
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logValue = logMin + value * (logMax - logMin)
        return pow(10, logValue)
    }
}

struct VolumeControlView: View {
    @Binding var volume: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Volume")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }

            Slider(value: $volume, in: 0...1)
                .liquidglassSliderStyle()
        }
    }
}

struct PlayButtonView: View {
    @Binding var isPlaying: Bool

    var body: some View {
        Button(action: {
            isPlaying.toggle()
        }) {
            HStack {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 20))
                Text(isPlaying ? "Stop" : "Play")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(LiquidglassButtonStyle())
    }
}
