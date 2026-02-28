//
//  AudioPlayerService.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 27/01/26.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit
import os

// MARK: - Audio Player State

/// Represents the current state of audio playback
enum AudioPlayerState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(String)
    
    var isPlaying: Bool {
        self == .playing
    }
    
    var isLoading: Bool {
        self == .loading
    }
}

// MARK: - Audio Playback Mode

/// Defines how audio should be played
enum AudioPlaybackMode: Sendable {
    /// Play entire surah as single file
    case surah
    /// Play specific verse only (seeks within chapter audio)
    case singleVerse(Int)
}

// MARK: - Audio Player Service

/// Service for playing Quran recitations.
/// Delegates Now Playing and Remote Command handling to dedicated managers.
@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: AudioPlayerState = .idle
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentVerseIndex: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var currentPlayingVerse: Int = 0
    
    // MARK: - Configuration
    
    @Published var selectedQari: Qari = PopularQari.misharyAlafasy.qari
    @Published var playbackMode: AudioPlaybackMode = .surah
    @Published var isRepeatEnabled: Bool = false
    @Published var playbackSpeed: Float = 1.0
    
    // MARK: - Extracted Managers
    
    private let nowPlayingManager = NowPlayingManager()
    private let remoteCommandHandler = RemoteCommandHandler()
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    private var currentSurahNumber: Int?
    private var currentSurahName: String?
    private var currentChapterAudioUrl: URL?
    private var verseTimings: [(verse: Int, startTime: TimeInterval, endTime: TimeInterval)] = []
    private var currentPlaybackTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        currentPlaybackTask?.cancel()
        player?.pause()
        playerItem = nil
        player = nil
        cancellables.removeAll()
        // NowPlayingManager and RemoteCommandHandler cleanup is handled
        // by their own deinit since they share MainActor isolation.
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowAirPlay, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true)
        } catch {
            AppLogger.audio.error("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Remote Commands (delegated to RemoteCommandHandler)
    
    private func setupRemoteCommands() {
        remoteCommandHandler.setup(callbacks: .init(
            onPlay: { [weak self] in self?.resume() },
            onPause: { [weak self] in self?.pause() },
            onTogglePlayPause: { [weak self] in self?.togglePlayPause() },
            onSkipForward: { [weak self] seconds in self?.skipForward(seconds) },
            onSkipBackward: { [weak self] seconds in self?.skipBackward(seconds) },
            onSeek: { [weak self] time in self?.seek(to: time) }
        ))
    }
    
    // MARK: - Now Playing (delegated to NowPlayingManager)
    
    private func updateNowPlayingInfo() {
        nowPlayingManager.update(
            surahName: currentSurahName,
            surahNumber: currentSurahNumber,
            qariName: selectedQari.name,
            duration: duration,
            currentTime: currentTime,
            playbackSpeed: playbackSpeed,
            isPlaying: state == .playing,
            currentVerse: currentPlayingVerse
        )
    }
    
    private func clearNowPlayingInfo() {
        nowPlayingManager.clear()
    }
    
    // MARK: - Public Methods
    
    /// Check if currently playing a specific surah
    func isPlayingSurah(_ surahNumber: Int) -> Bool {
        currentSurahNumber == surahNumber
    }
    
    /// Play full surah from the beginning (resets mode to .surah)
    /// Use this when user explicitly wants to play the whole surah
    /// - Parameters:
    ///   - surahNumber: The surah number
    ///   - surahName: Optional surah name for Now Playing display
    func playSurahFull(_ surahNumber: Int, surahName: String? = nil) async {
        playbackMode = .surah
        currentPlayingVerse = 1
        currentSurahName = surahName
        await playSurah(surahNumber, surahName: surahName)
    }
    
    /// Load and play audio for a surah
    /// - Parameters:
    ///   - surahNumber: The surah number (78-114 for Juz Amma)
    ///   - surahName: Optional surah name for Now Playing display
    ///   - startFromVerse: Optional verse number to start from
    func playSurah(_ surahNumber: Int, surahName: String? = nil, startFromVerse: Int? = nil) async {
        // Cancel any in-flight playback to prevent race conditions
        currentPlaybackTask?.cancel()
        
        currentSurahNumber = surahNumber
        currentSurahName = surahName
        state = .loading
        updateNowPlayingInfo()
        
        let task = Task {
            switch playbackMode {
            case .surah:
                currentPlayingVerse = 1
                await playChapterAudio(surahNumber: surahNumber)
            case .singleVerse(let verseNum):
                currentPlayingVerse = verseNum
                await playChapterAudioFromVerse(surahNumber: surahNumber, verseNumber: verseNum)
            }
        }
        currentPlaybackTask = task
        await task.value
    }
    
    /// Play specific verse using chapter audio (consistent voice)
    /// Uses same audio source as full surah but seeks to verse timestamp
    func playVerse(_ surahNumber: Int, verseNumber: Int, surahName: String? = nil) async {
        // Cancel any in-flight playback to prevent race conditions
        currentPlaybackTask?.cancel()
        
        playbackMode = .singleVerse(verseNumber)
        currentPlayingVerse = verseNumber
        currentSurahNumber = surahNumber
        currentSurahName = surahName
        state = .loading
        updateNowPlayingInfo()
        
        let task = Task {
            await playChapterAudioFromVerse(surahNumber: surahNumber, verseNumber: verseNumber)
        }
        currentPlaybackTask = task
        await task.value
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        switch state {
        case .playing:
            pause()
        case .paused:
            resume()
        case .idle, .stopped:
            if let surahNumber = currentSurahNumber {
                Task {
                    await playSurah(surahNumber, surahName: currentSurahName)
                }
            }
        default:
            break
        }
    }
    
    /// Pause playback
    func pause() {
        player?.pause()
        state = .paused
        updateNowPlayingInfo()
    }
    
    /// Resume playback
    func resume() {
        player?.play()
        player?.rate = playbackSpeed
        state = .playing
        updateNowPlayingInfo()
    }
    
    /// Stop playback
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        currentTime = 0
        progress = 0
        state = .stopped
        clearNowPlayingInfo()
    }
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        updateProgress()
        updateNowPlayingInfo()
    }
    
    /// Seek to percentage
    func seekToProgress(_ newProgress: Double) {
        let time = duration * newProgress
        seek(to: time)
    }
    
    /// Skip forward by seconds
    func skipForward(_ seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    /// Skip backward by seconds
    func skipBackward(_ seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    /// Play next verse (for verse-by-verse mode)
    /// Change playback speed
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        player?.rate = state == .playing ? speed : 0
    }
    
    /// Change Qari
    func setQari(_ qari: Qari) {
        selectedQari = qari
        // Reload if currently playing
        if let surahNumber = currentSurahNumber, state == .playing || state == .paused {
            Task {
                await playSurah(surahNumber)
            }
        }
    }
    
    /// Save current playback state for restoration
    func savePlaybackState(to settings: AppSettings) {
        settings.lastPlayingSurahNumber = currentSurahNumber
        settings.lastPlaybackPosition = currentTime > 0 ? currentTime : nil
    }
    
    /// Restore playback state (position only — does not auto-play)
    func restorePlaybackState(from settings: AppSettings) -> (surahNumber: Int, position: TimeInterval)? {
        guard let surahNumber = settings.lastPlayingSurahNumber else { return nil }
        let position = settings.lastPlaybackPosition ?? 0
        return (surahNumber, position)
    }
    
    // MARK: - Private Methods
    
    /// Play chapter-level audio (single MP3 for entire surah) with caching support
    private func playChapterAudio(surahNumber: Int) async {
        do {
            let audioFile = try await fetchChapterAudio(surahNumber: surahNumber)
            
            // Store verse timings for tracking current verse (API returns 'timestamps')
            if let timings = audioFile.timestamps {
                verseTimings = timings.compactMap { timing in
                    guard let verseNum = timing.verseNumber else { return nil }
                    return (verse: verseNum, startTime: timing.startTimeSeconds, endTime: timing.endTimeSeconds)
                }.sorted { $0.verse < $1.verse }
                AppLogger.audio.debug("Loaded \(self.verseTimings.count) verse timings")
            } else {
                verseTimings = []
                AppLogger.audio.debug("No verse timings available")
            }
            
            guard let remoteURL = URL(string: audioFile.audioUrl) else {
                state = .error("Invalid audio URL")
                return
            }
            
            // Check cache first, then stream and cache in background
            let playbackURL = await getPlaybackURL(remoteURL: remoteURL, surahNumber: surahNumber)
            
            // Store the audio URL for verse playback
            currentChapterAudioUrl = playbackURL
            
            AppLogger.audio.info("Playing chapter audio: \(playbackURL)")
            await playAudio(from: playbackURL)
        } catch {
            state = .error("Failed to load audio: \(error.localizedDescription)")
        }
    }
    
    /// Play chapter audio starting from a specific verse (consistent voice for verse mode)
    private func playChapterAudioFromVerse(surahNumber: Int, verseNumber: Int) async {
        do {
            let audioFile = try await fetchChapterAudio(surahNumber: surahNumber)
            
            // Store verse timings
            if let timings = audioFile.timestamps {
                verseTimings = timings.compactMap { timing in
                    guard let verseNum = timing.verseNumber else { return nil }
                    return (verse: verseNum, startTime: timing.startTimeSeconds, endTime: timing.endTimeSeconds)
                }.sorted { $0.verse < $1.verse }
            } else {
                verseTimings = []
            }
            
            guard let remoteURL = URL(string: audioFile.audioUrl) else {
                state = .error("Invalid audio URL")
                return
            }
            
            // Check cache first, then stream and cache in background
            let playbackURL = await getPlaybackURL(remoteURL: remoteURL, surahNumber: surahNumber)
            currentChapterAudioUrl = playbackURL
            
            // Find the timestamp for the requested verse
            if let verseTiming = verseTimings.first(where: { $0.verse == verseNumber }) {
                AppLogger.audio.info("Playing verse \(verseNumber) from chapter audio, seeking to \(verseTiming.startTime)s")
                await playAudio(from: playbackURL, seekTo: verseTiming.startTime)
            } else {
                AppLogger.audio.warning("Verse timing not found for verse \(verseNumber), playing from start")
                await playAudio(from: playbackURL)
            }
        } catch {
            state = .error("Failed to load audio: \(error.localizedDescription)")
        }
    }
    
    /// Get playback URL - returns cached URL if available, otherwise returns remote URL and caches in background
    private func getPlaybackURL(remoteURL: URL, surahNumber: Int) async -> URL {
        let qariId = selectedQari.id
        
        // Check if cached
        if let cachedURL = await AudioCacheService.shared.getCachedAudioURL(surahNumber: surahNumber, qariId: qariId) {
            AppLogger.audio.debug("Playing from cache: \(cachedURL.lastPathComponent)")
            return cachedURL
        }
        
        // Not cached - start background download and return remote URL for streaming
        AppLogger.audio.info("Streaming from remote, caching in background...")
        await AudioCacheService.shared.cacheAudioInBackground(from: remoteURL, surahNumber: surahNumber, qariId: qariId)
        
        return remoteURL
    }
    
    /// Play audio from URL with optional seek position
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - seekTo: Optional time to seek to after loading (for verse playback)
    private func playAudio(from url: URL, seekTo: TimeInterval? = nil) async {
        cleanup()
        
        AppLogger.audio.info("Starting playback from: \(url)")
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup observers first
        setupTimeObserver()
        setupNotifications()
        
        // If we need to seek to a specific position
        if let seekTime = seekTo {
            let cmTime = CMTime(seconds: seekTime, preferredTimescale: 600)
            await player?.seek(to: cmTime)
            currentTime = seekTime
            AppLogger.audio.debug("Seeked to: \(seekTime)s")
        }
        
        // Start playback - AVPlayer handles buffering internally
        player?.play()
        player?.rate = playbackSpeed
        state = .playing
        updateNowPlayingInfo()
        
        // Load duration asynchronously (don't block playback)
        Task { [weak self] in
            do {
                if let asset = self?.playerItem?.asset {
                    let durationValue = try await asset.load(.duration)
                    let durationSeconds = CMTimeGetSeconds(durationValue)
                    if durationSeconds.isFinite && durationSeconds > 0 {
                        await MainActor.run {
                            self?.duration = durationSeconds
                            self?.updateNowPlayingInfo()
                            AppLogger.audio.debug("Duration loaded: \(durationSeconds)s")
                        }
                    }
                }
            } catch {
                AppLogger.audio.error("Failed to load duration: \(error.localizedDescription)")
                // Still allow playback even if duration fails
            }
        }
    }
    
    /// Setup time observer for progress updates
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)  // Update every 0.5s for Now Playing  
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = CMTimeGetSeconds(time)
                self.updateProgress()
                self.updateCurrentVerseFromTime()
                self.checkSingleVerseEnd()
            }
        }
    }
    
    /// Check if we've reached the end of a single verse (for singleVerse mode)
    private func checkSingleVerseEnd() {
        guard case .singleVerse(let verseNum) = playbackMode,
              !verseTimings.isEmpty,
              state == .playing else { return }
        
        // Find the timing for the current verse
        if let verseTiming = verseTimings.first(where: { $0.verse == verseNum }) {
            // Stop when we reach the end of this verse
            if currentTime >= verseTiming.endTime {
                if isRepeatEnabled {
                    // Seek back to start of verse
                    seek(to: verseTiming.startTime)
                } else {
                    pause()
                    state = .stopped
                    AppLogger.audio.info("Single verse \(verseNum) ended")
                }
            }
        }
    }
    
    /// Update currentPlayingVerse based on current playback time
    private func updateCurrentVerseFromTime() {
        guard !verseTimings.isEmpty else { return }
        
        // Find which verse is currently playing based on time
        for timing in verseTimings {
            if currentTime >= timing.startTime && currentTime < timing.endTime {
                if currentPlayingVerse != timing.verse {
                    currentPlayingVerse = timing.verse
                }
                return
            }
        }
        
        // If past all timings, we're at the last verse
        if let lastTiming = verseTimings.last, currentTime >= lastTiming.startTime {
            currentPlayingVerse = lastTiming.verse
        }
    }
    
    /// Setup notifications for playback events
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handlePlaybackEnded()
                }
            }
            .store(in: &cancellables)
        
        // Observe playback status for errors and ready state
        playerItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .failed:
                    let errorMessage = self.playerItem?.error?.localizedDescription ?? "Unknown error"
                    AppLogger.audio.error("Playback failed: \(errorMessage)")
                    self.state = .error("Playback failed: \(errorMessage)")
                case .readyToPlay:
                    AppLogger.audio.debug("Ready to play")
                    // Ensure we're playing if we should be
                    if self.state == .loading {
                        self.player?.play()
                        self.player?.rate = self.playbackSpeed
                        self.state = .playing
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Also observe player timeControlStatus for buffering state
        player?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .playing:
                    if self.state != .playing {
                        self.state = .playing
                    }
                case .paused:
                    // Only update if we didn't explicitly pause
                    break
                case .waitingToPlayAtSpecifiedRate:
                    // Buffering - could show loading indicator
                    AppLogger.audio.debug("Buffering...")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handle when playback ends
    private func handlePlaybackEnded() async {
        switch playbackMode {
        case .surah:
            if isRepeatEnabled {
                seek(to: 0)
                resume()
            } else {
                state = .stopped
            }
            
        case .singleVerse:
            if isRepeatEnabled {
                seek(to: 0)
                resume()
            } else {
                state = .stopped
            }
        }
    }
    
    /// Update progress percentage
    private func updateProgress() {
        guard duration > 0 else {
            progress = 0
            return
        }
        progress = currentTime / duration
    }
    
    /// Cleanup resources
    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        player?.pause()
        player = nil
        playerItem = nil
        cancellables.removeAll()
    }
    
    // MARK: - API Methods
    
    /// Fetch chapter audio file info with verse timings
    private func fetchChapterAudio(surahNumber: Int) async throws -> ChapterAudioFile {
        // Add segments=true to get verse timings in the response
        let urlString = "\(AppConstants.API.baseURL)\(AppConstants.API.chapterRecitationsEndpoint)/\(selectedQari.id)/\(surahNumber)?segments=true"
        
        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }
        
        let response = try await NetworkService.shared.fetch(ChapterAudioResponse.self, from: url)
        return response.audioFile
    }
    
    /// Fetch available reciters from API
    func fetchAvailableReciters() async throws -> [Qari] {
        let urlString = "\(AppConstants.API.baseURL)\(AppConstants.API.recitationsEndpoint)"
        
        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }
        
        let response = try await NetworkService.shared.fetch(
            RecitationsResponse.self,
            from: url,
            cachePolicy: .cacheFirst(maxAge: AppConstants.Network.recitersCacheDuration)
        )
        return response.recitations.map { $0.toQari() }
    }
}

// MARK: - Audio Errors

enum AudioError: LocalizedError, Sendable {
    case invalidURL
    case networkError
    case playbackFailed
    case noAudioAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .networkError:
            return "Failed to load audio. Check your internet connection."
        case .playbackFailed:
            return "Audio playback failed"
        case .noAudioAvailable:
            return "No audio available for this surah"
        }
    }
}

// MARK: - Time Formatting Extension

extension AudioPlayerService {
    /// Format time interval as MM:SS
    static func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
