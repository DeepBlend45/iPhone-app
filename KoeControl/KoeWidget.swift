import SwiftUI
import WidgetKit
import AppIntents

/// ホーム画面のウィジェット。「記録」と「カレンダー」をボタンで選べる
struct KoeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.atsuya.koe.Widget", provider: KoeProvider()) { _ in
            KoeWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Koe")
        .description("ワンタップで声の記録を始めたり、カレンダーを開いたりします")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct KoeEntry: TimelineEntry {
    let date: Date
}

struct KoeProvider: TimelineProvider {
    func placeholder(in context: Context) -> KoeEntry { KoeEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (KoeEntry) -> Void) {
        completion(KoeEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<KoeEntry>) -> Void) {
        // 表示は変わらないので、明日0時に更新すれば足りる
        let tomorrow = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [KoeEntry(date: .now)], policy: .after(tomorrow)))
    }
}

struct KoeWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) { buttons }
        default:
            VStack(spacing: 8) { buttons }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button(intent: StartRecordingIntent()) {
            actionLabel("mic.fill", "記録", .red)
        }
        Button(intent: OpenCalendarIntent()) {
            actionLabel("calendar", "カレンダー", .blue)
        }
    }

    private func actionLabel(_ icon: String, _ title: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.caption.bold())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.gradient, in: .rect(cornerRadius: 16))
    }
}
