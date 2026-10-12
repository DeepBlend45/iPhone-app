import SwiftUI
import SwiftData

/// カレンダーで選んだ日の、運動量と記録の一覧
struct DayDetailView: View {
    let day: Date
    @Query private var entries: [JournalEntry]
    @State private var health: DayHealth?

    init(day: Date) {
        self.day = day
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        _entries = Query(
            filter: #Predicate<JournalEntry> { $0.createdAt >= start && $0.createdAt < end },
            sort: \.createdAt
        )
    }

    var body: some View {
        List {
            Section("この日の運動量") {
                HealthCard(health: health)
                    .padding(.vertical, 4)
                    .themedRow()
            }
            Section("記録") {
                if entries.isEmpty {
                    Text("この日の記録はありません").foregroundStyle(.secondary).themedRow()
                }
                ForEach(entries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        HStack(alignment: .top) {
                            Text(moodEmojis[entry.mood - 1]).font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(entry.transcript.isEmpty ? "（文字起こしなし）" : entry.transcript)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .themedRow()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .themedBackground()
        .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await HealthService.shared.requestAuthorization()
            health = await HealthService.shared.summary(for: day)
        }
    }
}
