import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var track: Track
    @Binding var globalChordType: ChordType
    var onChordTypeChanged: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            FrequencyControlView(
                frequency: $track.frequency,
                scaleType: $track.scaleType
            )
            HarmonyControlView(
                track: track,
                globalChordType: $globalChordType,
                onChordTypeChanged: onChordTypeChanged
            )
            VolumeControlView(volume: $track.volume)
            PortamentoControlView(portamentoTime: $track.portamentoTime)
            PlayButtonView(isPlaying: $track.isPlaying)
        }
    }
}

struct FrequencyControlView: View {
    @Binding var frequency: Float
    @Binding var scaleType: ScaleType
    @State private var showScalePicker = false
    private let minFreq: Float = 20
    private let maxFreq: Float = 20_000

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("Frequency")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 80, alignment: .leading)

                CustomFrequencySlider(
                    value: Binding(
                        get: { logScale(frequency) },
                        set: { newValue in
                            let rawFrequency = expScale(newValue)
                            frequency = scaleType.quantizeFrequency(rawFrequency)
                        }
                    ),
                    onChanged: { newValue in
                        let rawFrequency = expScale(newValue)
                        frequency = scaleType.quantizeFrequency(rawFrequency)
                    }
                )
                .liquidglassSliderStyle()

                Text("\(Int(frequency))")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 50, alignment: .trailing)
            }
            .frame(height: 30)
            .padding(.bottom, 10)

            HStack(spacing: 12) {
                Text("Scale")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 80, alignment: .leading)

                Button(action: {
                    showScalePicker = true
                }, label: {
                    Text(scaleType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(LiquidglassButtonStyle())
                .popover(isPresented: $showScalePicker, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                    ScalePickerView(scaleType: $scaleType, isPresented: $showScalePicker)
                        .frame(width: 260, height: 300)
                        .background(Color.clear)
                        .presentationBackground(.regularMaterial.opacity(0))
                        .presentationCompactAdaptation(.popover)
                }
            }
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
        HStack(spacing: 12) {
            Text("Volume")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .leading)

            CustomSlider(
                value: $volume,
                in: 0...1,
                useLiquidGlassStyle: true
            )

            Text("\(Int(volume * 100))%")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 50, alignment: .trailing)
        }
        .frame(height: 30)
    }
}

struct PortamentoControlView: View {
    @Binding var portamentoTime: Float

    var body: some View {
        HStack(spacing: 12) {
            Text("Portamento")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .leading)

            CustomSlider(
                value: $portamentoTime,
                in: 0...1_000,
                useLiquidGlassStyle: true
            )

            Text("\(Int(portamentoTime))ms")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 50, alignment: .trailing)
        }
        .frame(height: 30)
    }
}

struct HarmonyControlView: View {
    @ObservedObject var track: Track
    @Binding var globalChordType: ChordType
    var onChordTypeChanged: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            // First row: Harmony Toggle + Position label + Vibrato Toggle
            HStack(spacing: 12) {
                Text("Harmony")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 80, alignment: .leading)

                Toggle("", isOn: $track.harmonyEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.9, green: 0.5, blue: 0.1)))
                    .labelsHidden()
                    .scaleEffect(0.8)

                Spacer()

                Text(track.harmonyEnabled ? (track.assignedInterval ?? "--") : "--")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(track.harmonyEnabled ? Color(red: 0.9, green: 0.5, blue: 0.1) : .gray)
                    .frame(width: 50)

                Spacer()

                // Vibrato Toggle
                Text("Vibrato")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(minWidth: 55)

                Toggle("", isOn: $track.vibratoEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.9, green: 0.5, blue: 0.1)))
                    .labelsHidden()
                    .scaleEffect(0.8)
            }

            // Second row: Chord Type Selector (compact)
            HStack(spacing: 8) {
                Text("Chord")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(track.harmonyEnabled ? 0.8 : 0.3))
                    .frame(width: 60, alignment: .leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(ChordType.allCases, id: \.self) { chord in
                            Button(action: {
                                if track.harmonyEnabled {
                                    globalChordType = chord
                                    onChordTypeChanged()
                                }
                            }, label: {
                                Text(chord.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(chordForegroundColor(for: chord))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(chordBackgroundColor(for: chord))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(chordBorderColor, lineWidth: 1)
                                    )
                            })
                            .disabled(!track.harmonyEnabled)
                        }
                    }
                }
                .opacity(track.harmonyEnabled ? 1.0 : 0.4)
            }

        }
    }
}

private extension HarmonyControlView {
    var chordBorderColor: Color {
        Color.white.opacity(track.harmonyEnabled ? 0.2 : 0.1)
    }

    func chordForegroundColor(for chord: ChordType) -> Color {
        guard track.harmonyEnabled else { return .gray }
        return globalChordType == chord ? .black : .white
    }

    func chordBackgroundColor(for chord: ChordType) -> Color {
        let activeColor = Color(red: 0.9, green: 0.5, blue: 0.1)
        guard track.harmonyEnabled else {
            return Color.gray.opacity(globalChordType == chord ? 0.3 : 0.1)
        }
        return globalChordType == chord ? activeColor : Color.white.opacity(0.1)
    }

}

struct PlayButtonView: View {
    @Binding var isPlaying: Bool

    var body: some View {
        Button(action: {
            isPlaying.toggle()
        }, label: {
            HStack {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 20))
                Text(isPlaying ? "Stop" : "Play")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        })
        .buttonStyle(LiquidglassButtonStyle(isPlaying: isPlaying))
    }
}
