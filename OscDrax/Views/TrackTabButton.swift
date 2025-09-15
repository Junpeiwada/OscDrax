import SwiftUI

struct TrackTabButton: View {
    let trackNumber: Int
    let isSelected: Bool
    @ObservedObject var track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Playing status (speaker emoji only when playing)
                Text(track.isPlaying ? "🔊" : " ")
                    .font(.system(size: 12))
                    .frame(height: 14)

                // Frequency display
                Text("\(Int(track.frequency))Hz")
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)

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