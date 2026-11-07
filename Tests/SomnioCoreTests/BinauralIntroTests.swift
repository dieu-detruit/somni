import XCTest
@testable import SomnioCore

final class BinauralIntroTests: XCTestCase {
    func testLegacySettingsDoNotEnableIntro() throws {
        let old = Data(#"{"mode":"beat","volume":0.2,"timerMinutes":30}"#.utf8)
        XCTAssertFalse(try JSONDecoder().decode(SoundSettings.self, from: old).binauralIntro)
    }

    func testIntroIsSeparatedIntoTheCorrectEarFrequencies() {
        var signal = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, binauralIntro: true), sampleRate: 1000)
        for _ in 0..<4000 { _ = signal.nextStereo() }
        var left = [Double](), right = [Double]()
        for _ in 0..<1000 {
            let sample = signal.nextStereo()
            left.append(Double(sample.left)); right.append(Double(sample.right))
        }
        func amplitude(_ values: [Double], at frequency: Double) -> Double {
            var real = 0.0, imaginary = 0.0
            for (index, value) in values.enumerated() {
                let phase = 2 * Double.pi * frequency * Double(index) / 1000
                real += value * cos(phase); imaginary += value * sin(phase)
            }
            return 2 * sqrt(real * real + imaginary * imaginary) / Double(values.count)
        }
        XCTAssertGreaterThan(amplitude(left, at: 165), 0.05)
        XCTAssertGreaterThan(amplitude(right, at: 179), 0.05)
        XCTAssertLessThan(amplitude(left, at: 179), 0.001)
        XCTAssertLessThan(amplitude(right, at: 165), 0.001)
    }

    func testCrossfadeReturnsExactlyToOriginalSoundWithoutRestartingTimer() {
        var intro = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: nil, binauralIntro: true), sampleRate: 1000)
        var baseline = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: nil), sampleRate: 1000)
        var differenceDuringTransition = false
        for index in 0..<751_000 {
            let sample = intro.nextStereo(), original = baseline.nextStereo()
            XCTAssertTrue(sample.left.isFinite && sample.right.isFinite)
            XCTAssertLessThanOrEqual(max(abs(sample.left), abs(sample.right)), AudioSignal.peakLimit)
            if index == 735_000 { differenceDuringTransition = sample.left != original.left }
            if index >= 750_000 { XCTAssertEqual(sample.left, original.left); XCTAssertEqual(sample.right, original.right) }
        }
        XCTAssertTrue(differenceDuringTransition)
        XCTAssertEqual(intro.elapsedSeconds, 751, accuracy: 0.001)
    }

    func testShortTimerAndManualStopSilenceBothChannels() {
        var timed = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: 1, binauralIntro: true), sampleRate: 1000)
        for _ in 0..<60_000 { _ = timed.nextStereo() }
        XCTAssertTrue(timed.isFinished)
        XCTAssertEqual(timed.nextStereo().left, 0); XCTAssertEqual(timed.nextStereo().right, 0)
        var manual = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, binauralIntro: true), sampleRate: 1000)
        for _ in 0..<5000 { _ = manual.nextStereo() }
        manual.beginFadeOut(seconds: 2)
        for _ in 0..<2000 { _ = manual.nextStereo() }
        XCTAssertTrue(manual.isFinished)
        XCTAssertEqual(manual.nextStereo().left, 0); XCTAssertEqual(manual.nextStereo().right, 0)
    }

    func testIntroSelectionIsFixedForThePlayback() {
        var signal = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, binauralIntro: true), sampleRate: 1000)
        signal.update(settings: SoundSettings(volume: 1, timerMinutes: nil, binauralIntro: false))
        XCTAssertTrue(signal.settings.binauralIntro)
    }

    func testIntroSelectionSurvivesSettingsAndSessionEncoding() throws {
        let json = Data(#"{"mode":"beat","volume":0.2,"timerMinutes":30,"binauralIntro":true}"#.utf8)
        let settings = try JSONDecoder().decode(SoundSettings.self, from: json)
        let session = PlaybackSession(settings: settings)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        let changes = try XCTUnwrap(object["changes"] as? [[String: Any]])
        let saved = try XCTUnwrap(changes.first?["settings"] as? [String: Any])
        XCTAssertEqual(saved["binauralIntro"] as? Bool, true)
    }
}
