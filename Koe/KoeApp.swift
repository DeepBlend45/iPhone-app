import SwiftUI
import SwiftData

@main
struct KoeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.coral)
        }
        .modelContainer(for: JournalEntry.self)
    }
}
