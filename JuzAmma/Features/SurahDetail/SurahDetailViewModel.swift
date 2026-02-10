//
//  SurahDetailViewModel.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 10/02/26.
//

import SwiftUI
import SwiftData

/// Handles business logic for SurahDetailView
@MainActor
struct SurahDetailViewModel {
    
    // MARK: - Output
    
    var availableTranslations: [DownloadedTranslation] = []
    var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    
    mutating func toggleBookmark(for surah: Surah) {
        do {
            let service = QuranDataService(modelContext: modelContext)
            try service.toggleBookmark(for: surah)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to toggle bookmark: \(error.localizedDescription)"
        }
    }
    
    mutating func toggleMemorization(for surah: Surah) {
        do {
            let service = QuranDataService(modelContext: modelContext)
            try service.toggleMemorization(for: surah)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to toggle memorization: \(error.localizedDescription)"
        }
    }
    
    mutating func toggleNextToMemorize(for surah: Surah) {
        do {
            if surah.isNextToMemorize {
                surah.isNextToMemorize = false
                try modelContext.save()
            } else {
                let service = QuranDataService(modelContext: modelContext)
                try service.setNextToMemorize(surah)
            }
            errorMessage = nil
        } catch {
            errorMessage = "Failed to update memorization target: \(error.localizedDescription)"
        }
    }
    
    func updateLastAccessed(for surah: Surah) {
        surah.lastAccessedDate = Date()
        try? modelContext.save()
    }
    
    func updateShowBothTranslations(_ newValue: Bool, settings: AppSettings?) {
        if let settings = settings {
            settings.showBothTranslations = newValue
            try? modelContext.save()
        }
    }
    
    mutating func loadAvailableTranslations(settings: AppSettings? = nil) {
        do {
            let descriptor = FetchDescriptor<Translation>()
            let allTranslations = try modelContext.fetch(descriptor)
            
            let grouped = Dictionary(grouping: allTranslations, by: { $0.id })
            availableTranslations = grouped.compactMap { id, translations in
                guard let first = translations.first else { return nil }
                return DownloadedTranslation(
                    id: id,
                    name: first.name,
                    languageCode: first.languageCode
                )
            }.sorted { $0.name < $1.name }
            
            // Auto-select translation if current settings don't match any downloaded translation
            if let settings = settings, !availableTranslations.isEmpty {
                let primaryExists = availableTranslations.contains { $0.id == settings.primaryTranslationId }
                if !primaryExists {
                    // Current primary translation not downloaded — auto-select first available
                    let first = availableTranslations[0]
                    settings.primaryTranslationId = first.id
                    settings.primaryTranslationLanguage = first.languageCode
                    try? modelContext.save()
                }
            }
            
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load translations: \(error.localizedDescription)"
        }
    }
}
