import AppIntents
import Observation
import SwiftUI

enum KoeTab: Hashable {
    case history, calendar
}

/// アプリ内のどこからでも「画面を切り替える」を指示するための窓口。
/// スワイプ操作の状態（指に合わせて動かす量など）もここで共有する
@Observable @MainActor
final class AppRouter {
    static let shared = AppRouter()
    var showRecord = false
    var selectedTab: KoeTab = .calendar   // 起動時はカレンダーを開く

    // カレンダー
    var month = Date.now
    /// 月のスワイプ中、指に合わせて動かす量
    var monthDrag: CGFloat = 0
    /// カレンダーの日付マスの範囲（画面全体の座標）。ここから始めたスワイプは月の移動になる
    var gridFrame: CGRect = .zero

    // 詳細画面を開いている間は、タブのスワイプを止める
    var calendarPushed = false
    var historyPushed = false
    var detailOpen: Bool { selectedTab == .calendar ? calendarPushed : historyPushed }

    func shiftMonth(_ delta: Int) {
        withAnimation {
            month = Calendar.current.date(byAdding: .month, value: delta, to: month)!
        }
    }

    /// 月のスワイプを離したとき。十分動かしていれば、画面外へ流してから次の月を反対側から滑り込ませる
    func finishMonthDrag(dx: CGFloat, predicted: CGFloat, width: CGFloat) {
        guard abs(dx) > width * 0.25 || abs(predicted) > width * 0.5 else {
            withAnimation(.spring(duration: 0.3)) { monthDrag = 0 }
            return
        }
        let direction: CGFloat = dx < 0 ? 1 : -1      // 左へスワイプ = 次の月
        withAnimation(.easeOut(duration: 0.18)) { monthDrag = -direction * width }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            var noAnimation = Transaction()
            noAnimation.disablesAnimations = true
            withTransaction(noAnimation) {
                month = Calendar.current.date(byAdding: .month, value: Int(direction), to: month)!
                monthDrag = direction * width
            }
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.easeOut(duration: 0.22)) { monthDrag = 0 }
        }
    }
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
