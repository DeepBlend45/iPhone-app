import Foundation
import SwiftData

/// 記録するときに表示する「お題」。初期のお題も自分で足したお題も、同じリストで扱う
@Model
final class PromptTemplate {
    var text: String
    var createdAt: Date

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}

enum PromptStore {
    static let defaults = [
        "今日いちばん印象に残ったことは？",
        "いま、体のどこが一番疲れている？",
        "今日、誰かに感謝したことは？",
        "明日、楽しみなことは？",
        "今日の自分に、ひとこと声をかけるなら？",
        "いま気になっていることを、3つ挙げると？",
    ]

    private static let seededKey = "promptsSeeded"

    /// 初回だけ初期のお題を入れる。あとで削除しても、勝手に復活しない
    static func seedIfNeeded(_ context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        defaults.enumerated().forEach { index, text in
            context.insert(PromptTemplate(text: text, createdAt: Date(timeIntervalSinceNow: Double(index))))
        }
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// 消してしまった初期お題を、足りない分だけ戻す
    static func restoreDefaults(_ context: ModelContext, existing: [PromptTemplate]) {
        let have = Set(existing.map(\.text))
        for text in defaults where !have.contains(text) {
            context.insert(PromptTemplate(text: text))
        }
    }
}
