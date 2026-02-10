//
//  ContentView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData

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
                // Loading Screen
                ZStack {
                    // Background gradient matching launch screen
                    LinearGradient(
                        colors: [
                            Color(red: 0.165, green: 0.620, blue: 0.427),
                            Color(red: 0.263, green: 0.722, blue: 0.549)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // App Icon
                        Image("AppIconImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(26.4)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                        
                        // Bismillah
                        Text("بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ")
                            .font(.custom("Amiri Quran", size: 24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // App Name
                        Text("Juz Amma")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Loading indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.top, 8)
                        
                        Text("Loading Quran data...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 8)
                        
                        Spacer()
                        
                        // Version
                        Text("Version 1.0")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 20)
                    }
                }
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
                    try? modelContext.save()
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
            _ = try quranService.getSettings()
            
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
