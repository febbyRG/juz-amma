//
//  AppSettings.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 15/11/25.
//

import Foundation
import SwiftData

/// User preferences and app settings
@Model
final class AppSettings {
    /// Unique identifier (singleton pattern)
    var id: String
    
    /// Theme preference: light, dark, or auto
    var themeMode: ThemeMode
    
    /// Font size multiplier (1.0 = default)
    var fontSizeMultiplier: Double
    
    /// Whether to show transliteration
    var showTransliteration: Bool
    
    /// Primary translation ID (e.g., 20 for Saheeh International)
    var primaryTranslationId: Int
    
    /// Primary translation language code (e.g., "en", "id")
    var primaryTranslationLanguage: String
    
    /// Secondary translation ID (optional)
    var secondaryTranslationId: Int?
    
    /// Secondary translation language code (optional)
    var secondaryTranslationLanguage: String?
    
    /// Whether to show both primary and secondary translations
    var showBothTranslations: Bool
    
    /// Whether notifications are enabled
    var notificationsEnabled: Bool
    
    /// Time for daily reminder notification
    var reminderTime: Date?
    
    /// Selected Qari for audio recitation (future feature)
    var selectedQari: String
    
    /// Last app version launched
    var lastAppVersion: String
    
    /// Date when app was first launched
    var firstLaunchDate: Date
    
    /// Total time spent in app (seconds)
    var totalTimeSpent: TimeInterval
    
    /// Whether to only download audio on WiFi
    var wifiOnlyDownload: Bool
    
    /// Last playing surah number (for playback state persistence)
    var lastPlayingSurahNumber: Int?
    
    /// Last playback position in seconds
    var lastPlaybackPosition: TimeInterval?
    
    init(
        id: String = "singleton",
        themeMode: ThemeMode = .auto,
        fontSizeMultiplier: Double = 1.0,
        showTransliteration: Bool = true,
        primaryTranslationId: Int = 20,
        primaryTranslationLanguage: String = "en",
        secondaryTranslationId: Int? = 33,
        secondaryTranslationLanguage: String? = "id",
        showBothTranslations: Bool = true,
        notificationsEnabled: Bool = false,
        reminderTime: Date? = nil,
        selectedQari: String = "Mishary Alafasy",
        lastAppVersion: String = "1.0",
        firstLaunchDate: Date = Date(),
        totalTimeSpent: TimeInterval = 0,
        wifiOnlyDownload: Bool = false,
        lastPlayingSurahNumber: Int? = nil,
        lastPlaybackPosition: TimeInterval? = nil
    ) {
        self.id = id
        self.themeMode = themeMode
        self.fontSizeMultiplier = fontSizeMultiplier
        self.showTransliteration = showTransliteration
        self.primaryTranslationId = primaryTranslationId
        self.primaryTranslationLanguage = primaryTranslationLanguage
        self.secondaryTranslationId = secondaryTranslationId
        self.secondaryTranslationLanguage = secondaryTranslationLanguage
        self.showBothTranslations = showBothTranslations
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.selectedQari = selectedQari
        self.lastAppVersion = lastAppVersion
        self.firstLaunchDate = firstLaunchDate
        self.totalTimeSpent = totalTimeSpent
        self.wifiOnlyDownload = wifiOnlyDownload
        self.lastPlayingSurahNumber = lastPlayingSurahNumber
        self.lastPlaybackPosition = lastPlaybackPosition
    }
}

/// Theme mode options
enum ThemeMode: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case auto = "Auto"
    
    var displayName: String {
        rawValue
    }
}
