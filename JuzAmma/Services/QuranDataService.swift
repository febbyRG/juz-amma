//
//  QuranDataService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import Foundation
import SwiftData

/// Service for loading and managing Quran data
@MainActor
class QuranDataService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Load Juz Amma data from JSON file into SwiftData
    func loadJuzAmmaData() async throws {
        // Check if data already exists
        let descriptor = FetchDescriptor<Surah>()
        let existingSurahs = try modelContext.fetch(descriptor)
        
        guard existingSurahs.isEmpty else {
            return
        }
        
        // Load JSON file
        guard let url = Bundle.main.url(forResource: "juz_amma_data", withExtension: "json") else {
            throw QuranDataError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let jsonData = try decoder.decode(JuzAmmaJSON.self, from: data)
        
        // Convert JSON to SwiftData models
        for surahData in jsonData.juzAmma {
            let surah = Surah(
                number: surahData.number,
                nameArabic: surahData.nameArabic,
                nameTransliteration: surahData.nameTransliteration,
                nameTranslation: surahData.nameTranslation,
                ayahCount: surahData.ayahCount,
                revelation: surahData.revelation
            )
            
            // Add ayahs if available
            var ayahModels: [Ayah] = []
            for ayahData in surahData.ayahs {
                let ayah = Ayah(
                    number: ayahData.number,
                    textArabic: ayahData.textArabic,
                    textTransliteration: ayahData.textTransliteration,
                    translationEnglish: ayahData.translationEnglish,
                    translationIndonesian: ayahData.translationIndonesian
                )
                ayah.surah = surah
                ayahModels.append(ayah)
                modelContext.insert(ayah)
            }
            
            surah.ayahs = ayahModels
            modelContext.insert(surah)
        }
        
        try modelContext.save()
    }
    
    /// Get all surahs from Juz Amma
    func getAllSurahs() throws -> [Surah] {
        let descriptor = FetchDescriptor<Surah>(
            sortBy: [SortDescriptor(\.number)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get a specific surah by number
    func getSurah(number: Int) throws -> Surah? {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.number == number }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// Get bookmarked surahs
    func getBookmarkedSurahs() throws -> [Surah] {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.isBookmarked == true },
            sortBy: [SortDescriptor(\.number)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get memorized surahs
    func getMemorizedSurahs() throws -> [Surah] {
        let descriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.isMemorized == true },
            sortBy: [SortDescriptor(\.number)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Toggle bookmark for a surah
    func toggleBookmark(for surah: Surah) throws {
        surah.isBookmarked.toggle()
        try modelContext.save()
    }
    
    /// Toggle memorization status for a surah
    func toggleMemorization(for surah: Surah) throws {
        surah.isMemorized.toggle()
        surah.memorizedDate = surah.isMemorized ? Date() : nil
        try modelContext.save()
    }
    
    /// Set next surah to memorize
    func setNextToMemorize(_ surah: Surah) throws {
        // Clear previous "next to memorize"
        let allSurahs = try getAllSurahs()
        for s in allSurahs {
            s.isNextToMemorize = false
        }
        
        // Set new one
        surah.isNextToMemorize = true
        try modelContext.save()
    }
    
    /// Get or create app settings (singleton)
    func getSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let settings = try modelContext.fetch(descriptor)
        
        if let existingSettings = settings.first {
            return existingSettings
        }
        
        // Create default settings
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        try modelContext.save()
        return newSettings
    }
    
    /// Update app settings
    func updateSettings(_ settings: AppSettings) throws {
        try modelContext.save()
    }
}

// MARK: - JSON Decoding Models
private struct JuzAmmaJSON: Codable {
    let juzAmma: [SurahJSON]
}

private struct SurahJSON: Codable {
    let number: Int
    let nameArabic: String
    let nameTransliteration: String
    let nameTranslation: String
    let ayahCount: Int
    let revelation: String
    let ayahs: [AyahJSON]
}

private struct AyahJSON: Codable {
    let number: Int
    let textArabic: String
    let textTransliteration: String
    let translationEnglish: String
    let translationIndonesian: String
}

// MARK: - Errors
enum QuranDataError: LocalizedError {
    case fileNotFound
    case decodingFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Quran data file not found in bundle"
        case .decodingFailed:
            return "Failed to decode Quran data"
        case .saveFailed:
            return "Failed to save data to storage"
        }
    }
}
