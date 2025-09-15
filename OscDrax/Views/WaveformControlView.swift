import SwiftUI

struct WaveformControlView: View {
    @ObservedObject var track: Track
    @State private var showPresetPicker = false

    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                showPresetPicker = true
            }) {
                HStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                    Text(track.waveformType.displayName)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(LiquidglassButtonStyle())
            .sheet(isPresented: $showPresetPicker) {
                PresetPickerView(track: track, isPresented: $showPresetPicker)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(30)
                    .presentationBackground(.thinMaterial)
            }

            Spacer()

            Button(action: {
                track.setWaveformType(.custom)
                track.clearCustomWaveform()
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Clear")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(LiquidglassButtonStyle())
        }
    }
}

struct PresetPickerView: View {
    @ObservedObject var track: Track
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Harmonized background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.95),
                    Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                // Subtle noise texture
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.05), location: 0),
                        .init(color: Color.clear, location: 0.3),
                        .init(color: Color.white.opacity(0.02), location: 0.7),
                        .init(color: Color.clear, location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: 20) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                Text("Select Waveform")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)

                VStack(spacing: 12) {
                    ForEach([WaveformType.sine, .triangle, .square], id: \.self) { type in
                        WaveformButton(
                            type: type,
                            isSelected: track.waveformType == type,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    track.setWaveformType(type)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isPresented = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
    }
}

struct WaveformButton: View {
    let type: WaveformType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                Text(type.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.5))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidglassButtonStyle())
        .overlay(
            isSelected ?
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.5), lineWidth: 2)
            : nil
        )
    }

    private var iconName: String {
        switch type {
        case .sine: return "waveform.path"
        case .triangle: return "triangle"
        case .square: return "square"
        case .custom: return "scribble"
        }
    }
}
