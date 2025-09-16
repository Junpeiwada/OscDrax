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
    private let minFreq: Float = 20
    private let maxFreq: Float = 20_000

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("Frequency")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 80, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { logScale(frequency) },
                        set: { newValue in
                            let rawFrequency = expScale(newValue)
                            frequency = scaleType.quantizeFrequency(rawFrequency)
                        }
                    ),
                    in: 0...1
                )
                .liquidglassSliderStyle()

                Text("\(Int(frequency))")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 50, alignment: .trailing)
            }
            .frame(height: 30)

            HStack(spacing: 12) {
                Text("Scale")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 80, alignment: .leading)

                Picker("Scale", selection: $scaleType) {
                    ForEach(ScaleType.allCases, id: \.self) { scale in
                        Text(scale.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .tag(scale)
                    }
                }
                .pickerStyle(.segmented)
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

            Slider(value: $volume, in: 0...1)
                .liquidglassSliderStyle()

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

            Slider(value: $portamentoTime, in: 0...1_000)
                .liquidglassSliderStyle()

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
            // First row: Harmony Toggle + Position label
            HStack(spacing: 12) {
                Text("Harmony")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 60, alignment: .leading)

                Toggle("", isOn: $track.harmonyEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.9, green: 0.5, blue: 0.1)))
                    .labelsHidden()
                    .scaleEffect(0.8)

                Spacer(minLength: 0)

                Text("Position")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(track.harmonyEnabled ? 0.6 : 0.3))

                Text(track.harmonyEnabled ? (track.assignedInterval ?? "--") : "--")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(track.harmonyEnabled ? Color(red: 0.9, green: 0.5, blue: 0.1) : .gray)
                    .frame(width: 40)

                Spacer()
            }

            // Second row: Chord Type Selector (compact)
            HStack(spacing: 8) {
                Text("Chord")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(track.harmonyEnabled ? 0.6 : 0.3))
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

            // Third row: Octave Selector (compact)
            HStack(spacing: 8) {
                Text("Octave")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(track.harmonyEnabled ? 0.6 : 0.3))
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    ForEach([-2, -1, 0, 1, 2], id: \.self) { offset in
                        Button(action: {
                            if track.harmonyEnabled {
                                track.octaveOffset = offset
                            }
                        }, label: {
                            Text(offset > 0 ? "+\(offset)" : "\(offset)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(octaveForegroundColor(for: offset))
                                .frame(width: 28)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(octaveBackgroundColor(for: offset))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(chordBorderColor, lineWidth: 1)
                                )
                        })
                        .disabled(!track.harmonyEnabled)
                    }
                }
                .opacity(track.harmonyEnabled ? 1.0 : 0.4)

                Spacer()
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

    func octaveForegroundColor(for offset: Int) -> Color {
        guard track.harmonyEnabled else { return .gray }
        return track.octaveOffset == offset ? .black : .white
    }

    func octaveBackgroundColor(for offset: Int) -> Color {
        let activeColor = Color(red: 0.9, green: 0.5, blue: 0.1)
        guard track.harmonyEnabled else {
            return Color.gray.opacity(track.octaveOffset == offset ? 0.3 : 0.1)
        }
        return track.octaveOffset == offset ? activeColor : Color.white.opacity(0.1)
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
        .buttonStyle(PlayStopButtonStyle(isStop: isPlaying))
    }
}
