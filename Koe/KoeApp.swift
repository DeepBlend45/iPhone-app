import SwiftUI
import SwiftData

@main
struct KoeApp: App {
    var body: some Scene {
        WindowGroup {
            HistoryView()
        }
        .modelContainer(for: JournalEntry.self)
    }
}
