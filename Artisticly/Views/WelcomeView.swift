//Made by Lumaa

import SwiftUI

struct WelcomeView: View {
    @Binding var browser: MusicBrowser?
    
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
                        TextField("input.code", text: $code)
                            .keyboardType(.asciiCapable)
                        
                        Button {
                            guard let browser = self.browser else { return }
                            
                            Task {
                                let res: CodeResponse = await browser.get(path: "/code", credential: code)
                                
                                if !res.correct {
                                    code = ""
                                    errStr = String(localized: "error.incorrect-code")
                                } else {
                                    UserDefaults.standard.setValue(serverUrl, forKey: "server")
                                    UserDefaults.standard.setValue(code, forKey: "code")
                                    browser.setup = true
                                    print("Setup succeeded")
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
        }
    }
}

#Preview {
    WelcomeView(browser: .constant(.none))
}
