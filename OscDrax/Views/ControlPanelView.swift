import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var track: Track
    @Binding var globalChordType: ChordType
    @Binding var formantType: FormantType
    @Binding var showHelp: Bool
    @Binding var currentHelpItem: HelpDescriptions.HelpItem?
    var onChordTypeChanged: () -> Void = {}
    var onFormantChanged: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            FrequencyControlView(
                frequency: $track.frequency,
                scaleType: $track.scaleType,
                showHelp: $showHelp,
                currentHelpItem: $currentHelpItem
            )
            HarmonyControlView(
                track: track,
                globalChordType: $globalChordType,
                onChordTypeChanged: onChordTypeChanged,
                showHelp: $showHelp,
                currentHelpItem: $currentHelpItem
            )
            VolumeControlView(
                volume: $track.volume,
                showHelp: $showHelp,
                currentHelpItem: $currentHelpItem
            )
            PortamentoControlView(
                portamentoTime: $track.portamentoTime,
                showHelp: $showHelp,
                currentHelpItem: $currentHelpItem
            )
            formantSelector
            PlayButtonView(isPlaying: $track.isPlaying)
        }
    }
}

struct FrequencyControlView: View {
    @Binding var frequency: Float
    @Binding var scaleType: ScaleType
    @Binding var showHelp: Bool
    @Binding var currentHelpItem: HelpDescriptions.HelpItem?
    @State private var showScalePicker = false
    private let minFreq: Float = 20
    private let maxFreq: Float = 20_000

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                HelpButton(
                    text: "Frequency",
                    helpItem: .frequency,
                    currentHelpItem: $currentHelpItem,
                    showHelp: $showHelp
                )

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
                    .frame(width: 60, alignment: .trailing)
            }
            .frame(height: 30)
            .padding(.bottom, 10)

            HStack(spacing: 12) {
                HelpButton(
                    text: "Scale",
                    helpItem: .scale,
                    currentHelpItem: $currentHelpItem,
                    showHelp: $showHelp
                )

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
    @Binding var showHelp: Bool
    @Binding var currentHelpItem: HelpDescriptions.HelpItem?

    var body: some View {
        HStack(spacing: 12) {
            HelpButton(
                text: "Volume",
                helpItem: .volume,
                currentHelpItem: $currentHelpItem,
                showHelp: $showHelp
            )

            CustomSlider(
                value: $volume,
                in: 0...1,
                useLiquidGlassStyle: true
            )

            Text("\(Int(volume * 100))%")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 60, alignment: .trailing)
        }
        .frame(height: 30)
    }
}

struct PortamentoControlView: View {
    @Binding var portamentoTime: Float
    @Binding var showHelp: Bool
    @Binding var currentHelpItem: HelpDescriptions.HelpItem?

    var body: some View {
        HStack(spacing: 12) {
            HelpButton(
                text: "Portamento",
                helpItem: .portamento,
                currentHelpItem: $currentHelpItem,
                showHelp: $showHelp
            )

            CustomSlider(
                value: $portamentoTime,
                in: 0...1_000,
                useLiquidGlassStyle: true
            )

            Text("\(Int(portamentoTime))ms")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 60, alignment: .trailing)
        }
        .frame(height: 30)
    }
}

struct HarmonyControlView: View {
    @ObservedObject var track: Track
    @Binding var globalChordType: ChordType
    var onChordTypeChanged: () -> Void = {}
    @Binding var showHelp: Bool
    @Binding var currentHelpItem: HelpDescriptions.HelpItem?

    var body: some View {
        VStack(spacing: 12) {
            // First row: Harmony Toggle + Position label + Vibrato Toggle
            HStack(spacing: 12) {
                HelpButton(
                    text: "Harmony",
                    helpItem: .harmony,
                    currentHelpItem: $currentHelpItem,
                    showHelp: $showHelp
                )

                Toggle("", isOn: $track.harmonyEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.9, green: 0.5, blue: 0.1)))
                    .labelsHidden()
                    .scaleEffect(0.8)

                Spacer()

                // Vibrato Toggle
                HelpButton(
                    text: "Vibrato",
                    helpItem: .vibrato,
                    currentHelpItem: $currentHelpItem,
                    showHelp: $showHelp
                )
                .frame(minWidth: 55)

                Toggle("", isOn: $track.vibratoEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.9, green: 0.5, blue: 0.1)))
                    .labelsHidden()
                    .scaleEffect(0.8)
            }

            // Second row: Chord Type Selector (compact)
            HStack(spacing: 8) {
                HelpButton(
                    text: "Chord",
                    helpItem: .chord,
                    currentHelpItem: $currentHelpItem,
                    showHelp: $showHelp
                )
                .opacity(track.harmonyEnabled ? 1.0 : 0.4)

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

private extension ControlPanelView {
    var formantSelector: some View {
        HStack(spacing: 8) {
            HelpButton(
                text: "Formant",
                helpItem: .formant,
                currentHelpItem: $currentHelpItem,
                showHelp: $showHelp
            )

            HStack(spacing: 4) {
                ForEach(FormantType.allCases, id: \.self) { formant in
                    Button(action: {
                        formantType = formant
                        onFormantChanged()
                    }, label: {
                        Text(formant.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(formantForegroundColor(for: formant))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(formantBackgroundColor(for: formant))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    })
                }
            }
        }
    }

    func formantForegroundColor(for formant: FormantType) -> Color {
        return formantType == formant ? .black : .white
    }

    func formantBackgroundColor(for formant: FormantType) -> Color {
        let activeColor = Color(red: 0.9, green: 0.5, blue: 0.1)
        return formantType == formant ? activeColor : Color.white.opacity(0.1)
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
