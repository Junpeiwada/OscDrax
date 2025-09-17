//
//  ContentView.swift
//  OscDrax
//
//  Created by Junpei on 2025/09/15.
//

import SwiftUI
import Combine
import UIKit

struct ContentView: View {
    @State private var selectedTrack = 1
    @StateObject private var track1 = Track(id: 1)
    @StateObject private var track2 = Track(id: 2)
    @StateObject private var track3 = Track(id: 3)
    @StateObject private var track4 = Track(id: 4)
    @StateObject private var audioManager = AudioManager.shared
    @State private var isUpdatingHarmony = false
    @State private var globalChordType: ChordType = .major

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
                    .padding(.bottom, -10)

                WaveformDisplayView(track: currentTrack)
                    .frame(height: 200)

                ControlPanelView(
                    track: currentTrack,
                    globalChordType: $globalChordType,
                    formantType: $audioManager.formantType,
                    onChordTypeChanged: updateHarmonyForChordChange,
                    onFormantChanged: {
                        // Formant change is already handled via AudioManager's @Published property
                    }
                )

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

            audioManager.configureAudioSession()

            // Setup audio for all tracks
            audioManager.setupTrack(track1)
            audioManager.setupTrack(track2)
            audioManager.setupTrack(track3)
            audioManager.setupTrack(track4)

            audioManager.startEngineIfNeeded()

            // Setup frequency change observers for harmony
            setupHarmonyObservers()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Save tracks when app goes to background
            saveTracks()
            audioManager.handleWillResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            audioManager.handleDidEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            audioManager.handleWillEnterForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            audioManager.handleDidBecomeActive()
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
        target.harmonyEnabled = source.harmonyEnabled
        target.assignedInterval = source.assignedInterval
        target.scaleType = source.scaleType
        target.vibratoEnabled = source.vibratoEnabled
        // Don't restore isPlaying state to avoid audio playing on launch
    }

    private func updateHarmonyForChordChange() {
        let allTracks = [track1, track2, track3, track4]

        guard !isUpdatingHarmony else { return }

        // Find current master track
        if let masterTrack = allTracks.first(where: { $0.isHarmonyMaster }) {
            isUpdatingHarmony = true

            // Re-calculate all harmonies with new chord type
            audioManager.updateHarmonyFrequencies(
                masterTrack: masterTrack,
                allTracks: allTracks,
                chordType: globalChordType
            )

            isUpdatingHarmony = false
        }
    }

    private func setupHarmonyObservers() {
        let allTracks = [track1, track2, track3, track4]

        // Observe frequency changes on all tracks
        for track in allTracks {
            track.$frequency
                .dropFirst() // Skip initial value
                .sink { _ in
                    guard !self.isUpdatingHarmony else { return }

                    // Set this track as the master and update others
                    self.isUpdatingHarmony = true

                    // Reset all master flags and set this track as master
                    allTracks.forEach { $0.isHarmonyMaster = false }
                    track.isHarmonyMaster = true

                    // Update harmony frequencies for other tracks
                    self.audioManager.updateHarmonyFrequencies(
                        masterTrack: track,
                        allTracks: allTracks,
                        chordType: self.globalChordType
                    )

                    self.isUpdatingHarmony = false
                }
                .store(in: &audioManager.cancellables)

            // Also observe harmony enabled state changes
            track.$harmonyEnabled
                .dropFirst()
                .sink { _ in
                    guard !self.isUpdatingHarmony else { return }

                    // Find current master track
                    if let masterTrack = allTracks.first(where: { $0.isHarmonyMaster }) {
                        self.isUpdatingHarmony = true

                        // Re-assign intervals based on current master
                        self.audioManager.updateHarmonyFrequencies(
                            masterTrack: masterTrack,
                            allTracks: allTracks,
                            chordType: self.globalChordType
                        )

                        self.isUpdatingHarmony = false
                    }
                }
                .store(in: &audioManager.cancellables)
        }
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
