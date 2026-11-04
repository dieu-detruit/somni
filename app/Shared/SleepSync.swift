import Foundation

public enum SleepConnection: String, Codable, Sendable { case notConnected, enabled, pausedAfterDeletion }

public struct SleepSyncState: Codable, Sendable {
    public var connection: SleepConnection
    public let generation: UUID
    public var anchor: Data?
    public var samples: [SleepSample]
    public var lastSyncAt: Date?
    public var lastBatchAddedCount: Int
    public var lastBatchDeletedCount: Int
    public init(connection: SleepConnection = .notConnected) {
        self.connection = connection; generation = UUID(); samples = []; lastBatchAddedCount = 0; lastBatchDeletedCount = 0
    }
    public func applying(additions: [SleepSample], deletedIDs: Set<String>, anchor: Data, syncedAt: Date) -> Self {
        var next = self
        var indexed = Dictionary(samples.map { ($0.id, $0) }, uniquingKeysWith: { _, newest in newest })
        for id in deletedIDs { indexed.removeValue(forKey: id) }
        for sample in additions where !deletedIDs.contains(sample.id) { indexed[sample.id] = sample }
        next.samples = indexed.values.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
        next.anchor = anchor; next.lastSyncAt = syncedAt
        next.lastBatchAddedCount = additions.count; next.lastBatchDeletedCount = deletedIDs.count
        return next
    }
}

public enum SleepNightIndex {
    /// Index original intervals into every overlapping overnight window; daytime samples stay in raw storage.
    public static func nightKeys(for sample: SleepSample, calendar: Calendar = .current) -> Set<String> {
        guard sample.end > sample.start, let first = Night.window(for: Night.key(for: sample.start, calendar: calendar), calendar: calendar) else { return [] }
        var result = Set<String>(); var cursor = first.start
        while cursor < sample.end {
            let key = Night.key(for: cursor, calendar: calendar)
            if let window = Night.sleepWindow(for: key, calendar: calendar), sample.start < window.end, sample.end > window.start { result.insert(key) }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor), next > cursor else { break }
            cursor = next
        }
        return result
    }
    public static func removing(_ deletedIDs: Set<String>, from records: [NightSleepRecord]) -> [NightSleepRecord] {
        guard !deletedIDs.isEmpty else { return records }
        return records.compactMap { record in
            let hasDeleted = record.summaries.contains { $0.samples.contains { deletedIDs.contains($0.id) } }
            guard hasDeleted else { return record }
            let summaries = record.summaries.map { summary in
                SleepSummary(samples: summary.samples.filter { !deletedIDs.contains($0.id) }, sourceID: summary.sourceID, fetchedAt: summary.fetchedAt)
            }.filter { $0.totalSleep > 0 }
            guard !summaries.isEmpty else { return nil }
            let selected = summaries.contains { $0.sourceID == record.selectedSourceID } ? record.selectedSourceID : summaries.first?.sourceID
            return NightSleepRecord(id: record.id, summaries: summaries, selectedSourceID: selected, fetchedAt: record.fetchedAt)
        }
    }
    public static func rebuild(samples: [SleepSample], existing: [NightSleepRecord], affectedNights: Set<String>? = nil,
                               fetchedAt: Date, calendar: Calendar = .current) -> [NightSleepRecord] {
        if affectedNights?.isEmpty == true { return existing }
        var buckets: [String: [SleepSample]] = [:]
        for sample in samples {
            for key in nightKeys(for: sample, calendar: calendar) where affectedNights?.contains(key) ?? true { buckets[key, default: []].append(sample) }
        }
        var records = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { _, newest in newest })
        let affected = affectedNights ?? Set(buckets.keys)
        for key in affected {
            guard let raw = buckets[key], let window = Night.sleepWindow(for: key, calendar: calendar) else { records.removeValue(forKey: key); continue }
            let grouped = Dictionary(grouping: raw, by: \.sourceID)
            let summaries = grouped.map { sourceID, values in SleepSummary(samples: values, sourceID: sourceID, fetchedAt: fetchedAt, window: window) }
                .filter { $0.totalSleep > 0 }.sorted { $0.sourceID < $1.sourceID }
            guard !summaries.isEmpty else { records.removeValue(forKey: key); continue }
            let priorSource = records[key]?.selectedSourceID
            let preferred = summaries.sorted {
                if $0.isAppleWatch != $1.isAppleWatch { return $0.isAppleWatch }
                if $0.totalSleep != $1.totalSleep { return $0.totalSleep > $1.totalSleep }
                return $0.sourceID < $1.sourceID
            }.first?.sourceID
            let selected = summaries.contains { $0.sourceID == priorSource } ? priorSource : preferred
            records[key] = NightSleepRecord(id: key, summaries: summaries, selectedSourceID: selected, fetchedAt: fetchedAt)
        }
        return records.values.sorted { $0.id > $1.id }
    }
}

public extension StoredRecords {
    /// The in-memory anchor changes only after persistence accepts the complete candidate state.
    @discardableResult mutating func commitSleepSync(_ candidate: SleepSyncState, expectedGeneration: UUID,
        nightlyRecords: [NightSleepRecord]? = nil, removedSampleIDs: Set<String> = [], persist: (StoredRecords) throws -> Void) throws -> Bool {
        guard sleepSync.generation == expectedGeneration, sleepSync.connection != .pausedAfterDeletion else { return false }
        var next = self; next.sleepSync = candidate
        next.legacySleepCaches = SleepNightIndex.removing(removedSampleIDs, from: next.legacySleepCaches)
        if let nightlyRecords { next.sleep = nightlyRecords }
        try persist(next)
        self = next
        return true
    }
}

public struct SyncedSleepCoverage: Codable, Sendable {
    public let connection: SleepConnection
    public let lastSuccessfulSyncAt: Date?
    public let retainedSampleCount: Int
    public let lastBatchAddedCount: Int
    public let lastBatchDeletedCount: Int
    public let scope = "All readable sleepAnalysis history, no date predicate; incremental additions and explicit deletions. Original intervals retained."
    public let missingness = "Read authorization is unknown. Successful queries do not establish completeness. Missing or inaccessible samples are not zero sleep; full refresh merges known samples rather than deleting by absence."
    public init(_ state: SleepSyncState) {
        connection = state.connection; lastSuccessfulSyncAt = state.lastSyncAt; retainedSampleCount = state.samples.count
        lastBatchAddedCount = state.lastBatchAddedCount; lastBatchDeletedCount = state.lastBatchDeletedCount
    }
}
