import SwiftUI
import SwiftData
import Charts

struct CalendarView: View {
    @Binding var showRecord: Bool
    @Query(sort: \JournalEntry.createdAt) private var entries: [JournalEntry]
    @State private var selectedDay: Date?
    @State private var pageWidth: CGFloat = 400
    @State private var dragMode: DragMode = .undecided
    private let router = AppRouter.shared
    private let cal = Calendar.current

    private var month: Date { router.month }

    private enum DragMode { case undecided, month, tab, ignore }

    private var entriesByDay: [Date: [JournalEntry]] {
        Dictionary(grouping: entries) { cal.startOfDay(for: $0.createdAt) }
    }

    /// 表示中の月の日付。先頭は曜日合わせの空白(nil)
    private var cells: [Date?] {
        let first = monthStart
        let days = cal.range(of: .day, in: .month, for: first)!.count
        let blanks = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        return Array(repeating: nil, count: blanks)
            + (0..<days).map { cal.date(byAdding: .day, value: $0, to: first)! }
    }

    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: month))!
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    // 月のスワイプ中は、日付・サマリー・グラフが指に合わせて動く
                    VStack(spacing: 16) {
                        grid
                        MonthSummary(monthStart: monthStart, entriesByDay: entriesByDay)
                        MoodChart(monthStart: monthStart, entriesByDay: entriesByDay)
                    }
                    .offset(x: router.monthDrag)
                    .opacity(1 - min(abs(router.monthDrag) / 500, 0.6))
                }
                .padding()
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
            .simultaneousGesture(swipeGesture)
            .themedBackground()
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("記録", systemImage: "plus") { showRecord = true }
            }
            .navigationDestination(item: $selectedDay) { DayDetailView(day: $0) }
        }
    }

    /// 日付マスから始めた横スワイプは、月が指についてくる。それ以外の左スワイプは、履歴タブへ
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                let dx = value.translation.width, dy = value.translation.height
                if dragMode == .undecided {
                    guard abs(dx) > 8 || abs(dy) > 8 else { return }
                    if abs(dx) < abs(dy) * 1.2 {
                        dragMode = .ignore                       // 縦スクロール
                    } else if router.gridFrame.contains(value.startLocation) {
                        dragMode = .month
                    } else {
                        dragMode = .tab
                    }
                }
                if dragMode == .month {
                    router.monthDrag = max(-pageWidth, min(pageWidth, dx))
                }
            }
            .onEnded { value in
                defer { dragMode = .undecided }
                let dx = value.translation.width
                switch dragMode {
                case .month:
                    router.finishMonthDrag(dx: dx, predicted: value.predictedEndTranslation.width, width: pageWidth)
                case .tab where dx < -60:
                    router.selectedTab = .history
                default:
                    break
                }
            }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) {
                Text($0).font(.caption).foregroundStyle(.secondary)
            }
            ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                if let date { dayCell(date) } else { Color.clear.frame(height: 48) }
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { router.gridFrame = $0 }
    }

    private var header: some View {
        HStack {
            Button("前の月", systemImage: "chevron.left") { router.shiftMonth(-1) }
            Spacer()
            Text(month.formatted(.dateTime.year().month())).font(.headline)
            Spacer()
            Button("次の月", systemImage: "chevron.right") { router.shiftMonth(1) }
        }
        .labelStyle(.iconOnly)
    }

    private func dayCell(_ date: Date) -> some View {
        let dayEntries = entriesByDay[date] ?? []
        let isToday = cal.isDateInToday(date)
        return Button {
            selectedDay = date
        } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: date))")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .fontWeight(isToday ? .bold : .regular)
                if dayEntries.isEmpty {
                    Text(" ").font(.title3)
                } else {
                    let avg = Double(dayEntries.map(\.mood).reduce(0, +)) / Double(dayEntries.count)
                    Text(moodEmojis[Int(avg.rounded()) - 1]).font(.title3)   // その日の気分の平均
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white.opacity(isToday ? 0.32 : 0.12), in: .rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 今月のサマリー

private struct MonthSummary: View {
    let monthStart: Date
    let entriesByDay: [Date: [JournalEntry]]
    private let cal = Calendar.current

    var body: some View {
        let allDays = Set(entriesByDay.keys)
        let monthDays = allDays.filter { cal.isDate($0, equalTo: monthStart, toGranularity: .month) }
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)!.count
        let moods = monthDays.flatMap { entriesByDay[$0] ?? [] }.map(\.mood)
        let average = moods.isEmpty ? nil : Double(moods.reduce(0, +)) / Double(moods.count)

        HStack(spacing: 8) {
            tile("\(monthDays.count)/\(daysInMonth)日", "記録した日")
            tile("\(SharedStatus.streak(days: allDays).count)日", "連続")
            tile("\(SharedStatus.longestStreak(days: allDays))日", "最長連続")
            tile(average.map { moodEmojis[Int($0.rounded()) - 1] + String(format: "%.1f", $0) } ?? "—", "気分の平均")
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.18), in: .rect(cornerRadius: 12))
    }
}

// MARK: - 気分の推移

private struct MoodChart: View {
    let monthStart: Date
    let entriesByDay: [Date: [JournalEntry]]
    private let cal = Calendar.current

    private struct Point: Identifiable {
        let date: Date
        let mood: Double
        var id: Date { date }
    }

    private var points: [Point] {
        entriesByDay
            .filter { cal.isDate($0.key, equalTo: monthStart, toGranularity: .month) }
            .map { Point(date: $0.key, mood: Double($0.value.map(\.mood).reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("気分の推移").font(.subheadline.bold())
            if points.isEmpty {
                Text("この月の記録はありません").font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(points) { point in
                    LineMark(x: .value("日付", point.date, unit: .day), y: .value("気分", point.mood))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.white)
                    PointMark(x: .value("日付", point.date, unit: .day), y: .value("気分", point.mood))
                        .foregroundStyle(.white)
                }
                .chartYScale(domain: 0.5...5.5)
                .chartXScale(domain: monthStart...cal.date(byAdding: .month, value: 1, to: monthStart)!)
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5]) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.25))
                        AxisValueLabel {
                            if let v = value.as(Int.self) { Text(moodEmojis[v - 1]) }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.25))
                        AxisValueLabel(format: .dateTime.day()).foregroundStyle(.white)
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.18), in: .rect(cornerRadius: 12))
    }
}
