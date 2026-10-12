import Foundation

/// アプリとウィジェットで共有する「記録した日」の一覧と、連続日数の計算
enum SharedStatus {
    static let groupID = "group.com.atsuya.koe"
    private static let key = "recordedDays"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    /// 記録のあった日（その日の0時）を保存する。アプリ側が書き、ウィジェットが読む
    static func save(recordedDates: [Date]) {
        let cal = Calendar.current
        let days = Set(recordedDates.map { cal.startOfDay(for: $0).timeIntervalSince1970 })
        defaults.set(Array(days), forKey: key)
    }

    static func loadDays() -> Set<Date> {
        let values = defaults.array(forKey: key) as? [Double] ?? []
        return Set(values.map { Date(timeIntervalSince1970: $0) })
    }

    /// 連続日数。今日まだ記録していなくても、昨日までの連続は途切れていない扱いにする
    static func streak(days: Set<Date>, now: Date = .now) -> (count: Int, recordedToday: Bool) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let recordedToday = days.contains(today)
        var cursor = recordedToday ? today : cal.date(byAdding: .day, value: -1, to: today)!
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return (count, recordedToday)
    }
}
