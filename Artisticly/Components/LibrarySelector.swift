//Made by Lumaa

import SwiftUI
import SwiftData

struct LibrarySelector: View {
    private var modelContext: ModelContext = DataContainer.shared.context
    @State var browser: MusicBrowser
    
    @State private var libraries: [KnownLibrary] = []
    @State private var onlineLibraries: [KnownLibrary] = []
    private var offlineLibraries: [KnownLibrary] {
        libraries.filter({ !onlineLibraries.contains($0) })
    }
    
    init(browser: MusicBrowser, onChangeLibrary: @escaping (MusicBrowser) -> Void) {
        self.browser = browser
        self.libraries = (try? modelContext.fetch(FetchDescriptor<KnownLibrary>())) ?? []
        self.onChangeLibrary = onChangeLibrary
        
//        self.checkup()
    }
    
    private func checkup() {
        Task {
            for library in libraries {
                let tempBrowser = await MusicBrowser(url: library.url)
                if tempBrowser.online {
                    print("lib of \(tempBrowser.name)")
                    self.onlineLibraries.append(library)
                }
            }
        }
        print(self.offlineLibraries)
    }
    
    var onChangeLibrary: (MusicBrowser) -> Void
    
    var body: some View {
        Menu {
            if self.libraries.count <= 0 {
                Text("no.alts")
            } else {
                ForEach(self.libraries, id: \.self) { lib in
                    Button {
                        Task {
                            let tempBrowser = await MusicBrowser(url: lib.url)
                            if tempBrowser.online {
                                onChangeLibrary(tempBrowser)
                            } else {
                                print("Unavailable browser")
                            }
                        }
                    } label: {
                        if browser.url == lib.url {
                            Label(lib.label, systemImage: "checkmark")
                        } else {
                            Text(lib.label)
                        }
                    }
                    
                    if lib.personal {
                        Divider()
                    }
                }
                
                Divider()
                
                Button {
                    self.browser.setup = false
                } label: {
                    Label("add.server", systemImage: "plus.circle")
                }
                
//                if offlineLibraries.count > 0 {
//                    if offlineLibraries.count != onlineLibraries.count {
//                        Divider()
//                    }
//                    
//                    Text("offline.libs-\(offlineLibraries.count)")
//                }
            }
        } label: {
            Label("alt.servers", systemImage: "server.rack")
        }
        .modelContainer(DataContainer.shared.container)
        .modelContext(DataContainer.shared.context)
        .environment(\.modelContext, DataContainer.shared.context)
    }
}

@Model
class KnownLibrary: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let url: URL
    let code: String
    let personal: Bool
    
    var label: String {
        return self.personal ? String(localized:"song.my-list") : String(localized:"song.list-\(self.name)")
    }
    
    init(name: String, url: URL, code: String, personal: Bool = false) {
        self.name = name
        self.url = url
        self.code = code
        self.personal = personal
    }
    
    static func defineAsCurrent(name: String) -> KnownLibrary {
        let new: KnownLibrary = .init(name: name, url: URL(string: UserDefaults.standard.string(forKey: "server") ?? "")!, code: UserDefaults.standard.string(forKey: "code") ?? "")
        return new
    }
}
