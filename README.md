# QuickReminder (ワンタップ・リマインダー)

ロック画面やホーム画面のウィジェットのボタンを押すだけで、
iPhone純正の「リマインダー」に「あとで確認する」を追加するアプリです。

- 対応: iOS 17 以上 / Xcode 15 以上 / Swift + SwiftUI
- ボタン: 5分後 / 1時間後 / 今夜(20:00)

## フォルダの説明

| フォルダ | 中身 | 入れる先(ターゲット) |
|---|---|---|
| `App/` | 本体アプリの画面 | QuickReminder(アプリ) |
| `Widget/` | ウィジェットの見た目 | QuickReminderWidget(ウィジェット) |
| `Shared/` | リマインダー追加の処理 | **両方** |

## セットアップ手順(Xcode)

### 1. アプリのプロジェクトを作る
1. Xcode → File → New → Project → **iOS → App**
2. Product Name: `QuickReminder` / Interface: **SwiftUI** / Language: **Swift**
3. 自動で作られた `QuickReminderApp.swift` と `ContentView.swift` を**削除**(Move to Trash)
4. このリポジトリの `App/` の2ファイルをXcodeにドラッグして追加
   (「Add to targets」は QuickReminder にチェック)
5. プロジェクト設定 → General → **Minimum Deployments を iOS 17.0** にする

### 2. ウィジェットを追加する
1. File → New → Target → **Widget Extension**
2. Product Name: `QuickReminderWidget`
   - 「Include Live Activity」「Include Control」「Include Configuration App Intent」は**全部オフ**
3. 「Activate scheme?」と出たら Activate
4. 自動生成されたウィジェット用のswiftファイルを**削除**
5. `Widget/QuickReminderWidget.swift` を追加(ターゲットは QuickReminderWidget)
6. ウィジェット側も Minimum Deployments を **iOS 17.0** にする

### 3. 共通ファイルを両方のターゲットに入れる
`Shared/` の3ファイルをXcodeに追加し、**右サイドバーの Target Membership で
QuickReminder と QuickReminderWidget の両方にチェック**を入れます。
(片方だけだと「見つからない」エラーになります)

### 4. 許可の説明文を追加する
リマインダーを使うには、なぜ必要かの説明文が必須です。
**アプリとウィジェットの両方**のターゲットで、
Info タブ → 項目を追加:

- キー: `Privacy - Reminders Full Access Usage Description`
  (`NSRemindersFullAccessUsageDescription`)
- 値: `ウィジェットのボタンからリマインダーを追加するために使います`

### 5. 実機で動かす
1. iPhoneをMacにつなぎ、Signing & Capabilities で Team に自分のApple IDを選ぶ(両ターゲット)
2. 実行先をiPhoneにして ▶ を押す
3. アプリが開いたら「許可する」→「許可」をタップ
4. ロック画面を長押し → カスタマイズ → ウィジェット → 「ワンタップ・リマインダー」を追加
5. ボタンを押して、リマインダーアプリに追加されるか確認

## うまく動かないとき
- 「許可する」を押しても何も出ない → Info.plist の説明文(手順4)を確認
- ウィジェットを押しても追加されない → 先に本体アプリで許可を済ませたか確認。
  iPhoneの 設定 → プライバシー → リマインダー でオンになっているかも確認
- `Cannot find 'ReminderService' in scope` → 手順3のTarget Membershipを確認
