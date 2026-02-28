//
//  L10n.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 01/03/26.
//

import Foundation

/// Type-safe localization accessors.
/// All keys map to entries in `Localizable.strings` files.
/// Usage: `Text(L10n.appName)` or `label.text = L10n.appName`
enum L10n {

    // MARK: - General

    static var appName: String { String(localized: "app_name") }
    static var memorizeQuran: String { String(localized: "memorize_quran") }
    static var version: String { String(localized: "version") }

    // MARK: - Loading

    static var loadingQuranData: String { String(localized: "loading_quran_data") }

    // MARK: - Surah List

    static var juzAmma: String { String(localized: "juz_amma") }
    static var searchSurahs: String { String(localized: "search_surahs") }
    static var noSurahsFound: String { String(localized: "no_surahs_found") }
    static func noResultsFor(_ query: String) -> String {
        String(format: String(localized: "no_results_for"), query)
    }
    static var bookmarks: String { String(localized: "bookmarks") }
    static var memorized: String { String(localized: "memorized") }

    // MARK: - Progress

    static var memorizationProgress: String { String(localized: "memorization_progress") }
    static var nextToMemorize: String { String(localized: "next_to_memorize") }

    // MARK: - Surah Detail

    static var bookmark: String { String(localized: "bookmark") }
    static var removeBookmark: String { String(localized: "remove_bookmark") }
    static var markAsMemorized: String { String(localized: "mark_as_memorized") }
    static var markAsNotMemorized: String { String(localized: "mark_as_not_memorized") }
    static var setAsNextToMemorize: String { String(localized: "set_as_next_to_memorize") }
    static var removeFromNextToMemorize: String { String(localized: "remove_from_next_to_memorize") }
    static var displayOptions: String { String(localized: "display_options") }
    static var selectTranslation: String { String(localized: "select_translation") }
    static var fontSize: String { String(localized: "font_size") }
    static var showBothTranslations: String { String(localized: "show_both_translations") }
    static var ayahsNotAvailable: String { String(localized: "ayahs_not_available") }
    static var fullContentComingSoon: String { String(localized: "full_content_coming_soon") }
    static var playSurah: String { String(localized: "play_surah") }
    static var pause: String { String(localized: "pause") }
    static var downloadedLabel: String { String(localized: "downloaded") }
    static var download: String { String(localized: "download") }

    // MARK: - Audio

    static var playbackProgress: String { String(localized: "playback_progress") }
    static var skipBack10Seconds: String { String(localized: "skip_back_10_seconds") }
    static var skipForward10Seconds: String { String(localized: "skip_forward_10_seconds") }
    static var audioOptions: String { String(localized: "audio_options") }
    static var changeReciter: String { String(localized: "change_reciter") }
    static var playbackSpeed: String { String(localized: "playback_speed") }
    static var repeatOn: String { String(localized: "repeat_on") }
    static var repeatOff: String { String(localized: "repeat_off") }
    static var stopPlayback: String { String(localized: "stop_playback") }
    static var selectReciter: String { String(localized: "select_reciter") }
    static var searchReciters: String { String(localized: "search_reciters") }
    static var popularReciters: String { String(localized: "popular_reciters") }
    static var allReciters: String { String(localized: "all_reciters") }

    // MARK: - Settings

    static var settings: String { String(localized: "settings") }
    static var appearance: String { String(localized: "appearance") }
    static var theme: String { String(localized: "theme") }
    static var displayPreferences: String { String(localized: "display_preferences") }
    static var manageTranslations: String { String(localized: "manage_translations") }
    static var audio: String { String(localized: "audio") }
    static var reciterQari: String { String(localized: "reciter_qari") }
    static var offlineDownloads: String { String(localized: "offline_downloads") }
    static var clearAudioCache: String { String(localized: "clear_audio_cache") }
    static var notifications: String { String(localized: "notifications") }
    static var dailyReminders: String { String(localized: "daily_reminders") }
    static var reminderTime: String { String(localized: "reminder_time") }
    static var statistics: String { String(localized: "statistics") }
    static var totalSurahs: String { String(localized: "total_surahs") }
    static var about: String { String(localized: "about") }
    static var developer: String { String(localized: "developer") }
    static var githubRepository: String { String(localized: "github_repository") }
    static var shareApp: String { String(localized: "share_app") }

    // MARK: - Downloads

    static var downloads: String { String(localized: "downloads") }
    static var offlineAudio: String { String(localized: "offline_audio") }
    static var wifiOnly: String { String(localized: "wifi_only") }
    static var downloadAllSurahs: String { String(localized: "download_all_surahs") }
    static var allDownloaded: String { String(localized: "all_downloaded") }
    static var deleteAllDownloads: String { String(localized: "delete_all_downloads") }
    static var batchActions: String { String(localized: "batch_actions") }

    // MARK: - Translations

    static var translations: String { String(localized: "translations") }
    static var popularTranslations: String { String(localized: "popular_translations") }
    static var downloadTranslations: String { String(localized: "download_translations") }
    static var noTranslations: String { String(localized: "no_translations") }
    static var primaryTranslation: String { String(localized: "primary_translation") }
    static var secondaryTranslation: String { String(localized: "secondary_translation") }

    // MARK: - Common

    static var cancel: String { String(localized: "cancel") }
    static var delete: String { String(localized: "delete") }
    static var done: String { String(localized: "done") }
    static var retry: String { String(localized: "retry") }
    static var error: String { String(localized: "error") }
    static var ok: String { String(localized: "ok") }
}
