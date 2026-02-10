//
//  Translation.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 17/11/25.
//

import Foundation
import SwiftData

/// Represents a translation of Quranic text in a specific language
@Model
final class Translation {
    /// Unique translation ID from Quran.com API
    var id: Int
    
    /// ISO language code (e.g., "en", "id", "ar", "fr")
    var languageCode: String
    
    /// Display name of the translation source
    var name: String
    
    /// Translated text content
    var text: String
    
    /// Parent ayah reference
    var ayah: Ayah?
    
    init(
        id: Int,
        languageCode: String,
        name: String,
        text: String
    ) {
        self.id = id
        self.languageCode = languageCode
        self.name = name
        self.text = text
    }
}

/// Metadata about available translations
struct TranslationInfo: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let authorName: String
    /// The language name from API (e.g., "english", "indonesian")
    let languageName: String
    /// Translated display name from API
    let translatedName: TranslatedName?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case authorName = "author_name"
        case languageName = "language_name"
        case translatedName = "translated_name"
    }
    
    /// ISO language code derived from the language name
    var languageCode: String {
        Self.languageNameToCode[languageName.lowercased()] ?? languageName.lowercased()
    }
    
    var displayName: String {
        "\(name) - \(authorName)"
    }
    
    /// Mapping from API language names to ISO codes
    private static let languageNameToCode: [String: String] = [
        "english": "en",
        "indonesian": "id",
        "arabic": "ar",
        "french": "fr",
        "spanish": "es",
        "german": "de",
        "turkish": "tr",
        "urdu": "ur",
        "malay": "ms",
        "russian": "ru",
        "bengali": "bn",
        "persian": "fa",
        "chinese": "zh",
        "japanese": "ja",
        "korean": "ko",
        "hindi": "hi",
        "tamil": "ta",
        "portuguese": "pt",
        "italian": "it",
        "dutch": "nl",
        "thai": "th",
        "swedish": "sv",
        "bosnian": "bs",
        "albanian": "sq",
        "azerbaijani": "az",
        "azeri": "az",
        "kurdish": "ku",
        "somali": "so",
        "swahili": "sw",
        "amharic": "am",
        "hausa": "ha",
        "yoruba": "yo",
        "uzbek": "uz",
        "tajik": "tg",
        "malaysian": "ms",
        "malayalam": "ml",
        "telugu": "te",
        "tagalog": "tl",
        "cebuano": "ceb",
        "vietnamese": "vi",
        "sinhalese": "si",
        "kazakh": "kk",
        "pashto": "ps",
        "sindhi": "sd",
        "assamese": "as",
        "gujarati": "gu",
        "oromo": "om",
        "amazigh": "ber",
        "divehi, dhivehi, maldivian": "dv",
        "uighur, uyghur": "ug",
        "norwegian": "no",
    ]
    
    /// Manual initializer for building TranslationInfo from PopularTranslation
    init(id: Int, name: String, authorName: String, languageCode: String, languageName: String) {
        self.id = id
        self.name = name
        self.authorName = authorName
        self.languageName = languageName
        self.translatedName = nil
    }
}

/// Represents the "translated_name" nested object from the API
struct TranslatedName: Codable, Hashable {
    let name: String
    let languageName: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case languageName = "language_name"
    }
}

/// Represents a downloaded translation with its metadata
/// Used instead of tuples for type safety and clarity
struct DownloadedTranslation: Identifiable, Hashable {
    let id: Int
    let name: String
    let languageCode: String
    
    init(id: Int, name: String, languageCode: String) {
        self.id = id
        self.name = name
        self.languageCode = languageCode
    }
}

/// Popular pre-defined translations
enum PopularTranslation: CaseIterable, Identifiable {
    case saheehInternational
    case indonesianMinistry
    case yusufAli
    case kingFahadQuran
    case french
    case spanish
    case german
    case turkish
    case urdu
    case malay
    
    var id: Int {
        info.id
    }
    
    var info: (id: Int, name: String, language: String, code: String) {
        switch self {
        case .saheehInternational:
            return (20, "Saheeh International", "English", "en")
        case .indonesianMinistry:
            return (33, "Indonesian Ministry of Religious Affairs", "Indonesian", "id")
        case .yusufAli:
            return (22, "Yusuf Ali", "English", "en")
        case .kingFahadQuran:
            return (78, "King Fahad Quran Complex", "Arabic", "ar")
        case .french:
            return (31, "Muhammad Hamidullah", "French", "fr")
        case .spanish:
            return (83, "Muhammad Isa García", "Spanish", "es")
        case .german:
            return (27, "Frank Bubenheim & Nadeem", "German", "de")
        case .turkish:
            return (77, "Diyanet İşleri", "Turkish", "tr")
        case .urdu:
            return (97, "Maulana Fateh Muhammad Jalandhry", "Urdu", "ur")
        case .malay:
            return (134, "Abdullah Muhammad Basmeih", "Malay", "ms")
        }
    }
}
