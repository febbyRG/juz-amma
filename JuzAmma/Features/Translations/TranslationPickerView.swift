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
    
    let availableTranslations: [(id: Int, name: String, code: String)]
    let onManageTranslations: () -> Void
    
    private var settings: AppSettings? {
        if let existing = appSettings.first {
            return existing
        }
        // Create settings if it doesn't exist
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
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
                                        
                                        Text(translation.code.uppercased())
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
                                            
                                            Text(translation.code.uppercased())
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
    
    private func selectPrimaryTranslation(_ translation: (id: Int, name: String, code: String)) {
        print("🔍 Selecting primary translation: \(translation.name) (ID: \(translation.id))")
        guard let settings = settings else {
            print("❌ Settings is nil!")
            return
        }
        
        settings.primaryTranslationId = translation.id
        settings.primaryTranslationLanguage = translation.code
        
        // If secondary is same as primary, clear it
        if settings.secondaryTranslationId == translation.id {
            settings.secondaryTranslationId = nil
            settings.secondaryTranslationLanguage = nil
        }
        
        do {
            try modelContext.save()
            print("✅ Primary translation saved: \(translation.name)")
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
    
    private func selectSecondaryTranslation(_ translation: (id: Int, name: String, code: String)) {
        guard let settings = settings else { return }
        
        settings.secondaryTranslationId = translation.id
        settings.secondaryTranslationLanguage = translation.code
        
        try? modelContext.save()
    }
    
    private func clearSecondaryTranslation() {
        guard let settings = settings else { return }
        
        settings.secondaryTranslationId = nil
        settings.secondaryTranslationLanguage = nil
        
        try? modelContext.save()
    }
}
