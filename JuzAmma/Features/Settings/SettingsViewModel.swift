//
//  SettingsViewModel.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 01/03/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import Observation
import os

/// Handles all business logic for SettingsView.
/// Extracted to keep the view thin and improve testability.
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - State

    var selectedTheme: ThemeMode = .auto
    var notificationsEnabled = false
    var audioCacheSize: String = "Calculating..."
    var audioCacheCount: Int = 0
    var errorMessage: String?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let cacheService: any AudioCacheServiceProtocol

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        cacheService: any AudioCacheServiceProtocol = AudioCacheService.shared
    ) {
        self.modelContext = modelContext
        self.cacheService = cacheService
    }

    // MARK: - Computed Properties

    var memorizedCount: Int {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.isMemorized == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    var bookmarkedCount: Int {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.isBookmarked == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Settings Management

    /// Sync local state from the persisted AppSettings singleton.
    /// Creates a default singleton if none exists.
    func loadSettings(from settings: AppSettings?) {
        guard let settings else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            saveContext()
            return
        }
        selectedTheme = settings.themeMode
        notificationsEnabled = settings.notificationsEnabled
    }

    func updateTheme(_ theme: ThemeMode, settings: AppSettings?) {
        selectedTheme = theme
        settings?.themeMode = theme
        saveContext()
    }

    // MARK: - Notifications

    func updateNotificationsSetting(_ enabled: Bool, settings: AppSettings?) {
        notificationsEnabled = enabled
        settings?.notificationsEnabled = enabled

        if enabled {
            requestNotificationPermission(settings: settings)
            if settings?.reminderTime == nil {
                let defaultTime = Calendar.current.date(
                    bySettingHour: 9, minute: 0, second: 0, of: Date()
                ) ?? Date()
                settings?.reminderTime = defaultTime
                scheduleReminder(at: defaultTime)
            } else if let time = settings?.reminderTime {
                scheduleReminder(at: time)
            }
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["daily_memorization_reminder"]
            )
        }
        saveContext()
    }

    func updateReminderTime(_ time: Date, settings: AppSettings?) {
        settings?.reminderTime = time
        saveContext()
        scheduleReminder(at: time)
    }

    private func requestNotificationPermission(settings: AppSettings?) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            if !granted {
                Task { @MainActor in
                    settings?.notificationsEnabled = false
                    self?.notificationsEnabled = false
                    self?.saveContext()
                    self?.errorMessage = "Notification permission denied. Enable in Settings > Notifications."
                }
            }
        }
    }

    func scheduleReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_memorization_reminder"])

        let content = UNMutableNotificationContent()
        content.title = L10n.appName
        content.body = "Time to practice your Quran memorization! 📖"
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_memorization_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { [weak self] error in
            if let error {
                Task { @MainActor in
                    self?.errorMessage = "Failed to schedule reminder: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Cache Management

    func loadCacheInfo() async {
        audioCacheSize = await cacheService.getFormattedCacheSize()
        audioCacheCount = await cacheService.getCachedFileCount()
    }

    func clearAudioCache() async {
        do {
            try await cacheService.clearCache()
            audioCacheSize = "0 MB"
            audioCacheCount = 0
        } catch {
            errorMessage = "Failed to clear cache: \(error.localizedDescription)"
        }
    }

    // MARK: - Share

    func shareApp() {
        let text = "\(AppConstants.appName) - Quran Juz 30 Memorization App"
        let url = AppConstants.githubURL
        let activityVC = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            AppLogger.settings.error("Failed to save: \(error.localizedDescription)")
        }
    }
}
