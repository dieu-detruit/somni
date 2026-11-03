import Foundation
import HealthKit
import Combine
import SomnioCore

@MainActor
final class HealthSleepReader: ObservableObject {
    @Published var loading = false
    @Published var message: String?
    private let healthStore = HKHealthStore()

    func refresh(nightID: String, store: AppStore) async {
        guard !loading else { return }
        guard HKHealthStore.isHealthDataAvailable() else { message = "この端末ではヘルスケアを利用できません。音と朝の記録は使えます。"; return }
        guard let window = Night.sleepWindow(for: nightID) else { return }
        loading = true; message = nil
        defer { loading = false }
        do {
            let converted = try await query(window: window)
            let fetchedAt = Date()
            let preferred = SleepSummary.preferred(samples: converted, fetchedAt: fetchedAt, window: window)
            let sourceIDs = Set(converted.map(\.sourceID))
            let summaries = sourceIDs.map { SleepSummary(samples: converted, sourceID: $0, fetchedAt: fetchedAt, window: window) }
                .filter { $0.totalSleep > 0 }.sorted { $0.sourceName < $1.sourceName }
            let priorSource = store.sleep(for: nightID)?.selectedSourceID
            let selected = summaries.contains { $0.sourceID == priorSource } ? priorSource : preferred?.sourceID
            store.setSleep(NightSleepRecord(id: nightID, summaries: summaries, selectedSourceID: selected, fetchedAt: fetchedAt))
            if preferred == nil { message = "睡眠データを取得できませんでした。Watchの同期後に再取得できます。読み取りが許可されていない場合も同じ表示になります。" }
        } catch { message = "睡眠記録を取得できませんでした。\(error.localizedDescription)" }
    }

    func export(range: ExportDateRange) async -> HealthExportResult {
        let queriedAt = Date()
        guard HKHealthStore.isHealthDataAvailable() else {
            return HealthExportResult(coverage: HealthCoverage(range: range, queriedAt: queriedAt, status: .unavailable, sampleCount: 0), samples: [])
        }
        do {
            let window = DateInterval(start: range.startInclusive, end: range.endExclusive)
            let all = try await query(window: window)
            let samples = SampleDeduplication.unique(all.filter { range.overlaps(start: $0.start, end: $0.end) })
            let status: HealthCoverageStatus = samples.isEmpty ? .noSamplesOrNotAuthorized : .available
            return HealthExportResult(coverage: HealthCoverage(range: range, queriedAt: queriedAt, status: status, sampleCount: samples.count), samples: samples)
        } catch {
            return HealthExportResult(coverage: HealthCoverage(range: range, queriedAt: queriedAt, status: .queryFailed,
                sampleCount: 0, errorDescription: error.localizedDescription), samples: [])
        }
    }

    private func query(window: DateInterval) async throws -> [SleepSample] {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        try await healthStore.requestAuthorization(toShare: [], read: [type])
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end, options: [])
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: (samples as? [HKCategorySample]) ?? []) }
            }
            healthStore.execute(query)
        }
        return samples.map(Self.convert)
    }

    private static func convert(_ sample: HKCategorySample) -> SleepSample {
        let stage: SleepStage
        switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
        case .inBed?: stage = .inBed
        case .awake?: stage = .awake
        case .asleepCore?: stage = .core
        case .asleepDeep?: stage = .deep
        case .asleepREM?: stage = .rem
        case .asleepUnspecified?: stage = .unspecified
        default: stage = .unrecognized
        }
        let product = sample.sourceRevision.productType ?? ""
        let watch = product.lowercased().hasPrefix("watch") || sample.device?.model?.lowercased().contains("watch") == true
        let source = sample.sourceRevision.source
        return SleepSample(id: sample.uuid.uuidString, start: sample.startDate, end: sample.endDate, stage: stage,
            sourceID: source.bundleIdentifier + ":" + product, sourceName: source.name + (watch ? " · Apple Watch" : ""), isAppleWatch: watch,
            sourceBundleIdentifier: source.bundleIdentifier, sourceVersion: sample.sourceRevision.version,
            productType: sample.sourceRevision.productType, deviceModel: sample.device?.model,
            isUserEntered: sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool, categoryValue: sample.value)
    }
}
