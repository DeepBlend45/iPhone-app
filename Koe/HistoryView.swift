import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showRecord = false
    private let router = AppRouter.shared

    /// 過去の年の「同じ月日」の記録
    private var onThisDay: [JournalEntry] {
        let cal = Calendar.current
        let today = cal.dateComponents([.month, .day, .year], from: .now)
        return entries.filter {
            let c = cal.dateComponents([.month, .day, .year], from: $0.createdAt)
            return c.month == today.month && c.day == today.day && c.year != today.year
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !onThisDay.isEmpty {
                    Section("過去の今日") {
                        ForEach(onThisDay) { row($0) }
                    }
                }
                Section("すべての記録") {
                    ForEach(entries) { row($0) }
                        .onDelete(perform: delete)
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("まだ記録がありません", systemImage: "mic", description: Text("右上の＋から話してみましょう"))
                }
            }
            .navigationTitle("Koe")
            .toolbar {
                Button("記録", systemImage: "plus") { showRecord = true }
            }
            .sheet(isPresented: $showRecord) { RecordView() }
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

    private func row(_ entry: JournalEntry) -> some View {
        NavigationLink {
            EntryDetailView(entry: entry)
        } label: {
            HStack(alignment: .top) {
                Text(moodEmojis[entry.mood - 1]).font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(entry.transcript.isEmpty ? "（文字起こしなし）" : entry.transcript)
                        .lineLimit(2)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let entry = entries[index]
            if let name = entry.audioFileName {
                try? FileManager.default.removeItem(at: AudioStore.url(for: name))
            }
            context.delete(entry)
        }
    }
}
