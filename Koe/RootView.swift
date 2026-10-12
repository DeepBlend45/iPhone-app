import SwiftUI
import SwiftData
import WidgetKit

/// 2つの画面（カレンダー・履歴）を横に並べ、指の動きに合わせてスライドさせる
struct RootView: View {
    @Query private var entries: [JournalEntry]
    @State private var showRecord = false
    @State private var dragX: CGFloat = 0
    @State private var mode: DragMode = .undecided
    @Bindable private var router = AppRouter.shared

    private enum DragMode { case undecided, page, month, ignore }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            HStack(spacing: 0) {
                CalendarView(showRecord: $showRecord).frame(width: width, height: geo.size.height)
                HistoryView(showRecord: $showRecord).frame(width: width, height: geo.size.height)
            }
            .offset(x: (router.selectedTab == .calendar ? 0 : -width) + dragX)
            .simultaneousGesture(dragGesture(width: width))
        }
        .clipped()
        .safeAreaInset(edge: .bottom) { tabBar }
        .sheet(isPresented: $showRecord) { RecordView() }
        // ロック画面のボタンから呼ばれたとき、どちらの画面にいても記録画面を出す
        .onChange(of: router.showRecord) { _, newValue in
            if newValue {
                showRecord = true
                router.showRecord = false
            }
        }
        .onChange(of: entries.count) { syncWidget() }
        .onAppear {
            syncWidget()
            if router.showRecord {
                showRecord = true
                router.showRecord = false
            }
        }
        .animation(.spring(duration: 0.3), value: router.selectedTab)
    }

    // MARK: - タブバー

    private var tabBar: some View {
        HStack {
            tabButton("カレンダー", "calendar", .calendar)
            tabButton("履歴", "list.bullet", .history)
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    private func tabButton(_ title: String, _ icon: String, _ tab: KoeTab) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { router.selectedTab = tab }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white.opacity(router.selectedTab == tab ? 1 : 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - スワイプ

    /// 指の動きに合わせて画面を動かす。縦のスクロールは邪魔しない。
    /// カレンダーの日付マスから始めたら月の移動、それ以外から始めたら画面（タブ）の移動
    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                let dx = value.translation.width, dy = value.translation.height
                if mode == .undecided {
                    guard abs(dx) > 8 || abs(dy) > 8 else { return }
                    if abs(dx) < abs(dy) * 1.2 || router.detailOpen {
                        mode = .ignore                                   // 縦スクロール、または詳細画面の中
                    } else if router.selectedTab == .calendar && router.gridFrame.contains(value.startLocation) {
                        mode = .month
                    } else if (router.selectedTab == .calendar && dx < 0) || (router.selectedTab == .history && dx > 0) {
                        mode = .page                                     // 履歴の行の削除（左スワイプ）とは重ならない向きだけ
                    } else {
                        mode = .ignore
                    }
                }
                switch mode {
                case .page:
                    dragX = router.selectedTab == .calendar ? min(0, max(-width, dx)) : max(0, min(width, dx))
                case .month:
                    router.monthDrag = max(-width, min(width, dx))
                default:
                    break
                }
            }
            .onEnded { value in
                defer { mode = .undecided }
                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width
                switch mode {
                case .page:
                    let commit = abs(dx) > width * 0.3 || abs(predicted) > width * 0.6
                    withAnimation(.spring(duration: 0.3)) {
                        if commit { router.selectedTab = router.selectedTab == .calendar ? .history : .calendar }
                        dragX = 0
                    }
                case .month:
                    router.finishMonthDrag(dx: dx, predicted: predicted, width: width)
                default:
                    break
                }
            }
    }

    /// ウィジェットに「記録した日」を渡して、表示を更新させる
    private func syncWidget() {
        SharedStatus.save(recordedDates: entries.map(\.createdAt))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
