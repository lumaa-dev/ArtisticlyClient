//Made by Lumaa

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var browser: MusicBrowser?
    @State private var initBrowser: MusicBrowser?
    @Query private var libraries: [KnownLibrary] = []
    
    @State private var serverUrl: String = "http://localhost:3000"
    @State private var acceptable: Bool = false
    @State private var code: String = "Artisticly"
    
    @State private var errStr: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                if errStr != nil {
                    Section(header: Text("error")) {
                        Text(errStr!)
                            .font(.headline)
                            .bold()
                            .lineLimit(2)
                            .foregroundStyle(Color.red)
                    }
                }
                
                Section {
                    TextField("input.server.url", text: $serverUrl)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    if !acceptable {
                        Button {
                            if let url = URL(string: serverUrl.lowercased()) {
                                Task {
                                    let tempBrowser = await MusicBrowser(url: url)
                                    
                                    if tempBrowser.online {
                                        tempBrowser.isPersonal(self.initBrowser == nil)
                                        self.browser = tempBrowser
                                        
                                        withAnimation {
                                            acceptable = true
                                        }
                                    } else {
                                        errStr = String(localized: "error.url-not-server")
                                    }
                                }
                            } else {
                                errStr = String(localized: "error.nonconforming-url")
                            }
                        } label: {
                            Text("server.verify")
                        }
                        .disabled(serverUrl.isEmpty || !serverUrl.lowercased().hasPrefix("http"))
                    } else {
                        if initBrowser == nil {
                            TextField("input.code", text: $code)
                                .keyboardType(.asciiCapable)
                        }
                        
                        Button {
                            guard let browser = self.browser else { return }
                            
                            Task {
                                do {
                                    let res: CodeResponse = try await browser.get(path: "/code", credential: code)
                                    
                                    if !res.correct {
                                        code = ""
                                        errStr = String(localized: "error.incorrect-code")
                                    } else {
                                        UserDefaults.standard.setValue(serverUrl, forKey: "server")
                                        UserDefaults.standard.setValue(initBrowser == nil ? code : "N/A-ArtisticlyCode", forKey: "code")
                                        
                                        browser.setup = true
                                        
                                        let known: KnownLibrary = .init(name: browser.name, url: browser.url, code: code, personal: browser.personal)
                                        
                                        modelContext.insert(known)
                                        
                                        print("Setup succeeded")
                                    }
                                } catch {
                                    code = ""
                                    errStr = String(localized: "error.unknown")
                                    print(error)
                                }
                            }
                        } label: {
                            Text("start.app")
                        }
                    }
                }
            }
            .navigationTitle(Text("welcome.user"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                initBrowser = self.browser
            }
        }
    }
}

#Preview {
    WelcomeView(browser: .constant(.none))
}
