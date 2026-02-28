//
//  AppLogger.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 23/02/26.
//

import Foundation
import os

/// Centralized structured logging using Apple's os.Logger
/// Usage: AppLogger.audio.info("Playing surah \(number)")
enum AppLogger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.juzamma.app"
    
    // MARK: - Category Loggers
    
    /// Audio playback and streaming
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    
    /// Data loading, persistence, and SwiftData operations
    static let data = Logger(subsystem: subsystem, category: "Data")
    
    /// Network requests and API communication
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    /// Audio file caching and storage
    static let cache = Logger(subsystem: subsystem, category: "Cache")
    
    /// Audio downloads and batch operations
    static let download = Logger(subsystem: subsystem, category: "Download")
    
    /// Translation downloads and management
    static let translation = Logger(subsystem: subsystem, category: "Translation")
    
    /// Schema migration operations
    static let migration = Logger(subsystem: subsystem, category: "Migration")
    
    /// Settings and user preferences
    static let settings = Logger(subsystem: subsystem, category: "Settings")
    
    /// UI-related logging (view lifecycle, navigation)
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// General app lifecycle events
    static let general = Logger(subsystem: subsystem, category: "General")
}
