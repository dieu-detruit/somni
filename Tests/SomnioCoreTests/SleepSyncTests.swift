import XCTest
@testable import SomnioCore

final class SleepSyncTests: XCTestCase {
    private var calendar: Calendar { var value = Calendar(identifier: .gregorian); value.timeZone = TimeZone(secondsFromGMT: 0)!; return value }
    private func date(_ day: Int, _ hour: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))! }
    private func sample(_ id: String, day: Int = 2, hour: Int = 22, hours: Int = 8, source: String = "watch") -> SleepSample {
        SleepSample(id: id, start: date(day, hour), end: date(day, hour).addingTimeInterval(Double(hours) * 3600), stage: .core, sourceID: source, sourceName: source, isAppleWatch: source == "watch")
    }
    func testDeltaAddsReplacesDeletesAndIsIdempotent() {
        var sync = SleepSyncState(connection: .enabled)
        sync = sync.applying(additions: [sample("a"), sample("b")], deletedIDs: [], anchor: Data([1]), syncedAt: date(3, 9))
        sync = sync.applying(additions: [sample("a", hours: 6)], deletedIDs: ["b"], anchor: Data([2]), syncedAt: date(3, 10))
        let replay = sync.applying(additions: [sample("a", hours: 6)], deletedIDs: ["b"], anchor: Data([2]), syncedAt: date(3, 10))
        XCTAssertEqual(replay.samples.count, 1)
        XCTAssertEqual(replay.samples.first?.end, date(3, 4))
        XCTAssertEqual(replay.anchor, Data([2]))
    }
    func testDaytimeRetainedAndMultipleNightsIndexedWithoutClippingRawSamples() {
        let raw = [sample("night-a"), sample("night-b", day: 3), sample("nap", day: 3, hour: 14, hours: 1)]
        let records = SleepNightIndex.rebuild(samples: raw, existing: [], fetchedAt: date(4, 10), calendar: calendar)
        XCTAssertEqual(records.map(\.id).sorted(), ["2026-11-02", "2026-11-03"])
        XCTAssertEqual(records.first { $0.id == "2026-11-02" }?.selected?.totalSleep, 8 * 3600)
        let sync = SleepSyncState(connection: .enabled).applying(additions: raw, deletedIDs: [], anchor: Data([1]), syncedAt: date(4, 10))
        XCTAssertEqual(sync.samples.count, 3)
        XCTAssertEqual(sync.samples.first { $0.id == "nap" }?.start, date(3, 14))
    }
    func testMidnightAndLongIntervalsContributeToEveryOverlappingNight() {
        let records = SleepNightIndex.rebuild(samples: [sample("long", hours: 36)], existing: [], fetchedAt: date(5, 10), calendar: calendar)
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.first { $0.id == "2026-11-02" }?.selected?.totalSleep, 14 * 3600)
    }
    func testSourceSelectionIsPreservedWhenAvailable() {
        let original = NightSleepRecord(id: "2026-11-02", summaries: [], selectedSourceID: "other", fetchedAt: date(3, 8))
        let records = SleepNightIndex.rebuild(samples: [sample("a"), sample("b", source: "other")], existing: [original], fetchedAt: date(3, 9), calendar: calendar)
        XCTAssertEqual(records.first?.selectedSourceID, "other")
    }
    func testRemovingLastSampleClearsDerivedNightButPreservesUnrelatedLegacyNight() {
        let legacy = NightSleepRecord(id: "2025-01-01", summaries: [], selectedSourceID: nil, fetchedAt: date(3, 8))
        let old = [legacy, NightSleepRecord(id: "2026-11-02", summaries: [], selectedSourceID: nil, fetchedAt: date(3, 8))]
        let result = SleepNightIndex.rebuild(samples: [], existing: old, affectedNights: ["2026-11-02"], fetchedAt: date(3, 9), calendar: calendar)
        XCTAssertEqual(result.map(\.id), ["2025-01-01"])
    }
    func testFailedPersistenceDoesNotAdvanceSampleAnchorOrState() throws {
        enum Failure: Error { case disk }
        let old = SleepSyncState(connection: .enabled)
        var stored = StoredRecords(); stored.sleepSync = old
        let next = old.applying(additions: [sample("a")], deletedIDs: [], anchor: Data([9]), syncedAt: date(3, 8))
        XCTAssertThrowsError(try stored.commitSleepSync(next, expectedGeneration: old.generation, persist: { _ in throw Failure.disk }))
        XCTAssertNil(stored.sleepSync.anchor)
        XCTAssertTrue(stored.sleepSync.samples.isEmpty)
    }
    func testResetGenerationRejectsInFlightResultsAndRequiresReconnect() throws {
        var records = StoredRecords(); let token = records.sleepSync.generation
        let candidate = SleepSyncState(connection: .enabled)
        records.sleepSync = SleepSyncState(connection: .pausedAfterDeletion)
        XCTAssertFalse(try records.commitSleepSync(candidate, expectedGeneration: token, persist: { _ in }))
        XCTAssertEqual(records.sleepSync.connection, .pausedAfterDeletion)
        records.sleepSync.connection = .enabled
        XCTAssertTrue(try records.commitSleepSync(records.sleepSync, expectedGeneration: records.sleepSync.generation, persist: { _ in }))
    }
    func testEmptyRescanPreservesKnownSamplesRatherThanInferringDeniedReadIsDeletion() {
        let initial = SleepSyncState(connection: .enabled).applying(additions: [sample("known")], deletedIDs: [], anchor: Data([1]), syncedAt: date(3, 8))
        let rescanned = initial.applying(additions: [], deletedIDs: [], anchor: Data([2]), syncedAt: date(3, 9))
        XCTAssertEqual(rescanned.samples.count, 1)
    }
}
