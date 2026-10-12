import SwiftUI
import WidgetKit
import AppIntents

@main
struct KoeControlBundle: WidgetBundle {
    var body: some Widget {
        RecordControl()
        KoeWidget()
    }
}

/// ロック画面・コントロールセンター・Action Buttonに置けるボタン
struct RecordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.atsuya.koe.RecordControl") {
            ControlWidgetButton(action: StartRecordingIntent()) {
                Label("Koeで記録", systemImage: "mic.fill")
            }
        }
        .displayName("Koeで記録")
        .description("タップして声の日記を始めます")
    }
}
