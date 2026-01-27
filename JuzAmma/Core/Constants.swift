//
//  Constants.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 27/01/26.
//

import SwiftUI

// MARK: - App Constants

/// Central location for all app-wide constants
enum AppConstants {
    
    // MARK: - App Info
    
    static let appName = "Juz Amma"
    static let appVersion = "1.0.0"
    static let developerName = "Febby Rachmat G."
    static let githubURL = URL(string: "https://github.com/febbyRG/juz-amma")!
    
    // MARK: - Juz Amma Range
    
    static let juzAmmaSurahRange = 78...114
    static let totalSurahsInJuzAmma = 37
    
    // MARK: - API
    
    enum API {
        static let baseURL = "https://api.quran.com/api/v4"
        static let translationsEndpoint = "/resources/translations"
        static let quranTranslationsEndpoint = "/quran/translations"
        
        /// Rate limiting delay between API calls (in milliseconds)
        static let rateLimitDelay: UInt64 = 300
    }
    
    // MARK: - Fonts
    
    enum Fonts {
        /// Arabic Quran font with proper harakat rendering
        static let quranArabic = "Amiri Quran"
        
        /// Arabic display font
        static let arabicDisplay = "GeezaPro"
        static let arabicDisplayBold = "GeezaPro-Bold"
        
        /// Default sizes
        static let quranDefaultSize: CGFloat = 28
        static let quranSmallSize: CGFloat = 24
        static let quranLargeSize: CGFloat = 32
        static let quranExtraLargeSize: CGFloat = 36
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let defaultDuration: TimeInterval = 0.3
        static let loadingTransitionDelay: TimeInterval = 0.5
    }
    
    // MARK: - Layout
    
    enum Layout {
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        
        static let iconSizeSmall: CGFloat = 50
        static let iconSizeMedium: CGFloat = 60
        static let iconSizeLarge: CGFloat = 120
        
        static let appIconCornerRadius: CGFloat = 26.4
    }
    
    // MARK: - Storage
    
    enum Storage {
        static let settingsSingletonId = "singleton"
    }
}

// MARK: - Theme Colors

enum AppColors {
    
    // MARK: - Brand Colors
    
    static let primaryGreen = Color(red: 0.165, green: 0.620, blue: 0.427)
    static let secondaryGreen = Color(red: 0.263, green: 0.722, blue: 0.549)
    
    // MARK: - Gradient
    
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [primaryGreen, secondaryGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Status Colors
    
    static let memorized = Color.green
    static let bookmarked = Color.blue
    static let nextToMemorize = Color.yellow
    static let error = Color.red
    
    // MARK: - Background Colors
    
    static let cardBackground = Color.gray.opacity(0.05)
    static let chipActiveBackground = Color.accentColor
    static let chipInactiveBackground = Color.gray.opacity(0.2)
}

// MARK: - Accessibility Identifiers

enum AccessibilityIdentifiers {
    static let surahList = "surah_list"
    static let surahRow = "surah_row"
    static let surahDetail = "surah_detail"
    static let ayahView = "ayah_view"
    static let settingsView = "settings_view"
    static let translationPicker = "translation_picker"
    static let translationManager = "translation_manager"
    static let progressCard = "progress_card"
    static let filterChip = "filter_chip"
}

// MARK: - Localization Keys (for future i18n support)

enum LocalizationKeys {
    static let appName = "app_name"
    static let loadingQuranData = "loading_quran_data"
    static let memorizedProgress = "memorization_progress"
    static let nextToMemorize = "next_to_memorize"
    static let bookmarks = "bookmarks"
    static let memorized = "memorized"
    static let searchSurahs = "search_surahs"
    static let noResults = "no_results"
    static let bismillah = "bismillah"
}
