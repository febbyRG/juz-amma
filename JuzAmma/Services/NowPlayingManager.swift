//
//  NowPlayingManager.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 23/02/26.
//

import Foundation
import MediaPlayer
import UIKit

/// Manages the MPNowPlayingInfoCenter (lock screen / Control Center metadata).
/// Extracted from AudioPlayerService for single-responsibility.
@MainActor
final class NowPlayingManager {
    
    // MARK: - Cached Artwork
    
    /// Cache the artwork so we don't re-create it every update
    private lazy var cachedArtwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "AppIcon") ?? UIImage(systemName: "book.fill") else {
            return nil
        }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }()
    
    // MARK: - Public API
    
    /// Update Now Playing info with the current playback state.
    func update(
        surahName: String?,
        surahNumber: Int?,
        qariName: String,
        duration: TimeInterval,
        currentTime: TimeInterval,
        playbackSpeed: Float,
        isPlaying: Bool,
        currentVerse: Int
    ) {
        var info = [String: Any]()
        
        // Title
        if let surahName {
            info[MPMediaItemPropertyTitle] = surahName
        } else if let surahNumber {
            info[MPMediaItemPropertyTitle] = "Surah \(surahNumber)"
        }
        
        // Artist / Album
        info[MPMediaItemPropertyArtist] = qariName
        info[MPMediaItemPropertyAlbumTitle] = AppConstants.appName
        
        // Timing
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackSpeed) : 0.0
        
        // Verse info
        if currentVerse > 0 {
            info[MPMediaItemPropertyComposer] = "Ayah \(currentVerse)"
        }
        
        // Artwork
        if let artwork = cachedArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    /// Clear Now Playing info (e.g., when playback stops).
    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
