//Made by Lumaa

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var browser: MusicBrowser? = nil
    @State private var fetching: Bool = false

    var body: some View {
        ZStack {
            if !fetching {
                if let browser = self.browser, browser.setup {
                    SongList(browser: browser)
                } else {
                    WelcomeView(browser: $browser)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .ignoresSafeArea()
        .background(Color.background) // force dark background
    }
}

extension Color {
    static let label: Color = Color(uiColor: UIColor.label)
    static let background: Color = Color.black
    static let listBackground: Color = Color.gray.opacity(0.4)
}
