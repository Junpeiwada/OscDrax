import SwiftUI

struct WaveformControlView: View {
    @ObservedObject var track: Track
    @State private var showPresetPicker = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                showPresetPicker = true
            }, label: {
                HStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                    Text(track.waveformType.displayName)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
            })
            .buttonStyle(LiquidglassButtonStyle())
            .popover(isPresented: $showPresetPicker) {
                PresetPickerView(track: track, isPresented: $showPresetPicker)
                    .frame(width: 280, height: 300)
                    .background(Color.clear)
                    .presentationBackground(.regularMaterial.opacity(0))
                    .presentationCompactAdaptation(.popover)
            }

            Spacer()

            Button(action: {
                track.setWaveformType(.custom)
                track.clearCustomWaveform()
            }, label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Clear")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
            })
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
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .cornerRadius(12)

            VStack(spacing: 20) {
                Text("Select Waveform")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.top, 20)

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
        .background(Color.clear)
    }
}

struct ScalePickerView: View {
    @Binding var scaleType: ScaleType
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .cornerRadius(12)

            VStack(spacing: 20) {
                Text("Select Scale")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.top, 20)

                VStack(spacing: 12) {
                    ForEach(ScaleType.allCases, id: \.self) { scale in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scaleType = scale
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }, label: {
                            HStack {
                                Text(scale.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                if scaleType == scale {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.1))
                                        .font(.system(size: 18))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(LiquidglassButtonStyle(isPlaying: scaleType == scale))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .background(Color.clear)
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
                    .foregroundColor(.white)

                Text(type.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.1))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidglassButtonStyle(isPlaying: isSelected))
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
