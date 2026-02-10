
//  AudioDownloadsView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 10/02/26.
//

import SwiftUI
import SwiftData

/// View for managing offline audio downloads per surah
struct AudioDownloadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Surah.number) private var surahs: [Surah]
    @Query private var settingsQuery: [AppSettings]
    @ObservedObject var downloadManager: AudioDownloadManager
    @EnvironmentObject private var audioService: AudioPlayerService
    
    @State private var showDeleteAllAlert = false
    @State private var surahToDelete: Surah?
    
    private var settings: AppSettings? {
        settingsQuery.first
    }
    
    private var qariId: Int {
        audioService.selectedQari.id
    }
    
    private var qariName: String {
        audioService.selectedQari.displayName
    }
    
    private var cachedCount: Int {
        downloadManager.cachedSurahs.count
    }
    
    private var totalSurahs: Int {
        AppConstants.juzAmmaSurahRange.count
    }
    
    var body: some View {
        List {
            // Status Section
            Section {
                // Qari info
                HStack {
                    Label("Reciter", systemImage: "person.wave.2")
                    Spacer()
                    Text(qariName)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Download progress
                HStack {
                    Label("Downloaded", systemImage: "arrow.down.circle.fill")
                    Spacer()
                    Text("\(cachedCount)/\(totalSurahs) surahs")
                        .foregroundStyle(.secondary)
                }
                
                // WiFi-only toggle
                Toggle(isOn: Binding(
                    get: { settings?.wifiOnlyDownload ?? false },
                    set: { newValue in
                        settings?.wifiOnlyDownload = newValue
                        do {
                            try modelContext.save()
                        } catch {
                            print("[AudioDownloads] Failed to save WiFi setting: \(error.localizedDescription)")
                        }
                    }
                )) {
                    Label("WiFi Only", systemImage: "wifi")
                }
            } header: {
                Label("Offline Audio", systemImage: "icloud.and.arrow.down")
            }
            
            // Batch Actions
            Section {
                if downloadManager.isBatchDownloading {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Downloading...")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(downloadManager.batchProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: downloadManager.batchProgress)
                            .tint(AppColors.primaryGreen)
                    }
                    
                    Button("Cancel Download", role: .destructive) {
                        downloadManager.cancelBatchDownload()
                    }
                } else {
                    Button {
                        Task {
                            await downloadManager.downloadAll(
                                qariId: qariId,
                                wifiOnly: settings?.wifiOnlyDownload ?? false
                            )
                        }
                    } label: {
                        Label(
                            cachedCount == totalSurahs ? "All Downloaded" : "Download All Surahs",
                            systemImage: "arrow.down.circle"
                        )
                    }
                    .disabled(cachedCount == totalSurahs)
                }
                
                if cachedCount > 0 {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("Delete All Downloads", systemImage: "trash")
                    }
                }
            } header: {
                Text("Batch Actions")
            } footer: {
                if cachedCount == totalSurahs {
                    Text("All surahs are available offline! ✅")
                } else {
                    Text("Download surahs to listen offline without internet.")
                }
            }
            
            // Per-surah list
            Section {
                ForEach(surahs) { surah in
                    SurahDownloadRow(
                        surah: surah,
                        isCached: downloadManager.isCached(surahNumber: surah.number),
                        isDownloading: downloadManager.isDownloading(surahNumber: surah.number),
                        progress: downloadManager.downloadProgress[surah.number] ?? 0,
                        onDownload: {
                            Task {
                                await downloadManager.downloadSurah(surah.number, qariId: qariId)
                            }
                        },
                        onDelete: {
                            surahToDelete = surah
                        }
                    )
                }
            } header: {
                Text("Surahs")
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await downloadManager.refreshCachedSurahs(qariId: qariId)
        }
        .alert("Delete All Downloads?", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task {
                    for surahNumber in AppConstants.juzAmmaSurahRange {
                        await downloadManager.deleteCached(surahNumber: surahNumber, qariId: qariId)
                    }
                }
            }
        } message: {
            Text("This will remove all downloaded audio for \(qariName). You can re-download them later.")
        }
        .alert("Download Error", isPresented: Binding(
            get: { downloadManager.errorMessage != nil },
            set: { if !$0 { downloadManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(downloadManager.errorMessage ?? "")
        }
        .alert("Delete Download?", isPresented: Binding(
            get: { surahToDelete != nil },
            set: { if !$0 { surahToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                surahToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let surah = surahToDelete {
                    Task {
                        await downloadManager.deleteCached(surahNumber: surah.number, qariId: qariId)
                    }
                    surahToDelete = nil
                }
            }
        } message: {
            if let surah = surahToDelete {
                Text("Remove downloaded audio for \(surah.nameTransliteration)?")
            }
        }
    }
}

// MARK: - Surah Download Row

struct SurahDownloadRow: View {
    let surah: Surah
    let isCached: Bool
    let isDownloading: Bool
    let progress: Double
    let onDownload: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Surah number
            Text("\(surah.number)")
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            // Surah name
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliteration)
                    .font(.subheadline.weight(.medium))
                
                if isDownloading {
                    ProgressView(value: progress)
                        .tint(AppColors.primaryGreen)
                }
            }
            
            Spacer()
            
            // Status / Action
            if isDownloading {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isCached {
                HStack(spacing: 8) {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.body)
                }
            } else {
                Button {
                    onDownload()
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.blue)
                        .font(.body)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 2)
    }
}
