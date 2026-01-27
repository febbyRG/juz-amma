//
//  TranslationService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 17/11/25.
//

import Foundation
import SwiftData

/// Service for managing Quran translations
@MainActor
final class TranslationService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Text Cleaning
    
    /// Clean HTML tags and special characters from translation text
    private func cleanTranslationText(_ text: String) -> String {
        var cleanText = text
        
        // Remove sup tags with foot_note attribute AND their content (e.g., <sup foot_note="...">1</sup>)
        do {
            let footnoteSupRegex = try NSRegularExpression(pattern: "<sup[^>]*foot_note[^>]*>.*?</sup>", options: [])
            let range = NSRange(cleanText.startIndex..., in: cleanText)
            cleanText = footnoteSupRegex.stringByReplacingMatches(
                in: cleanText,
                options: [],
                range: range,
                withTemplate: ""
            )
        } catch {
            print("Footnote sup regex error: \(error)")
        }
        
        // Remove remaining sup tags with their content (e.g., <sup>1</sup>)
        do {
            let supRegex = try NSRegularExpression(pattern: "<sup[^>]*>.*?</sup>", options: [])
            let range = NSRange(cleanText.startIndex..., in: cleanText)
            cleanText = supRegex.stringByReplacingMatches(
                in: cleanText,
                options: [],
                range: range,
                withTemplate: ""
            )
        } catch {
            print("Sup regex error: \(error)")
        }
        
        // Remove all other HTML tags (but keep their content)
        do {
            let regex = try NSRegularExpression(pattern: "<[^>]*>", options: [])
            let range = NSRange(cleanText.startIndex..., in: cleanText)
            cleanText = regex.stringByReplacingMatches(
                in: cleanText,
                options: [],
                range: range,
                withTemplate: ""
            )
        } catch {
            print("Regex error: \(error)")
        }
        
        // Remove HTML entities
        let entities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'"
        ]
        
        for (entity, replacement) in entities {
            cleanText = cleanText.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Trim whitespace and newlines
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple spaces with single space
        do {
            let spaceRegex = try NSRegularExpression(pattern: "\\s{2,}", options: [])
            let range = NSRange(cleanText.startIndex..., in: cleanText)
            cleanText = spaceRegex.stringByReplacingMatches(
                in: cleanText,
                options: [],
                range: range,
                withTemplate: " "
            )
        } catch {
            print("Space regex error: \(error)")
        }
        
        return cleanText
    }
    
    // MARK: - Available Translations
    
    /// Fetch list of all available translations from API
    func fetchAvailableTranslations() async throws -> [TranslationInfo] {
        guard let url = URL(string: "\(AppConstants.API.baseURL)\(AppConstants.API.translationsEndpoint)") else {
            throw TranslationError.networkError
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let translations: [TranslationInfo]
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.translations
    }
    
    /// Get popular translations (predefined list)
    func getPopularTranslations() -> [TranslationInfo] {
        PopularTranslation.allCases.map { popular in
            let info = popular.info
            return TranslationInfo(
                id: info.id,
                name: info.name,
                authorName: "",
                languageCode: info.code,
                languageName: info.language
            )
        }
    }
    
    // MARK: - Download Translations
    
    /// Download translation for all surahs in Juz Amma (78-114)
    func downloadTranslation(
        translationId: Int,
        languageCode: String,
        name: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let juzAmmaSurahs = AppConstants.juzAmmaSurahRange
        let totalSurahs = juzAmmaSurahs.count
        var completed = 0
        
        for surahNumber in juzAmmaSurahs {
            try await downloadTranslationForSurah(
                surahNumber: surahNumber,
                translationId: translationId,
                languageCode: languageCode,
                name: name
            )
            
            completed += 1
            progress(Double(completed) / Double(totalSurahs))
        }
    }
    
    /// Download translation for a specific surah
    private func downloadTranslationForSurah(
        surahNumber: Int,
        translationId: Int,
        languageCode: String,
        name: String
    ) async throws {
        guard let url = URL(string: "\(AppConstants.API.baseURL)\(AppConstants.API.quranTranslationsEndpoint)/\(translationId)?chapter_number=\(surahNumber)") else {
            throw TranslationError.networkError
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let translations: [TranslationData]
        }
        
        struct TranslationData: Codable {
            let resource_id: Int
            let text: String
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        
        // Get ayahs from this surah
        let surahDescriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.number == surahNumber }
        )
        guard let surah = try modelContext.fetch(surahDescriptor).first,
              let ayahs = surah.ayahs else {
            return
        }
        
        // Add translations to ayahs
        for (index, translationData) in response.translations.enumerated() {
            guard index < ayahs.count else { break }
            let ayah = ayahs[index]
            
            // Check if translation already exists
            let existingTranslation = ayah.translations?.first { $0.id == translationId }
            
            if existingTranslation == nil {
                // Create new translation with cleaned text
                let cleanText = cleanTranslationText(translationData.text)
                let translation = Translation(
                    id: translationId,
                    languageCode: languageCode,
                    name: name,
                    text: cleanText
                )
                translation.ayah = ayah
                
                if ayah.translations == nil {
                    ayah.translations = []
                }
                ayah.translations?.append(translation)
                
                modelContext.insert(translation)
            }
        }
        
        try modelContext.save()
        
        // Small delay to avoid rate limiting
        try await Task.sleep(for: .milliseconds(AppConstants.API.rateLimitDelay))
    }
    
    // MARK: - Manage Downloaded Translations
    
    /// Get list of downloaded translation IDs
    func getDownloadedTranslationIds() throws -> [Int] {
        let descriptor = FetchDescriptor<Translation>()
        let allTranslations = try modelContext.fetch(descriptor)
        
        let uniqueIds = Set(allTranslations.map { $0.id })
        return Array(uniqueIds).sorted()
    }
    
    /// Check if a translation is downloaded
    func isTranslationDownloaded(translationId: Int) throws -> Bool {
        let descriptor = FetchDescriptor<Translation>(
            predicate: #Predicate { $0.id == translationId }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }
    
    /// Delete a translation
    func deleteTranslation(translationId: Int) throws {
        let descriptor = FetchDescriptor<Translation>(
            predicate: #Predicate { $0.id == translationId }
        )
        let translations = try modelContext.fetch(descriptor)
        
        for translation in translations {
            modelContext.delete(translation)
        }
        
        try modelContext.save()
    }
    
    /// Clean existing translations that have HTML tags
    func cleanExistingTranslations() throws {
        let descriptor = FetchDescriptor<Translation>()
        let allTranslations = try modelContext.fetch(descriptor)
        
        var cleanedCount = 0
        for translation in allTranslations {
            // Check if text contains HTML tags
            if translation.text.contains("<") && translation.text.contains(">") {
                translation.text = cleanTranslationText(translation.text)
                cleanedCount += 1
            }
        }
        
        if cleanedCount > 0 {
            try modelContext.save()
        }
    }
    
    /// Get translation statistics
    func getTranslationStats() throws -> TranslationStats {
        let descriptor = FetchDescriptor<Translation>()
        let allTranslations = try modelContext.fetch(descriptor)
        
        let byLanguage = Dictionary(grouping: allTranslations) { $0.languageCode }
        let totalSize = allTranslations.reduce(0) { $0 + $1.text.utf8.count }
        
        return TranslationStats(
            totalTranslations: allTranslations.count,
            uniqueLanguages: byLanguage.keys.count,
            estimatedSize: totalSize
        )
    }
}

// MARK: - Supporting Types

struct TranslationStats {
    let totalTranslations: Int
    let uniqueLanguages: Int
    let estimatedSize: Int
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(estimatedSize), countStyle: .memory)
    }
}

enum TranslationError: LocalizedError {
    case networkError
    case decodingError
    case notFound
    case alreadyDownloaded
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Failed to download translation. Check your internet connection."
        case .decodingError:
            return "Failed to process translation data."
        case .notFound:
            return "Translation not found."
        case .alreadyDownloaded:
            return "Translation already downloaded."
        }
    }
}
