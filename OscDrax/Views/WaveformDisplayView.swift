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

                // Grid overlay for oscilloscope effect
                GridOverlay()
                    .stroke(AppTheme.Colors.Waveform.grid, lineWidth: 0.5)
                    .padding(20)

                WaveformShape(waveformData: track.waveformData)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: AppTheme.Colors.Waveform.gradient),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: AppTheme.Colors.Waveform.glow, radius: 4)
                    .padding(20)
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
        if startIndex <= endIndex {
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
        }

        track.waveformData = updatedWaveform
    }
}

struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Vertical lines (10 divisions)
        let verticalSpacing = rect.width / 10
        for i in 0...10 {
            let x = CGFloat(i) * verticalSpacing
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        // Horizontal lines (8 divisions)
        let horizontalSpacing = rect.height / 8
        for i in 0...8 {
            let y = CGFloat(i) * horizontalSpacing
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
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
