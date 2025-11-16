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
    
    /// Whether to show English translation
    var showEnglishTranslation: Bool
    
    /// Whether to show Indonesian translation
    var showIndonesianTranslation: Bool
    
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
    
    init(
        id: String = "singleton",
        themeMode: ThemeMode = .auto,
        fontSizeMultiplier: Double = 1.0,
        showTransliteration: Bool = true,
        showEnglishTranslation: Bool = true,
        showIndonesianTranslation: Bool = true,
        notificationsEnabled: Bool = false,
        reminderTime: Date? = nil,
        selectedQari: String = "Mishary Alafasy",
        lastAppVersion: String = "1.0",
        firstLaunchDate: Date = Date(),
        totalTimeSpent: TimeInterval = 0
    ) {
        self.id = id
        self.themeMode = themeMode
        self.fontSizeMultiplier = fontSizeMultiplier
        self.showTransliteration = showTransliteration
        self.showEnglishTranslation = showEnglishTranslation
        self.showIndonesianTranslation = showIndonesianTranslation
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.selectedQari = selectedQari
        self.lastAppVersion = lastAppVersion
        self.firstLaunchDate = firstLaunchDate
        self.totalTimeSpent = totalTimeSpent
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
