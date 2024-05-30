//Made by Lumaa

import Foundation

/// This class allows to browse through any Artisticly song library using its API URL.
@Observable
final class MusicBrowser {
    let url: URL
    var name: String
    var online: Bool
    var setup: Bool
    var personal: Bool = false
    
    init() async throws {
        self.url = URL(string: UserDefaults.standard.string(forKey: "server") ?? "http://localhost:3000")!
        self.name = ""
        self.online = false
        self.setup = false
        
        try? await self.refreshStatus()
    }
    
    init(url: URL) async {
        self.url = url
        self.name = ""
        self.online = false
        self.setup = false
        
        try? await self.refreshStatus()
    }
    
    func isPersonal(_ personal: Bool) {
        self.personal = personal
    }
    
    func refreshStatus() async throws {
        if let data = try? await URLSession.shared.data(from: self.url).0 {
            if let json: [String: Any] = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.online = json["artisticly"] as! Bool
                print("Artisticly server is \(self.online ? "online" : "offline")")
                if self.online {
                    self.name = json["username"] as! String
                }
            }
        }
    }
    
    func getVersions(completionHandler: (String, String) -> Void) async throws {
        guard self.online else { throw ArtisticlyError("Cannot make API calls when URL isn't Artisticly") }
        
        if let data = try? await URLSession.shared.data(from: self.url).0 {
            if let json: [String: Any] = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let versions: [String: Any] = json["versions"] as! [String: Any]
                
                completionHandler("\(versions["server"] as! Int)", versions["client"] as! String)
            }
        }
    }
    
    /// Makes a GET call to the given Artisticly URL
    func get<Entity : Decodable>(path: String = "/", queries: [URLQueryItem] = [], credential: String? = nil) async throws -> Entity {
        guard self.online else { throw ArtisticlyError("Cannot make API calls when URL isn't Artisticly") }
        
        let url = URL(string: "\(self.url.absoluteString)\(path)") ?? self.url
        var fullUrl = URLRequest(url: url.addQueries(queries))
        
        let authorization: String = credential == nil ? (UserDefaults.standard.string(forKey: "code") ?? "") : credential!
        if authorization.count > 0 {
            fullUrl.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        
        do {
            let data = try await URLSession.shared.data(for: fullUrl).0
            let decoder = JSONDecoder()
            if let string = String(data: data, encoding: .utf8) {
                print(string.count < 100 ? string : "too long")
            }
            return try decoder.decode(Entity.self, from: data)
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
    
    func get<Entity : Decodable>(_ path: String = "/", queries: [URLQueryItem] = [], credential: String? = nil) async throws -> Entity {
        return try await self.get(path: path, queries: queries, credential: credential)
    }
    
    /// Makes a POST call to the given Artisticly URL
    func post<Entity : Decodable>(path: String = "/", headers: [String: String] = [:], queries: [URLQueryItem] = [], credential: String? = nil) async throws -> Entity {
        guard self.online else { throw ArtisticlyError("Cannot make API calls when URL isn't Artisticly") }
        
        let url = URL(string: "\(self.url.absoluteString)\(path)") ?? self.url
        var fullUrl = URLRequest(url: url.addQueries(queries))
        fullUrl.httpMethod = "POST"
        
        let authorization: String = credential == nil ? (UserDefaults.standard.string(forKey: "code") ?? "") : credential!
        if authorization.count > 0 {
            fullUrl.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        
        for header in headers {
            fullUrl.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        do {
            let data = try await URLSession.shared.data(for: fullUrl).0
            let decoder = JSONDecoder()
            if let string = String(data: data, encoding: .utf8) {
                print(string.count < 100 ? string : "too long")
            }
            return try decoder.decode(Entity.self, from: data)
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
    
    func post<Entity : Decodable>(_ path: String = "/", headers: [String: String] = [:], queries: [URLQueryItem] = [], credential: String? = nil) async throws -> Entity {
        return try await self.post(path: path, headers: headers, queries: queries, credential: credential)
    }
}

struct ArtisticlyError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

extension Bool {
    func toString() -> String {
        return self ? "true" : "false"
    }
}

extension URLQueryItem {
    init(name: String, value: Bool?) {
        self.init(name: name, value: value?.toString())
    }
    
    init(name: String, value: Int?) {
        let str = value != nil ? String(value!) : nil
        self.init(name: name, value: str)
    }
}

extension URL {
    func addQueries(_ query: [URLQueryItem]) -> String {
        var stringQueries: [String] = []
        for q in query {
            guard let v = q.value else { continue }
            stringQueries.append("\(q.name)=\(v)")
        }
        let fullPath = "\(self.absoluteString)?\(stringQueries.joined(separator: "&"))"
        return fullPath
    }
    
    func addQueries(_ query: [URLQueryItem]) -> URL {
        let q: String = self.addQueries(query)
        return URL(string: q)!
    }
}
