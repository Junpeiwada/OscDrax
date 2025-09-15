import SwiftUI

struct TrackTabButton: View {
    let trackNumber: Int
    let isSelected: Bool
    @ObservedObject var track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Playing status (green dot with glow when playing)
                ZStack {
                    if track.isPlaying {
                        Circle()
                            .fill(AppTheme.Colors.TrackTab.playingIndicator)
                            .frame(width: 12, height: 12)
                            .shadow(color: AppTheme.Colors.TrackTab.playingIndicator, radius: 8)
                            .shadow(color: AppTheme.Colors.TrackTab.playingIndicator.opacity(0.5), radius: 12)
                    } else {
                        Text(" ")
                            .font(.system(size: 12))
                    }
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

                // Track number
                Text("\(trackNumber)")
                    .font(.system(size: 16, weight: .bold))
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
