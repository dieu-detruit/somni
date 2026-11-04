import XCTest
@testable import SomnioCore

final class RecordDiskStorageTests: XCTestCase {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
    private func records() -> StoredRecords {
        var value = StoredRecords()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let sample = SleepSample(id: "known", start: start, end: start.addingTimeInterval(3600), stage: .deep, sourceID: "watch", sourceName: "Synthetic", isAppleWatch: true)
        value.sleepSync = SleepSyncState(connection: .enabled).applying(additions: [sample], deletedIDs: [], anchor: Data([1, 2]), syncedAt: start)
        value.sleep = [NightSleepRecord(id: "2026-01-01", summaries: [SleepSummary(samples: [sample], sourceID: "watch", fetchedAt: start)], selectedSourceID: "watch", fetchedAt: start)]
        value.legacySleepCaches = value.sleep
        value.feedback = [MorningFeedback(nightID: "2026-01-01", refreshed: 4, note: "synthetic")]
        return value
    }
    func testOrdinaryUserWriteDoesNotRewriteOrEmbedBulkSleepData() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        var state = records()
        try disk.saveSleep(state); try disk.saveUser(state)
        let before = try Data(contentsOf: disk.sleepURL)
        state.settings.volume = 0.4
        try disk.saveUser(state)
        XCTAssertEqual(try Data(contentsOf: disk.sleepURL), before)
        let userText = String(decoding: try Data(contentsOf: disk.userURL), as: UTF8.self)
        XCTAssertFalse(userText.contains("known"))
        let loaded = try disk.load().records
        XCTAssertEqual(loaded.settings.volume, 0.4)
        XCTAssertEqual(loaded.sleepSync.anchor, Data([1, 2]))
        XCTAssertEqual(loaded.sleepSync.samples.count, 1)
    }
    func testNonemptyLegacyMigrationWritesRecoverableBulkBeforeStrippingUserFile() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        let legacy = records()
        try JSONEncoder().encode(legacy).write(to: disk.userURL)
        let migrated = try disk.load().records
        XCTAssertTrue(FileManager.default.fileExists(atPath: disk.sleepURL.path))
        let reopened = try RecordDiskStorage(directory: directory).load().records
        XCTAssertEqual(reopened.feedback, legacy.feedback)
        XCTAssertEqual(reopened.sleepSync.anchor, migrated.sleepSync.anchor)
        XCTAssertEqual(reopened.sleep.first?.selectedSourceID, "watch")
        XCTAssertEqual(reopened.legacySleepCaches.first?.selected?.samples.first?.id, "known")
    }
    func testResetMarkerPreventsResurrectionWhenOldBulkCannotBeDeleted() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        let original = records(); try disk.saveSleep(original); try disk.saveUser(original)
        var reset = StoredRecords(); reset.sleepSync = SleepSyncState(connection: .pausedAfterDeletion); reset.resetAt = Date()
        try disk.saveUser(reset) // Simulate a crash or deletion failure before removing the old bulk file.
        let reopened = try RecordDiskStorage(directory: directory).load().records
        XCTAssertEqual(reopened.sleepSync.connection, .pausedAfterDeletion)
        XCTAssertTrue(reopened.sleepSync.samples.isEmpty)
        XCTAssertNil(reopened.sleepSync.anchor)
        XCTAssertTrue(reopened.sleep.isEmpty)
        reset.sleepSync.connection = .enabled
        try disk.saveUser(reset)
        let reconnected = try RecordDiskStorage(directory: directory).load().records
        XCTAssertTrue(reconnected.sleepSync.samples.isEmpty)
        XCTAssertNil(reconnected.sleepSync.anchor)
    }
    func testCorruptBulkPreservesUserRecordsAndRequiresAnchorRebuild() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        let original = records(); try disk.saveSleep(original); try disk.saveUser(original)
        try Data("invalid".utf8).write(to: disk.sleepURL)
        let loaded = try RecordDiskStorage(directory: directory).load()
        XCTAssertEqual(loaded.records.feedback, original.feedback)
        XCTAssertNil(loaded.records.sleepSync.anchor)
        XCTAssertNotNil(loaded.warning)
    }
    func testFailedBulkWriteDoesNotCommitCandidateAnchor() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        var current = records(); try disk.saveSleep(current); try disk.saveUser(current)
        let oldAnchor = current.sleepSync.anchor
        let backup = directory.appendingPathComponent("previous-sleep.json")
        try FileManager.default.moveItem(at: disk.sleepURL, to: backup)
        let before = try Data(contentsOf: backup)
        try FileManager.default.createDirectory(at: disk.sleepURL, withIntermediateDirectories: true)
        try Data("blocker".utf8).write(to: disk.sleepURL.appendingPathComponent("child"))
        var candidate = current.sleepSync; candidate.anchor = Data([9])
        XCTAssertThrowsError(try current.commitSleepSync(candidate, expectedGeneration: current.sleepSync.generation, persist: disk.saveSleep))
        XCTAssertEqual(current.sleepSync.anchor, oldAnchor)
        XCTAssertEqual(try Data(contentsOf: backup), before)
        try FileManager.default.removeItem(at: disk.sleepURL)
        try FileManager.default.moveItem(at: backup, to: disk.sleepURL)
        XCTAssertEqual(try disk.load().records.sleepSync.anchor, oldAnchor)
    }
    func testMigrationWriteFailureLeavesFullLegacySourceRecoverable() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        let legacy = records(); let original = try JSONEncoder().encode(legacy)
        try original.write(to: disk.userURL)
        try FileManager.default.createDirectory(at: disk.sleepURL, withIntermediateDirectories: true)
        try Data("blocker".utf8).write(to: disk.sleepURL.appendingPathComponent("child"))
        let loaded = try disk.load()
        XCTAssertEqual(loaded.records.feedback, legacy.feedback)
        XCTAssertEqual(loaded.records.sleepSync.anchor, legacy.sleepSync.anchor)
        XCTAssertNotNil(loaded.warning)
        XCTAssertEqual(try Data(contentsOf: disk.userURL), original)
        try FileManager.default.removeItem(at: disk.sleepURL)
        let retried = try RecordDiskStorage(directory: directory).load().records
        XCTAssertEqual(retried.sleepSync.samples.count, 1)
        XCTAssertEqual(retried.feedback, legacy.feedback)
    }
    func testMissingBulkLeavesLocalJournalAndRatingsReadable() throws {
        let directory = try directory(); let disk = RecordDiskStorage(directory: directory)
        var state = records()
        state.journal = [try JournalEvent(kind: .sleepiness, severity: 3, note: "synthetic")]
        try disk.saveSleep(state); try disk.saveUser(state); try disk.removeSleepFile()
        let loaded = try disk.load()
        XCTAssertEqual(loaded.records.feedback, state.feedback)
        XCTAssertEqual(loaded.records.journal, state.journal)
        XCTAssertNil(loaded.records.sleepSync.anchor)
        XCTAssertNotNil(loaded.warning)
    }
}
