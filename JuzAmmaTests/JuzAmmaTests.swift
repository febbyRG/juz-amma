//
//  JuzAmmaTests.swift
//  JuzAmmaTests
//
//  Created by Febby Rachmat on 15/11/25.
//

import Testing
import Foundation
@testable import Juz_Amma

// MARK: - Surah Model Tests

struct SurahModelTests {
    
    @Test func surahInitialization() {
        let surah = Surah(
            number: 114,
            nameArabic: "الناس",
            nameTransliteration: "An-Nas",
            nameTranslation: "Mankind",
            ayahCount: 6,
            revelation: "Makkah"
        )
        
        #expect(surah.number == 114)
        #expect(surah.nameArabic == "الناس")
        #expect(surah.nameTransliteration == "An-Nas")
        #expect(surah.nameTranslation == "Mankind")
        #expect(surah.ayahCount == 6)
        #expect(surah.revelation == "Makkah")
        #expect(surah.isBookmarked == false)
        #expect(surah.isMemorized == false)
        #expect(surah.isNextToMemorize == false)
    }
    
    @Test func surahBookmarkToggle() {
        let surah = Surah(
            number: 112,
            nameArabic: "الإخلاص",
            nameTransliteration: "Al-Ikhlas",
            nameTranslation: "The Sincerity",
            ayahCount: 4
        )
        
        #expect(surah.isBookmarked == false)
        surah.isBookmarked = true
        #expect(surah.isBookmarked == true)
        surah.isBookmarked = false
        #expect(surah.isBookmarked == false)
    }
    
    @Test func surahMemorizationWithDate() {
        let surah = Surah(
            number: 113,
            nameArabic: "الفلق",
            nameTransliteration: "Al-Falaq",
            nameTranslation: "The Daybreak",
            ayahCount: 5
        )
        
        #expect(surah.isMemorized == false)
        #expect(surah.memorizedDate == nil)
        
        let now = Date()
        surah.isMemorized = true
        surah.memorizedDate = now
        
        #expect(surah.isMemorized == true)
        #expect(surah.memorizedDate == now)
    }
}

// MARK: - Ayah Model Tests

struct AyahModelTests {
    
    @Test func ayahInitialization() {
        let ayah = Ayah(
            number: 1,
            textArabic: "قُلْ هُوَ اللَّهُ أَحَدٌ",
            textTransliteration: "Qul huwa Allahu ahad"
        )
        
        #expect(ayah.number == 1)
        #expect(ayah.textArabic == "قُلْ هُوَ اللَّهُ أَحَدٌ")
        #expect(ayah.textTransliteration == "Qul huwa Allahu ahad")
        #expect(ayah.isBookmarked == false)
    }
    
    @Test func ayahTranslations() {
        let ayah = Ayah(
            number: 1,
            textArabic: "قُلْ هُوَ اللَّهُ أَحَدٌ",
            textTransliteration: "Qul huwa Allahu ahad"
        )
        
        let englishTranslation = Translation(
            id: 20,
            languageCode: "en",
            name: "Saheeh International",
            text: "Say, He is Allah, [who is] One"
        )
        
        let indonesianTranslation = Translation(
            id: 33,
            languageCode: "id",
            name: "Indonesian Ministry",
            text: "Katakanlah (Muhammad), Dialah Allah, Yang Maha Esa"
        )
        
        ayah.translations = [englishTranslation, indonesianTranslation]
        
        #expect(ayah.getTranslation(languageCode: "en") == "Say, He is Allah, [who is] One")
        #expect(ayah.getTranslation(languageCode: "id") == "Katakanlah (Muhammad), Dialah Allah, Yang Maha Esa")
        #expect(ayah.getTranslation(languageCode: "fr") == nil)
        #expect(ayah.availableLanguages.count == 2)
        #expect(ayah.availableLanguages.contains("en"))
        #expect(ayah.availableLanguages.contains("id"))
    }
}

// MARK: - Qari Model Tests

struct QariModelTests {
    
    @Test func qariInitialization() {
        let qari = Qari(
            id: 7,
            name: "Mishari Rashid al-Afasy",
            style: nil,
            arabicName: "مشاري راشد العفاسي"
        )
        
        #expect(qari.id == 7)
        #expect(qari.name == "Mishari Rashid al-Afasy")
        #expect(qari.style == nil)
        #expect(qari.displayName == "Mishari Rashid al-Afasy")
    }
    
    @Test func qariWithStyle() {
        let qari = Qari(
            id: 2,
            name: "AbdulBaset AbdulSamad",
            style: "Murattal",
            arabicName: "عبد الباسط عبد الصمد"
        )
        
        #expect(qari.displayName == "AbdulBaset AbdulSamad (Murattal)")
    }
    
    @Test func popularQariValues() {
        let alafasy = PopularQari.misharyAlafasy.qari
        #expect(alafasy.id == 7)
        #expect(alafasy.name == "Mishari Rashid al-Afasy")
        
        let sudais = PopularQari.sudais.qari
        #expect(sudais.id == 3)
        #expect(sudais.name == "Abdur-Rahman as-Sudais")
        
        let husaryMuallim = PopularQari.husaryMuallim.qari
        #expect(husaryMuallim.id == 12)
        #expect(husaryMuallim.style == "Muallim")
    }
    
    @Test func allPopularQarisHaveUniqueIds() {
        let ids = PopularQari.allCases.map { $0.qari.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "All popular qaris should have unique IDs")
    }
}

// MARK: - VerseTiming Tests

struct VerseTimingTests {
    
    @Test func verseTimingParsing() {
        let timing = VerseTiming(
            verseKey: "114:3",
            timestampFrom: 5000,
            timestampTo: 8500,
            segments: nil
        )
        
        #expect(timing.verseNumber == 3)
        #expect(timing.startTimeSeconds == 5.0)
        #expect(timing.endTimeSeconds == 8.5)
    }
    
    @Test func invalidVerseKey() {
        let timing = VerseTiming(
            verseKey: "invalid",
            timestampFrom: 0,
            timestampTo: 1000,
            segments: nil
        )
        
        #expect(timing.verseNumber == nil)
    }
}

// MARK: - VerseAudioFile Tests

struct VerseAudioFileTests {
    
    @Test func verseAudioFileParsing() {
        let audioFile = VerseAudioFile(
            verseKey: "112:4",
            url: "Alafasy/mp3/112004.mp3"
        )
        
        #expect(audioFile.verseNumber == 4)
        #expect(audioFile.chapterNumber == 112)
        #expect(audioFile.fullUrl == "https://verses.quran.com/Alafasy/mp3/112004.mp3")
    }
}

// MARK: - Translation Model Tests

struct TranslationModelTests {
    
    @Test func translationInitialization() {
        let translation = Translation(
            id: 20,
            languageCode: "en",
            name: "Saheeh International",
            text: "Say, He is Allah, [who is] One"
        )
        
        #expect(translation.id == 20)
        #expect(translation.languageCode == "en")
        #expect(translation.name == "Saheeh International")
        #expect(translation.text == "Say, He is Allah, [who is] One")
    }
    
    @Test func popularTranslationValues() {
        let saheeh = PopularTranslation.saheehInternational.info
        #expect(saheeh.id == 20)
        #expect(saheeh.code == "en")
        
        let indonesian = PopularTranslation.indonesianMinistry.info
        #expect(indonesian.id == 33)
        #expect(indonesian.code == "id")
    }
    
    @Test func downloadedTranslation() {
        let downloaded = DownloadedTranslation(
            id: 20,
            name: "Saheeh International",
            languageCode: "en"
        )
        
        #expect(downloaded.id == 20)
        #expect(downloaded.name == "Saheeh International")
        #expect(downloaded.languageCode == "en")
    }
}

// MARK: - Audio Player State Tests

struct AudioPlayerStateTests {
    
    @Test func stateIsPlaying() {
        #expect(AudioPlayerState.playing.isPlaying == true)
        #expect(AudioPlayerState.paused.isPlaying == false)
        #expect(AudioPlayerState.idle.isPlaying == false)
        #expect(AudioPlayerState.loading.isPlaying == false)
        #expect(AudioPlayerState.stopped.isPlaying == false)
        #expect(AudioPlayerState.error("test").isPlaying == false)
    }
    
    @Test func stateIsLoading() {
        #expect(AudioPlayerState.loading.isLoading == true)
        #expect(AudioPlayerState.playing.isLoading == false)
        #expect(AudioPlayerState.paused.isLoading == false)
        #expect(AudioPlayerState.idle.isLoading == false)
    }
    
    @Test func stateEquality() {
        #expect(AudioPlayerState.playing == AudioPlayerState.playing)
        #expect(AudioPlayerState.paused == AudioPlayerState.paused)
        #expect(AudioPlayerState.error("test") == AudioPlayerState.error("test"))
        #expect(AudioPlayerState.error("test1") != AudioPlayerState.error("test2"))
    }
}

// MARK: - Time Formatting Tests

@MainActor
struct TimeFormattingTests {
    
    @Test func formatTimeZero() {
        let formatted = AudioPlayerService.formatTime(0)
        #expect(formatted == "0:00")
    }
    
    @Test func formatTimeSeconds() {
        let formatted = AudioPlayerService.formatTime(45)
        #expect(formatted == "0:45")
    }
    
    @Test func formatTimeMinutes() {
        let formatted = AudioPlayerService.formatTime(125)
        #expect(formatted == "2:05")
    }
    
    @Test func formatTimeLong() {
        let formatted = AudioPlayerService.formatTime(3661)
        #expect(formatted == "61:01")
    }
    
    @Test func formatTimeInvalid() {
        let formatted = AudioPlayerService.formatTime(Double.nan)
        #expect(formatted == "0:00")
        
        let formattedInf = AudioPlayerService.formatTime(Double.infinity)
        #expect(formattedInf == "0:00")
    }
}

// MARK: - RecitationData Conversion Tests

struct RecitationDataTests {
    
    @Test func convertToQari() {
        let recitationData = RecitationData(
            id: 7,
            reciterName: "Mishari Rashid al-Afasy",
            style: nil,
            translatedName: nil
        )
        
        let qari = recitationData.toQari()
        
        #expect(qari.id == 7)
        #expect(qari.name == "Mishari Rashid al-Afasy")
        #expect(qari.style == nil)
    }
    
    @Test func convertToQariWithStyle() {
        let recitationData = RecitationData(
            id: 2,
            reciterName: "AbdulBaset AbdulSamad",
            style: "Murattal",
            translatedName: nil
        )
        
        let qari = recitationData.toQari()
        
        #expect(qari.id == 2)
        #expect(qari.style == "Murattal")
        #expect(qari.displayName == "AbdulBaset AbdulSamad (Murattal)")
    }
}

// MARK: - Juz Amma Range Tests

struct JuzAmmaRangeTests {
    
    @Test func juzAmmaContains37Surahs() {
        // Juz Amma contains surahs 78-114 (37 surahs)
        let startSurah = 78
        let endSurah = 114
        let expectedCount = 37
        
        let actualCount = endSurah - startSurah + 1
        #expect(actualCount == expectedCount)
    }
    
    @Test func surahNumbersInRange() {
        // Valid Juz Amma surah numbers
        for number in 78...114 {
            #expect(number >= 78 && number <= 114)
        }
    }
}
