//
//  TranslationManagerView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 17/11/25.
//

import SwiftUI
import SwiftData

struct TranslationManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var translations: [TranslationInfo] = []
    @State private var downloadedIds: [Int] = []
    @State private var isLoading = false
    @State private var downloadingProgress: [Int: Double] = [:]  // Track multiple downloads
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var translationToDelete: (id: Int, name: String)?
    @State private var showDeleteConfirmation = false
    
    private var service: TranslationService {
        TranslationService(modelContext: modelContext)
    }
    
    private var filteredTranslations: [TranslationInfo] {
        if searchText.isEmpty {
            return translations
        }
        return translations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.languageName.localizedCaseInsensitiveContains(searchText) ||
            $0.authorName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var groupedTranslations: [(String, [TranslationInfo])] {
        let grouped = Dictionary(grouping: filteredTranslations) { $0.languageName }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && translations.isEmpty {
                    ProgressView("Loading translations...")
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await loadTranslations()
                            }
                        }
                    }
                } else {
                    translationsList
                }
            }
            .navigationTitle("Translations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search translations")
            .task {
                await loadTranslations()
            }
            .alert("Delete Translation", isPresented: $showDeleteConfirmation, presenting: translationToDelete) { toDelete in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTranslation(id: toDelete.id)
                }
            } message: { toDelete in
                Text("Are you sure you want to delete '\(toDelete.name)'? This will remove all downloaded verses for this translation.")
            }
        }
    }
    
    private var translationsList: some View {
        List {
            // Popular translations section
            Section {
                ForEach(PopularTranslation.allCases) { popular in
                    let info = popular.info
                    TranslationRow(
                        name: info.name,
                        language: info.language,
                        languageCode: info.code,
                        isDownloaded: downloadedIds.contains(info.id),
                        isDownloading: downloadingProgress[info.id] != nil,
                        downloadProgress: downloadingProgress[info.id] ?? 0
                    ) {
                        await downloadTranslation(id: info.id, languageCode: info.code, name: info.name)
                    } onDelete: {
                        confirmDelete(id: info.id, name: info.name)
                    }
                }
            } header: {
                Text("Popular Translations")
            } footer: {
                Text("Most commonly used translations worldwide")
            }
            
            // All translations grouped by language
            if !filteredTranslations.isEmpty {
                ForEach(groupedTranslations, id: \.0) { language, translationsInLanguage in
                    Section(header: Text(language)) {
                        ForEach(translationsInLanguage) { translation in
                            TranslationRow(
                                name: translation.name,
                                language: translation.languageName,
                                languageCode: translation.languageCode,
                                author: translation.authorName,
                                isDownloaded: downloadedIds.contains(translation.id),
                                isDownloading: downloadingProgress[translation.id] != nil,
                                downloadProgress: downloadingProgress[translation.id] ?? 0
                            ) {
                                await downloadTranslation(
                                    id: translation.id,
                                    languageCode: translation.languageCode,
                                    name: translation.name
                                )
                            } onDelete: {
                                confirmDelete(id: translation.id, name: translation.name)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadTranslations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load downloaded IDs
            downloadedIds = try service.getDownloadedTranslationIds()
            
            // Try to fetch from API
            do {
                translations = try await service.fetchAvailableTranslations()
            } catch {
                // Fall back to popular translations if API fails
                translations = service.getPopularTranslations()
            }
        } catch {
            errorMessage = "Failed to load translations"
        }
        
        isLoading = false
    }
    
    private func downloadTranslation(id: Int, languageCode: String, name: String) async {
        // Set initial progress
        downloadingProgress[id] = 0
        
        do {
            try await service.downloadTranslation(
                translationId: id,
                languageCode: languageCode,
                name: name
            ) { progress in
                downloadingProgress[id] = progress
            }
            
            downloadedIds = try service.getDownloadedTranslationIds()
        } catch {
            errorMessage = "Failed to download translation: \(error.localizedDescription)"
        }
        
        // Remove from downloading list
        downloadingProgress.removeValue(forKey: id)
    }
    
    private func confirmDelete(id: Int, name: String) {
        translationToDelete = (id: id, name: name)
        showDeleteConfirmation = true
    }
    
    private func deleteTranslation(id: Int) {
        do {
            try service.deleteTranslation(translationId: id)
            downloadedIds = try service.getDownloadedTranslationIds()
        } catch {
            errorMessage = "Failed to delete translation"
        }
    }
}

// MARK: - Translation Row Component

struct TranslationRow: View {
    let name: String
    let language: String
    let languageCode: String
    var author: String = ""
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () async -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(language)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !author.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if isDownloading {
                    ProgressView(value: downloadProgress, total: 1.0)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            if isDownloading {
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isDownloaded {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    Task {
                        await onDownload()
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)
            }
        }
        .opacity(isDownloading ? 0.6 : 1.0)
    }
}

#Preview {
    TranslationManagerView()
        .modelContainer(for: [Translation.self, Ayah.self], inMemory: true)
}
