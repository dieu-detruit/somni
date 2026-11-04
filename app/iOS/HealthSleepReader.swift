import Foundation
import HealthKit
import Combine
import SomnioCore

@MainActor
final class HealthSleepReader: ObservableObject {
    @Published var loading = false
    @Published var message: String?
    private let healthStore = HKHealthStore()

    @Published private(set) var importedCount = 0
    private weak var store: AppStore?
    private var observer: HKObserverQuery?
    private var pendingSync = false
    private var pendingRescan = false
    private let pageLimit = 1000

    init(store: AppStore? = nil) {
        self.store = store
        store?.onSleepReset = { [weak self] in self?.stop() }
    }

    func foreground() async {
        guard let store, HKHealthStore.isHealthDataAvailable() else { return }
        if store.sleepSync.connection == .pausedAfterDeletion { return }
        if store.sleepSync.connection == .notConnected {
            do {
                let generation = store.sleepSync.generation
                let status = try await healthStore.statusForAuthorizationRequest(toShare: [], read: [sleepType])
                // This only means a request sheet is unnecessary; read permission remains unknowable.
                guard status == .unnecessary, store.sleepSync.generation == generation,
                      store.sleepSync.connection == .notConnected, store.connectSleep() else { return }
            } catch { message = "接続状態を確認できませんでした。接続ボタンから再試行できます。"; return }
        }
        startObserving()
        await synchronize()
    }

    func connect() async {
        guard let store, !loading else { return }
        guard HKHealthStore.isHealthDataAvailable() else { message = "この端末ではヘルスケアを利用できません。"; return }
        let generation = store.sleepSync.generation
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
            guard store.sleepSync.generation == generation, store.connectSleep() else { return }
            startObserving()
            await synchronize(fullRescan: true)
        } catch { message = "ヘルスケアに接続できませんでした。\(error.localizedDescription)" }
    }

    func synchronize(fullRescan: Bool = false) async {
        guard let store, store.sleepSync.connection == .enabled else { return }
        if loading { pendingSync = true; pendingRescan = pendingRescan || fullRescan; return }
        loading = true
        defer { loading = false }
        var rescan = fullRescan
        repeat {
            pendingSync = false; pendingRescan = false
            await synchronizeOnce(fullRescan: rescan)
            rescan = pendingRescan
        } while pendingSync && store.sleepSync.connection == .enabled && !Task.isCancelled
    }

    func stop() {
        if let observer { healthStore.stop(observer) }
        observer = nil; pendingSync = false; pendingRescan = false; importedCount = 0; message = nil
    }

    private var sleepType: HKCategoryType { HKObjectType.categoryType(forIdentifier: .sleepAnalysis)! }
    private func startObserving() {
        guard observer == nil else { return }
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completion, error in
            Task { @MainActor in
                defer { completion() }
                guard let self else { return }
                if let error { self.message = "睡眠の更新を確認できませんでした。\(error.localizedDescription)" }
                else { await self.synchronize() }
            }
        }
        observer = query; healthStore.execute(query)
    }

    private func synchronizeOnce(fullRescan: Bool) async {
        guard let store else { return }
        let original = store.sleepSync
        let generation = original.generation
        message = nil; importedCount = 0
        var anchor = fullRescan ? nil : original.anchor
        var indexed = Dictionary(original.samples.map { ($0.id, $0) }, uniquingKeysWith: { _, newest in newest })
        var affected = Set<String>(); var deletedIDs = Set<String>(); var added = 0; var removed = 0
        do {
            while true {
                let page = try await anchoredPage(anchorData: anchor)
                guard store.sleepSync.generation == generation, store.sleepSync.connection == .enabled else { return }
                deletedIDs.formUnion(page.deletedIDs)
                for id in page.deletedIDs {
                    if let previous = indexed.removeValue(forKey: id) { affected.formUnion(SleepNightIndex.nightKeys(for: previous)) }
                }
                for sample in page.samples where !deletedIDs.contains(sample.id) {
                    if let previous = indexed[sample.id] { affected.formUnion(SleepNightIndex.nightKeys(for: previous)) }
                    indexed[sample.id] = sample; affected.formUnion(SleepNightIndex.nightKeys(for: sample))
                }
                added += page.samples.count; removed += page.deletedIDs.count; importedCount = added
                anchor = page.anchor
                if page.samples.isEmpty && page.deletedIDs.isEmpty { break }
                try Task.checkCancellation()
            }
            guard let finalAnchor = anchor else { throw SleepSyncError.missingAnchor }
            let now = Date(); let raw = Array(indexed.values)
            let existing = SleepNightIndex.removing(deletedIDs, from: store.exportSnapshot.sleep)
            let affectedNights = affected; let addedCount = added; let removedCount = removed
            let result = await Task.detached(priority: .utility) {
                var sync = original
                sync.samples = raw.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
                sync.anchor = finalAnchor; sync.lastSyncAt = now; sync.lastBatchAddedCount = addedCount; sync.lastBatchDeletedCount = removedCount
                let nights = SleepNightIndex.rebuild(samples: sync.samples, existing: existing, affectedNights: affectedNights, fetchedAt: now)
                return (sync, nights)
            }.value
            guard store.sleepSync.generation == generation, store.sleepSync.connection == .enabled else { return }
            if store.commitSleepSync(result.0, expectedGeneration: generation, nightlyRecords: result.1, removedSampleIDs: deletedIDs) {
                message = result.0.samples.isEmpty ? "読み取れる睡眠記録はまだありません。未同期や読み取り不許可などは区別できません。許可を変更した場合は全履歴を再確認できます。" : "睡眠記録を同期しました。日中の睡眠も保存しています。"
            } else { message = store.errorMessage ?? "保存できなかったため、同期位置を進めていません。再試行してください。" }
        } catch {
            guard store.sleepSync.generation == generation else { return }
            message = "睡眠記録を同期できませんでした。保存済みの記録は残っています。\(error.localizedDescription)"
        }
    }

    private struct AnchoredPage: Sendable {
        let samples: [SleepSample]
        let deletedIDs: [String]
        let anchor: Data
    }
    private enum SleepSyncError: LocalizedError {
        case invalidAnchor, missingAnchor
        var errorDescription: String? { "同期位置を読み込めませんでした。「全履歴を再確認」で再取得できます。" }
    }
    private func anchoredPage(anchorData: Data?) async throws -> AnchoredPage {
        let anchor: HKQueryAnchor?
        if let anchorData {
            guard let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: anchorData) else { throw SleepSyncError.invalidAnchor }
            anchor = decoded
        } else { anchor = nil }
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(type: sleepType, predicate: nil, anchor: anchor, limit: pageLimit) { _, samples, deleted, nextAnchor, error in
                if let error { continuation.resume(throwing: error); return }
                do {
                    guard let nextAnchor else { throw SleepSyncError.missingAnchor }
                    let data = try NSKeyedArchiver.archivedData(withRootObject: nextAnchor, requiringSecureCoding: true)
                    let raw = (samples as? [HKCategorySample] ?? []).map(Self.convert)
                    continuation.resume(returning: AnchoredPage(samples: raw, deletedIDs: (deleted ?? []).map { $0.uuid.uuidString }, anchor: data))
                } catch { continuation.resume(throwing: error) }
            }
            healthStore.execute(query)
        }
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

    nonisolated private static func convert(_ sample: HKCategorySample) -> SleepSample {
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
