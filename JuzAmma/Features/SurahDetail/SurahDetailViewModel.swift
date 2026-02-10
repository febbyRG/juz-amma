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
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    
    /// Returns error message if operation fails, nil on success
    func toggleBookmark(for surah: Surah) -> String? {
        do {
            let service = QuranDataService(modelContext: modelContext)
            try service.toggleBookmark(for: surah)
            return nil
        } catch {
            return "Failed to toggle bookmark: \(error.localizedDescription)"
        }
    }
    
    func toggleMemorization(for surah: Surah) -> String? {
        do {
            let service = QuranDataService(modelContext: modelContext)
            try service.toggleMemorization(for: surah)
            return nil
        } catch {
            return "Failed to toggle memorization: \(error.localizedDescription)"
        }
    }
    
    func toggleNextToMemorize(for surah: Surah) -> String? {
        do {
            if surah.isNextToMemorize {
                surah.isNextToMemorize = false
                try modelContext.save()
            } else {
                let service = QuranDataService(modelContext: modelContext)
                try service.setNextToMemorize(surah)
            }
            return nil
        } catch {
            return "Failed to update memorization target: \(error.localizedDescription)"
        }
    }
    
    func updateLastAccessed(for surah: Surah) {
        surah.lastAccessedDate = Date()
        do {
            try modelContext.save()
        } catch {
            print("[ViewModel] Failed to save last accessed date: \(error.localizedDescription)")
        }
    }
    
    func updateShowBothTranslations(_ newValue: Bool, settings: AppSettings?) {
        if let settings = settings {
            settings.showBothTranslations = newValue
            do {
                try modelContext.save()
            } catch {
                print("[ViewModel] Failed to save translation display setting: \(error.localizedDescription)")
            }
        }
    }
    
    func loadAvailableTranslations(settings: AppSettings? = nil) -> (translations: [DownloadedTranslation], error: String?) {
        do {
            let descriptor = FetchDescriptor<Translation>()
            let allTranslations = try modelContext.fetch(descriptor)
            
            let grouped = Dictionary(grouping: allTranslations, by: { $0.id })
            let available = grouped.compactMap { id, translations -> DownloadedTranslation? in
                guard let first = translations.first else { return nil }
                return DownloadedTranslation(
                    id: id,
                    name: first.name,
                    languageCode: first.languageCode
                )
            }.sorted { $0.name < $1.name }
            
            // Auto-select translation if current settings don't match any downloaded translation
            if let settings = settings, !available.isEmpty {
                let primaryExists = available.contains { $0.id == settings.primaryTranslationId }
                if !primaryExists, let first = available.first {
                    settings.primaryTranslationId = first.id
                    settings.primaryTranslationLanguage = first.languageCode
                    do {
                        try modelContext.save()
                    } catch {
                        print("[ViewModel] Failed to auto-select translation: \(error.localizedDescription)")
                    }
                }
            }
            
            return (available, nil)
        } catch {
            return ([], "Failed to load translations: \(error.localizedDescription)")
        }
    }
}
