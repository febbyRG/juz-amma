//
//  Surah.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import Foundation
import SwiftData

/// Represents a Surah (chapter) from Juz Amma (Juz 30)
@Model
final class Surah {
    /// Surah number in the Quran (78-114 for Juz Amma)
    var number: Int
    
    /// Arabic name of the surah
    var nameArabic: String
    
    /// Transliteration of the Arabic name
    var nameTransliteration: String
    
    /// English translation of the name
    var nameTranslation: String
    
    /// Number of ayahs (verses) in this surah
    var ayahCount: Int
    
    /// Revelation location (Makkah or Madinah)
    var revelation: String
    
    /// Whether this surah is bookmarked by the user
    var isBookmarked: Bool
    
    /// Whether the user has memorized this surah
    var isMemorized: Bool
    
    /// Date when the surah was marked as memorized
    var memorizedDate: Date?
    
    /// Date when the surah was last accessed
    var lastAccessedDate: Date?
    
    /// Whether this is marked as the next surah to memorize
    var isNextToMemorize: Bool
    
    /// Array of ayahs in this surah
    @Relationship(deleteRule: .cascade) var ayahs: [Ayah]?
    
    init(
        number: Int,
        nameArabic: String,
        nameTransliteration: String,
        nameTranslation: String,
        ayahCount: Int,
        revelation: String = "Makkah",
        isBookmarked: Bool = false,
        isMemorized: Bool = false,
        memorizedDate: Date? = nil,
        lastAccessedDate: Date? = nil,
        isNextToMemorize: Bool = false
    ) {
        self.number = number
        self.nameArabic = nameArabic
        self.nameTransliteration = nameTransliteration
        self.nameTranslation = nameTranslation
        self.ayahCount = ayahCount
        self.revelation = revelation
        self.isBookmarked = isBookmarked
        self.isMemorized = isMemorized
        self.memorizedDate = memorizedDate
        self.lastAccessedDate = lastAccessedDate
        self.isNextToMemorize = isNextToMemorize
    }
}

/// Represents an Ayah (verse) within a Surah
@Model
final class Ayah {
    /// Ayah number within the surah
    var number: Int
    
    /// Arabic text of the ayah
    var textArabic: String
    
    /// Transliteration of the ayah
    var textTransliteration: String
    
    /// English translation
    var translationEnglish: String
    
    /// Indonesian translation
    var translationIndonesian: String
    
    /// Whether this specific ayah is bookmarked
    var isBookmarked: Bool
    
    /// Parent surah reference
    var surah: Surah?
    
    init(
        number: Int,
        textArabic: String,
        textTransliteration: String = "",
        translationEnglish: String = "",
        translationIndonesian: String = "",
        isBookmarked: Bool = false
    ) {
        self.number = number
        self.textArabic = textArabic
        self.textTransliteration = textTransliteration
        self.translationEnglish = translationEnglish
        self.translationIndonesian = translationIndonesian
        self.isBookmarked = isBookmarked
    }
}

// MARK: - Codable Support for JSON Import
extension Ayah {
    struct AyahData: Codable {
        let number: Int
        let textArabic: String
        let textTransliteration: String
        let translationEnglish: String
        let translationIndonesian: String
    }
}

extension Surah {
    struct SurahData: Codable {
        let number: Int
        let nameArabic: String
        let nameTransliteration: String
        let nameTranslation: String
        let ayahCount: Int
        let revelation: String
        let ayahs: [Ayah.AyahData]
    }
}
