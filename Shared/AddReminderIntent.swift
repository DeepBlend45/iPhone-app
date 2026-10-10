import AppIntents

/// ウィジェットのボタンを押したときに実行される処理。
/// アプリを開かずに、バックグラウンドでリマインダーを追加します。
struct AddReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "リマインダーを追加"

    @Parameter(title: "いつ")
    var preset: ReminderPreset

    init() {}

    init(preset: ReminderPreset) {
        self.preset = preset
    }

    func perform() async throws -> some IntentResult {
        try ReminderService.add(title: "あとで確認する", due: preset.dueDate)
        return .result()
    }
}
