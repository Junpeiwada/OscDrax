import SwiftUI

struct WaveformDisplayView: View {
    @ObservedObject var track: Track
    @State private var currentDrawingPoints: [CGPoint] = []
    @State private var isDrawing = false
    @State private var touchStartX: CGFloat?
    @State private var touchEndX: CGFloat?

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
                            // Don't clear, keep existing waveform data
                            if track.waveformData.isEmpty {
                                track.waveformData = Array(repeating: 0, count: 512)
                            }
                        }

                        // Record touch positions
                        if touchStartX == nil {
                            touchStartX = value.location.x
                        }
                        touchEndX = value.location.x

                        isDrawing = true
                        let location = value.location
                        currentDrawingPoints.append(location)
                        updateWaveformFromDrawing(in: geometry.size)
                    }
                    .onEnded { _ in
                        isDrawing = false
                        currentDrawingPoints.removeAll()
                        touchStartX = nil
                        touchEndX = nil
                    }
            )
        }
    }

    private func updateWaveformFromDrawing(in size: CGSize) {
        guard currentDrawingPoints.count > 1,
              let startX = touchStartX,
              let endX = touchEndX else { return }

        let padding: CGFloat = 20
        let effectiveWidth = size.width - padding * 2
        let effectiveHeight = size.height - padding * 2

        // Calculate the range of indices to update
        let minX = min(startX, endX)
        let maxX = max(startX, endX)

        // Convert X positions to waveform indices
        let startIndex = max(0, Int(((minX - padding) / effectiveWidth) * 511))
        let endIndex = min(511, Int(((maxX - padding) / effectiveWidth) * 511))

        // Start with existing waveform data or create new if empty
        var updatedWaveform = track.waveformData.isEmpty ?
            Array(repeating: Float(0), count: 512) : track.waveformData

        // Only update the touched range
        for index in startIndex...endIndex {
            let xPos = CGFloat(index) / 511.0 * effectiveWidth + padding

            // Find the closest drawn point for this index
            let closestPoint = currentDrawingPoints.min(by: { abs($0.x - xPos) < abs($1.x - xPos) })

            if let point = closestPoint {
                // Only update if the point is within reasonable horizontal distance
                let horizontalDistance = abs(point.x - xPos)
                if horizontalDistance < effectiveWidth / 50 { // Threshold for proximity
                    let normalizedY = Float((point.y - padding) / effectiveHeight)
                    let waveValue = 1.0 - normalizedY * 2.0
                    updatedWaveform[index] = max(-1.0, min(1.0, waveValue))
                }
            }
        }

        track.waveformData = updatedWaveform
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
