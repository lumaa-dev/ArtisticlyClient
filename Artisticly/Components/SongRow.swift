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
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.0)
                            .stroke(.gray.opacity(0.2), lineWidth: 0.5)
                    )
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
    @ViewBuilder
    func coverArt(_ missing: Bool = false) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: missing ? 20 : 40, height: missing ? 20 : 40)
            .padding(missing ? 10 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
    }
}

#Preview {
    List {
        SongRow(detail: .template)
    }
}
