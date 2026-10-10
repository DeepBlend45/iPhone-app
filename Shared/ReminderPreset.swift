import AppIntents
import Foundation

/// ウィジェットのボタンに対応する「いつ通知するか」のプリセット。
/// AppEnum にすると、AppIntent の引数として使えるようになります。
enum ReminderPreset: String, AppEnum {
    case fiveMinutes
    case oneHour
    case tonight

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "いつ"

    static let caseDisplayRepresentations: [ReminderPreset: DisplayRepresentation] = [
        .fiveMinutes: "5分後",
        .oneHour: "1時間後",
        .tonight: "今夜",
    ]

    /// ボタンに表示する短い文字
    var label: String {
        switch self {
        case .fiveMinutes: return "5分後"
        case .oneHour: return "1時間後"
        case .tonight: return "今夜"
        }
    }

    /// ボタンを押した時点から計算した通知日時
    var dueDate: Date {
        let now = Date()
        let calendar = Calendar.current
        switch self {
        case .fiveMinutes:
            return now.addingTimeInterval(5 * 60)
        case .oneHour:
            return now.addingTimeInterval(60 * 60)
        case .tonight:
            // 今日の20:00。すでに過ぎていたら明日の20:00にする
            let today20 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
            return today20 > now ? today20 : calendar.date(byAdding: .day, value: 1, to: today20) ?? today20
        }
    }
}
