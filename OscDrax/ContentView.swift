//
//  ContentView.swift
//  OscDrax
//
//  Created by Junpei on 2025/09/15.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTrack = 1
    @StateObject private var track1 = Track(id: 1)
    @StateObject private var track2 = Track(id: 2)
    @StateObject private var track3 = Track(id: 3)
    @StateObject private var track4 = Track(id: 4)

    var currentTrack: Track {
        switch selectedTrack {
        case 1: return track1
        case 2: return track2
        case 3: return track3
        case 4: return track4
        default: return track1
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                WaveformControlView(track: currentTrack)

                WaveformDisplayView(track: currentTrack)
                    .frame(height: 200)

                ControlPanelView(track: currentTrack)

                Spacer()

                TrackTabBar(selectedTrack: $selectedTrack)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct TrackTabBar: View {
    @Binding var selectedTrack: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...4, id: \.self) { track in
                Button(action: {
                    selectedTrack = track
                }) {
                    Text("\(track)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedTrack == track ? .white : .gray)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidglassButtonStyle())
            }
        }
    }
}

#Preview {
    ContentView()
}
