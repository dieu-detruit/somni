import Foundation

public struct ExportDateRange: Codable, Equatable, Sendable {
    public let startInclusive: Date
    public let endExclusive: Date
    public let timeZoneIdentifier: String
    public init(firstDay: Date, lastDay: Date, calendar: Calendar = .current) throws {
        let start = calendar.startOfDay(for: firstDay)
        let last = calendar.startOfDay(for: lastDay)
        guard last >= start, let end = calendar.date(byAdding: .day, value: 1, to: last) else { throw JournalValidationError.invalidInterval }
        startInclusive = start; endExclusive = end; timeZoneIdentifier = calendar.timeZone.identifier
    }
    public func overlaps(start: Date, end: Date) -> Bool { start < endExclusive && end > startInclusive }
}

public enum HealthCoverageStatus: String, Codable, Sendable {
    case available, noSamplesOrNotAuthorized, queryFailed, unavailable
}

public struct HealthCoverage: Codable, Sendable {
    public let requestedRange: ExportDateRange
    public let queriedAt: Date
    public let status: HealthCoverageStatus
    public let sampleCount: Int
    public let errorDescription: String?
    public let scope = "All returned sleepAnalysis sources; complete original intervals overlapping [startInclusive,endExclusive). No clipping or synthesized samples."
    public let missingness = "No samples does not distinguish unreadable permissions, unsynced data, no device recording, or actual absence. It never means zero sleep."
    public init(range: ExportDateRange, queriedAt: Date = Date(), status: HealthCoverageStatus, sampleCount: Int, errorDescription: String? = nil) {
        requestedRange = range; self.queriedAt = queriedAt; self.status = status; self.sampleCount = sampleCount; self.errorDescription = errorDescription
    }
}

public struct HealthExportResult: Sendable {
    public let coverage: HealthCoverage
    public let samples: [SleepSample]
    public init(coverage: HealthCoverage, samples: [SleepSample]) { self.coverage = coverage; self.samples = samples }
}

public struct AnalysisMetadata: Codable, Sendable {
    public let schemaVersion = 2
    public let appVersion: String
    public let buildVersion: String
    public let audioVersion = AudioSignal.version
    public let exportedAt: Date
    public let timeZoneIdentifier: String
    public let utcOffsetSeconds: Int
    public let localRecordScope = "allSavedRecords; the chosen date range applies only to the fresh HealthKit query"
    public let timestampFormat = "ISO-8601 UTC with nine fractional digits; timezone identifiers/offsets retained where originally recorded"
    public let cachedSleepScope = "Previously imported overnight summaries may be clipped to 18:00-12:00; separate from fresh, full-day HealthKit intervals"
    public let deviceVolume = "Not recorded. Settings volume is application master gain, not device volume, acoustic output level, or exposure. Historical device timezone is unavailable unless explicitly stored."
    public let csvSafety = "Formula-like cells starting =,+,-,@,tab,CR are prefixed with an apostrophe in CSV; analysis.json preserves original text"
    public init(appVersion: String, buildVersion: String, exportedAt: Date = Date(), timeZone: TimeZone = .current) {
        self.appVersion = appVersion; self.buildVersion = buildVersion; self.exportedAt = exportedAt
        timeZoneIdentifier = timeZone.identifier; utcOffsetSeconds = timeZone.secondsFromGMT(for: exportedAt)
    }
}

public struct AnalysisBundle: Codable, Sendable {
    public let metadata: AnalysisMetadata
    public let healthCoverage: HealthCoverage
    public let playbackSessions: [PlaybackSession]
    public let morningFeedback: [MorningFeedback]
    public let journalEvents: [JournalEvent]
    public let cachedSleepRecords: [NightSleepRecord]
    public let healthSleepSamples: [SleepSample]
    public let syncedSleepSamples: [SleepSample]
    public let syncedSleepCoverage: SyncedSleepCoverage
    public let nightlySleepRecords: [NightSleepRecord]
    public init(records: StoredRecords, health: HealthExportResult, appVersion: String, buildVersion: String) {
        metadata = AnalysisMetadata(appVersion: appVersion, buildVersion: buildVersion)
        healthCoverage = health.coverage; playbackSessions = records.sessions; morningFeedback = records.feedback
        journalEvents = records.journal; cachedSleepRecords = records.legacySleepCaches
        syncedSleepSamples = records.sleepSync.samples; syncedSleepCoverage = SyncedSleepCoverage(records.sleepSync)
        nightlySleepRecords = records.sleep
        healthSleepSamples = SampleDeduplication.unique(health.samples)
    }
}

public enum SampleDeduplication {
    public static func unique(_ samples: [SleepSample]) -> [SleepSample] {
        var ids = Set<String>()
        return samples.filter { ids.insert($0.sourceID + ":" + $0.id).inserted }
            .sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
    }
}

public enum AnalysisEncoding {
    public static func timestamp(_ date: Date) -> String {
        let seconds = date.timeIntervalSince1970
        var whole = floor(seconds)
        var fraction = Int(((seconds - whole) * 1_000_000_000).rounded())
        if fraction >= 1_000_000_000 { whole += 1; fraction = 0 }
        let formatter = ISO8601DateFormatter()
        let base = formatter.string(from: Date(timeIntervalSince1970: whole)).dropLast()
        return String(base) + String(format: ".%09dZ", fraction)
    }
    public static func json<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in var container = encoder.singleValueContainer(); try container.encode(timestamp(date)) }
        return try encoder.encode(value)
    }
    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            guard let dot = text.firstIndex(of: "."), text.hasSuffix("Z"),
                  let base = formatter.date(from: String(text[..<dot]) + "Z"),
                  let fraction = Double("0" + String(text[dot..<text.index(before: text.endIndex)])) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid ISO-8601 date"))
            }
            return base.addingTimeInterval(fraction)
        }
        return decoder
    }
}

public enum CSV {
    public static func row(_ values: [String]) -> String {
        values.map { raw in
            var value = raw
            if let first = value.first, ["=", "+", "-", "@", "\t", "\r"].contains(String(first)) { value = "'" + value }
            if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") { return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
            return value
        }.joined(separator: ",") + "\r\n"
    }
    public static func table(_ header: [String], _ rows: [[String]]) -> String { row(header) + rows.map(row).joined() }
}
