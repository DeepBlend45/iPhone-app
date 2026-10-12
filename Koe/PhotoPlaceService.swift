import Photos
import CoreLocation

struct PhotoPlace: Identifiable {
    let id = UUID()
    var name: String
    var count: Int
    var first: Date
    var last: Date
}

/// その日に撮った写真の位置情報から、行った場所を出す（写真は読むだけ）
enum PhotoPlaceService {
    static var status: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    static func requestAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    static func places(on day: Date) async -> [PhotoPlace] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        // 近い場所（約300m以内）の写真を1か所にまとめる
        struct Cluster { var center: CLLocation; var count: Int; var first: Date; var last: Date }
        var clusters: [Cluster] = []
        PHAsset.fetchAssets(with: options).enumerateObjects { asset, _, _ in
            guard let location = asset.location, let date = asset.creationDate else { return }
            if let i = clusters.firstIndex(where: { $0.center.distance(from: location) < 300 }) {
                clusters[i].count += 1
                clusters[i].last = date
            } else {
                clusters.append(Cluster(center: location, count: 1, first: date, last: date))
            }
        }

        var result: [PhotoPlace] = []
        for cluster in clusters.prefix(10) {   // 住所検索には回数制限があるので上限を設ける
            let name = await PlaceNamer.name(for: cluster.center) ?? "場所名を取得できませんでした"
            result.append(PhotoPlace(name: name, count: cluster.count, first: cluster.first, last: cluster.last))
        }
        return result
    }
}
