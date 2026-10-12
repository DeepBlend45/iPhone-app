import SwiftUI
import SwiftData
import WidgetKit

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [JournalEntry]
    @State private var showRecord = false
    @Bindable private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("カレンダー", systemImage: "calendar", value: KoeTab.calendar) {
                CalendarView(showRecord: $showRecord)
            }
            Tab("履歴", systemImage: "list.bullet", value: KoeTab.history) {
                HistoryView(showRecord: $showRecord)
            }
        }
        .sheet(isPresented: $showRecord) { RecordView() }
        // ロック画面のボタンから呼ばれたとき、どちらのタブにいても記録画面を出す
        .onChange(of: router.showRecord) { _, newValue in
            if newValue {
                showRecord = true
                router.showRecord = false
            }
        }
        .onChange(of: entries.count) { syncWidget() }
        .onAppear {
            PromptStore.seedIfNeeded(context)
            syncWidget()
            if router.showRecord {
                showRecord = true
                router.showRecord = false
            }
        }
    }

    /// ウィジェットに「記録した日」を渡して、表示を更新させる
    private func syncWidget() {
        SharedStatus.save(recordedDates: entries.map(\.createdAt))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
