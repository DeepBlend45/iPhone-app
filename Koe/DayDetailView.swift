import SwiftUI
import SwiftData
import Photos
import CoreLocation

/// カレンダーで選んだ日の、運動量と記録の一覧
struct DayDetailView: View {
    let day: Date
    @Query private var entries: [JournalEntry]
    @Query private var visits: [VisitRecord]
    @State private var photoPlaces: [PhotoPlace] = []
    @State private var photoStatus = PhotoPlaceService.status
    private let monitor = VisitMonitor.shared
    @State private var health: DayHealth?
    @State private var showRecord = false

    /// 未来の日には記録を追加できない
    private var canAdd: Bool { Calendar.current.startOfDay(for: day) <= .now }

    init(day: Date) {
        self.day = day
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        _entries = Query(
            filter: #Predicate<JournalEntry> { $0.createdAt >= start && $0.createdAt < end },
            sort: \.createdAt
        )
        let far = Date.distantFuture   // #Predicate の中では Date.distantFuture を直接使えない
        _visits = Query(
            filter: #Predicate<VisitRecord> { $0.arrivalDate < end && ($0.departureDate ?? far) >= start },
            sort: \.arrivalDate
        )
    }

    var body: some View {
        List {
            Section("この日の運動量") {
                HealthCard(health: health)
                    .padding(.vertical, 4)
                    .themedRow()
            }
            placesSection
            Section("記録") {
                if entries.isEmpty {
                    Text("この日の記録はありません").foregroundStyle(.secondary).themedRow()
                }
                ForEach(entries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        HStack(alignment: .top) {
                            Text(moodEmojis[entry.mood - 1]).font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(entry.transcript.isEmpty ? "（文字起こしなし）" : entry.transcript)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .themedRow()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .themedBackground()
        .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canAdd {
                Button("この日に記録", systemImage: "plus") { showRecord = true }
            }
        }
        .sheet(isPresented: $showRecord) { RecordView(day: day) }
        .task {
            await HealthService.shared.requestAuthorization()
            health = await HealthService.shared.summary(for: day)
        }
        .task { await loadPlaces() }
    }

    // MARK: - 場所

    @ViewBuilder
    private var placesSection: some View {
        Section("この日の場所") {
            if visits.isEmpty && photoPlaces.isEmpty {
                Text("この日の場所の記録はありません").foregroundStyle(.secondary).themedRow()
            }
            ForEach(visits) { visit in
                placeRow("mappin.circle.fill", visit.placeName ?? "場所を取得中…", visitTime(visit))
            }
            ForEach(photoPlaces) { place in
                placeRow("photo.fill", place.name, "写真\(place.count)枚 ・ " + place.first.formatted(date: .omitted, time: .shortened))
            }
            if photoStatus == .notDetermined {
                Button("写真の撮影場所を読み込む", systemImage: "photo") {
                    Task {
                        photoStatus = await PhotoPlaceService.requestAccess()
                        await loadPlaces()
                    }
                }
                .themedRow()
            } else if photoStatus == .denied || photoStatus == .restricted {
                Text("写真へのアクセスが許可されていません（設定アプリで変更できます）")
                    .font(.footnote).foregroundStyle(.secondary).themedRow()
            }
            if monitor.status != .authorizedAlways {
                Button("滞在した場所の自動記録を始める", systemImage: "location.fill") {
                    monitor.requestAuthorization()
                }
                .themedRow()
            }
        }
    }

    private func placeRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .themedRow()
    }

    private func visitTime(_ visit: VisitRecord) -> String {
        let startOfDay = Calendar.current.startOfDay(for: day)
        let from = visit.arrivalDate < startOfDay ? "前日から" : visit.arrivalDate.formatted(date: .omitted, time: .shortened)
        let to = visit.departureDate?.formatted(date: .omitted, time: .shortened) ?? "（滞在中）"
        return "\(from) 〜 \(to)"
    }

    private func loadPlaces() async {
        // 場所の名前を取れていない訪問は、ここで取り直す
        for visit in visits where visit.placeName == nil {
            visit.placeName = await PlaceNamer.name(for: CLLocation(latitude: visit.latitude, longitude: visit.longitude))
        }
        guard photoStatus == .authorized || photoStatus == .limited else { return }
        photoPlaces = await PhotoPlaceService.places(on: day)
    }
}
