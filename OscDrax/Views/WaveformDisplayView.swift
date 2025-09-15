import SwiftUI

struct WaveformDisplayView: View {
    @ObservedObject var track: Track
    @State private var currentDrawingPoints: [CGPoint] = []
    @State private var isDrawing = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .liquidglassStyle(intensity: 0.8)

                WaveformShape(waveformData: track.waveformData)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan,
                                Color.blue
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .padding(20)

                if isDrawing {
                    Path { path in
                        if currentDrawingPoints.count > 1 {
                            path.move(to: currentDrawingPoints[0])
                            for point in currentDrawingPoints.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if track.waveformType != .custom {
                            track.setWaveformType(.custom)
                            track.clearCustomWaveform()
                        }
                        isDrawing = true
                        let location = value.location
                        currentDrawingPoints.append(location)
                        updateWaveformFromDrawing(in: geometry.size)
                    }
                    .onEnded { _ in
                        isDrawing = false
                        currentDrawingPoints.removeAll()
                    }
            )
        }
    }

    private func updateWaveformFromDrawing(in size: CGSize) {
        guard currentDrawingPoints.count > 1 else { return }

        let padding: CGFloat = 20
        let effectiveWidth = size.width - padding * 2
        let effectiveHeight = size.height - padding * 2

        var newWaveform = Array(repeating: Float(0), count: 512)

        for index in 0..<512 {
            let xPos = CGFloat(index) / 511.0 * effectiveWidth + padding
            let closestPoint = currentDrawingPoints.min(by: { abs($0.x - xPos) < abs($1.x - xPos) })

            if let point = closestPoint {
                let normalizedY = Float((point.y - padding) / effectiveHeight)
                let waveValue = 1.0 - normalizedY * 2.0
                newWaveform[index] = max(-1.0, min(1.0, waveValue))
            }
        }

        track.waveformData = newWaveform
    }
}

struct WaveformShape: Shape {
    let waveformData: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard !waveformData.isEmpty else { return path }

        let stepX = rect.width / CGFloat(waveformData.count - 1)
        let midY = rect.height / 2

        for (index, sample) in waveformData.enumerated() {
            let xPos = CGFloat(index) * stepX
            let yPos = midY - CGFloat(sample) * midY * 0.8

            if index == 0 {
                path.move(to: CGPoint(x: xPos, y: yPos))
            } else {
                path.addLine(to: CGPoint(x: xPos, y: yPos))
            }
        }

        return path
    }
}
