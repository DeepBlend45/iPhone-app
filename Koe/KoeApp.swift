import SwiftUI
import SwiftData

@main
struct KoeApp: App {
    init() {
        Task { @MainActor in VisitMonitor.shared.start() }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.white)
                .preferredColorScheme(.dark)
        }
        .modelContainer(Persistence.container)
    }
}
