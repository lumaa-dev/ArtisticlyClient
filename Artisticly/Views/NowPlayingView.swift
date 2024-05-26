//Made by Lumaa

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import MediaPlayer

struct NowPlayingView: View {
    private var isPortrait: Bool {
        return UIDevice.current.orientation.isPortrait
    }
    
    private let player: MusicManager = MusicManager.shared
    var detail: MusicManager.SongDetails
    
    private let timeLabelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var newTime: Double = 0.0
    @State private var deviceVolume: Double = 0.0
    
    var body: some View {
        if isPortrait {
            portrait
        } else {
            landscape
        }
    }
    
    var landscape: some View {
        HStack(alignment: .center) {
            VStack {
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
                .scaleEffect(CGSize(width: player.isPlaying ? 0.75 : 0.35, height: player.isPlaying ? 0.75 : 0.35))
                
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
                .frame(maxHeight: 30)
            }
            .frame(height: 100)
            
            
            VStack {
                ScrubberView(value: $newTime, maxValue: 1) { changed in
                    MusicManager.shared.pause()
                    
                    if !changed {
                        MusicManager.shared.currentTime = newTime * MusicManager.shared.maxTime
                    }
                }
                .onReceive(timeLabelTimer) { _ in
                    guard MusicManager.shared.isPlaying else { return }
                    
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
                    
                    Spacer()
                }
                .padding(.vertical, 20)
                
                //                ScrubberView(value: $deviceVolume, maxValue: 1.0) { _ in
                //                    MPVolumeView.setVolume(Float(deviceVolume))
                //                }
                //                .onAppear {
                //                    deviceVolume = Double(MPVolumeView.getVolume())
                //                }
                
                HStack {
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
            .frame(width: 300, height: 200)
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
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            }
        }
    }
    
    var portrait: some View {
        VStack {
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
            .scaleEffect(CGSize(width: player.isPlaying ? 1.0 : 0.65, height: player.isPlaying ? 1.0 : 0.65))
            .padding(.vertical, 50)
            
            Spacer()
            
            VStack(alignment: .leading) {
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
                
                ScrubberView(value: $newTime, maxValue: 1) { changed in
                    MusicManager.shared.pause()
                    
                    if !changed {
                        MusicManager.shared.currentTime = newTime * MusicManager.shared.maxTime
                    }
                }
                .onReceive(timeLabelTimer) { _ in
                    guard MusicManager.shared.isPlaying else { return }
                    
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
                    
                    Spacer()
                }
                .padding(.vertical, 20)
                
//                ScrubberView(value: $deviceVolume, maxValue: 1.0) { _ in
//                    MPVolumeView.setVolume(Float(deviceVolume))
//                }
//                .onAppear {
//                    deviceVolume = Double(MPVolumeView.getVolume())
//                }
                
                HStack {
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
            
            Spacer()
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

#Preview {
//    ZStack { EmptyView() }
//        .sheet(isPresented: .constant(true)) {
//            NowPlayingView(detail: .template)
//        }
    
    NowPlayingView(detail: .template)
}
