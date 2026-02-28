//
//  SettingsViewModelTests.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 01/03/26.
//

import Testing
import Foundation
import SwiftData
@testable import Juz_Amma

@Suite(.serialized)
@MainActor
struct SettingsViewModelTests {

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Surah.self, Ayah.self, AppSettings.self, Translation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    // MARK: - Load Settings

    @Test func loadSettingsCreatesDefaultWhenNil() throws {
        let context = try makeContext()
        let vm = SettingsViewModel(modelContext: context)

        vm.loadSettings(from: nil)

        // A default AppSettings singleton should have been inserted
        let descriptor = FetchDescriptor<AppSettings>()
        let settings = try context.fetch(descriptor)
        #expect(!settings.isEmpty)
    }

    @Test func loadSettingsSyncsFromExisting() throws {
        let context = try makeContext()
        let settings = AppSettings(themeMode: .dark)
        settings.notificationsEnabled = true
        context.insert(settings)
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        vm.loadSettings(from: settings)

        #expect(vm.selectedTheme == .dark)
        #expect(vm.notificationsEnabled == true)
    }

    // MARK: - Theme

    @Test func updateThemePersists() throws {
        let context = try makeContext()
        let settings = AppSettings()
        context.insert(settings)
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        vm.updateTheme(.dark, settings: settings)

        #expect(vm.selectedTheme == .dark)
        #expect(settings.themeMode == .dark)
    }

    @Test func updateThemeToLight() throws {
        let context = try makeContext()
        let settings = AppSettings(themeMode: .dark)
        context.insert(settings)
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        vm.updateTheme(.light, settings: settings)

        #expect(vm.selectedTheme == .light)
        #expect(settings.themeMode == .light)
    }

    // MARK: - Computed Stats

    @Test func memorizedCountReflectsData() throws {
        let context = try makeContext()
        context.insert(Surah(number: 112, nameArabic: "", nameTransliteration: "", nameTranslation: "", ayahCount: 4, isMemorized: true))
        context.insert(Surah(number: 113, nameArabic: "", nameTransliteration: "", nameTranslation: "", ayahCount: 5, isMemorized: false))
        context.insert(Surah(number: 114, nameArabic: "", nameTransliteration: "", nameTranslation: "", ayahCount: 6, isMemorized: true))
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        #expect(vm.memorizedCount == 2)
    }

    @Test func bookmarkedCountReflectsData() throws {
        let context = try makeContext()
        context.insert(Surah(number: 112, nameArabic: "", nameTransliteration: "", nameTranslation: "", ayahCount: 4, isBookmarked: true))
        context.insert(Surah(number: 113, nameArabic: "", nameTransliteration: "", nameTranslation: "", ayahCount: 5))
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        #expect(vm.bookmarkedCount == 1)
    }

    @Test func countsReturnZeroWhenEmpty() throws {
        let context = try makeContext()
        let vm = SettingsViewModel(modelContext: context)
        #expect(vm.memorizedCount == 0)
        #expect(vm.bookmarkedCount == 0)
    }

    // MARK: - Cache Info (with Mock)

    @Test func loadCacheInfoFromMock() async throws {
        let context = try makeContext()
        let mockCache = MockAudioCacheService()
        mockCache.cacheSize = "50 MB"
        mockCache.fileCount = 10

        let vm = SettingsViewModel(modelContext: context, cacheService: mockCache)
        await vm.loadCacheInfo()

        #expect(vm.audioCacheSize == "50 MB")
        #expect(vm.audioCacheCount == 10)
    }

    @Test func clearCacheResetsValues() async throws {
        let context = try makeContext()
        let mockCache = MockAudioCacheService()
        mockCache.cacheSize = "50 MB"
        mockCache.fileCount = 10
        mockCache.cachedSurahs = [112, 113, 114]

        let vm = SettingsViewModel(modelContext: context, cacheService: mockCache)
        await vm.loadCacheInfo()
        #expect(vm.audioCacheCount == 10)

        await vm.clearAudioCache()
        #expect(vm.audioCacheSize == "0 MB")
        #expect(vm.audioCacheCount == 0)
        #expect(vm.errorMessage == nil)
    }

    @Test func clearCacheSetsErrorOnFailure() async throws {
        let context = try makeContext()
        let mockCache = MockAudioCacheService()
        mockCache.shouldThrowOnClear = true

        let vm = SettingsViewModel(modelContext: context, cacheService: mockCache)
        await vm.clearAudioCache()

        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage?.contains("clear") == true)
    }

    // MARK: - Notifications

    @Test func updateNotificationsEnablesSetsState() throws {
        let context = try makeContext()
        let settings = AppSettings()
        context.insert(settings)
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        vm.updateNotificationsSetting(true, settings: settings)

        #expect(vm.notificationsEnabled == true)
        #expect(settings.notificationsEnabled == true)
    }

    @Test func updateNotificationsDisableSetsState() throws {
        let context = try makeContext()
        let settings = AppSettings()
        settings.notificationsEnabled = true
        context.insert(settings)
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        vm.updateNotificationsSetting(false, settings: settings)

        #expect(vm.notificationsEnabled == false)
        #expect(settings.notificationsEnabled == false)
    }

    @Test func updateReminderTimePersists() throws {
        let context = try makeContext()
        let settings = AppSettings()
        context.insert(settings)
        try context.save()

        let vm = SettingsViewModel(modelContext: context)
        let newTime = Date()
        vm.updateReminderTime(newTime, settings: settings)

        #expect(settings.reminderTime == newTime)
    }
}
