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
    @StateObject private var synthController = SynthUIAdapter.shared
    @State private var isUpdatingHarmony = false
    @State private var globalChordType: ChordType = .major
    @State private var showHelp = false
    @State private var currentHelpItem: HelpDescriptions.HelpItem?

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
                WaveformControlView(
                    track: currentTrack,
                    showHelp: $showHelp,
                    currentHelpItem: $currentHelpItem
                )
                    .padding(.bottom, -10)

                WaveformDisplayView(track: currentTrack)
                    .frame(height: 200)

                ControlPanelView(
                    track: currentTrack,
                    globalChordType: $globalChordType,
                    formantType: $synthController.formantType,
                    showHelp: $showHelp,
                    currentHelpItem: $currentHelpItem,
                    onChordTypeChanged: updateHarmonyForChordChange,
                    onFormantChanged: {
                        // フォルマント変更はSynthUIAdapter経由で伝播済み
                    }
                )

                Spacer()

                TrackTabBar(selectedTrack: $selectedTrack, tracks: [track1, track2, track3, track4])
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Help overlay - covers entire screen
            if showHelp, let helpItem = currentHelpItem {
                HelpOverlayView(
                    helpItem: helpItem,
                    isPresented: $showHelp
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            // Load saved state if exists
            loadSavedTracks()

            synthController.configureAudioSession()

            // Setup audio for all tracks
            synthController.setupTrack(track1)
            synthController.setupTrack(track2)
            synthController.setupTrack(track3)
            synthController.setupTrack(track4)

            synthController.startEngineIfNeeded()

            // Setup frequency change observers for harmony
            setupHarmonyObservers()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Save tracks when app goes to background
            saveTracks()
            synthController.handleWillResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            synthController.handleDidEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            synthController.handleWillEnterForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            synthController.handleDidBecomeActive()
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

        // Find current harmony lead track
        if let leadTrack = allTracks.first(where: { $0.isHarmonyLead }) {
            isUpdatingHarmony = true

            // Re-calculate all harmonies with new chord type
            synthController.updateHarmonyFrequencies(
                leadTrack: leadTrack,
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

                    // Set this track as the harmony lead and update others
                    self.isUpdatingHarmony = true

                    // Reset all lead flags and set this track as the lead
                    allTracks.forEach { $0.isHarmonyLead = false }
                    track.isHarmonyLead = true

                    // Update harmony frequencies for other tracks
                    self.synthController.updateHarmonyFrequencies(
                        leadTrack: track,
                        allTracks: allTracks,
                        chordType: self.globalChordType
                    )

                    self.isUpdatingHarmony = false
                }
                .store(in: &synthController.cancellables)

            // Also observe harmony enabled state changes
            track.$harmonyEnabled
                .dropFirst()
                .sink { _ in
                    guard !self.isUpdatingHarmony else { return }

                    // Find current harmony lead track
                    if let leadTrack = allTracks.first(where: { $0.isHarmonyLead }) {
                        self.isUpdatingHarmony = true

                        // Re-assign intervals based on current harmony lead
                        self.synthController.updateHarmonyFrequencies(
                            leadTrack: leadTrack,
                            allTracks: allTracks,
                            chordType: self.globalChordType
                        )

                        self.isUpdatingHarmony = false
                    }
                }
                .store(in: &synthController.cancellables)
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
