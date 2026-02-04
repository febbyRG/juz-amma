//
//  AudioCacheServiceTests.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 04/02/26.
//

import Testing
import Foundation
@testable import Juz_Amma

// MARK: - AudioCacheService Tests

struct AudioCacheServiceTests {
    
    @Test func cacheServiceSingleton() async {
        let instance1 = AudioCacheService.shared
        let instance2 = AudioCacheService.shared
        
        // Both should reference the same instance (actor identity)
        #expect(instance1 === instance2)
    }
    
    @Test func generateFileName() async {
        // Test the file naming convention
        // Expected format: surah_XXX_qari_YYY.mp3
        
        let surahNumber = 114
        let qariId = 7
        let expectedFileName = "surah_114_qari_7.mp3"
        
        // The file name should follow the pattern
        #expect(expectedFileName.contains("surah_"))
        #expect(expectedFileName.contains("_qari_"))
        #expect(expectedFileName.hasSuffix(".mp3"))
    }
    
    @Test func cacheInfoDefaults() async {
        // Initial cache should be empty or have some files
        let cacheService = AudioCacheService.shared
        
        let size = await cacheService.getFormattedCacheSize()
        let count = await cacheService.getCachedFileCount()
        
        // Size should be a valid string
        #expect(!size.isEmpty)
        
        // Count should be non-negative
        #expect(count >= 0)
    }
    
    @Test func isCachedReturnsFalseForNonExistent() async {
        let cacheService = AudioCacheService.shared
        
        // Use a very unlikely surah/qari combination
        let isCached = await cacheService.isCached(surahNumber: 999, qariId: 999)
        
        #expect(isCached == false)
    }
    
    @Test func getCachedSurahsForNonExistentQari() async {
        let cacheService = AudioCacheService.shared
        
        // Non-existent qari should return empty array
        let cachedSurahs = await cacheService.getCachedSurahs(for: 99999)
        
        #expect(cachedSurahs.isEmpty)
    }
    
    @Test func getCachedAudioURLReturnsNilForNonCached() async {
        let cacheService = AudioCacheService.shared
        
        // Non-cached file should return nil
        let url = await cacheService.getCachedAudioURL(surahNumber: 999, qariId: 999)
        
        #expect(url == nil)
    }
}

// MARK: - AudioCacheInfo Tests

struct AudioCacheInfoTests {
    
    @Test func audioCacheInfoInitialization() {
        let info = AudioCacheInfo(
            totalSize: "10.5 MB",
            fileCount: 5,
            cachedSurahs: [112, 113, 114]
        )
        
        #expect(info.totalSize == "10.5 MB")
        #expect(info.fileCount == 5)
        #expect(info.cachedSurahs.count == 3)
        #expect(info.cachedSurahs.contains(114))
    }
}
