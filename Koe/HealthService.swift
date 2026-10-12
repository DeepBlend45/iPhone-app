import HealthKit

/// ある1日の運動量のまとめ。データが無い項目は nil
struct DayHealth {
    var sleep: TimeInterval?
    var steps: Double?
    var distanceMeters: Double?
}

/// HealthKit から睡眠・歩数・歩行距離を「読むだけ」。書き込みや外部送信はしない
final class HealthService {
    static let shared = HealthService()
    private let store = HKHealthStore()
    private let stepType = HKQuantityType(.stepCount)
    private let distanceType = HKQuantityType(.distanceWalkingRunning)
    private let sleepType = HKCategoryType(.sleepAnalysis)

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: [], read: [stepType, distanceType, sleepType])
    }

    func summary(for day: Date) async -> DayHealth {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        async let steps = sum(stepType, unit: .count(), from: start, to: end)
        async let distance = sum(distanceType, unit: .meter(), from: start, to: end)
        async let sleep = sleepDuration(endingOn: start)
        return await DayHealth(sleep: sleep, steps: steps, distanceMeters: distance)
    }

    /// 合計値。複数デバイス（iPhone/Watch）の重複は HealthKit 側で除かれる
    private func sum(_ type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum
        )
        let stats = try? await descriptor.result(for: store)
        return stats?.sumQuantity()?.doubleValue(for: unit)
    }

    /// その日の朝に終わる睡眠（前日18時〜当日14時）の合計。重なった区間は二重に数えない
    private func sleepDuration(endingOn dayStart: Date) async -> TimeInterval? {
        let cal = Calendar.current
        let windowStart = cal.date(byAdding: .hour, value: -6, to: dayStart)!
        let windowEnd = cal.date(byAdding: .hour, value: 14, to: dayStart)!
        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: windowEnd)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        guard let samples = try? await descriptor.result(for: store) else { return nil }

        let asleep: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        var total: TimeInterval = 0
        var currentEnd: Date?
        for sample in samples where asleep.contains(sample.value) {
            var start = sample.startDate
            if let end = currentEnd, start < end { start = end }   // 重なり分を除く
            if sample.endDate > start {
                total += sample.endDate.timeIntervalSince(start)
                currentEnd = sample.endDate
            }
        }
        return total > 0 ? total : nil
    }
}
