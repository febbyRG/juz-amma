//
//  AudioPlayerView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 27/01/26.
//

import SwiftUI

// MARK: - Audio Player View

/// A floating audio player control for Quran recitation
struct AudioPlayerView: View {
    @ObservedObject var audioService: AudioPlayerService
    let surahNumber: Int
    let surahName: String
    
    // Callbacks to show pickers in parent view (avoids UIReparentingView error)
    var onShowQariPicker: (() -> Void)?
    var onShowOptionsSheet: (() -> Void)?
    
    private var isPlaying: Bool {
        audioService.state == .playing
    }
    
    private var isLoading: Bool {
        audioService.state == .loading
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar - tappable for seeking
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(AppColors.primaryGreen)
                        .frame(width: geometry.size.width * audioService.progress, height: 3)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let progress = location.x / geometry.size.width
                    audioService.seekToProgress(max(0, min(1, progress)))
                }
            }
            .frame(height: 3)
            
            // Main Controls
            HStack(spacing: 16) {
                // Surah Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(surahName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    
                    Text(audioService.selectedQari.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Playback Controls
                HStack(spacing: 20) {
                    // Skip Back
                    Button {
                        audioService.skipBackward()
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                    .disabled(isLoading)
                    
                    // Play/Pause
                    Button {
                        if isPlaying || audioService.state == .paused {
                            audioService.togglePlayPause()
                        } else {
                            Task {
                                await audioService.playSurahFull(surahNumber)
                            }
                        }
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(AppColors.primaryGreen)
                            }
                        }
                        .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier(isPlaying ? AccessibilityIdentifiers.pauseButton : AccessibilityIdentifiers.playButton)
                    .accessibilityLabel(isPlaying ? "Pause" : "Play")
                    
                    // Skip Forward
                    Button {
                        audioService.skipForward()
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                    .disabled(isLoading)
                }
                
                // Time Display
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AudioPlayerService.formatTime(audioService.currentTime))
                        .font(.caption.monospacedDigit())
                    
                    Text(AudioPlayerService.formatTime(audioService.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50)
                
                // More Options - use button instead of Menu to avoid UIReparentingView
                Button {
                    onShowOptionsSheet?()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.audioPlayer)
    }
}

// MARK: - Compact Audio Player (for List)

/// A compact inline audio player for surah list
struct CompactAudioPlayerView: View {
    @ObservedObject var audioService: AudioPlayerService
    let surahNumber: Int
    
    var body: some View {
        Button {
            if audioService.state == .playing && audioService.currentVerseIndex >= 0 {
                audioService.togglePlayPause()
            } else {
                Task {
                    await audioService.playSurah(surahNumber)
                }
            }
        } label: {
            ZStack {
                if audioService.state == .loading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: audioService.state == .playing ? "pause.fill" : "play.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.primaryGreen)
                }
            }
            .frame(width: 32, height: 32)
            .background(AppColors.primaryGreen.opacity(0.1))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Qari Picker View

struct QariPickerView: View {
    let selectedQari: Qari
    let onSelect: (Qari) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var allQaris: [Qari] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    private var popularQaris: [Qari] {
        PopularQari.allCases.map { $0.qari }
    }
    
    private var filteredQaris: [Qari] {
        if searchText.isEmpty {
            return allQaris
        }
        return allQaris.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.style?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Popular Qaris
                Section("Popular Reciters") {
                    ForEach(popularQaris) { qari in
                        QariRow(
                            qari: qari,
                            isSelected: qari.id == selectedQari.id,
                            onSelect: onSelect
                        )
                    }
                }
                
                // All Qaris
                if !allQaris.isEmpty {
                    Section("All Reciters") {
                        ForEach(filteredQaris) { qari in
                            QariRow(
                                qari: qari,
                                isSelected: qari.id == selectedQari.id,
                                onSelect: onSelect
                            )
                        }
                    }
                }
            }
            .navigationTitle("Select Reciter")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search reciters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadAllQaris()
            }
        }
    }
    
    private func loadAllQaris() async {
        isLoading = true
        do {
            let service = AudioPlayerService()
            allQaris = try await service.fetchAvailableReciters()
        } catch {
            // Fall back to popular qaris only
            allQaris = popularQaris
        }
        isLoading = false
    }
}

// MARK: - Qari Row

struct QariRow: View {
    let qari: Qari
    let isSelected: Bool
    let onSelect: (Qari) -> Void
    
    var body: some View {
        Button {
            onSelect(qari)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(qari.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let style = qari.style {
                        Text(style)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let arabicName = qari.arabicName {
                        Text(arabicName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primaryGreen)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Verse Audio Button

/// Button to play audio for a specific verse
struct VerseAudioButton: View {
    @ObservedObject var audioService: AudioPlayerService
    let surahNumber: Int
    let verseNumber: Int
    
    private var isThisVersePlaying: Bool {
        guard audioService.state == .playing || audioService.state == .paused else {
            return false
        }
        // Check if this surah is playing and this verse is current
        return audioService.isPlayingSurah(surahNumber) &&
               audioService.currentPlayingVerse == verseNumber
    }
    
    var body: some View {
        Button {
            Task {
                await audioService.playVerse(surahNumber, verseNumber: verseNumber)
            }
        } label: {
            Image(systemName: isThisVersePlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.caption)
                .foregroundStyle(isThisVersePlaying ? AppColors.primaryGreen : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Audio Options Sheet

/// Sheet view for audio player options (replaces Menu to avoid UIReparentingView issues)
struct AudioOptionsSheet: View {
    @ObservedObject var audioService: AudioPlayerService
    @Environment(\.dismiss) private var dismiss
    var onShowQariPicker: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            List {
                // Qari Selection
                Section {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onShowQariPicker?()
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Change Reciter")
                                Text(audioService.selectedQari.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "person.wave.2")
                                .foregroundStyle(AppColors.primaryGreen)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // Playback Speed
                Section("Playback Speed") {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                        Button {
                            audioService.setPlaybackSpeed(Float(speed))
                        } label: {
                            HStack {
                                Text("\(speed, specifier: "%.2g")x")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if audioService.playbackSpeed == Float(speed) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.primaryGreen)
                                }
                            }
                        }
                    }
                }
                
                // Repeat Toggle
                Section {
                    Button {
                        audioService.isRepeatEnabled.toggle()
                    } label: {
                        Label {
                            Text(audioService.isRepeatEnabled ? "Repeat: On" : "Repeat: Off")
                        } icon: {
                            Image(systemName: audioService.isRepeatEnabled ? "repeat.1" : "repeat")
                                .foregroundStyle(audioService.isRepeatEnabled ? AppColors.primaryGreen : .secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // Stop
                Section {
                    Button(role: .destructive) {
                        audioService.stop()
                        dismiss()
                    } label: {
                        Label("Stop Playback", systemImage: "stop.circle")
                    }
                }
            }
            .navigationTitle("Audio Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        AudioPlayerView(
            audioService: AudioPlayerService(),
            surahNumber: 114,
            surahName: "An-Nas"
        )
    }
}
