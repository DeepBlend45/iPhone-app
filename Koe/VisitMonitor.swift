import CoreLocation
import SwiftData
import Observation
import UIKit

/// 訪問検知。iOS が「ある場所に滞在した」と判断したときだけ通知され、バッテリーへの影響は小さい。
/// バックグラウンドで動かすため「常に許可」が必要。記録は端末内にだけ保存する。
@Observable @MainActor
final class VisitMonitor: NSObject, CLLocationManagerDelegate {
    static let shared = VisitMonitor()

    private let manager = CLLocationManager()
    private(set) var status: CLAuthorizationStatus = .notDetermined
    private var wantsAlways = false

    override init() {
        super.init()
        manager.delegate = self
        status = manager.authorizationStatus
    }

    /// アプリ起動時に呼ぶ。バックグラウンドからの再起動でも、通知を受け取れるようにする
    func start() {
        if status == .authorizedAlways { manager.startMonitoringVisits() }
    }

    func requestAuthorization() {
        wantsAlways = true
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        Task { @MainActor in self.authorizationChanged(newStatus) }
    }

    private func authorizationChanged(_ newStatus: CLAuthorizationStatus) {
        status = newStatus
        if newStatus == .authorizedWhenInUse && wantsAlways {
            manager.requestAlwaysAuthorization()   // 「使用中のみ」の次に「常に」を聞く
        }
        if newStatus == .authorizedAlways { manager.startMonitoringVisits() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        let arrival = visit.arrivalDate, departure = visit.departureDate, coordinate = visit.coordinate
        Task { @MainActor in await self.record(arrival: arrival, departure: departure, coordinate: coordinate) }
    }

    private func record(arrival: Date, departure: Date, coordinate: CLLocationCoordinate2D) async {
        let arrivalDate = arrival == .distantPast ? Date.now : arrival   // 到着時刻が不明なときは受信時刻
        let departureDate: Date? = departure == .distantFuture ? nil : departure
        let context = ModelContext(Persistence.container)

        // 同じ到着の記録があれば、出発時刻だけ更新する（iOS は到着時と出発時に2回通知する）
        let descriptor = FetchDescriptor<VisitRecord>(predicate: #Predicate { $0.arrivalDate == arrivalDate })
        if let existing = try? context.fetch(descriptor).first {
            existing.departureDate = departureDate
        } else {
            context.insert(VisitRecord(arrivalDate: arrivalDate, departureDate: departureDate,
                                       latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
        try? context.save()
    }
}
