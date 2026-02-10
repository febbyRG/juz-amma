//
//  QuranDataServiceTests.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 10/02/26.
//

import Testing
import Foundation
import SwiftData
@testable import Juz_Amma

// MARK: - QuranDataService Tests

@Suite(.serialized)
@MainActor
struct QuranDataServiceTests {
    
    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Surah.self, Ayah.self, AppSettings.self, Translation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    @Test func toggleBookmark() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        let surah = Surah(
            number: 114,
            nameArabic: "الناس",
            nameTransliteration: "An-Nas",
            nameTranslation: "Mankind",
            ayahCount: 6
        )
        context.insert(surah)
        try context.save()
        
        #expect(surah.isBookmarked == false)
        
        try service.toggleBookmark(for: surah)
        #expect(surah.isBookmarked == true)
        
        try service.toggleBookmark(for: surah)
        #expect(surah.isBookmarked == false)
    }
    
    @Test func toggleMemorization() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        let surah = Surah(
            number: 112,
            nameArabic: "الإخلاص",
            nameTransliteration: "Al-Ikhlas",
            nameTranslation: "The Sincerity",
            ayahCount: 4
        )
        context.insert(surah)
        try context.save()
        
        #expect(surah.isMemorized == false)
        #expect(surah.memorizedDate == nil)
        
        try service.toggleMemorization(for: surah)
        #expect(surah.isMemorized == true)
        #expect(surah.memorizedDate != nil)
        
        try service.toggleMemorization(for: surah)
        #expect(surah.isMemorized == false)
        #expect(surah.memorizedDate == nil)
    }
    
    @Test func setNextToMemorize() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        let surah1 = Surah(number: 112, nameArabic: "الإخلاص", nameTransliteration: "Al-Ikhlas", nameTranslation: "The Sincerity", ayahCount: 4)
        let surah2 = Surah(number: 113, nameArabic: "الفلق", nameTransliteration: "Al-Falaq", nameTranslation: "The Daybreak", ayahCount: 5)
        context.insert(surah1)
        context.insert(surah2)
        try context.save()
        
        try service.setNextToMemorize(surah1)
        #expect(surah1.isNextToMemorize == true)
        #expect(surah2.isNextToMemorize == false)
        
        // Setting surah2 should clear surah1
        try service.setNextToMemorize(surah2)
        #expect(surah1.isNextToMemorize == false)
        #expect(surah2.isNextToMemorize == true)
    }
    
    @Test func getSettings() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        // First call creates default settings
        let settings1 = try service.getSettings()
        #expect(settings1.id == "singleton")
        #expect(settings1.themeMode == .auto)
        
        // Second call returns same settings
        let settings2 = try service.getSettings()
        #expect(settings1.id == settings2.id)
    }
    
    @Test func getAllSurahsSorted() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        let surah114 = Surah(number: 114, nameArabic: "الناس", nameTransliteration: "An-Nas", nameTranslation: "Mankind", ayahCount: 6)
        let surah112 = Surah(number: 112, nameArabic: "الإخلاص", nameTransliteration: "Al-Ikhlas", nameTranslation: "The Sincerity", ayahCount: 4)
        let surah113 = Surah(number: 113, nameArabic: "الفلق", nameTransliteration: "Al-Falaq", nameTranslation: "The Daybreak", ayahCount: 5)
        
        // Insert in reverse order
        context.insert(surah114)
        context.insert(surah112)
        context.insert(surah113)
        try context.save()
        
        let allSurahs = try service.getAllSurahs()
        #expect(allSurahs.count == 3)
        #expect(allSurahs[0].number == 112)
        #expect(allSurahs[1].number == 113)
        #expect(allSurahs[2].number == 114)
    }
    
    @Test func getBookmarkedSurahs() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        let surah1 = Surah(number: 112, nameArabic: "الإخلاص", nameTransliteration: "Al-Ikhlas", nameTranslation: "The Sincerity", ayahCount: 4, isBookmarked: true)
        let surah2 = Surah(number: 113, nameArabic: "الفلق", nameTransliteration: "Al-Falaq", nameTranslation: "The Daybreak", ayahCount: 5)
        context.insert(surah1)
        context.insert(surah2)
        try context.save()
        
        let bookmarked = try service.getBookmarkedSurahs()
        #expect(bookmarked.count == 1)
        #expect(bookmarked[0].number == 112)
    }
    
    @Test func getSurahByNumber() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let service = QuranDataService(modelContext: context)
        
        let surah = Surah(number: 114, nameArabic: "الناس", nameTransliteration: "An-Nas", nameTranslation: "Mankind", ayahCount: 6)
        context.insert(surah)
        try context.save()
        
        let found = try service.getSurah(number: 114)
        #expect(found != nil)
        #expect(found?.nameTransliteration == "An-Nas")
        
        let notFound = try service.getSurah(number: 1)
        #expect(notFound == nil)
    }
}

// MARK: - SurahDetailViewModel Tests

@Suite(.serialized)
@MainActor
struct SurahDetailViewModelTests {
    
    private func makeTestContext() throws -> ModelContext {
        let schema = Schema([Surah.self, Ayah.self, AppSettings.self, Translation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }
    
    @Test func toggleBookmarkSetsError() throws {
        let context = try makeTestContext()
        let vm = SurahDetailViewModel(modelContext: context)
        
        let surah = Surah(number: 114, nameArabic: "الناس", nameTransliteration: "An-Nas", nameTranslation: "Mankind", ayahCount: 6)
        context.insert(surah)
        try context.save()
        
        let error = vm.toggleBookmark(for: surah)
        #expect(error == nil)
        #expect(surah.isBookmarked == true)
    }
    
    @Test func toggleMemorizationSetsError() throws {
        let context = try makeTestContext()
        let vm = SurahDetailViewModel(modelContext: context)
        
        let surah = Surah(number: 112, nameArabic: "الإخلاص", nameTransliteration: "Al-Ikhlas", nameTranslation: "The Sincerity", ayahCount: 4)
        context.insert(surah)
        try context.save()
        
        let error = vm.toggleMemorization(for: surah)
        #expect(error == nil)
        #expect(surah.isMemorized == true)
    }
    
    @Test func loadAvailableTranslations() throws {
        let context = try makeTestContext()
        let vm = SurahDetailViewModel(modelContext: context)
        
        // No translations yet
        let result = vm.loadAvailableTranslations()
        #expect(result.translations.isEmpty)
        #expect(result.error == nil)
    }
    
    @Test func updateLastAccessed() throws {
        let context = try makeTestContext()
        let vm = SurahDetailViewModel(modelContext: context)
        
        let surah = Surah(number: 114, nameArabic: "الناس", nameTransliteration: "An-Nas", nameTranslation: "Mankind", ayahCount: 6)
        context.insert(surah)
        try context.save()
        
        #expect(surah.lastAccessedDate == nil)
        vm.updateLastAccessed(for: surah)
        #expect(surah.lastAccessedDate != nil)
    }
}

// MARK: - Constants Tests

struct ConstantsTests {
    
    @Test func appConstantsJuzAmmaRange() {
        #expect(AppConstants.juzAmmaSurahRange == 78...114)
        #expect(AppConstants.totalSurahsInJuzAmma == 37)
    }
    
    @Test func apiEndpoints() {
        #expect(AppConstants.API.baseURL.contains("quran.com"))
        #expect(!AppConstants.API.translationsEndpoint.isEmpty)
        #expect(!AppConstants.API.recitationsEndpoint.isEmpty)
        #expect(!AppConstants.API.chapterRecitationsEndpoint.isEmpty)
    }
    
    @Test func fontConstants() {
        #expect(AppConstants.Fonts.quranDefaultSize > 0)
        #expect(!AppConstants.Fonts.quranArabic.isEmpty)
        #expect(!AppConstants.Fonts.arabicDisplay.isEmpty)
    }
}

// MARK: - QuranDataError Tests

struct QuranDataErrorTests {
    
    @Test func errorDescriptions() {
        #expect(QuranDataError.fileNotFound.errorDescription != nil)
        #expect(QuranDataError.decodingFailed.errorDescription != nil)
        #expect(QuranDataError.saveFailed.errorDescription != nil)
    }
}

// MARK: - AudioError Tests

struct AudioErrorTests {
    
    @Test func errorDescriptions() {
        #expect(AudioError.invalidURL.errorDescription != nil)
        #expect(AudioError.networkError.errorDescription != nil)
        #expect(AudioError.playbackFailed.errorDescription != nil)
        #expect(AudioError.noAudioAvailable.errorDescription != nil)
    }
}
