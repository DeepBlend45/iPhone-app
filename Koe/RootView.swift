import SwiftUI

struct RootView: View {
    @State private var showRecord = false
    @Bindable private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("履歴", systemImage: "list.bullet", value: KoeTab.history) {
                HistoryView(showRecord: $showRecord)
            }
            Tab("カレンダー", systemImage: "calendar", value: KoeTab.calendar) {
                CalendarView(showRecord: $showRecord)
            }
        }
        .sheet(isPresented: $showRecord) { RecordView() }
        // ロック画面のボタンから呼ばれたとき、どのタブにいても記録画面を出す
        .onChange(of: router.showRecord) { _, newValue in
            if newValue {
                showRecord = true
                router.showRecord = false
            }
        }
        .onAppear {
            if router.showRecord {
                showRecord = true
                router.showRecord = false
            }
        }
    }
}
