import AppIntents
import SwiftUI
import WidgetKit

// MARK: - データ(このウィジェットは表示内容が変わらないので中身は空)

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .never))
    }
}

// MARK: - 見た目

struct QuickReminderWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // 丸型: 1つだけボタンを置く
            Button(intent: AddReminderIntent(preset: .oneHour)) {
                Image(systemName: "bell.badge.plus")
            }
        default:
            // 長方形(ロック画面)・ホーム画面: 3つのボタンを横に並べる
            VStack(alignment: .leading, spacing: 6) {
                Label("あとで確認", systemImage: "bell")
                    .font(.caption.bold())
                HStack {
                    ForEach([ReminderPreset.fiveMinutes, .oneHour, .tonight], id: \.self) { preset in
                        Button(intent: AddReminderIntent(preset: preset)) {
                            Text(preset.label).font(.caption2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ウィジェット本体

struct QuickReminderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickReminderWidget", provider: Provider()) { _ in
            QuickReminderWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ワンタップ・リマインダー")
        .description("ボタンを押すだけでリマインダーを追加します。")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .systemSmall, .systemMedium])
    }
}

@main
struct QuickReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickReminderWidget()
    }
}
