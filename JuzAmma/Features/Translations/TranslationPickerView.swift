//
//  TranslationPickerView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 17/11/25.
//

import SwiftUI
import SwiftData

struct TranslationPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var appSettings: [AppSettings]
    
    let availableTranslations: [DownloadedTranslation]
    let onManageTranslations: () -> Void
    
    private var settings: AppSettings? {
        appSettings.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                if availableTranslations.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No Translations", systemImage: "globe.badge.chevron.backward")
                        } description: {
                            Text("Download translations to read in your preferred language")
                        } actions: {
                            Button("Download Translations") {
                                onManageTranslations()
                            }
                        }
                    }
                } else {
                    Section {
                        ForEach(availableTranslations, id: \.id) { translation in
                            Button {
                                selectPrimaryTranslation(translation)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(translation.name)
                                            .font(.headline)
                                        
                                        Text(translation.languageCode.uppercased())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if settings?.primaryTranslationId == translation.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Primary Translation")
                    }
                    
                    if let settings = settings, settings.showBothTranslations {
                        Section {
                            Button {
                                clearSecondaryTranslation()
                            } label: {
                                HStack {
                                    Text("None")
                                    
                                    Spacer()
                                    
                                    if settings.secondaryTranslationId == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            ForEach(availableTranslations.filter { $0.id != settings.primaryTranslationId }, id: \.id) { translation in
                                Button {
                                    selectSecondaryTranslation(translation)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(translation.name)
                                                .font(.headline)
                                            
                                            Text(translation.languageCode.uppercased())
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if settings.secondaryTranslationId == translation.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("Secondary Translation")
                        } footer: {
                            Text("Show an additional translation below the primary one")
                        }
                    }
                    
                    Section {
                        Button {
                            onManageTranslations()
                        } label: {
                            Label("Manage Translations", systemImage: "arrow.down.circle")
                        }
                    }
                }
            }
            .navigationTitle("Select Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectPrimaryTranslation(_ translation: DownloadedTranslation) {
        guard let settings = settings else {
            return
        }
        
        settings.primaryTranslationId = translation.id
        settings.primaryTranslationLanguage = translation.languageCode
        
        // If secondary is same as primary, clear it
        if settings.secondaryTranslationId == translation.id {
            settings.secondaryTranslationId = nil
            settings.secondaryTranslationLanguage = nil
        }
        
        do {
            try modelContext.save()
        } catch {
            // Handle save error silently - UI will still reflect the change
        }
    }
    
    private func selectSecondaryTranslation(_ translation: DownloadedTranslation) {
        guard let settings = settings else { return }
        
        settings.secondaryTranslationId = translation.id
        settings.secondaryTranslationLanguage = translation.languageCode
        
        do {
            try modelContext.save()
        } catch {
            print("[TranslationPicker] Failed to save secondary translation: \(error.localizedDescription)")
        }
    }
    
    private func clearSecondaryTranslation() {
        guard let settings = settings else { return }
        
        settings.secondaryTranslationId = nil
        settings.secondaryTranslationLanguage = nil
        
        do {
            try modelContext.save()
        } catch {
            print("[TranslationPicker] Failed to clear secondary translation: \(error.localizedDescription)")
        }
    }
}
