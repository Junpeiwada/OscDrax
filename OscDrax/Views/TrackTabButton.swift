import SwiftUI

struct TrackTabButton: View {
    let trackNumber: Int
    let isSelected: Bool
    @ObservedObject var track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Playing status with track number
                HStack(spacing: 4) {
                    // Playing indicator
                    if track.isPlaying {
                        Circle()
                            .fill(AppTheme.Colors.TrackTab.playingIndicator)
                            .frame(width: 10, height: 10)
                            .shadow(color: AppTheme.Colors.TrackTab.playingIndicator, radius: 6)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 10, height: 10)
                    }

                    // Small track number
                    Text("T\(trackNumber)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray.opacity(0.6))
                }
                .frame(height: 14)

                // Mini waveform display with animation
                MiniWaveformView(
                    waveformData: track.waveformData,
                    isPlaying: track.isPlaying
                )
                .frame(height: 20)
                .padding(.horizontal, 4)

                // Volume bar (proportional display)
                Text(volumeBar(track.volume))
                    .font(.system(size: 8, design: .monospaced))
                    .lineLimit(1)

                // Position (Interval) display - Large
                Text(track.harmonyEnabled ? (track.assignedInterval ?? "--") : "Free")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(track.harmonyEnabled ?
                        Color(red: 0.9, green: 0.5, blue: 0.1) :
                        (isSelected ? .white : .gray))

                // Frequency display
                Text("\(Int(track.frequency)) Hz")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .gray.opacity(0.6))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidglassButtonStyle())
    }

    private func volumeBar(_ volume: Float) -> String {
        let barCount = 10
        let filledCount = Int(volume * Float(barCount))
        let emptyCount = barCount - filledCount
        return String(repeating: "█", count: filledCount) +
               String(repeating: "░", count: emptyCount)
    }
}
