//
//  SettingsView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import os

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]
    
    private var settings: AppSettings? {
        settingsQuery.first
    }
    
    @State private var viewModel: SettingsViewModel?
    @State private var showTranslationManager = false
    @State private var showClearCacheAlert = false
    
    var body: some View {
        Form {
            // Appearance Section
            Section {
                Picker(L10n.theme, selection: Binding(
                    get: { viewModel?.selectedTheme ?? .auto },
                    set: { viewModel?.updateTheme($0, settings: settings) }
                )) {
                    ForEach(ThemeMode.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            } header: {
                Label(L10n.appearance, systemImage: "paintbrush")
            }
            
            // Display Preferences
            Section {
                Button {
                    showTranslationManager = true
                } label: {
                    HStack {
                        Label(L10n.manageTranslations, systemImage: "globe")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            } header: {
                Label(L10n.displayPreferences, systemImage: "eye")
            } footer: {
                Text("Download and manage translations in multiple languages")
            }
            
            // Audio Settings
            Section {
                NavigationLink {
                    QariSettingsView()
                } label: {
                    HStack {
                        Label(L10n.reciterQari, systemImage: "speaker.wave.2")
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
                        Label(L10n.offlineDownloads, systemImage: "icloud.and.arrow.down")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(viewModel?.audioCacheSize ?? "Calculating...")
                                .foregroundStyle(.secondary)
                            if let count = viewModel?.audioCacheCount, count > 0 {
                                Text("\(count) surahs cached")
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
                        Label(L10n.clearAudioCache, systemImage: "trash")
                        Spacer()
                    }
                }
                .disabled(viewModel?.audioCacheCount == 0)
            } header: {
                Label(L10n.audio, systemImage: "speaker.wave.3")
            } footer: {
                Text("Cached audio plays offline. Clear cache to free up storage.")
            }
            
            // Notifications
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel?.notificationsEnabled ?? false },
                    set: { viewModel?.updateNotificationsSetting($0, settings: settings) }
                )) {
                    Label(L10n.dailyReminders, systemImage: "bell")
                }
                
                if viewModel?.notificationsEnabled == true {
                    DatePicker(
                        L10n.reminderTime,
                        selection: Binding(
                            get: { settings?.reminderTime ?? Date() },
                            set: { viewModel?.updateReminderTime($0, settings: settings) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Label(L10n.notifications, systemImage: "bell.badge")
            } footer: {
                Text("Get daily reminders to practice memorization")
            }
            
            // Statistics
            Section {
                StatRow(
                    icon: "book.closed.fill",
                    label: L10n.totalSurahs,
                    value: "\(AppConstants.juzAmmaSurahRange.count)"
                )
                
                StatRow(
                    icon: "checkmark.circle.fill",
                    label: L10n.memorized,
                    value: "\(viewModel?.memorizedCount ?? 0)",
                    color: .green
                )
                
                StatRow(
                    icon: "bookmark.fill",
                    label: L10n.bookmarks,
                    value: "\(viewModel?.bookmarkedCount ?? 0)",
                    color: .blue
                )
            } header: {
                Label(L10n.statistics, systemImage: "chart.bar")
            }
            
            // About Section
            Section {
                HStack {
                    Text(L10n.version)
                    Spacer()
                    Text(AppConstants.appVersion)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(L10n.developer)
                    Spacer()
                    Text(AppConstants.developerName)
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: AppConstants.githubURL) {
                    HStack {
                        Label(L10n.githubRepository, systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
                
                Button {
                    viewModel?.shareApp()
                } label: {
                    HStack {
                        Label(L10n.shareApp, systemImage: "square.and.arrow.up")
                        Spacer()
                    }
                }
            } header:{
                Label(L10n.about, systemImage: "info.circle")
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
        .navigationTitle(L10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTranslationManager) {
            NavigationStack {
                TranslationManagerView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SettingsViewModel(modelContext: modelContext)
            }
            viewModel?.loadSettings(from: settings)
            await viewModel?.loadCacheInfo()
        }
        .alert("Clear Audio Cache?", isPresented: $showClearCacheAlert) {
            Button(L10n.cancel, role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task { await viewModel?.clearAudioCache() }
            }
        } message: {
            Text("This will delete all cached audio files (\(viewModel?.audioCacheSize ?? "")). You can re-download them when playing.")
        }
        .alert(L10n.error, isPresented: Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.errorMessage = nil } }
        )) {
            Button(L10n.ok, role: .cancel) { }
        } message: {
            Text(viewModel?.errorMessage ?? "")
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
