//Made by Lumaa

import SwiftUI

struct ContentView: View {
    @State private var browser: MusicBrowser? = nil
    
    var body: some View {
        ZStack {
            if let browser = self.browser, browser.setup {
                SongList(browser: browser)
            } else {
                WelcomeView(browser: $browser)
            }
        }
        .task {
            if let tempBrowser: MusicBrowser = try? await MusicBrowser() {
                let res: CodeResponse = await tempBrowser.get(path: "/code")
                
                if !res.correct {
                    UserDefaults.standard.removeObject(forKey: "code")
                } else {
                    self.browser = tempBrowser
                    self.browser?.setup = true
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "server")
                UserDefaults.standard.removeObject(forKey: "code")
            }
        }
    }
}

extension Color {
    static let label: Color = Color(uiColor: UIColor.label)
    static let background: Color = Color(uiColor: UIColor.systemBackground)
    static let listBackground: Color = Color(uiColor: UIColor.systemGroupedBackground)
}

#Preview {
    ContentView()
}
