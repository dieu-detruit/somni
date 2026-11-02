import XCTest
@testable import SomnioCore

final class CoreTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)
    private func sample(_ start: Double, _ end: Double, _ stage: SleepStage, source: String = "watch") -> SleepSample {
        SleepSample(id: UUID().uuidString, start: origin.addingTimeInterval(start), end: origin.addingTimeInterval(end), stage: stage, sourceID: source, sourceName: source, isAppleWatch: source == "watch")
    }

    func testSleepTotalMergesOverlapsAndExcludesInBedAndAwake() {
        let summary = SleepSummary(samples: [sample(0, 100, .inBed), sample(10, 40, .core), sample(30, 50, .deep), sample(50, 60, .awake), sample(60, 80, .rem)], sourceID: "watch", fetchedAt: origin)
        XCTAssertEqual(summary.totalSleep, 60)
        XCTAssertEqual(summary.stageDuration(.deep), 20)
    }

    func testOtherSourceIsNotSilentlyMixedIn() {
        let summary = SleepSummary(samples: [sample(0, 20, .core), sample(20, 100, .deep, source: "manual")], sourceID: "watch", fetchedAt: origin)
        XCTAssertEqual(summary.totalSleep, 20)
        XCTAssertEqual(summary.samples.count, 1)
    }

    func testMissingSleepIsMissingRatherThanZeroClaim() {
        XCTAssertNil(SleepSummary.preferred(samples: [], fetchedAt: origin))
        XCTAssertEqual(SleepSummary.preferred(samples: [sample(0, 40, .core, source: "manual"), sample(5, 25, .deep)], fetchedAt: origin)?.sourceID, "watch")
    }

    func testClipToWindowAndRejectReversedIntervals() {
        let window = DateInterval(start: origin.addingTimeInterval(10), duration: 20)
        let summary = SleepSummary(samples: [sample(0, 100, .core), sample(50, 20, .deep)], sourceID: "watch", fetchedAt: origin, window: window)
        XCTAssertEqual(summary.totalSleep, 20)
    }

    func testNightKeyUsesPreviousDateBeforeNoon() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let late = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 23))!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 8))!
        XCTAssertEqual(Night.key(for: late, calendar: calendar), Night.key(for: morning, calendar: calendar))
    }

    func testFeedbackReplayCannotOverwriteNewerRating() {
        let newer = MorningFeedback(nightID: "2026-11-02", refreshed: 5, easeOfSleep: 4, note: "rested", updatedAt: origin.addingTimeInterval(50))
        let older = MorningFeedback(nightID: newer.nightID, refreshed: 1, easeOfSleep: 2, note: "", updatedAt: origin)
        XCTAssertEqual(MorningFeedback.latest(newer, older).id, newer.id)
        XCTAssertEqual(MorningFeedback.latest(older, newer).id, newer.id)
        XCTAssertEqual(MorningFeedback.latest(newer, newer).id, newer.id)
    }

    func testSignalIsFiniteBoundedAndEndsExactlyAtTimer() {
        var signal = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: 15), sampleRate: 100)
        var peak: Float = 0
        for _ in 0..<90_000 {
            let value = signal.next()
            XCTAssertTrue(value.isFinite)
            peak = max(peak, abs(value))
        }
        XCTAssertLessThanOrEqual(peak, AudioSignal.peakLimit)
        XCTAssertEqual(signal.next(), 0)
        XCTAssertTrue(signal.isFinished)
        XCTAssertEqual(signal.elapsedSeconds, 900, accuracy: 0.01)
    }

    func testFadeAndNonFiniteInputAreSafe() {
        var signal = AudioSignal(settings: SoundSettings(mode: .ambience, volume: .nan, timerMinutes: nil), sampleRate: 100)
        XCTAssertEqual(signal.next(), 0)
        for _ in 0..<500 { XCTAssertTrue(signal.next().isFinite) }
        signal.beginFadeOut(seconds: 1)
        for _ in 0..<100 { _ = signal.next() }
        XCTAssertTrue(signal.isFinished)
        XCTAssertEqual(signal.next(), 0)
    }

    func testChangingBeatModeRampsInRatherThanClicks() {
        var baseline = AudioSignal(settings: SoundSettings(mode: .ambience, volume: 1), sampleRate: 44_100)
        var changed = baseline
        for _ in 0..<150_000 { _ = baseline.next(); _ = changed.next() }
        changed.update(settings: SoundSettings(mode: .beat, volume: 1))
        XCTAssertLessThan(abs(changed.next() - baseline.next()), 0.001)
    }

    func testManualFadeDoesNotRunPastTimer() {
        var signal = AudioSignal(settings: SoundSettings(mode: .ambience, volume: 0.2, timerMinutes: 15), sampleRate: 10)
        for _ in 0..<8_995 { _ = signal.next() }
        signal.beginFadeOut(seconds: 2)
        for _ in 0..<5 { _ = signal.next() }
        XCTAssertTrue(signal.isFinished)
    }
}
