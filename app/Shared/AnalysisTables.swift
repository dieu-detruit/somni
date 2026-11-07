import Foundation

public extension AnalysisBundle {
    func csvTables() -> [String: String] {
        ["metadata.csv": metadataTable(), "playback_sessions.csv": sessionTable(), "setting_changes.csv": settingTable(),
         "morning_feedback.csv": feedbackTable(), "journal_events.csv": journalTable(),
         "health_sleep_samples.csv": CSV.table(Self.sampleHeader, healthSleepSamples.map(Self.sampleValues)),
         "cached_sleep_records.csv": cachedRecordTable(), "cached_sleep_samples.csv": cachedSampleTable(),
         "synced_sleep_samples.csv": CSV.table(Self.sampleHeader, syncedSleepSamples.map(Self.sampleValues)),
         "synced_sleep_coverage.csv": syncCoverageTable(), "nightly_sleep_records.csv": nightlyTable()]
    }
    private static func date(_ value: Date?) -> String { value.map(AnalysisEncoding.timestamp) ?? "" }
    private static func number<T: CustomStringConvertible>(_ value: T?) -> String { value?.description ?? "" }
    private static let sampleHeader = ["id", "start", "end", "stage", "sourceID", "sourceName", "isAppleWatch", "sourceBundleIdentifier", "sourceVersion", "productType", "deviceModel", "isUserEntered", "categoryValue"]
    private static func sampleValues(_ sample: SleepSample) -> [String] {
        [sample.id, date(sample.start), date(sample.end), sample.stage.rawValue, sample.sourceID, sample.sourceName,
         String(sample.isAppleWatch), sample.sourceBundleIdentifier ?? "", sample.sourceVersion ?? "", sample.productType ?? "", sample.deviceModel ?? "", number(sample.isUserEntered), number(sample.categoryValue)]
    }
    private func syncCoverageTable() -> String {
        let value = syncedSleepCoverage
        return CSV.table(["connection", "lastSuccessfulSyncAt", "retainedSampleCount", "lastBatchAddedCount", "lastBatchDeletedCount", "scope", "missingness"],
            [[value.connection.rawValue, Self.date(value.lastSuccessfulSyncAt), String(value.retainedSampleCount), String(value.lastBatchAddedCount),
              String(value.lastBatchDeletedCount), value.scope, value.missingness]])
    }
    private func nightlyTable() -> String {
        let rows = nightlySleepRecords.map { [$0.id, $0.selectedSourceID ?? "", Self.date($0.fetchedAt), String($0.summaries.count)] }
        return CSV.table(["nightID", "selectedSourceID", "fetchedAt", "sourceCount"], rows)
    }
    private func metadataTable() -> String {
        let rows = [
            ["schemaVersion", String(metadata.schemaVersion)], ["appVersion", metadata.appVersion], ["buildVersion", metadata.buildVersion],
            ["audioVersion", metadata.audioVersion], ["exportedAt", Self.date(metadata.exportedAt)], ["timeZoneIdentifier", metadata.timeZoneIdentifier],
            ["utcOffsetSeconds", String(metadata.utcOffsetSeconds)], ["localRecordScope", metadata.localRecordScope],
            ["deviceVolume", metadata.deviceVolume], ["csvSafety", metadata.csvSafety], ["cachedSleepScope", metadata.cachedSleepScope],
            ["healthStatus", healthCoverage.status.rawValue], ["healthStartInclusive", Self.date(healthCoverage.requestedRange.startInclusive)],
            ["healthEndExclusive", Self.date(healthCoverage.requestedRange.endExclusive)], ["healthTimeZone", healthCoverage.requestedRange.timeZoneIdentifier],
            ["healthQueriedAt", Self.date(healthCoverage.queriedAt)], ["healthSampleCount", String(healthCoverage.sampleCount)],
            ["healthError", healthCoverage.errorDescription ?? ""], ["healthScope", healthCoverage.scope], ["healthMissingness", healthCoverage.missingness]
        ]
        return CSV.table(["key", "value"], rows)
    }
    private func sessionTable() -> String {
        let rows = playbackSessions.map { session in
            [session.id.uuidString, session.nightID, Self.date(session.startedAt), Self.date(session.endedAt), String(session.playedSeconds),
             session.endReason?.rawValue ?? "", session.audioVersion]
        }
        return CSV.table(["id", "nightID", "startedAt", "endedAt", "playedSeconds", "endReason", "audioVersion"], rows)
    }
    private func settingTable() -> String {
        var rows: [[String]] = []
        for session in playbackSessions {
            for change in session.changes {
                let value = change.settings
                rows.append([session.id.uuidString, change.id.uuidString, Self.date(change.at), value.mode.rawValue, String(value.volume),
                             Self.number(value.timerMinutes), String(value.ambienceGain), String(value.beatGain), String(value.beatRateHz), String(value.binauralIntro)])
            }
        }
        return CSV.table(["sessionID", "id", "at", "mode", "volume", "timerMinutes", "ambienceGain", "beatGain", "beatRateHz", "binauralIntro"], rows)
    }
    private func feedbackTable() -> String {
        let rows = morningFeedback.map { value in
            [value.id.uuidString, value.nightID, String(value.refreshed), Self.number(value.easeOfSleep), value.note, Self.date(value.createdAt), Self.date(value.updatedAt)]
        }
        return CSV.table(["id", "nightID", "refreshed", "easeOfSleep", "note", "createdAt", "updatedAt"], rows)
    }
    private func journalTable() -> String {
        let rows = journalEvents.map { value in
            [value.id.uuidString, value.kind.rawValue, Self.date(value.start), Self.date(value.end), Self.number(value.severity), value.note,
             Self.date(value.createdAt), Self.date(value.updatedAt), value.timeZoneIdentifier, String(value.utcOffsetSeconds), value.provenance]
        }
        return CSV.table(["id", "kind", "start", "end", "severity", "note", "createdAt", "updatedAt", "timeZoneIdentifier", "utcOffsetSeconds", "provenance"], rows)
    }
    private func cachedRecordTable() -> String {
        let rows = cachedSleepRecords.map { value in
            [value.id, value.selectedSourceID ?? "", Self.date(value.fetchedAt), String(value.summaries.count)]
        }
        return CSV.table(["nightID", "selectedSourceID", "fetchedAt", "sourceCount"], rows)
    }
    private func cachedSampleTable() -> String {
        var rows: [[String]] = []
        for record in cachedSleepRecords {
            for summary in record.summaries {
                for sample in summary.samples {
                    rows.append([record.id, record.selectedSourceID ?? "", Self.date(record.fetchedAt), summary.sourceID, Self.date(summary.fetchedAt)] + Self.sampleValues(sample))
                }
            }
        }
        return CSV.table(["nightID", "selectedSourceID", "recordFetchedAt", "summarySourceID", "summaryFetchedAt"] + Self.sampleHeader, rows)
    }
}
