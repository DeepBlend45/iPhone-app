import CoreLocation

/// 座標から「場所の名前」を作る（住所検索。端末外の Apple のサービスに座標が送られる）
enum PlaceNamer {
    static func name(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let pm = try? await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ja_JP")).first else {
            return nil
        }
        let area = [pm.locality, pm.subLocality].compactMap { $0 }.joined()
        if let name = pm.name, !name.isEmpty, name != pm.locality {
            return area.isEmpty ? name : "\(name)（\(area)）"
        }
        return area.isEmpty ? nil : area
    }
}
