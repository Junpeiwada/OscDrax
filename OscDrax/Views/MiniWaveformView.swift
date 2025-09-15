import SwiftUI

struct MiniWaveformView: View {
    let waveformData: [Float]
    let isPlaying: Bool
    @State private var animationPhase: Double = 0

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // Background waveform (static)
                WaveformPath(data: downsampledData)
                    .stroke(
                        LinearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )

                // Animated waveform (only when playing)
                if isPlaying {
                    WaveformPath(data: downsampledData)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                        .opacity(0.5 + sin(animationPhase) * 0.5) // Pulse effect
                        .scaleEffect(1.0 + sin(animationPhase) * 0.05) // Subtle scale animation
                }
            }
        }
        .frame(height: 20)
        .onAppear {
            if isPlaying {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    animationPhase = 0
                }
            }
        }
    }

    // Downsample from 512 points to 32 points for performance
    private var downsampledData: [Float] {
        guard !waveformData.isEmpty else { return [] }
        let targetCount = 32
        let step = max(1, waveformData.count / targetCount)
        var result: [Float] = []

        for i in 0..<targetCount {
            let startIndex = i * step
            let endIndex = min((i + 1) * step, waveformData.count)
            if startIndex < waveformData.count {
                let slice = waveformData[startIndex..<endIndex]
                if !slice.isEmpty {
                    let average = slice.reduce(0, +) / Float(slice.count)
                    result.append(average)
                }
            }
        }
        return result
    }
}

struct WaveformPath: Shape {
    let data: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !data.isEmpty else { return path }

        let stepX = rect.width / CGFloat(max(1, data.count - 1))
        let midY = rect.height / 2

        for (index, sample) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = midY - CGFloat(sample) * midY * 0.9

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
