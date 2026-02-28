//
//  AudioCacheServiceProtocol.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 01/03/26.
//

import Foundation

/// Abstraction for audio caching operations, enabling dependency injection and testability.
protocol AudioCacheServiceProtocol: Sendable {
    /// Check if audio file is cached and return local URL
    func getCachedAudioURL(surahNumber: Int, qariId: Int) async -> URL?

    /// Download and cache audio file with optional progress reporting
    func cacheAudio(from remoteURL: URL, surahNumber: Int, qariId: Int, progressHandler: ((Double) -> Void)?) async throws -> URL

    /// Cache audio in background (fire and forget)
    func cacheAudioInBackground(from remoteURL: URL, surahNumber: Int, qariId: Int) async

    /// Check if a surah is cached for a specific qari
    func isCached(surahNumber: Int, qariId: Int) async -> Bool

    /// Get list of cached surahs for a qari
    func getCachedSurahs(for qariId: Int) async -> [Int]

    /// Delete specific cached audio
    func deleteCachedAudio(surahNumber: Int, qariId: Int) async throws

    /// Clear all cached audio files
    func clearCache() async throws

    /// Get formatted cache size string
    func getFormattedCacheSize() async -> String

    /// Get number of cached files
    func getCachedFileCount() async -> Int

    /// Get total cache size in bytes
    func getCacheSize() async -> Int64
}
