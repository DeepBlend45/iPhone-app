import SwiftUI
import SwiftData

@main
struct KoeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.white)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: JournalEntry.self)
    }
}
