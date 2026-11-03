import XCTest
@testable import SomnioCore

final class JournalExportTests: XCTestCase {
    func testOldSettingsDecodeWithIdenticalLayerDefaults() throws {
        let old = Data(#"{"mode":"beat","volume":0.3,"timerMinutes":30}"#.utf8)
        let value = try JSONDecoder().decode(SoundSettings.self, from: old)
        XCTAssertEqual(value.ambienceGain, 1)
        XCTAssertEqual(value.beatGain, 1)
        XCTAssertEqual(value.beatRateHz, 4)
        XCTAssertEqual(value.volume, 0.3)
    }
    func testNewSettingsAreFiniteAndClamped() {
        let settings = SoundSettings(ambienceGain: -2, beatGain: 4, beatRateHz: .nan)
        XCTAssertEqual(settings.ambienceGain, 0)
        XCTAssertEqual(settings.beatGain, 1)
        XCTAssertEqual(settings.beatRateHz, 4)
    }
    func testLayersCanBeMutedIndependently() {
        var silence = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, ambienceGain: 0, beatGain: 0), sampleRate: 44_100)
        var beats = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, ambienceGain: 0, beatGain: 1), sampleRate: 44_100)
        var beatPeak: Float = 0
        for _ in 0..<50_000 { XCTAssertEqual(silence.next(), 0); beatPeak = max(beatPeak, abs(beats.next())) }
        XCTAssertGreaterThan(beatPeak, 0.01)
    }
    func testChangingRateAndGainsHasNoImmediateDiscontinuity() {
        var baseline = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1), sampleRate: 44_100)
        for _ in 0..<50_000 { _ = baseline.next() }
        var changed = baseline
        changed.update(settings: SoundSettings(mode: .beat, volume: 1, ambienceGain: 0, beatGain: 0, beatRateHz: 1))
        XCTAssertLessThan(abs(changed.next() - baseline.next()), 0.001)
    }
    func testAllExploratoryRatesRespectTimerAndLimits() {
        for rate in SoundSettings.exploratoryRates {
            var signal = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: 1, ambienceGain: 0, beatRateHz: rate), sampleRate: 100)
            for _ in 0..<6000 { let value = signal.next(); XCTAssertTrue(value.isFinite); XCTAssertLessThanOrEqual(abs(value), AudioSignal.peakLimit) }
            XCTAssertTrue(signal.isFinished)
        }
    }
    func testOldStoredStateMigratesWithoutLosingRatings() throws {
        let old = Data(#"{"settings":{"mode":"ambience","volume":0.2,"timerMinutes":30},"sessions":[],"feedback":[],"sleep":[],"receivedEvents":[],"resetAt":null}"#.utf8)
        let state = try JSONDecoder().decode(StoredRecords.self, from: old)
        XCTAssertTrue(state.journal.isEmpty)
        XCTAssertEqual(state.settings.volume, 0.2)
        XCTAssertEqual(state.schemaVersion, 2)
    }
    func testJournalValidatesIntervalsAndSeverity() throws {
        let start = Date(timeIntervalSince1970: 100)
        XCTAssertThrowsError(try JournalEvent(kind: .nap, start: start, end: start))
        XCTAssertThrowsError(try JournalEvent(kind: .morningResleep, start: start))
        XCTAssertThrowsError(try JournalEvent(kind: .sleepiness, start: start, severity: 6))
        let event = try JournalEvent(kind: .nap, start: start, end: start.addingTimeInterval(90_000))
        XCTAssertEqual(event.end!.timeIntervalSince(event.start), 90_000)
        XCTAssertEqual(event.provenance, "selfReported")
    }
    func testJSONTimestampsUseISO8601AndRoundTripNotes() throws {
        let event = try JournalEvent(kind: .bedtime, start: Date(timeIntervalSince1970: 1_700_000_000), note: "comma, \"quote\"\nnext line")
        let data = try AnalysisEncoding.json(event)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("2023-11-14T22:13:20"))
        let decoder = AnalysisEncoding.decoder()
        XCTAssertEqual(try decoder.decode(JournalEvent.self, from: data).note, event.note)
    }
    func testCSVQuotesCommasQuotesAndNewlines() {
        XCTAssertEqual(CSV.row(["plain", "a,b", "say \"yes\"", "a\nb"]), "plain,\"a,b\",\"say \"\"yes\"\"\",\"a\nb\"\r\n")
        XCTAssertEqual(CSV.row(["=1+1"]), "'=1+1\r\n")
    }
    func testFullDayRangeHandlesDSTAndExclusiveBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 14))!
        let range = try ExportDateRange(firstDay: date, lastDay: date, calendar: calendar)
        XCTAssertEqual(range.endExclusive.timeIntervalSince(range.startInclusive), 25 * 3600)
        XCTAssertFalse(range.overlaps(start: range.endExclusive, end: range.endExclusive.addingTimeInterval(30)))
        XCTAssertTrue(range.overlaps(start: range.startInclusive.addingTimeInterval(-20), end: range.startInclusive.addingTimeInterval(20)))
    }
    func testDuplicateHealthSamplesAreRemovedWithoutMergingDifferentStages() {
        let start = Date(timeIntervalSince1970: 100)
        let sample = SleepSample(id: "raw-id", start: start, end: start.addingTimeInterval(10), stage: .deep, sourceID: "watch", sourceName: "Watch", isAppleWatch: true)
        XCTAssertEqual(SampleDeduplication.unique([sample, sample]).count, 1)
    }
}
