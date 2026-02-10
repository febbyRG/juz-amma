//
//  QariSettingsView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 27/01/26.
//

import SwiftUI
import SwiftData

/// Settings view for selecting preferred Qari (reciter)
struct QariSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var appSettings: [AppSettings]
    @EnvironmentObject private var audioService: AudioPlayerService
    
    @State private var allQaris: [Qari] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var errorMessage: String?
    
    private var settings: AppSettings? {
        appSettings.first
    }
    
    private var selectedQariId: Int {
        settings?.selectedQariId ?? AppConstants.Audio.defaultQariId
    }
    
    private var popularQaris: [Qari] {
        PopularQari.allCases.map { $0.qari }
    }
    
    private var filteredQaris: [Qari] {
        if searchText.isEmpty {
            return allQaris
        }
        return allQaris.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.style?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        List {
            if isLoading && allQaris.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading reciters...")
                        Spacer()
                    }
                }
            } else {
                // Popular Qaris
                Section("Popular Reciters") {
                    ForEach(popularQaris) { qari in
                        QariSettingsRow(
                            qari: qari,
                            isSelected: qari.id == selectedQariId,
                            onSelect: { selectQari(qari) }
                        )
                    }
                }
                
                // All Qaris
                if !allQaris.isEmpty {
                    Section("All Reciters") {
                        ForEach(filteredQaris) { qari in
                            QariSettingsRow(
                                qari: qari,
                                isSelected: qari.id == selectedQariId,
                                onSelect: { selectQari(qari) }
                            )
                        }
                    }
                }
            }
            
            // Error message
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Select Reciter")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search reciters")
        .task {
            await loadAllQaris()
        }
    }
    
    private func loadAllQaris() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allQaris = try await QariService.fetchAvailableReciters()
        } catch {
            errorMessage = "Failed to load reciters. Using popular reciters only."
            allQaris = []
        }
        
        isLoading = false
    }
    
    private func selectQari(_ qari: Qari) {
        guard let settings = settings else { return }
        settings.selectedQariId = qari.id
        settings.selectedQariName = qari.displayName
        audioService.setQari(qari)
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save reciter selection: \(error.localizedDescription)"
        }
    }
}

// MARK: - Qari Settings Row

struct QariSettingsRow: View {
    let qari: Qari
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(qari.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        if let style = qari.style {
                            Text(style)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.primaryGreen.opacity(0.1))
                                .foregroundStyle(AppColors.primaryGreen)
                                .clipShape(Capsule())
                        }
                        
                        if let arabicName = qari.arabicName {
                            Text(arabicName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primaryGreen)
                        .font(.title2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QariSettingsView()
    }
    .environmentObject(AudioPlayerService())
    .modelContainer(for: [AppSettings.self], inMemory: true)
}
