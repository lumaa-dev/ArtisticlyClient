//Made by Lumaa

import SwiftUI

struct ContentView: View {
    @State private var playing: MusicManager.SongDetails?
    
    var body: some View {
        VStack(spacing: 10) {
            if playing != nil {
                HStack {
                    if let ui = UIImage(data: playing!.artwork) {
                        Image(uiImage: ui)
                            .resizable()
                            .frame(width: 100, height: 100)
                    }
                    
                    VStack {
                        Text(playing!.name)
                        Text(playing!.artist)
                    }
                }
            }
            
            Button {
                do { try MusicManager.shared.play(at: .mp3) } catch { print(error) }
            } label: {
                Text("Play mp3")
            }
            
            Button {
                try? MusicManager.shared.play(at: .wav)
            } label: {
                Text("Play wav")
            }
            
            Button {
                try? MusicManager.shared.play(at: .m4a)
            } label: {
                Text("Play m4a (metadata)")
            }
            
            Button {
                MusicManager.shared.smartPause()
            } label: {
                Image(systemName: "pause")
                    .bold()
            }
            
            Button {
                Task {
                    playing = await MusicManager.shared.getDetails()
                }
            } label: {
                Text("Get data")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
