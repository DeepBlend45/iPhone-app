import SwiftUI
import WidgetKit
import AppIntents

/// ホーム画面のウィジェット。「記録」と「カレンダー」をボタンで選べる
struct KoeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.atsuya.koe.Widget", provider: KoeProvider()) { entry in
            KoeWidgetView(entry: entry)
                .containerBackground(Theme.gradient, for: .widget)
        }
        .configurationDisplayName("Koe")
        .description("ワンタップで声の記録を始めたり、カレンダーを開いたりします")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct KoeEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let recordedToday: Bool

    init(date: Date) {
        self.date = date
        let result = SharedStatus.streak(days: SharedStatus.loadDays(), now: date)
        streak = result.count
        recordedToday = result.recordedToday
    }
}

struct KoeProvider: TimelineProvider {
    func placeholder(in context: Context) -> KoeEntry { KoeEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (KoeEntry) -> Void) {
        completion(KoeEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<KoeEntry>) -> Void) {
        // 日付が変わった瞬間に「今日は未記録」へ切り替えるため、明日0時の分も用意する
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        let entries = [KoeEntry(date: .now), KoeEntry(date: midnight.addingTimeInterval(1))]
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(60))))
    }
}

struct KoeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KoeEntry

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) {
                status
                VStack(spacing: 8) { buttons }
            }
        default:
            VStack(spacing: 8) {
                status
                HStack(spacing: 8) { buttons }
            }
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("\(entry.streak)日連続", systemImage: "flame.fill")
                .font(.system(family == .systemMedium ? .title : .title3, design: .rounded, weight: .heavy))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(.white)
            Label(entry.recordedToday ? "今日は記録済み" : "今日はまだ",
                  systemImage: entry.recordedToday ? "checkmark.circle.fill" : "circle")
                .font(family == .systemMedium ? .title3.bold() : .subheadline.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(.white.opacity(entry.recordedToday ? 1 : 0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var buttons: some View {
        Button(intent: StartRecordingIntent()) {
            actionLabel("mic.fill", "記録")
        }
        .buttonStyle(.plain)
        Button(intent: OpenCalendarIntent()) {
            actionLabel("calendar", "カレンダー")
        }
        .buttonStyle(.plain)
    }

    /// 半透明の白地に白い文字（グラデーション背景の上で読みやすい）
    private func actionLabel(_ icon: String, _ title: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.title3)
            Text(title).font(.caption2.bold())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.22), in: .rect(cornerRadius: 12))
    }
}
