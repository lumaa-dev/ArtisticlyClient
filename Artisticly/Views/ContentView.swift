//Made by Lumaa

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
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
                do {
                    let res: CodeResponse = try await tempBrowser.get(path: "/code")
                    
                    if !res.correct {
                        UserDefaults.standard.removeObject(forKey: "code")
                    } else {
                        self.browser = tempBrowser
                        self.browser?.setup = true
                    }
                } catch {
                    self.browser = nil
                    print(error)
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
