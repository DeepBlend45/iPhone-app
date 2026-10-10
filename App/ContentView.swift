import SwiftUI

/// 本体アプリの画面。役割は「リマインダーの許可をもらう」ことだけ。
struct ContentView: View {
    @State private var authorized = ReminderService.isAuthorized
    @State private var testMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: authorized ? "checkmark.circle.fill" : "bell.badge")
                .font(.system(size: 60))
                .foregroundStyle(authorized ? .green : .orange)

            Text(authorized ? "準備OK!" : "リマインダーの許可が必要です")
                .font(.headline)

            if authorized {
                Text("ロック画面やホーム画面にウィジェットを追加して使ってください。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("テスト: 1分後のリマインダーを追加") {
                    do {
                        try ReminderService.add(title: "テスト", due: Date().addingTimeInterval(60))
                        testMessage = "追加しました。リマインダーアプリを確認してみましょう。"
                    } catch {
                        testMessage = "失敗しました: \(error)"
                    }
                }
                .buttonStyle(.bordered)

                Text(testMessage).font(.footnote)
            } else {
                Button("許可する") {
                    Task { authorized = await ReminderService.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
