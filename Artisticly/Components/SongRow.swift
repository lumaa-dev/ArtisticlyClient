//Made by Lumaa

import SwiftUI

struct SongRow: View {
    @State var detail: MusicManager.SongDetails
    
    var body: some View {
        HStack {
            if let ui = UIImage(data: detail.artwork) {
                Image(uiImage: ui)
                    .coverArt()
            } else {
                Image(systemName: "music.note")
                    .coverArt(true)
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .font(.system(.body, weight: .ultraLight))
                #if os(iOS)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.0)
                            .stroke(.gray.opacity(0.2), lineWidth: 0.5)
                    )
                #elseif os(tvOS)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.0)
                            .stroke(.gray.opacity(0.6), lineWidth: 2)
                    )
                #endif
            }
            
            VStack(alignment: .leading) {
                Text(detail.name)
                    .lineLimit(1)
                    .foregroundStyle(Color.label)
                
                if detail.artist.count > 0 && detail.album.count > 0 {
                    Text("\(detail.artist) — \(detail.album)")
                        .lineLimit(1)
                        .font(.footnote)
                        .foregroundStyle(Color.gray)
                }
            }
            
            Spacer()
        }
    }
}

private extension Image {
    #if os(iOS)
    static let coverSize: CGSize = .init(width: 40, height: 40)
    #elseif os(tvOS)
    static let coverSize: CGSize = .init(width: 70, height: 70)
    #endif
    
    @ViewBuilder
    func coverArt(_ missing: Bool = false) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: missing ? 20 : Self.coverSize.width, height: missing ? 20 : Self.coverSize.height)
            .padding(missing ? 10 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
    }
}

#Preview {
    List {
        SongRow(detail: .template)
    }
}
