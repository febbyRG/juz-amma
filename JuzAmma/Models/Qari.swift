//
//  Qari.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 27/01/26.
//

import Foundation

// MARK: - Qari Model

/// Represents a Quran reciter (Qari)
struct Qari: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let style: String?
    let arabicName: String?
    
    /// Display name including style if available
    var displayName: String {
        if let style = style {
            return "\(name) (\(style))"
        }
        return name
    }
}

// MARK: - API Response Models

/// Response from /resources/recitations endpoint
struct RecitationsResponse: Codable {
    let recitations: [RecitationData]
}

/// Recitation data from API
struct RecitationData: Codable {
    let id: Int
    let reciterName: String
    let style: String?
    let translatedName: TranslatedName?
    
    enum CodingKeys: String, CodingKey {
        case id
        case reciterName = "reciter_name"
        case style
        case translatedName = "translated_name"
    }
    
    struct TranslatedName: Codable {
        let name: String
        let languageName: String
        
        enum CodingKeys: String, CodingKey {
            case name
            case languageName = "language_name"
        }
    }
    
    /// Convert to Qari model
    func toQari() -> Qari {
        Qari(
            id: id,
            name: reciterName,
            style: style,
            arabicName: nil
        )
    }
}

// MARK: - Chapter Audio Response

/// Response from /chapter_recitations/:reciter_id/:chapter_number endpoint
struct ChapterAudioResponse: Codable {
    let audioFile: ChapterAudioFile
    
    enum CodingKeys: String, CodingKey {
        case audioFile = "audio_file"
    }
}

/// Chapter-level audio file metadata
struct ChapterAudioFile: Codable {
    let id: Int
    let chapterId: Int
    let fileSize: Double
    let format: String
    let audioUrl: String
    let timestamps: [VerseTiming]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case fileSize = "file_size"
        case format
        case audioUrl = "audio_url"
        case timestamps
    }
}

/// Timing information for each verse in chapter audio
struct VerseTiming: Codable {
    let verseKey: String
    let timestampFrom: Int
    let timestampTo: Int
    let segments: [[Int]]?
    
    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case timestampFrom = "timestamp_from"
        case timestampTo = "timestamp_to"
        case segments
    }
    
    /// Verse number extracted from verseKey (e.g., "114:3" -> 3)
    var verseNumber: Int? {
        let components = verseKey.split(separator: ":")
        guard components.count == 2 else { return nil }
        return Int(components[1])
    }
    
    /// Start time in seconds
    var startTimeSeconds: TimeInterval {
        TimeInterval(timestampFrom) / 1000.0
    }
    
    /// End time in seconds
    var endTimeSeconds: TimeInterval {
        TimeInterval(timestampTo) / 1000.0
    }
}

// MARK: - Verse Audio Response

/// Response from /recitations/:reciter_id/by_chapter/:chapter_number endpoint
struct VerseAudioResponse: Codable {
    let audioFiles: [VerseAudioFile]
    let pagination: Pagination?
    
    enum CodingKeys: String, CodingKey {
        case audioFiles = "audio_files"
        case pagination
    }
}

/// Verse-level audio file metadata
struct VerseAudioFile: Codable {
    let verseKey: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case url
    }
    
    /// Parse verse number from verseKey (e.g., "114:3" -> 3)
    var verseNumber: Int? {
        let components = verseKey.split(separator: ":")
        guard components.count == 2 else { return nil }
        return Int(components[1])
    }
    
    /// Parse chapter number from verseKey (e.g., "114:3" -> 114)
    var chapterNumber: Int? {
        let components = verseKey.split(separator: ":")
        guard components.count == 2 else { return nil }
        return Int(components[0])
    }
    
    /// Full URL for verse audio
    /// The URL from API is like "Alafasy/mp3/114001.mp3"
    /// We construct full URL using Quran.com CDN
    var fullUrl: String {
        // Primary CDN for verse audio
        "https://verses.quran.com/\(url)"
    }
}

/// Pagination info for API responses
struct Pagination: Codable {
    let perPage: Int
    let currentPage: Int
    let nextPage: Int?
    let totalPages: Int
    let totalRecords: Int
    
    enum CodingKeys: String, CodingKey {
        case perPage = "per_page"
        case currentPage = "current_page"
        case nextPage = "next_page"
        case totalPages = "total_pages"
        case totalRecords = "total_records"
    }
}

// MARK: - Popular Qaris (Predefined)

/// Commonly used Qaris for quick access
enum PopularQari: CaseIterable, Identifiable {
    case misharyAlafasy
    case abdulBasetMurattal
    case abdulBasetMujawwad
    case sudais
    case shatri
    case husary
    case husaryMuallim
    case minshawi
    
    var id: Int {
        qari.id
    }
    
    var qari: Qari {
        switch self {
        case .misharyAlafasy:
            return Qari(id: 7, name: "Mishari Rashid al-Afasy", style: nil, arabicName: "مشاري راشد العفاسي")
        case .abdulBasetMurattal:
            return Qari(id: 2, name: "AbdulBaset AbdulSamad", style: "Murattal", arabicName: "عبد الباسط عبد الصمد")
        case .abdulBasetMujawwad:
            return Qari(id: 1, name: "AbdulBaset AbdulSamad", style: "Mujawwad", arabicName: "عبد الباسط عبد الصمد")
        case .sudais:
            return Qari(id: 3, name: "Abdur-Rahman as-Sudais", style: nil, arabicName: "عبد الرحمن السديس")
        case .shatri:
            return Qari(id: 4, name: "Abu Bakr al-Shatri", style: nil, arabicName: "أبو بكر الشاطري")
        case .husary:
            return Qari(id: 6, name: "Mahmoud Khalil Al-Husary", style: nil, arabicName: "محمود خليل الحصري")
        case .husaryMuallim:
            return Qari(id: 12, name: "Mahmoud Khalil Al-Husary", style: "Muallim", arabicName: "محمود خليل الحصري")
        case .minshawi:
            return Qari(id: 9, name: "Mohamed Siddiq al-Minshawi", style: "Murattal", arabicName: "محمد صديق المنشاوي")
        }
    }
}
