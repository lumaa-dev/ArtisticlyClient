//Made by Lumaa
#if DEBUG
import SwiftUI

struct DemoView: View {
    @State private var playing: MusicManager.SongDetails?
    private let timeLabelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var newTime: Double = 0.0
    
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
                try? MusicManager.shared.play(at: .mp3)
                
                Task {
                    playing = await MusicManager.shared.getDetails()
                    MusicManager.shared.setNowPlayingInfo(with: playing!)
                }
            } label: {
                Text(String("Play mp3"))
            }
            
            Button {
                try? MusicManager.shared.play(at: .wav)
                
                Task {
                    playing = await MusicManager.shared.getDetails()
                    MusicManager.shared.setNowPlayingInfo(with: playing!)
                }
            } label: {
                Text(String("Play wav"))
            }
            
            Button {
                try? MusicManager.shared.play(at: .m4a)
                
                Task {
                    playing = await MusicManager.shared.getDetails()
                    MusicManager.shared.setNowPlayingInfo(with: playing!)
                }
            } label: {
                Text(String("Play m4a (metadata)"))
            }
            
            HStack {
                
                Button {
                    MusicManager.shared.smartPause()
                } label: {
                    Image(systemName: "pause")
                        .bold()
                }
            }
            
            AirPlayButton()
                .frame(width: 10, height: 10)
            
            Slider(value: $newTime, in: 0...MusicManager.shared.maxTime, onEditingChanged: { changed in
                MusicManager.shared.pause()
                
                if !changed {
                    MusicManager.shared.currentTime = newTime
                }
            })
                .onReceive(timeLabelTimer) { _ in
                    guard MusicManager.shared.isPlaying else { return }
                    if let details = playing {
                        MusicManager.shared.setNowPlayingPlaybackInfo(with: details)
                    }
                    newTime = MusicManager.shared.currentTime
                }
            
            VolumeSliderView()
                .frame(height: 40)
                .padding(.horizontal)
        }
        .padding()
    }
}
#endif
