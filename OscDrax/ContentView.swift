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
    @StateObject private var audioManager = AudioManager.shared

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
                gradient: Gradient(colors: AppTheme.Colors.backgroundGradient),
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

                TrackTabBar(selectedTrack: $selectedTrack, tracks: [track1, track2, track3, track4])
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .onAppear {
            // Load saved state if exists
            loadSavedTracks()

            // Setup audio for all tracks
            audioManager.setupTrack(track1)
            audioManager.setupTrack(track2)
            audioManager.setupTrack(track3)
            audioManager.setupTrack(track4)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Save tracks when app goes to background
            saveTracks()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            // Save tracks when app terminates
            saveTracks()
        }
    }

    private func saveTracks() {
        let tracks = [track1, track2, track3, track4]
        PersistenceManager.shared.saveTracks(tracks)
    }

    private func loadSavedTracks() {
        guard let savedTracks = PersistenceManager.shared.loadTracks(),
              savedTracks.count == 4 else { return }

        // Apply saved state to tracks
        applyTrackState(from: savedTracks[0], to: track1)
        applyTrackState(from: savedTracks[1], to: track2)
        applyTrackState(from: savedTracks[2], to: track3)
        applyTrackState(from: savedTracks[3], to: track4)
    }

    private func applyTrackState(from source: Track, to target: Track) {
        target.waveformType = source.waveformType
        target.waveformData = source.waveformData
        target.frequency = source.frequency
        target.volume = source.volume
        target.portamentoTime = source.portamentoTime
        // Don't restore isPlaying state to avoid audio playing on launch
    }
}

struct TrackTabBar: View {
    @Binding var selectedTrack: Int
    let tracks: [Track]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                TrackTabButton(
                    trackNumber: index + 1,
                    isSelected: selectedTrack == index + 1,
                    track: track,
                    action: {
                        selectedTrack = index + 1
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
