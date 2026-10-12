import SwiftUI

/// 睡眠・歩数・歩行距離を横に並べて一目で見せる
struct HealthCard: View {
    let health: DayHealth?

    var body: some View {
        HStack {
            item("bed.double.fill", .white, sleepText, "睡眠")
            Divider()
            item("figure.walk", .white, stepsText, "歩数")
            Divider()
            item("point.topleft.down.to.point.bottomright.curvepath", .white, distanceText, "歩行距離")
        }
        .frame(maxWidth: .infinity)
    }

    private func item(_ icon: String, _ color: Color, _ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.headline).minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var sleepText: String {
        guard let sleep = health?.sleep else { return "—" }
        let minutes = Int(sleep / 60)
        return "\(minutes / 60)時間\(minutes % 60)分"
    }

    private var stepsText: String {
        guard let steps = health?.steps else { return "—" }
        return "\(Int(steps).formatted())歩"
    }

    private var distanceText: String {
        guard let meters = health?.distanceMeters else { return "—" }
        return String(format: "%.1f km", meters / 1000)
    }
}
