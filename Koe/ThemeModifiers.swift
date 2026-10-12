import SwiftUI

extension View {
    /// 画面全体にアイコンと同じグラデーションを敷く
    func themedBackground() -> some View {
        background(Theme.gradient.ignoresSafeArea())
    }

    /// リストの行を、半透明の白地にする（ウィジェットのボタンと同じ質感）
    func themedRow() -> some View {
        listRowBackground(Color.white.opacity(0.18))
    }
}
