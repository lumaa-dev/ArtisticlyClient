//Made by Lumaa

import SwiftUI

struct ContentView: View {
    @State private var browser: MusicBrowser? = nil
    
    var body: some View {
        ZStack {
            if let browser = self.browser, browser.setup {
                EmptyView()
            } else {
                WelcomeView(browser: $browser)
            }
        }
        .task {
            if let tempBrowser: MusicBrowser = try? await MusicBrowser() {
//                let code = UserDefaults.standard.string(forKey: "code")
                let res: CodeResponse = await tempBrowser.get(path: "/code")
                
                if !res.correct {
                    UserDefaults.standard.removeObject(forKey: "code")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "server")
                UserDefaults.standard.removeObject(forKey: "code")
            }
        }
    }
}

#Preview {
    ContentView()
}
