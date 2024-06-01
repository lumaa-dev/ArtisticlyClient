//Made by Lumaa

import SwiftUI
import SwiftData
import AVFAudio

// TODO: Use Focus filters with playlists
// https://developer.apple.com/documentation/appintents/focus

@main
struct ArtisticlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: KnownLibrary.self)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)
        try? audioSession.setActive(true, options: [])
        
        MusicManager.shared.configureRemoteCommands(remoteCommandHandler: { command, event in
            MusicManager.shared.handleRemoteCommand(for: command, with: event)
        })
        
        return true
    }
}
