//
//  SettingsView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]
    
    private var settings: AppSettings? {
        settingsQuery.first
    }
    
    @State private var selectedTheme: ThemeMode = .auto
    @State private var notificationsEnabled = false
    @State private var showTranslationManager = false
    @State private var audioCacheSize: String = "Calculating..."
    @State private var audioCacheCount: Int = 0
    @State private var showClearCacheAlert = false
    
    var body: some View {
        Form {
            // Appearance Section
            Section {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(ThemeMode.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .onChange(of: selectedTheme) { _, newValue in
                    updateTheme(newValue)
                }
            } header: {
                Label("Appearance", systemImage: "paintbrush")
            }
            
            // Display Preferences
            Section {
                Button {
                    showTranslationManager = true
                } label: {
                    HStack {
                        Label("Manage Translations", systemImage: "globe")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            } header: {
                Label("Display Preferences", systemImage: "eye")
            } footer: {
                Text("Download and manage translations in multiple languages")
            }
            
            // Audio Settings
            Section {
                NavigationLink {
                    QariSettingsView()
                } label: {
                    HStack {
                        Label("Reciter (Qari)", systemImage: "speaker.wave.2")
                        Spacer()
                        Text(settings?.selectedQari ?? "Mishary Alafasy")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Audio Cache Management
                HStack {
                    Label("Audio Cache", systemImage: "internaldrive")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(audioCacheSize)
                            .foregroundStyle(.secondary)
                        if audioCacheCount > 0 {
                            Text("\(audioCacheCount) surahs cached")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                Button(role: .destructive) {
                    showClearCacheAlert = true
                } label: {
                    HStack {
                        Label("Clear Audio Cache", systemImage: "trash")
                        Spacer()
                    }
                }
                .disabled(audioCacheCount == 0)
            } header: {
                Label("Audio", systemImage: "speaker.wave.3")
            } footer: {
                Text("Cached audio plays offline. Clear cache to free up storage.")
            }
            
            // Notifications
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Daily Reminders", systemImage: "bell")
                }
                .onChange(of: notificationsEnabled) { _, newValue in
                    updateNotificationsSetting(newValue)
                }
                
                if notificationsEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: Binding(
                            get: { settings?.reminderTime ?? Date() },
                            set: { updateReminderTime($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Label("Notifications", systemImage: "bell.badge")
            } footer: {
                Text("Get daily reminders to practice memorization")
            }
            
            // Statistics
            Section {
                StatRow(
                    icon: "book.closed.fill",
                    label: "Total Surahs",
                    value: "37"
                )
                
                StatRow(
                    icon: "checkmark.circle.fill",
                    label: "Memorized",
                    value: "\(memorizedCount)",
                    color: .green
                )
                
                StatRow(
                    icon: "bookmark.fill",
                    label: "Bookmarked",
                    value: "\(bookmarkedCount)",
                    color: .blue
                )
            } header: {
                Label("Statistics", systemImage: "chart.bar")
            }
            
            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppConstants.appVersion)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Developer")
                    Spacer()
                    Text(AppConstants.developerName)
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: AppConstants.githubURL) {
                    HStack {
                        Label("GitHub Repository", systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
                
                Button {
                    // Share app
                    shareApp()
                } label: {
                    HStack {
                        Label("Share App", systemImage: "square.and.arrow.up")
                        Spacer()
                    }
                }
            } header:{
                Label("About", systemImage: "info.circle")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(AppConstants.appName) - Islamic Learning App")
                    Text("Made with ❤️ for Muslims worldwide")
                    Text("Open source • Free • No Ads")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTranslationManager) {
            NavigationStack {
                TranslationManagerView()
            }
        }
        .onAppear {
            loadSettings()
            loadCacheInfo()
        }
        .alert("Clear Audio Cache?", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAudioCache()
            }
        } message: {
            Text("This will delete all cached audio files (\(audioCacheSize)). You can re-download them when playing.")
        }
    }
    
    // MARK: - Computed Properties
    private var memorizedCount: Int {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.isMemorized == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    private var bookmarkedCount: Int {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.isBookmarked == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    // MARK: - Methods
    private func loadSettings() {
        guard let settings = settings else {
            // Create default settings if not exists
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return
        }
        
        selectedTheme = settings.themeMode
        notificationsEnabled = settings.notificationsEnabled
    }
    
    private func updateTheme(_ theme: ThemeMode) {
        settings?.themeMode = theme
        try? modelContext.save()
    }
    
    private func updateDisplayPreference(_ keyPath: WritableKeyPath<AppSettings, Bool>, value: Bool) {
        guard var settings = settings else { return }
        settings[keyPath: keyPath] = value
        try? modelContext.save()
    }
    
    private func updateNotificationsSetting(_ enabled: Bool) {
        settings?.notificationsEnabled = enabled
        if enabled && settings?.reminderTime == nil {
            settings?.reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())
        }
        try? modelContext.save()
    }
    
    private func updateReminderTime(_ time: Date) {
        settings?.reminderTime = time
        try? modelContext.save()
    }
    
    private func shareApp() {
        // TODO: Implement share functionality
    }
    
    private func loadCacheInfo() {
        Task {
            let size = await AudioCacheService.shared.getFormattedCacheSize()
            let count = await AudioCacheService.shared.getCachedFileCount()
            await MainActor.run {
                audioCacheSize = size
                audioCacheCount = count
            }
        }
    }
    
    private func clearAudioCache() {
        Task {
            do {
                try await AudioCacheService.shared.clearCache()
                await MainActor.run {
                    audioCacheSize = "0 MB"
                    audioCacheCount = 0
                }
            } catch {
                print("Failed to clear cache: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Stat Row Component
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .accentColor
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(label)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Surah.self, Ayah.self, AppSettings.self, Translation.self], inMemory: true)
}
