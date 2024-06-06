//Made by Lumaa

import SwiftUI

struct SongList: View {
    
    @State var browser: MusicBrowser
    
    private let player: MusicManager = MusicManager.shared
    private var playingMusic: MusicManager.SongDetails { musics.first(where: { $0.id == playingId })?.songDetail ?? MusicManager.SongDetails(name: String(localized: "music.stopped"), artist: "", album: "") }
    private var lastSeen: Int? { musics.last?.id }
    
    @State private var playingId: Int? = nil
    @State private var occupied: Bool = false
    @State private var hasMore: Bool = true
    
    @State private var musics: [MusicResponse] = []
    
    var body: some View {
        TabView {
            list
                .tabItem {
                    Label("library", systemImage: "list.triangle")
                }
            
            NowPlayingView(detail: playingMusic, browser: browser)
                .tabItem {
                    Label("now-playing", systemImage: "play.circle")
                }
        }
    }
    
    var list: some View {
        NavigationStack {
            List {
                if musics.count > 0 {
                    ForEach(musics) { music in
                        Button {
                            playingId = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                var req = URLRequest(url: URL(string: "\(browser.url.absoluteString)/music/\(music.id)")!)
                                req.setValue((UserDefaults.standard.string(forKey: "code") ?? ""), forHTTPHeaderField: "Authorization")
                                
                                playingId = music.id
                                
                                try? player.play(at: req)
                                player.setNowPlayingInfo(with: music.songDetail)
                                
                                MusicManager.shared.setNowPlayingPlaybackInfo(with: music.songDetail)
                            }
                        } label: {
                            SongRow(detail: music.songDetail)
                        }
                        .listRowBackground(Color.listBackground)
                    }
                } else {
                    HStack {
                        Spacer()
                        ContentUnavailableView("no.songs", systemImage: "xmark.circle")
                        Spacer()
                    }
                }
                
                if (!occupied && hasMore) && !musics.isEmpty {
                    Button {
                        guard !occupied else { return }
                        loadMoreSongs()
                    } label: {
                        Text("songs.more")
                    }
                    .disabled(occupied)
                }
            }
        }
        .refreshable {
            await refresh()
        }
        .task {
            await loadSongs()
        }
    }
    
    private func loadSongs(with search: String? = nil, type: SearchType = .titles) async {
        do {
            try await browser.refreshStatus()
            if browser.online {
                let limit = 20
                let page = 1
                if let query = search {
                    if hasMore {
                        let searchResult: MusicSearch = try await browser.get("/musics", queries: [.init(name: "p", value: page), .init(name: "l", value: limit), .init(name: "q", value: query.lowercased()), .init(name: "type", value: type.rawValue)])
                        hasMore = searchResult.count >= limit
                        
                        musics = searchResult.results
                    } else {
                        let searched: [SearchMusic] = musics.map({
                            var searched: String = ""
                            switch (type) {
                                case .titles:
                                    searched = $0.metadata.name
                                case .artists:
                                    searched = $0.metadata.artist
                                case .albums:
                                    searched = $0.metadata.album
                            }
                            
                            return SearchMusic(id: $0.id, searched: searched)
                        })
                        
                        let filtered: [SearchMusic] = searched.filter({ $0.searched.localizedCaseInsensitiveContains(query) })
                        let ids: [Int] = filtered.map({ $0.id })
                        let results: [MusicResponse] = musics.filter({ ids.contains($0.id) })
                        hasMore = results.count >= limit
                        
                        if results.count <= 0 {
                            let searchResult: MusicSearch = try await browser.get("/musics", queries: [.init(name: "p", value: page), .init(name: "l", value: limit), .init(name: "q", value: query.lowercased()), .init(name: "type", value: type.rawValue)])
                            hasMore = searchResult.count >= limit
                            
                            musics = searchResult.results
                            return
                        }
                        
                        musics = results
                    }
                } else {
                    musics = try await browser.get("/musics", queries: [.init(name: "p", value: page), .init(name: "l", value: limit)])
                    hasMore = musics.count >= limit
                }
                
                let ids = musics.map { $0.id }
                if !ids.contains(playingId ?? -1) {
                    player.stop()
                    playingId = nil
                }
            } else {
                musics = []
            }
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
    
    private func refresh() async {
        musics = []
        hasMore = true
        do {
            try await browser.refreshStatus()
            if browser.online {
                let limit = 20
                musics = try await browser.get("/musics")
                hasMore = musics.count >= limit
            } else {
                musics = []
            }
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
    
    private func loadMoreSongs() {
        guard !occupied && hasMore && lastSeen ?? 0 == musics.count else { return }
        
        Task {
            occupied = true
            
            if browser.online {
                let limit = 20
                let page = Int((lastSeen ?? 0) / limit) + 1 // gets the current page + 1
                
                let newSongs: [MusicResponse] = try await browser.get("/musics", queries: [.init(name: "p", value: page), .init(name: "l", value: limit)])
                hasMore = newSongs.count >= limit
                
                musics.append(contentsOf: newSongs)
                
                let ids = musics.map { $0.id }
                if !ids.contains(playingId ?? -1) {
                    player.stop()
                    playingId = nil
                }
            } else {
                musics = []
            }
            
            occupied = false
        }
    }
    
    private struct SearchMusic {
        let id: Int
        let searched: String
    }
}
