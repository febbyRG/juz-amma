//
//  MockAudioCacheService.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 01/03/26.
//

import Foundation
@testable import Juz_Amma

/// Mock implementation of `AudioCacheServiceProtocol` for unit testing.
final class MockAudioCacheService: AudioCacheServiceProtocol, @unchecked Sendable {

    // MARK: - State

    var cachedSurahs: Set<Int> = []
    var cacheSize: String = "0 MB"
    var fileCount: Int = 0
    var shouldThrowOnClear = false

    // MARK: - AudioCacheServiceProtocol

    func getCachedAudioURL(surahNumber: Int, qariId: Int) async -> URL? {
        cachedSurahs.contains(surahNumber)
            ? URL(string: "file:///mock/surah_\(surahNumber)_qari_\(qariId).mp3")
            : nil
    }

    func cacheAudio(
        from remoteURL: URL,
        surahNumber: Int,
        qariId: Int,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        cachedSurahs.insert(surahNumber)
        progressHandler?(1.0)
        return URL(string: "file:///mock/surah_\(surahNumber)_qari_\(qariId).mp3")!
    }

    func cacheAudioInBackground(from remoteURL: URL, surahNumber: Int, qariId: Int) async {
        cachedSurahs.insert(surahNumber)
    }

    func isCached(surahNumber: Int, qariId: Int) async -> Bool {
        cachedSurahs.contains(surahNumber)
    }

    func getCachedSurahs(for qariId: Int) async -> [Int] {
        Array(cachedSurahs).sorted()
    }

    func deleteCachedAudio(surahNumber: Int, qariId: Int) async throws {
        cachedSurahs.remove(surahNumber)
    }

    func clearCache() async throws {
        if shouldThrowOnClear {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock clear failed"])
        }
        cachedSurahs.removeAll()
    }

    func getFormattedCacheSize() async -> String { cacheSize }
    func getCachedFileCount() async -> Int { fileCount }
    func getCacheSize() async -> Int64 { Int64(fileCount * 1024 * 1024) }

    // MARK: - Helpers

    func reset() {
        cachedSurahs.removeAll()
        cacheSize = "0 MB"
        fileCount = 0
        shouldThrowOnClear = false
    }
}
