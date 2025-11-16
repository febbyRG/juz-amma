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
    let languageCode: String
    let languageName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case authorName = "author_name"
        case languageCode = "language_name"
        case languageName = "translated_name"
    }
    
    var displayName: String {
        "\(name) - \(authorName)"
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
