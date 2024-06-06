//Made by Lumaa

import SwiftUI

struct NowPlayingView: View {
    private let player: MusicManager = MusicManager.shared
    var detail: MusicManager.SongDetails
    var browser: MusicBrowser
    
    var body: some View {
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
