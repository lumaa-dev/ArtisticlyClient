//Made by Lumaa

import SwiftUI
import SwiftData

@main
struct ArtisticlyTVApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: KnownLibrary.self)
    }
}
