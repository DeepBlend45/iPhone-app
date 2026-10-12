import AppIntents
import Observation

enum KoeTab: Hashable {
    case history, calendar
}

/// アプリ内のどこからでも「画面を切り替える」を指示するための窓口
@Observable @MainActor
final class AppRouter {
    static let shared = AppRouter()
    var showRecord = false
    var selectedTab: KoeTab = .calendar   // 起動時はカレンダーを開く
}

/// ロック画面・ウィジェットのボタンから呼ばれる。アプリを開いて記録画面を出す
struct StartRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "Koeで記録する"
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.showRecord = true
        return .result()
    }
}

/// ウィジェットのボタンから呼ばれる。アプリを開いてカレンダーを出す
struct OpenCalendarIntent: AppIntent {
    static let title: LocalizedStringResource = "Koeのカレンダーを開く"
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.selectedTab = .calendar
        return .result()
    }
}
