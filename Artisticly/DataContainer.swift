//Made by Lumaa

import Foundation
import SwiftData

class DataContainer {
    @MainActor
    static let shared: DataContainer = .init()
    
    let container: ModelContainer
    let context: ModelContext
    
    @MainActor
    init() {
        self.container = try! ModelContainer(for: KnownLibrary.self)
        self.context = self.container.mainContext
    }
}
