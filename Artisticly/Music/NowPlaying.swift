//Made by Lumaa

import Foundation
import SwiftUI
import UIKit
import MediaPlayer

enum NowPlayableCommand: CaseIterable {
    case play, pause, togglePlayPause,
         nextTrack, previousTrack,
         changePlaybackRate, changePlaybackPosition,
         skipForward, skipBackward,
         seekForward, seekBackward
}

// MARK: - MPRemoteCommand

extension NowPlayableCommand {
    var remoteCommand: MPRemoteCommand {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        switch self {
            case .play:
                return commandCenter.playCommand
            case .pause:
                return commandCenter.pauseCommand
            case .togglePlayPause:
                return commandCenter.togglePlayPauseCommand
            case .nextTrack:
                return commandCenter.nextTrackCommand
            case .previousTrack:
                return commandCenter.previousTrackCommand
            case .changePlaybackRate:
                return commandCenter.changePlaybackRateCommand
            case .changePlaybackPosition:
                return commandCenter.changePlaybackPositionCommand
            case .skipForward:
                return commandCenter.skipForwardCommand
            case .skipBackward:
                return commandCenter.skipBackwardCommand
                
            case .seekForward:
                return commandCenter.seekForwardCommand
            case .seekBackward:
                return commandCenter.seekBackwardCommand
        }
    }
    // Adding Handler and accepting an escaping closure for event handling for a praticular remote command
    func addHandler(remoteCommandHandler: @escaping  (NowPlayableCommand, MPRemoteCommandEvent)->(MPRemoteCommandHandlerStatus)) {
        switch self {
            case .skipBackward:
                MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [10.0]
                
            case .skipForward:
                MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [10.0]
                
            default:
                break
        }
        self.remoteCommand.addTarget { event in
            remoteCommandHandler(self,event)
        }
    }
    
    func removeHandler() {
        self.remoteCommand.removeTarget(self)
    }
}

protocol NowPlayable {
    var supportedNowPlayableCommands: [NowPlayableCommand] { get }
    
    func configureRemoteCommands(remoteCommandHandler: @escaping  (NowPlayableCommand, MPRemoteCommandEvent)->(MPRemoteCommandHandlerStatus))
    func handleRemoteCommand(for type: NowPlayableCommand, with event: MPRemoteCommandEvent)-> MPRemoteCommandHandlerStatus
    
//    func handleNowPlayingItemChange()
//    func handleNowPlayingItemPlaybackChange()
    
//    func addNowPlayingObservers()
    
    func setNowPlayingInfo(with metadata: MusicManager.SongDetails)
    func setNowPlayingPlaybackInfo(with metadata: MusicManager.SongDetails)
    
//    func resetNowPlaying()
}

extension MusicManager: NowPlayable {
    var supportedNowPlayableCommands: [NowPlayableCommand] {
        return [
            .togglePlayPause,
            .pause,
            .play,
            .nextTrack,
            .previousTrack,
            .changePlaybackPosition
        ]
    }
    
    func configureRemoteCommands(remoteCommandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> (MPRemoteCommandHandlerStatus)) {
        guard supportedNowPlayableCommands.count > 1 else {
            assertionFailure("Fatal error, atleast one remote command needs to be registered")
            return
        }
        
        supportedNowPlayableCommands.forEach { nowPlayableCommand in
            nowPlayableCommand.removeHandler()
            nowPlayableCommand.addHandler(remoteCommandHandler: remoteCommandHandler)
        }
    }
    
    func handleRemoteCommand(for type: NowPlayableCommand, with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch (type) {
            case .togglePlayPause:
                self.smartPause()
                return .success
            case .play:
                self.play()
                return .success
            case .pause:
                self.pause()
                return .success
            case .nextTrack:
                return .noSuchContent
            case .previousTrack:
                return .noSuchContent
            case .changePlaybackPosition:
                guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                self.currentTime = event.positionTime
                return .success
            default:
                return .commandFailed
        }
    }
    
    /// Static
    func setNowPlayingInfo(with metadata: SongDetails) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyPlaybackDuration: self.currentTime,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: self.maxTime,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPMediaItemPropertyArtist: metadata.artist,
            MPMediaItemPropertyTitle: metadata.name,
            MPNowPlayingInfoPropertyIsLiveStream: false
        ]
        
        if let image: UIImage = .init(data: metadata.artwork) {
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                return image
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        print("** NEW Now Playing ** \(metadata.name)")
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    /// Dynamic
    func setNowPlayingPlaybackInfo(with metadata: SongDetails) {
        let d = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo: [String: Any] = d.nowPlayingInfo ?? [:]
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.maxTime
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        d.nowPlayingInfo = nowPlayingInfo
    }
}

struct VolumeSliderView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        MPVolumeView(frame: .zero)
    }
    
    func updateUIView(_ view: MPVolumeView, context: Context) {}
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) -> Void {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
    
    static func getVolume() -> Float {
        var vol: Float = 0.0
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            vol = slider?.value ?? 0.0
        }
        
        return vol
    }
}
