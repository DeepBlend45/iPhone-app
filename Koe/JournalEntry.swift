import Foundation
import SwiftData

@Model
final class JournalEntry {
    var createdAt: Date
    /// 気分 1(つらい)〜5(とても良い)
    var mood: Int
    /// 文字起こし。ユーザーが修正した内容が「正」
    var transcript: String
    /// 原本の音声ファイル名（Documents/Audio 内）
    var audioFileName: String?
    /// 記録のときに使ったお題（使わなかったら nil）
    var prompt: String?

    init(createdAt: Date = .now, mood: Int, transcript: String, audioFileName: String?, prompt: String? = nil) {
        self.createdAt = createdAt
        self.mood = mood
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.prompt = prompt
    }
}

enum AudioStore {
    static var directory: URL {
        let dir = URL.documentsDirectory.appending(path: "Audio", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }
}

let moodEmojis = ["😣", "😕", "😐", "🙂", "😄"]
