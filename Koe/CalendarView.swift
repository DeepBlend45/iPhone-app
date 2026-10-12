import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var showRecord: Bool
    @Query(sort: \JournalEntry.createdAt) private var entries: [JournalEntry]
    @State private var month = Date.now
    @State private var selectedDay: Date?
    private let cal = Calendar.current

    private var entriesByDay: [Date: [JournalEntry]] {
        Dictionary(grouping: entries) { cal.startOfDay(for: $0.createdAt) }
    }

    /// 表示中の月の日付。先頭は曜日合わせの空白(nil)
    private var cells: [Date?] {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let days = cal.range(of: .day, in: .month, for: first)!.count
        let blanks = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        return Array(repeating: nil, count: blanks)
            + (0..<days).map { cal.date(byAdding: .day, value: $0, to: first)! }
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) {
                        Text($0).font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                        if let date { dayCell(date) } else { Color.clear.frame(height: 48) }
                    }
                }
                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("記録", systemImage: "plus") { showRecord = true }
            }
            .navigationDestination(item: $selectedDay) { DayDetailView(day: $0) }
        }
    }

    private var header: some View {
        HStack {
            Button("前の月", systemImage: "chevron.left") { shiftMonth(-1) }
            Spacer()
            Text(month.formatted(.dateTime.year().month())).font(.headline)
            Spacer()
            Button("次の月", systemImage: "chevron.right") { shiftMonth(1) }
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

    private func shiftMonth(_ delta: Int) {
        month = cal.date(byAdding: .month, value: delta, to: month)!
    }
}
