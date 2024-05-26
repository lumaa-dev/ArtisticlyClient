//Made by Lumaa

import SwiftUI
import SwiftData

struct SongList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query private var libraries: [KnownLibrary] = []
    
    @State var browser: MusicBrowser
    private let player: MusicManager = MusicManager.shared
    
    private var playingMusic: MusicManager.SongDetails { musics.first(where: { $0.id == playingId })?.songDetail ?? MusicManager.SongDetails(name: String(localized: "music.stopped"), artist: "", album: "") }
    
    @State private var nowPlayingSheet: Bool = false
    @State private var playingId: Int? = nil
    @State private var musics: [MusicResponse] = []
    
    @State private var changingCode: Bool = false
    @State private var newCode: String = ""
    
    @State private var serverVersion: String = "?"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(musics) { music in
                    Button {
                        playingId = nil
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            var req = URLRequest(url: URL(string: "\(browser.url.absoluteString)/music/\(music.id)")!)
                            req.setValue((UserDefaults.standard.string(forKey: "code") ?? ""), forHTTPHeaderField: "Authorization")
                            
                            playingId = music.id
                            
                            try? player.play(at: req)
                            player.setNowPlayingInfo(with: music.songDetail)
                        }
                    } label: {
                        SongRow(detail: music.songDetail)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            changingCode.toggle()
                        } label: {
                            Label("change.code", systemImage: "asterisk")
                        }
                        
                        Button(role: .destructive) {
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
                                }
                                if let personal = libraries.filter({ $0.personal == true }).first {
                                    Task {
                                        let tempBrowser = await MusicBrowser(url: personal.url)
                                        
                                        UserDefaults.standard.setValue(personal.code, forKey: "code")
                                        UserDefaults.standard.setValue(personal.url.absoluteString, forKey: "server")
                                        
                                        self.browser = tempBrowser
                                        
                                        await loadSongs()
                                    }
                                } else {
                                    UserDefaults.standard.removeObject(forKey: "server")
                                    UserDefaults.standard.removeObject(forKey: "code")
                                    
                                    self.browser.setup = false
                                    self.browser.online = false
                                }
                                print("removed public server")
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
            .navigationTitle(Text("song.list-\(browser.name)"))
            .toolbarTitleMenu {
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
            await loadSongs()
        }
        .sheet(isPresented: $nowPlayingSheet) {
            NowPlayingView(detail: playingMusic)
        }
    }
    
    private func loadSongs() async {
        print(modelContext.autosaveEnabled)
        do {
            try await browser.refreshStatus()
            if browser.online {
                musics = try await browser.get("/musics")
                
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
        print(modelContext.autosaveEnabled)
        do {
            try await browser.refreshStatus()
            if browser.online {
                musics = try await browser.get("/musics")
            } else {
                musics = []
            }
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
