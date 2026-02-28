//
//  RemoteCommandHandler.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 23/02/26.
//

import Foundation
import MediaPlayer

/// Manages MPRemoteCommandCenter (lock screen / AirPods controls).
/// Extracted from AudioPlayerService for single-responsibility.
@MainActor
final class RemoteCommandHandler {
    
    // MARK: - Callback Types
    
    struct Callbacks {
        let onPlay: () -> Void
        let onPause: () -> Void
        let onTogglePlayPause: () -> Void
        let onSkipForward: (TimeInterval) -> Void
        let onSkipBackward: (TimeInterval) -> Void
        let onSeek: (TimeInterval) -> Void
    }
    
    // MARK: - Properties
    
    private var callbacks: Callbacks?
    
    // MARK: - Public API
    
    /// Register remote command handlers. Call once during initialization.
    func setup(callbacks: Callbacks) {
        self.callbacks = callbacks
        
        let center = MPRemoteCommandCenter.shared()
        
        // Play
        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.callbacks?.onPlay() }
            return .success
        }
        
        // Pause
        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.callbacks?.onPause() }
            return .success
        }
        
        // Toggle Play/Pause
        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.callbacks?.onTogglePlayPause() }
            return .success
        }
        
        // Skip Forward
        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: AppConstants.Audio.skipIntervalSeconds)]
        center.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.callbacks?.onSkipForward(AppConstants.Audio.skipIntervalSeconds)
            }
            return .success
        }
        
        // Skip Backward
        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: AppConstants.Audio.skipIntervalSeconds)]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.callbacks?.onSkipBackward(AppConstants.Audio.skipIntervalSeconds)
            }
            return .success
        }
        
        // Seek (scrubbing)
        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in
                self?.callbacks?.onSeek(positionEvent.positionTime)
            }
            return .success
        }
    }
    
    /// Remove all remote command targets and disable commands.
    func tearDown() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.skipForwardCommand.removeTarget(nil)
        center.skipBackwardCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)
        callbacks = nil
    }
}
