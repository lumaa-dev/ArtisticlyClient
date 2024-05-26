//Made by Lumaa

import SwiftUI

struct SongList: View {
    var browser: MusicBrowser
    private let player: MusicManager = MusicManager.shared
    
    @State private var playingId: Int? = nil
    @State private var musics: [MusicResponse] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let playingMusic = musics.filter({ $0.id == self.playingId }).first {
                        VStack(spacing: 7.5) {
                            SongRow(detail: playingMusic.songDetail)
                            
                            Button {
                                withAnimation(.spring.speed(2.0)) {
                                    player.smartPause()
                                }
                            } label: {
                                Image(systemName: player.isPlaying ? "pause" : "play.fill")
                                    .font(.title.bold())
                                    .foregroundStyle(Color.label)
                                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                            }
                        }
                    }
                }
                
                ForEach(musics) { music in
                    Button {
                        var req = URLRequest(url: URL(string: "\(browser.url.absoluteString)/music/\(music.id)")!)
                        req.setValue((UserDefaults.standard.string(forKey: "code") ?? ""), forHTTPHeaderField: "Authorization")
                        
                        playingId = music.id
                        try? player.play(at: req)
                    } label: {
                        SongRow(detail: music.songDetail)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("song.list-\(browser.name)"))
        }
        .refreshable {
            await refresh()
        }
        .task {
            await loadSongs()
        }
    }
    
    private func loadSongs() async {
        do {
            try await browser.refreshStatus()
            if browser.online {
                musics = await browser.get("/musics")
            } else {
                musics = []
            }
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
    
    private func refresh() async {
        do {
            try await browser.refreshStatus()
            if browser.online {
                musics = await browser.get("/musics")
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
