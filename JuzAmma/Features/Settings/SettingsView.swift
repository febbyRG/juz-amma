//
//  SettingsView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData
import UserNotifications

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
    @State private var errorMessage: String?
    
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
                        Text(settings?.selectedQariName ?? "Mishary Rashid al-`Afasy")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                NavigationLink {
                    AudioDownloadsView(downloadManager: AudioDownloadManager.shared)
                } label: {
                    HStack {
                        Label("Offline Downloads", systemImage: "icloud.and.arrow.down")
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
                    value: "\(AppConstants.juzAmmaSurahRange.count)"
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
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
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
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to create settings: \(error.localizedDescription)"
            }
            return
        }
        
        selectedTheme = settings.themeMode
        notificationsEnabled = settings.notificationsEnabled
    }
    
    private func updateTheme(_ theme: ThemeMode) {
        settings?.themeMode = theme
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save theme: \(error.localizedDescription)"
        }
    }
    
    private func updateNotificationsSetting(_ enabled: Bool) {
        settings?.notificationsEnabled = enabled
        if enabled {
            requestNotificationPermission()
            if settings?.reminderTime == nil {
                let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
                settings?.reminderTime = defaultTime
                scheduleReminder(at: defaultTime)
            } else if let time = settings?.reminderTime {
                scheduleReminder(at: time)
            }
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_memorization_reminder"])
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save notification settings: \(error.localizedDescription)"
        }
    }
    
    private func updateReminderTime(_ time: Date) {
        settings?.reminderTime = time
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save reminder time: \(error.localizedDescription)"
        }
        scheduleReminder(at: time)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if !granted {
                Task { @MainActor in
                    settings?.notificationsEnabled = false
                    notificationsEnabled = false
                    do {
                        try modelContext.save()
                    } catch {
                        print("[Settings] Failed to save notification state: \(error.localizedDescription)")
                    }
                    errorMessage = "Notification permission denied. Enable in Settings > Notifications."
                }
            }
        }
    }
    
    private func scheduleReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_memorization_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Juz Amma"
        content.body = "Time to practice your Quran memorization! 📖"
        content.sound = .default
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_memorization_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                Task { @MainActor in
                    self.errorMessage = "Failed to schedule reminder: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func shareApp() {
        let text = "\(AppConstants.appName) - Quran Juz 30 Memorization App"
        let url = AppConstants.githubURL
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Find topmost presented controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
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
                await MainActor.run {
                    errorMessage = "Failed to clear cache: \(error.localizedDescription)"
                }
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
