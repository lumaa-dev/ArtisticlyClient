//Made by Lumaa

import SwiftUI
import SwiftData

struct SongList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.isSearching) private var isSearching: Bool
    @Environment(\.dismissSearch) private var dismissSearch: DismissSearchAction
    
    @Query private var libraries: [KnownLibrary] = []
    
    @State var browser: MusicBrowser
    private let player: MusicManager = MusicManager.shared
    
    private var playingMusic: MusicManager.SongDetails { musics.first(where: { $0.id == playingId })?.songDetail ?? MusicManager.SongDetails(name: String(localized: "music.stopped"), artist: "", album: "") }
    
    @State private var nowPlayingSheet: Bool = false
    @State private var playingId: Int? = nil
    @State private var musics: [MusicResponse] = []
    @State private var occupied: Bool = false
    @State private var hasMore: Bool = true
    @State private var lastSeen: Int?
    
    @State private var searchField: String = ""
    @State private var searchType: SearchType = .titles
    
    @State private var changingCode: Bool = false
    @State private var newCode: String = ""
    
    @State private var serverVersion: String = "?"
    
    @State private var addingSongs: Bool = false
    
    @State private var spotifySheet: Bool = false
    @State private var spotifyType: SpotifyType = .album
    @State private var spotifyUrl: String = "https://open.spotify.com/track/2UKARCqDrhkYDoVR4FN5Wi"
    
    var body: some View {
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let i = musics.firstIndex(where: { $0.id == music.id }) ?? -1
                                musics.remove(at: i)
                                
                                Task {
                                    do {
                                        let _: SpotifyAdded = try await browser.delete("/music/\(music.id)")
                                    } catch {
                                        musics.insert(music, at: i)
                                        print(error)
                                    }
                                }
                            } label: {
                                Label("delete", systemImage: "trash.fill")
                            }
                        }
                        .onAppear {
                            lastSeen = music.id
                            loadMoreSongs()
                        }
                    }
                } else {
                    ContentUnavailableView("no.songs", systemImage: "xmark.circle")
                }
                
                if occupied && hasMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .listRowSeparator(.hidden)
                            .listRowSpacing(10.0)
                            .listRowBackground(Color.listBackground)
                        Spacer()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            changingCode.toggle()
                        } label: {
                            Label("change.code", systemImage: "asterisk")
                        }
                        
                        Button(role: .destructive) {
                            // S.O.S. code for removing bugged libraries
                            //                              do {
                            //                                  try modelContext.delete(model: KnownLibrary.self)
                            //                              } catch {
                            //                                  print(error)
                            //                              }
                            
                            if browser.personal {
                                do {
                                    try modelContext.delete(model: KnownLibrary.self)
                                } catch {
                                    print(error)
                                }
                                
                                browser.setup = false
                                browser.online = false
                                
                                player.stop()
                                playingId = nil
                                
                                UserDefaults.standard.removeObject(forKey: "server")
                                UserDefaults.standard.removeObject(forKey: "code")
                                print("removed personal")
                            } else {
                                if let lib = libraries.filter({ $0.url == browser.url && $0.personal == false }).first {
                                    modelContext.delete(lib)
                                    print("removed public server")
                                }
                                if let personal = libraries.filter({ $0.personal == true }).first {
                                    Task {
                                        let tempBrowser = await MusicBrowser(url: personal.url)
                                        
                                        UserDefaults.standard.setValue(personal.code, forKey: "code")
                                        UserDefaults.standard.setValue(personal.url.absoluteString, forKey: "server")
                                        
                                        self.browser = tempBrowser
                                        print("loaded personal server")
                                        
                                        await loadSongs()
                                    }
                                } else {
                                    UserDefaults.standard.removeObject(forKey: "server")
                                    UserDefaults.standard.removeObject(forKey: "code")
                                    
                                    self.browser.setup = false
                                    self.browser.online = false
                                }
                            }
                        } label: {
                            Label("reset.server", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        Text(String("ArtisticlyServer v\(self.serverVersion)"))
                            .task {
                                do {
                                    try await browser.getVersions(completionHandler: { s, _ in
                                        self.serverVersion = s
                                    })
                                } catch {
                                    print(error)
                                }
                            }
                    } label: {
                        Label("server.settings", systemImage: "ellipsis.circle")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text(browser.personal ? "song.my-list" : "song.list-\(browser.name)"))
            .toolbarTitleMenu {
                if !isSearching {
                    LibrarySelector(browser: browser) { newBrowser in
                        guard newBrowser.url != browser.url else { return }
                        
                        self.browser = newBrowser
                        Task {
                            await loadSongs()
                        }
                    }
                    .modelContainer(DataContainer.shared.container)
                    .modelContext(DataContainer.shared.context)
                    .environment(\.modelContext, DataContainer.shared.context)
                    
                    Divider()
                    
                    Menu {
                        Button {
                            spotifySheet.toggle()
                        } label: {
                            Text(String("Spotify"))
                        }
                    } label: {
                        Label("add.song", systemImage: "plus.circle")
                    }
                }
            }
            .searchable(text: $searchField, prompt: "search.bar")
//          .searchSuggestions {
//              if musics.count > 0 {
//                  ForEach(musics.shuffled()[0...(musics.count <= 10 ? (musics.count - 1) : 10)]) { suggestion in
//                      Text("\(searchType == SearchType.titles ? suggestion.songDetail.name : suggestion.songDetail.album) — \(suggestion.songDetail.artist)")
//                          .searchCompletion(searchType == SearchType.titles ? suggestion.songDetail.name : suggestion.songDetail.album)
//                  }
//              }
//          }
            .searchScopes($searchType) {
                ForEach(SearchType.allCases, id: \.self) { type in
                    type.label
                        .id(type)
                }
            }
            .onSubmit(of: .search) {
                Task {
                    await loadSongs(with: searchField, type: searchType)
                    dismissSearch()
                }
            }
            .onChange(of: searchField) { _, new in
                if new.isEmpty {
                    Task {
                        await loadSongs()
                    }
                }
            }
            .alert("new.code", isPresented: $changingCode) {
                TextField("input.new.code", text: $newCode)
                
                Button {
                    UserDefaults.standard.setValue(newCode, forKey: "code")
                    newCode = ""
                    
                    Task {
                        await loadSongs()
                    }
                } label: {
                    Text("ok")
                }
            } message: {
                Text("new.code.desc")
            }
            
            if playingMusic.artist.count > 0 {
                Button {
                    nowPlayingSheet.toggle()
                } label: {
                    HStack(spacing: 7.5) {
                        SongRow(detail: playingMusic)
                        
                        Button {
                            withAnimation(.spring.speed(2.0)) {
                                player.smartPause()
                            }
                        } label: {
                            Image(systemName: player.isPlaying ? "pause" : "play.fill")
                                .font(.title2.bold())
                                .foregroundStyle(Color.label)
                                .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                                .padding(.trailing, 5)
                        }
                        .disabled(player.buffering)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 7.5)
                            .stroke(LinearGradient(colors: [Color.clear, Color.gray.opacity(0.15)], startPoint: .bottom, endPoint: .top), lineWidth: 1.0)
                            .frame(width: UIScreen.main.bounds.width)
                            .offset(y: -10.0)
                    }
                    .padding([.horizontal, .bottom])
                    .background(Color(uiColor: UIColor.systemGroupedBackground))
                    .offset(y: -7.0)
                    .transition(.blurReplace.combined(with: .move(edge: .bottom)))
                }
                .transition(.blurReplace.combined(with: .move(edge: .bottom)))
                .buttonStyle(NoTapAnimationStyle())
                .background(Color(uiColor: UIColor.systemGroupedBackground))
            }
        }
        .refreshable {
            await refresh()
        }
        .task {
            if !isSearching {
                await loadSongs()
            }
        }
        .sheet(isPresented: $nowPlayingSheet) {
            NowPlayingView(detail: playingMusic, browser: browser, songId: playingId ?? -1)
        }
        .sheet(isPresented: $spotifySheet) {
            ZStack {
                Form {
                    Picker("spotify.type", selection: $spotifyType) {
                        ForEach(SpotifyType.allCases, id: \.self) { type in
                            Text(type.label)
                                .id(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(addingSongs)
                    
                    HStack {
                        TextField(spotifyType.label, text: $spotifyUrl)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .disabled(addingSongs)
                            .onSubmit {
                                submitSong()
                            }
                        
                        if !addingSongs {
                            Button {
                                submitSong()
                            } label: {
                                Image(systemName: "arrow.forward.to.line")
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!spotifyUrl.lowercased().hasPrefix("https://open.spotify.com/\(spotifyType.rawValue)"))
                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
            }
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
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
    
    private func submitSong() {
        guard !addingSongs else { return }
        
        let url = spotifyUrl
        addingSongs = true
        
        Task {
            do {
                let added: SpotifyAdded = try await browser.post("/spotify/\(spotifyType)", queries: [.init(name: "link", value: url)])
                
                if added.success {
                    spotifySheet.toggle()
                    spotifyUrl = ""
                    addingSongs = false
                }
            } catch {
                print(error)
            }
        }
    }
    
    enum SpotifyType: String, CaseIterable {
        case album = "album"
        case track = "track"
        
        var label: String {
            switch self {
                case .album:
                    return String(localized: "song.album")
                case .track:
                    return String(localized: "song.track")
            }
        }
    }
    
    private struct SearchMusic {
        let id: Int
        let searched: String
    }
}

enum SearchType: String, CaseIterable {
    case titles = "title"
    case artists = "artist"
    case albums = "albums"
    
    @ViewBuilder
    var label: some View {
        switch (self) {
            case .titles:
                Label("search.type.title", systemImage: "square.text.square")
            case .albums:
                Label("search.type.album", systemImage: "square.stack")
            case .artists:
                Label("search.type.artist", systemImage: "person.crop.square")
        }
    }
}

#Preview {
    ContentView()
}
