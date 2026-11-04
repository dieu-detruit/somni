import Foundation

/// User records and the authoritative sleep generation are small; bulk samples/anchor live in one atomic file.
public final class RecordDiskStorage {
    public let userURL: URL
    public let sleepURL: URL
    private let directory: URL
    private var migrationPending = false
    private var blockedBulkGeneration: UUID?
    public struct Loaded {
        public let records: StoredRecords
        public let warning: String?
    }
    private struct UserFile: Codable {
        let storageFormatVersion: Int
        let records: StoredRecords
    }
    private struct SleepFile: Codable {
        let generation: UUID
        let sync: SleepSyncState
        let nightly: [NightSleepRecord]
        let legacy: [NightSleepRecord]
    }
    public init(directory: URL) {
        self.directory = directory
        userURL = directory.appendingPathComponent("records.json")
        sleepURL = directory.appendingPathComponent("sleep-records.json")
    }
    public func load() throws -> Loaded {
        guard FileManager.default.fileExists(atPath: userURL.path) else { return Loaded(records: StoredRecords(), warning: nil) }
        let data = try Data(contentsOf: userURL)
        let decoder = JSONDecoder()
        if let local = try? decoder.decode(UserFile.self, from: data) {
            guard local.storageFormatVersion == 1 else { throw StorageError.unsupportedFormat }
            var records = local.records
            guard records.sleepSync.connection != .pausedAfterDeletion else { return Loaded(records: records, warning: nil) }
            guard FileManager.default.fileExists(atPath: sleepURL.path) else {
                return Loaded(records: records, warning: records.sleepSync.connection == .enabled ? "保存済みの睡眠ファイルが見つかりません。全履歴を再確認します。" : nil)
            }
            do {
                let bulk = try decoder.decode(SleepFile.self, from: Data(contentsOf: sleepURL))
                guard bulk.generation == records.sleepSync.generation else {
                    return Loaded(records: records, warning: records.sleepSync.connection == .enabled ? "以前の睡眠ファイルは初期化前のため使用しません。全履歴を再確認します。" : nil)
                }
                let connection = records.sleepSync.connection
                records.sleepSync = bulk.sync; records.sleepSync.connection = connection
                records.sleep = bulk.nightly; records.legacySleepCaches = bulk.legacy
                return Loaded(records: records, warning: nil)
            } catch {
                // Keep unrelated notes/ratings readable; preserve the bad file before any recovery write.
                let backup = directory.appendingPathComponent("sleep-unreadable-\(UUID().uuidString).json")
                do { try FileManager.default.copyItem(at: sleepURL, to: backup) }
                catch { blockedBulkGeneration = records.sleepSync.generation }
                return Loaded(records: records, warning: "睡眠ファイルを読み込めませんでした。朝の評価や日中の記録は残っています。全履歴の再確認で復旧できます。")
            }
        }
        // v0.1/v0.2 stored everything in records.json. Preserve that source until bulk is durable.
        let legacy = try decoder.decode(StoredRecords.self, from: data)
        migrationPending = true
        do {
            try saveUser(legacy)
            return Loaded(records: legacy, warning: nil)
        } catch {
            return Loaded(records: legacy, warning: "保存形式を更新できませんでした。以前のファイルを残して再試行します。")
        }
    }
    public func saveUser(_ records: StoredRecords) throws {
        if migrationPending { try saveSleep(records) }
        var local = records
        local.sleep = []; local.legacySleepCaches = []
        local.sleepSync.samples = []; local.sleepSync.anchor = nil; local.sleepSync.lastSyncAt = nil
        local.sleepSync.lastBatchAddedCount = 0; local.sleepSync.lastBatchDeletedCount = 0
        let file = UserFile(storageFormatVersion: 1, records: local)
        try write(JSONEncoder().encode(file), to: userURL)
        migrationPending = false
    }
    public func saveSleep(_ records: StoredRecords) throws {
        guard blockedBulkGeneration != records.sleepSync.generation else { throw StorageError.recoveryBackupFailed }
        let file = SleepFile(generation: records.sleepSync.generation, sync: records.sleepSync, nightly: records.sleep, legacy: records.legacySleepCaches)
        try write(JSONEncoder().encode(file), to: sleepURL)
    }
    public func removeSleepFile() throws {
        if FileManager.default.fileExists(atPath: sleepURL.path) { try FileManager.default.removeItem(at: sleepURL) }
    }
    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #if os(iOS) || os(watchOS) || os(tvOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
    private enum StorageError: LocalizedError {
        case unsupportedFormat, recoveryBackupFailed
        var errorDescription: String? { "睡眠記録を安全に保存できませんでした。記録の初期化後に再接続するか、空き容量を確認してください。" }
    }
}
