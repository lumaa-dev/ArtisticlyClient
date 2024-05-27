//Made by Lumaa

import Foundation

struct CodeResponse: Codable {
    let correct: Bool
}

struct SpotifyAdded: Codable {
    let success: Bool
    let newFile: String?
}

struct SpotifyAddedAlbum: Codable {
    let success: Bool
    let newFiles: [String]?
}

struct MusicResponse: Codable, Identifiable{
    let id: Int
    let metadata: Metadata
    
    var songDetail: MusicManager.SongDetails {
        return .init(name: self.metadata.name, artist: self.metadata.artist, album: self.metadata.album, artwork: self.metadata.artwork)
    }
    
    struct Metadata: Codable {
        let name: String
        let artist: String
        let album: String
        let artwork: Data
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<MusicResponse.Metadata.CodingKeys> = try decoder.container(keyedBy: MusicResponse.Metadata.CodingKeys.self)
            self.name = try container.decode(String.self, forKey: MusicResponse.Metadata.CodingKeys.name)
            self.artist = try container.decode(String.self, forKey: MusicResponse.Metadata.CodingKeys.artist)
            self.album = try container.decode(String.self, forKey: MusicResponse.Metadata.CodingKeys.album)
            let artworkStr = try container.decode(String.self, forKey: MusicResponse.Metadata.CodingKeys.artwork)
            self.artwork = Data(base64Encoded: artworkStr) ?? Data()
        }
    }
}
