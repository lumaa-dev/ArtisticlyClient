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
        .task {
            fetching = true
            if let tempBrowser: MusicBrowser = try? await MusicBrowser() {
                do {
                    let res: CodeResponse = try await tempBrowser.get(path: "/code")
                    
                    if !res.correct {
                        UserDefaults.standard.removeObject(forKey: "code")
                        fetching = false
                    } else {
                        self.browser = tempBrowser
                        self.browser?.setup = true
                        fetching = false
                    }
                } catch {
                    self.browser = nil
                    fetching = false
                    print(error)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "server")
                UserDefaults.standard.removeObject(forKey: "code")
                fetching = false
            }
        }
    }
}

extension Color {
    static let label: Color = Color(uiColor: UIColor.label)
    static let background: Color = Color.black
    static let listBackground: Color = Color.gray.opacity(0.4)
}
