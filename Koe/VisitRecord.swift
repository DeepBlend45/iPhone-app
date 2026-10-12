import Foundation
import SwiftData

/// iOS が検知した「ここに滞在した」の記録（訪問検知）
@Model
final class VisitRecord {
    var arrivalDate: Date
    /// まだその場所にいる間は nil
    var departureDate: Date?
    var latitude: Double
    var longitude: Double
    /// 場所の名前。住所検索に失敗したときは nil で、表示時に再取得する
    var placeName: String?

    init(arrivalDate: Date, departureDate: Date?, latitude: Double, longitude: Double, placeName: String? = nil) {
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
    }
}

/// アプリ本体と、バックグラウンドの訪問検知とで同じデータベースを使うための入口
enum Persistence {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: JournalEntry.self, VisitRecord.self, PromptTemplate.self)
        } catch {
            fatalError("データベースを開けませんでした: \(error)")
        }
    }()
}
