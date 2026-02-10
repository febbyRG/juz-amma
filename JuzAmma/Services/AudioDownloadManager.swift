//
//  AudioDownloadManager.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 10/02/26.
//

import Foundation
import Combine
import Network

/// Observable manager for user-initiated audio downloads with progress tracking
@MainActor
final class AudioDownloadManager: ObservableObject {
    
    static let shared = AudioDownloadManager()
    
    // MARK: - Published State
    
    /// Per-surah download progress (surahNumber -> progress 0.0-1.0)
    @Published private(set) var downloadProgress: [Int: Double] = [:]
    
    /// Set of currently cached surah numbers for the active qari
    @Published private(set) var cachedSurahs: Set<Int> = []
    
    /// Whether a batch download is in progress
    @Published private(set) var isBatchDownloading = false
    
    /// Overall batch download progress
    @Published private(set) var batchProgress: Double = 0
    
    /// Error message for failed downloads
    @Published var errorMessage: String?
    
    // MARK: - Private
    
    private var currentQariId: Int = AppConstants.Audio.defaultQariId
    private var batchTask: Task<Void, Never>?
    private let monitor = NWPathMonitor()
    private var isOnWiFi = true
    
    private init() {
        startNetworkMonitor()
    }
    
    // MARK: - Network Monitor
    
    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnWiFi = path.usesInterfaceType(.wifi)
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
    
    // MARK: - Public Methods
    
    /// Refresh cached surahs list for a given qari, cancels in-flight downloads if qari changed
    func refreshCachedSurahs(qariId: Int) async {
        if currentQariId != qariId && isBatchDownloading {
            cancelBatchDownload()
        }
        currentQariId = qariId
        let cached = await AudioCacheService.shared.getCachedSurahs(for: qariId)
        cachedSurahs = Set(cached)
    }
    
    /// Check if a surah is currently cached
    func isCached(surahNumber: Int) -> Bool {
        cachedSurahs.contains(surahNumber)
    }
    
    /// Check if a surah is currently downloading
    func isDownloading(surahNumber: Int) -> Bool {
        downloadProgress[surahNumber] != nil
    }
    
    private static let maxRetries = AppConstants.Audio.maxDownloadRetries
    
    /// Download a single surah for offline playback with retry
    func downloadSurah(_ surahNumber: Int, qariId: Int) async {
        guard downloadProgress[surahNumber] == nil else { return }
        
        downloadProgress[surahNumber] = 0
        currentQariId = qariId
        
        var lastError: Error?
        for attempt in 1...Self.maxRetries {
            do {
                let audioUrl = try await fetchAudioURL(surahNumber: surahNumber, qariId: qariId)
                
                _ = try await AudioCacheService.shared.cacheAudio(
                    from: audioUrl,
                    surahNumber: surahNumber,
                    qariId: qariId
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.downloadProgress[surahNumber] = progress
                    }
                }
                
                downloadProgress.removeValue(forKey: surahNumber)
                cachedSurahs.insert(surahNumber)
                return // Success
            } catch {
                lastError = error
                if attempt < Self.maxRetries {
                    // Exponential backoff: 1s, 2s
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
        
        downloadProgress.removeValue(forKey: surahNumber)
        errorMessage = "Failed to download Surah \(surahNumber): \(lastError?.localizedDescription ?? "Unknown error")"
    }
    
    /// Download all surahs in Juz Amma for a qari with per-surah retry
    func downloadAll(qariId: Int, wifiOnly: Bool = false) async {
        if wifiOnly && !isOnWiFi {
            errorMessage = "WiFi-only mode is enabled. Connect to WiFi to download."
            return
        }
        
        batchTask?.cancel()
        isBatchDownloading = true
        batchProgress = 0
        currentQariId = qariId
        
        let allSurahs = Array(AppConstants.juzAmmaSurahRange)
        let uncached = allSurahs.filter { !cachedSurahs.contains($0) }
        
        guard !uncached.isEmpty else {
            isBatchDownloading = false
            batchProgress = 1.0
            return
        }
        
        let task = Task {
            var completed = 0
            var failed: [Int] = []
            
            for surahNumber in uncached {
                guard !Task.isCancelled else { break }
                
                // Check WiFi mid-batch
                if wifiOnly && !isOnWiFi {
                    errorMessage = "Download paused — WiFi disconnected. \(completed)/\(uncached.count) surahs downloaded."
                    break
                }
                
                let beforeCount = cachedSurahs.count
                await downloadSurah(surahNumber, qariId: qariId)
                if cachedSurahs.count == beforeCount {
                    failed.append(surahNumber)
                }
                
                completed += 1
                batchProgress = Double(completed) / Double(uncached.count)
            }
            
            if !failed.isEmpty && !Task.isCancelled {
                errorMessage = "\(failed.count) surah(s) failed to download. Please try again."
            }
            
            isBatchDownloading = false
        }
        batchTask = task
        await task.value
    }
    
    /// Cancel batch download
    func cancelBatchDownload() {
        batchTask?.cancel()
        batchTask = nil
        isBatchDownloading = false
        downloadProgress.removeAll()
    }
    
    /// Delete cached audio for a single surah
    func deleteCached(surahNumber: Int, qariId: Int) async {
        do {
            try await AudioCacheService.shared.deleteCachedAudio(surahNumber: surahNumber, qariId: qariId)
            cachedSurahs.remove(surahNumber)
        } catch {
            errorMessage = "Failed to delete cached audio: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private
    
    /// Fetch audio URL from API for a given surah and qari
    private func fetchAudioURL(surahNumber: Int, qariId: Int) async throws -> URL {
        let urlString = "\(AppConstants.API.baseURL)\(AppConstants.API.chapterRecitationsEndpoint)/\(qariId)/\(surahNumber)"
        
        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ChapterAudioResponse.self, from: data)
        
        guard let audioUrl = URL(string: response.audioFile.audioUrl) else {
            throw AudioError.invalidURL
        }
        
        return audioUrl
    }
}
