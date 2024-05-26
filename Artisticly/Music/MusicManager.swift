//Made by Lumaa

import Foundation
import AVFoundation
import CoreServices
import MediaPlayer

@Observable
final class MusicManager {
    static let shared: MusicManager = MusicManager()
    
    private var player: AVAudioPlayer
    
    private var songURL: URL?
    var isPlaying: Bool = false
    var buffering: Bool = false
    
    var currentTime: TimeInterval {
        get {
            self.player.currentTime
        }
        set {
            self.addTime(newValue)
        }
    }
    var maxTime: TimeInterval {
        get {
            self.player.duration
        }
    }
    var volume: Float {
        get {
            self.player.volume
        }
        set {
            self.player.setVolume(newValue, fadeDuration: 0)
        }
    }
    
    init() {
        player = AVAudioPlayer()
        player.prepareToPlay()
        player.setVolume(2.0, fadeDuration: 0.1)
    }
    
    func getDetails() async -> SongDetails {
        guard let url = self.songURL else { return .init() }
        print("scrapping data...")
        
        var details: SongDetails = .init()
        let playerItem = AVPlayerItem(url: url)
        if let metadataList = try? await playerItem.asset.load(.commonMetadata) {
            for item in metadataList {
                guard let key = item.commonKey?.rawValue, let value = try? await item.load(.value) else { continue }
                
                print("\(key): \(value)")
                
                switch (key) {
                    case "artwork":
                        details.artwork = value as! Data
                    case "title":
                        details.name = value as! String
                    case "artist":
                        details.artist = value as! String
                    case "albumName":
                        details.album = value as! String
                    default:
                        print("UNKNOWN \(key)")
                        continue
                }
            }
            
            let desc = AVMetadataItem.metadataItems(from: metadataList, filteredByIdentifier: .id3MetadataOriginalReleaseYear)
            for item in desc {
                guard let key = item.commonKey?.rawValue, let value = try? await item.load(.value) else { continue }
                
                print("\(key): \(value)")
            }
        }
        
        print("Finished scrapping all data")
        
        return details
    }
    
    /// Play a song from a URL
    func play(at url: URL) throws {
        player.pause()
        isPlaying = false
        buffering = true
        
        Task {
            self.songURL = url
            let data = try await URLSession.shared.data(for: URLRequest(url: url)).0
            
            player = try .init(data: data)
            player.play()
            
            isPlaying = true
            buffering = false
        }
    }
    
    func play(at urlr: URLRequest) throws {
        player.pause()
        isPlaying = false
        buffering = true
        
        Task {
            self.songURL = urlr.url
            let data = try await URLSession.shared.data(for: urlr).0
            
            player = try .init(data: data)
            player.play()
            
            isPlaying = true
            buffering = false
        }
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func stop() {
        player.stop()
        isPlaying = false
        buffering = false
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    /// Toggles on or off the "pause" feature accordingly
    func smartPause() {
         if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play(atTime: TimeInterval(Int(player.deviceCurrentTime + 0.1)))
            isPlaying = true
        }
        isPlaying = player.isPlaying
    }
    
    private func addTime(_ time: TimeInterval) {
        player.pause()
        isPlaying = false
        buffering = true
        
        player.currentTime = time
        player.play()
        
        isPlaying = true
        buffering = false
    }
    
    struct SongDetails {
        var name: String
        var artist: String
        var album: String
        var genre: String
        var artwork: Data
        
        init(name: String = "Unknown Song", artist: String = "Unknown Artist", album: String = "Unknown Album", genre: String = "Unknown Genre", artwork: Data = Data()) {
            self.name = name
            self.artist = artist
            self.album = album
            self.genre = genre
            self.artwork = artwork
        }
        
        static let template: Self = .init(name: "Song Name", artist: "Artist Name", album: "Album Name")
    }
}

@available(*, deprecated)
extension URL {
    static let mp3 = URL(string: "https://lumaa.fr/static/unaccess/HIG.mp3")!
    static let wav = URL(string: "https://lumaa.fr/static/unaccess/DBM.wav")!
    
    /// This one link includes metadata like the album cover, the song name, the artist name and other...
    static let m4a = URL(string: "https://lumaa.fr/static/unaccess/WWWM.m4a")!
}
