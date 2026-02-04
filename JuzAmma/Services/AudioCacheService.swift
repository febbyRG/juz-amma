//
//  AudioCacheService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 04/02/26.
//

import Foundation

/// Service for caching audio files locally for offline playback
actor AudioCacheService {
    
    // MARK: - Singleton
    
    static let shared = AudioCacheService()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // Create cache directory in app's Caches folder
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("AudioCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public Methods
    
    /// Check if audio file is cached
    /// - Parameters:
    ///   - surahNumber: Surah number (78-114)
    ///   - qariId: Qari/reciter ID
    /// - Returns: Local file URL if cached, nil otherwise
    func getCachedAudioURL(surahNumber: Int, qariId: Int) -> URL? {
        let fileName = generateFileName(surahNumber: surahNumber, qariId: qariId)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }
    
    /// Download and cache audio file
    /// - Parameters:
    ///   - remoteURL: Remote audio URL
    ///   - surahNumber: Surah number
    ///   - qariId: Qari ID
    ///   - progressHandler: Optional progress callback (0.0 - 1.0)
    /// - Returns: Local file URL after caching
    func cacheAudio(
        from remoteURL: URL,
        surahNumber: Int,
        qariId: Int,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> URL {
        let fileName = generateFileName(surahNumber: surahNumber, qariId: qariId)
        let destinationURL = cacheDirectory.appendingPathComponent(fileName)
        
        // If already cached, return existing file
        if fileManager.fileExists(atPath: destinationURL.path) {
            return destinationURL
        }
        
        // Download with progress tracking
        let (tempURL, _) = try await downloadWithProgress(from: remoteURL, progressHandler: progressHandler)
        
        // Move to cache directory
        try? fileManager.removeItem(at: destinationURL) // Remove if exists
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        
        print("[AudioCache] Cached: \(fileName)")
        return destinationURL
    }
    
    /// Cache audio in background (fire and forget)
    /// - Parameters:
    ///   - remoteURL: Remote audio URL
    ///   - surahNumber: Surah number
    ///   - qariId: Qari ID
    func cacheAudioInBackground(from remoteURL: URL, surahNumber: Int, qariId: Int) {
        Task {
            do {
                _ = try await cacheAudio(from: remoteURL, surahNumber: surahNumber, qariId: qariId)
            } catch {
                print("[AudioCache] Background cache failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get total cache size in bytes
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
    
    /// Get formatted cache size string
    func getFormattedCacheSize() -> String {
        let bytes = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Get number of cached files
    func getCachedFileCount() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return 0
        }
        return contents.filter { $0.pathExtension == "mp3" }.count
    }
    
    /// Clear all cached audio files
    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
        print("[AudioCache] Cache cleared")
    }
    
    /// Delete specific cached audio
    func deleteCachedAudio(surahNumber: Int, qariId: Int) throws {
        let fileName = generateFileName(surahNumber: surahNumber, qariId: qariId)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            print("[AudioCache] Deleted: \(fileName)")
        }
    }
    
    /// Check if a surah is cached for a specific qari
    func isCached(surahNumber: Int, qariId: Int) -> Bool {
        let fileName = generateFileName(surahNumber: surahNumber, qariId: qariId)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Get list of cached surahs for a qari
    func getCachedSurahs(for qariId: Int) -> [Int] {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents.compactMap { url -> Int? in
            let fileName = url.deletingPathExtension().lastPathComponent
            let parts = fileName.split(separator: "_")
            
            // Format: surah_XXX_qari_YYY
            guard parts.count >= 4,
                  parts[0] == "surah",
                  parts[2] == "qari",
                  let surahNum = Int(parts[1]),
                  let qari = Int(parts[3]),
                  qari == qariId else {
                return nil
            }
            
            return surahNum
        }.sorted()
    }
    
    // MARK: - Private Methods
    
    private func generateFileName(surahNumber: Int, qariId: Int) -> String {
        return "surah_\(String(format: "%03d", surahNumber))_qari_\(qariId).mp3"
    }
    
    private func downloadWithProgress(
        from url: URL,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (URL, URLResponse) {
        
        // Use URLSession with delegate for progress tracking
        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
        
        let expectedLength = response.expectedContentLength
        var data = Data()
        data.reserveCapacity(expectedLength > 0 ? Int(expectedLength) : 1024 * 1024)
        
        var downloadedBytes: Int64 = 0
        
        for try await byte in asyncBytes {
            data.append(byte)
            downloadedBytes += 1
            
            // Report progress every 64KB
            if downloadedBytes % (64 * 1024) == 0, expectedLength > 0 {
                let progress = Double(downloadedBytes) / Double(expectedLength)
                progressHandler?(progress)
            }
        }
        
        progressHandler?(1.0)
        
        // Write to temp file
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
        try data.write(to: tempURL)
        
        return (tempURL, response)
    }
}

// MARK: - Cache Info Model

struct AudioCacheInfo {
    let totalSize: String
    let fileCount: Int
    let cachedSurahs: [Int]
}
