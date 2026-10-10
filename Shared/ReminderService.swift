import EventKit
import Foundation

/// Apple純正の「リマインダー」アプリとやり取りする部分(EventKit)。
enum ReminderService {
    enum ReminderError: Error {
        case accessDenied
        case noDefaultList
    }

    private static let store = EKEventStore()

    /// リマインダーへのアクセス許可をユーザーにお願いする(初回だけ確認ダイアログが出る)
    static func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToReminders()) ?? false
    }

    static var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }

    /// リマインダーを1件追加する
    static func add(title: String, due: Date) throws {
        guard isAuthorized else { throw ReminderError.accessDenied }
        guard let list = store.defaultCalendarForNewReminders() else {
            throw ReminderError.noDefaultList
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = list
        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: due
        )
        // 指定時刻に通知が鳴るようにアラームを付ける
        reminder.addAlarm(EKAlarm(absoluteDate: due))

        try store.save(reminder, commit: true)
    }
}
