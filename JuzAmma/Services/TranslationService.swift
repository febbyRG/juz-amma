//
//  TranslationService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 17/11/25.
//

import Foundation
import SwiftData
import os

/// Service for managing Quran translations
@MainActor
final class TranslationService {
    
    // MARK: - Pre-compiled Regex Patterns (static let guarantees single init; patterns are compile-time safe)
    
    private static let footnoteSupRegex: NSRegularExpression = {
        // These patterns are hardcoded string literals, so they will never fail.
        // Using an IIFE instead of try! for static-analysis friendliness.
        do { return try NSRegularExpression(pattern: "<sup[^>]*foot_note[^>]*>.*?</sup>", options: []) }
        catch { fatalError("Invalid regex pattern – developer error") }
    }()
    private static let supRegex: NSRegularExpression = {
        do { return try NSRegularExpression(pattern: "<sup[^>]*>.*?</sup>", options: []) }
        catch { fatalError("Invalid regex pattern – developer error") }
    }()
    private static let htmlTagRegex: NSRegularExpression = {
        do { return try NSRegularExpression(pattern: "<[^>]*>", options: []) }
        catch { fatalError("Invalid regex pattern – developer error") }
    }()
    private static let multiSpaceRegex: NSRegularExpression = {
        do { return try NSRegularExpression(pattern: "\\s{2,}", options: []) }
        catch { fatalError("Invalid regex pattern – developer error") }
    }()
    
    private static let htmlEntities: [String: String] = [
        "&nbsp;": " ",
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&#39;": "'",
        "&apos;": "'"
    ]
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let networkService: any NetworkServiceProtocol
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, networkService: any NetworkServiceProtocol = NetworkService.shared) {
        self.modelContext = modelContext
        self.networkService = networkService
    }
    
    // MARK: - Text Cleaning
    
    /// Clean HTML tags and special characters from translation text.
    /// Visibility is `internal` (rather than `private`) so unit tests can verify cleaning logic.
    func cleanTranslationText(_ text: String) -> String {
        var cleanText = text
        let range = { NSRange(cleanText.startIndex..., in: cleanText) }
        
        // Remove sup tags with foot_note attribute AND their content
        cleanText = Self.footnoteSupRegex.stringByReplacingMatches(in: cleanText, range: range(), withTemplate: "")
        
        // Remove remaining sup tags with their content
        cleanText = Self.supRegex.stringByReplacingMatches(in: cleanText, range: range(), withTemplate: "")
        
        // Remove all other HTML tags (but keep their content)
        cleanText = Self.htmlTagRegex.stringByReplacingMatches(in: cleanText, range: range(), withTemplate: "")
        
        // Remove HTML entities
        for (entity, replacement) in Self.htmlEntities {
            cleanText = cleanText.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Trim whitespace and newlines
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace multiple spaces with single space
        cleanText = Self.multiSpaceRegex.stringByReplacingMatches(in: cleanText, range: range(), withTemplate: " ")
        
        return cleanText
    }
    
    // MARK: - Available Translations
    
    /// Fetch list of all available translations from API (cached for 5 min)
    func fetchAvailableTranslations() async throws -> [TranslationInfo] {
        guard let url = URL(string: "\(AppConstants.API.baseURL)\(AppConstants.API.translationsEndpoint)") else {
            throw TranslationError.networkError
        }
        
        struct Response: Codable, Sendable {
            let translations: [TranslationInfo]
        }
        
        let response = try await networkService.fetch(
            Response.self,
            from: url,
            cachePolicy: .cacheFirst(maxAge: AppConstants.Network.translationsCacheDuration)
        )
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
                languageName: info.language.lowercased()
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
        // Delete any existing translations with this ID first (clean re-download)
        let existingDescriptor = FetchDescriptor<Translation>(
            predicate: #Predicate { $0.id == translationId }
        )
        let existing = try modelContext.fetch(existingDescriptor)
        for t in existing {
            modelContext.delete(t)
        }
        if !existing.isEmpty {
            try modelContext.save()
        }
        
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
        
        struct Response: Codable, Sendable {
            let translations: [TranslationData]
        }
        
        struct TranslationData: Codable, Sendable {
            let resource_id: Int
            let text: String
        }
        
        let response = try await networkService.fetch(Response.self, from: url)
        
        // Get ayahs from this surah
        let surahDescriptor = FetchDescriptor<Surah>(
            predicate: #Predicate { $0.number == surahNumber }
        )
        guard let surah = try modelContext.fetch(surahDescriptor).first else {
            return
        }
        let ayahs = surah.ayahs
        
        // Sort ayahs by number to match API response order
        let sortedAyahs = ayahs.sorted { $0.number < $1.number }
        
        // Add translations to ayahs
        for (index, translationData) in response.translations.enumerated() {
            guard index < sortedAyahs.count else { break }
            let ayah = sortedAyahs[index]
            
            let cleanText = cleanTranslationText(translationData.text)
            
            // Check if translation already exists
            if let existingTranslation = ayah.translations.first(where: { $0.id == translationId }) {
                // Update existing translation text (in case of re-download)
                existingTranslation.text = cleanText
                existingTranslation.languageCode = languageCode
                existingTranslation.name = name
            } else {
                // Create new translation
                let translation = Translation(
                    id: translationId,
                    languageCode: languageCode,
                    name: name,
                    text: cleanText
                )
                translation.ayah = ayah
                ayah.translations.append(translation)
                
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
            AppLogger.translation.info("Cleaned HTML from \(cleanedCount) translations")
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

struct TranslationStats: Sendable {
    let totalTranslations: Int
    let uniqueLanguages: Int
    let estimatedSize: Int
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(estimatedSize), countStyle: .memory)
    }
}

enum TranslationError: LocalizedError, Sendable {
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
