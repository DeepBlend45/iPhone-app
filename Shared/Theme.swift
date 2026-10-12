import SwiftUI
import UIKit

/// アプリアイコンの色（藍 → 珊瑚）を、アプリとウィジェットで共通に使う
enum Theme {
    static let indigo = Color(red: 38 / 255, green: 36 / 255, blue: 110 / 255)
    static let coral = Color(red: 255 / 255, green: 122 / 255, blue: 89 / 255)

    /// アイコンと同じ斜めのグラデーション
    static let gradient = LinearGradient(colors: [indigo, coral], startPoint: .topLeading, endPoint: .bottomTrailing)

    /// ダークモードでも読める明るさの藍（文字・アイコン用）
    static let indigoText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.60, blue: 0.98, alpha: 1)
            : UIColor(red: 38 / 255, green: 36 / 255, blue: 110 / 255, alpha: 1)
    })
}
