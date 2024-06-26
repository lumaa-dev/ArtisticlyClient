//Made by Lumaa

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import MediaPlayer

struct NowPlayingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var device: Device = .shared
    
    private let player: MusicManager = MusicManager.shared
    var detail: MusicManager.SongDetails
    var browser: MusicBrowser
    var songId: Int
    
    private let timeLabelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private var hasLyrics: Bool {
        self.lyrics.isEmpty && !self.showLyrics
    }
    
    @State private var scrubbing: Bool = false
    @State private var newTime: Double = 0.0
    @State private var deviceVolume: Double = 0.0
    
    @State private var showLyrics: Bool = false
    @State private var lyrics: [LyricResponse] = []
    @State private var currentLyrics: LyricResponse? = nil
    
    var body: some View {
        ViewThatFits {
            if device.isPortrait {
                portrait
            } else {
                landscape
            }
            
            portrait
            landscape
        }
        .task {
            do {
                self.lyrics = try await browser.get("/lyrics/\(self.songId)")
            } catch {
                print(error)
            }
        }
    }
    
    var landscape: some View {
        HStack(alignment: .center) {
            header
            
            Spacer()
            
            VStack {
                Spacer()
                
                details
                actions
            }
            .safeAreaPadding(.trailing)
            .frame(width: 300, height: UIScreen.main.bounds.height)
            
        }
        .environment(\.colorScheme, ColorScheme.light)
        .foregroundStyle(Color.white)
        .fullSheet(.hidden)
        .background(alignment: .center) {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                let c: Color = UIImage(data: detail.artwork) != nil ? Color(uiColor: UIImage(data: detail.artwork)!.averageColor ?? .systemGray) : Color.gray
                
                Rectangle().fill(c.opacity(0.9).gradient)
                    .ignoresSafeArea()
                    .frame(width: UIScreen.main.bounds.width + 20, height: UIScreen.main.bounds.height + 20, alignment: .center)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.white)
                    .font(.title2)
            }
            .safeAreaPadding(.top, 50)
            .safeAreaPadding(.trailing)
        }
    }
    
    var portrait: some View {
        VStack {
            header
                .offset(y: 20)
                .safeAreaPadding(.top)
                .frame(height: 350)
            
            Spacer()
            
            VStack {
                details
                    .padding(.vertical)
                actions
            }
            .offset(y: -20 )
            .frame(height: 350)
        }
        .environment(\.colorScheme, ColorScheme.light)
        .foregroundStyle(Color.white)
        .fullSheet(.hidden)
        .showGrabber()
        .background(alignment: .center) {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                let c: Color = UIImage(data: detail.artwork) != nil ? Color(uiColor: UIImage(data: detail.artwork)!.averageColor ?? .systemGray) : Color.gray
                
                Rectangle().fill(c.opacity(0.9).gradient)
                    .ignoresSafeArea()
                    .frame(width: UIScreen.main.bounds.width)
            }
        }
    }
    
    @ViewBuilder
    var details: some View {
        VStack(spacing: -1) {
            let tfont = UIFont.preferredFont(forTextStyle: .title2)
            let tdescript = tfont.fontDescriptor.withSymbolicTraits(.traitBold)
            MarqueeText(
                text: detail.name,
                font: UIFont(descriptor: tdescript ?? .preferredFontDescriptor(withTextStyle: .title2), size: 22.0),
                leftFade: 16,
                rightFade: 16,
                startDelay: 3
            )
            
            MarqueeText(
                text: detail.artist,
                font: UIFont.preferredFont(forTextStyle: .callout),
                leftFade: 16,
                rightFade: 16,
                startDelay: 3
            )
        }
        .frame(width: 300)
    }
    
    @ViewBuilder
    var actions: some View {
        VStack(alignment: .leading) {
            ScrubberView(value: $newTime, maxValue: 1) { changed in
                scrubbing = changed
                
                if !changed {
                    MusicManager.shared.currentTime = newTime * MusicManager.shared.maxTime
                }
            }
            .onReceive(timeLabelTimer) { _ in
                guard MusicManager.shared.isPlaying && !scrubbing else { return }
                
                MusicManager.shared.setNowPlayingPlaybackInfo(with: detail)
                newTime = MusicManager.shared.currentTime / MusicManager.shared.maxTime
            }
            
            HStack {
                Spacer()
                
                Button {
                    withAnimation(.spring.speed(2.0)) {
                        player.smartPause()
                    }
                } label: {
                    Image(systemName: player.isPlaying ? "pause" : "play.fill")
                        .font(.title.bold())
                        .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                }
                .disabled(player.buffering)
                
                Spacer()
            }
            .frame(height: 45)
            .padding(.vertical, 20)
            
            HStack {
                Button {
                    withAnimation(.spring) {
                        showLyrics.toggle()
                    }
                } label: {
                    Image(systemName: "quote.bubble")
                        .foregroundStyle(!hasLyrics ? showLyrics ? Color.black.opacity(0.6) : Color.white : Color.white.opacity(0.25))
                }
                .toggleEffect(showLyrics)
                .disabled(hasLyrics)
                
                Spacer()
                
                Button {} label: {
                    Image(systemName: "music.note.list")
                        .foregroundStyle(Color.white.opacity(0.25))
                }
                .disabled(true)
                
                Spacer()
                
                AirPlayButton()
                    .frame(width: 10, height: 10)
                    .tint(Color.white)
            }
            .padding(.vertical)
        }
        .frame(width: 300)
    }
    
    @ViewBuilder
    var header: some View {
        if !showLyrics {
            albumCover
                .transition(.identity)
        } else {
            lyricsText
                .safeAreaPadding(.top)
                .padding(15)
                .transition(.identity)
        }
    }
    
    @ViewBuilder
    var lyricsText: some View {
        let width: CGFloat = device.isPortrait ? UIScreen.main.bounds.width : UIScreen.main.bounds.width / 2 - 30
        let height: CGFloat = 350
        
        ScrollViewReader { proxy in
            VStack(alignment: .leading) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(self.lyrics, id: \.self) { obj in
                            let selected: Bool = self.currentLyrics == obj
                            
                            VStack(alignment: .leading) {
                                Text(obj.lyric)
                                    .font(.system(size: 25, weight: .bold))
                                    .scaleEffect(selected ? 1.25 : 1.0, anchor: .leading)
                                    .opacity(selected ? 0.9 : 0.5)
                                    .id(obj)
                                    .lineLimit(4)
                                    .frame(maxWidth: width / 1.4, alignment: .leading)
                                    
                            }
                            .frame(width: width - 30, alignment: .leading)
                        }
                    }
                }
                .scrollDisabled(true)
                .frame(height: height)
            }
            .onReceive(timeLabelTimer) { _ in
                syncLyrics(using: proxy)
            }
        }
        .frame(height: height)
    }
    
    var albumCover: some View {
        ZStack {
            if let ui = UIImage(data: detail.artwork) {
                Image(uiImage: ui)
                    .coverArt()
            } else {
                Image(systemName: "music.note")
                    .coverArt(true)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .font(.system(.body, weight: .ultraLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25.0)
                            .stroke(.white.opacity(0.2), lineWidth: 2.5)
                    )
            }
        }
//      .scaleEffect(CGSize(width: player.isPlaying ? 1.0 : 0.65, height: player.isPlaying ? 1.0 : 0.65))
        .padding(.vertical, 50)
    }
    
    private func syncLyrics(using proxy: ScrollViewProxy) {
        guard !lyrics.isEmpty else { return }
        let index: Int = lyrics.firstIndex(where: { $0 == self.currentLyrics }) ?? -1
        let nextLyrics = lyrics.count - 1 >= index + 1 ? lyrics[index + 1] : lyrics[lyrics.count - 1]
        
        if player.currentTime >= nextLyrics.seconds {
            DispatchQueue.main.async {
                withAnimation(Animation.spring(duration: 0.45)) {
                    guard !lyrics.isEmpty else { return }
                    self.currentLyrics = nextLyrics
                }
                
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(currentLyrics, anchor: .center)
                }
            }
        } else {
            findLyric(using: proxy)
        }
    }
    
    private func findLyric(using proxy: ScrollViewProxy, time: TimeInterval? = nil) {
        guard !lyrics.isEmpty else { return }
        let nextLyrics = lyrics.nearest(to: time ?? self.player.currentTime)?.element ?? lyrics.first!
        
        if player.currentTime >= nextLyrics.seconds {
            DispatchQueue.main.async {
                withAnimation(Animation.spring(duration: 0.45)) {
                    guard !lyrics.isEmpty else { return }
                    self.currentLyrics = nextLyrics
                }
                
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(currentLyrics, anchor: .center)
                }
            }
        }
    }
}

struct LyricResponse: Codable, Hashable, Equatable {
    let seconds: TimeInterval
    let lyric: String
}

extension [LyricResponse] {
    func nearest(to seconds: TimeInterval) -> (offset: Int, element: Element)? {
        self.enumerated().min(by: {
            abs($0.element.seconds - seconds) < abs($1.element.seconds - seconds)
        })
    }
}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

private extension Image {
    @ViewBuilder
    func coverArt(_ missing: Bool = false) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: missing ? 250 : 350, height: missing ? 250 : 350)
            .padding(missing ? 50 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
    }
}

private extension View {
    @ViewBuilder
    func toggleEffect(_ toggled: Bool) -> some View {
        self
            .padding(4)
            .background(toggled ? Color.white.opacity(0.6) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5.5))
    }
}

@Observable
private class Device: ObservableObject {
    static let shared: Device = .init()
    
    var isPortrait: Bool {
        return UIDevice.current.orientation.isPortrait
    }
}
