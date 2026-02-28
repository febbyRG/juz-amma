//
//  ContentView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData
import os

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsQuery: [AppSettings]
    
    @State private var isLoading = true
    @State private var loadError: Error?
    @StateObject private var audioService = AudioPlayerService()
    private let downloadManager = AudioDownloadManager.shared
    
    private var settings: AppSettings? {
        settingsQuery.first
    }
    
    private var preferredColorScheme: ColorScheme? {
        guard let themeMode = settings?.themeMode else { return nil }
        
        switch themeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil // Use system setting
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                // Reuse shared launch screen with loading indicator
                LaunchScreenView(isLoading: true)
            } else if let error = loadError {
                // Error Screen
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    
                    Text("Failed to Load Data")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await loadData()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // Main App
                SurahListView()
                    .environmentObject(audioService)
                    .environmentObject(downloadManager)
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .task {
            await loadData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if let settings = settings {
                    audioService.savePlaybackState(to: settings)
                    do {
                        try modelContext.save()
                    } catch {
                        AppLogger.ui.error("Failed to save playback state: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        loadError = nil
        
        do {
            let quranService = QuranDataService(modelContext: modelContext)
            try await quranService.loadJuzAmmaData()
            
            // Ensure AppSettings singleton exists
            let appSettings = try quranService.getSettings()
            
            // Restore selected qari from settings
            if let savedQari = PopularQari.allCases.first(where: { $0.qari.id == appSettings.selectedQariId })?.qari {
                audioService.setQari(savedQari)
            }
            
            // Clean existing translations that have HTML tags
            let translationService = TranslationService(modelContext: modelContext)
            try translationService.cleanExistingTranslations()
            
            // Small delay for smooth transition
            try? await Task.sleep(for: .seconds(AppConstants.Animation.loadingTransitionDelay))
            
            isLoading = false
        } catch {
            loadError = error
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Surah.self, Ayah.self, AppSettings.self, Translation.self], inMemory: true)
}
