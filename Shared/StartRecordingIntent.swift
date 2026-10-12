import AppIntents
import Observation

/// アプリ内のどこからでも「記録画面を開く」を指示するための窓口
@Observable @MainActor
final class AppRouter {
    static let shared = AppRouter()
    var showRecord = false
}

/// ロック画面のボタンから呼ばれる。アプリを開いて記録画面を出す
struct StartRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "Koeで記録する"
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.showRecord = true
        return .result()
    }
}
