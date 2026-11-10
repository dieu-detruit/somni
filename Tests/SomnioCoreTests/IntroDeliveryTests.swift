import XCTest
@testable import SomnioCore

final class IntroDeliveryTests: XCTestCase {
    func testAutomaticAndManualRoutingRespectMonoOutput() {
        XCTAssertEqual(IntroDelivery.resolve(mode: .automatic, headphonesLikely: true, stereoAvailable: true, monoAudioEnabled: false), .binaural)
        XCTAssertEqual(IntroDelivery.resolve(mode: .automatic, headphonesLikely: false, stereoAvailable: true, monoAudioEnabled: false), .monaural)
        XCTAssertEqual(IntroDelivery.resolve(mode: .monaural, headphonesLikely: true, stereoAvailable: true, monoAudioEnabled: false), .monaural)
        XCTAssertEqual(IntroDelivery.resolve(mode: .binaural, headphonesLikely: false, stereoAvailable: true, monoAudioEnabled: false), .binaural)
        for mode in IntroMode.allCases {
            XCTAssertEqual(IntroDelivery.resolve(mode: mode, headphonesLikely: true, stereoAvailable: false, monoAudioEnabled: false), .monaural)
            XCTAssertEqual(IntroDelivery.resolve(mode: mode, headphonesLikely: true, stereoAvailable: true, monoAudioEnabled: true), .monaural)
        }
    }

    func testLegacyPreferencesUseAutoButOldBinauralHistoryKeepsItsDelivery() throws {
        let old = Data(#"{"mode":"beat","volume":0.2,"binauralIntro":true}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(SoundSettings.self, from: old).introMode, .automatic)
        let original = PlaybackSession(settings: SoundSettings(binauralIntro: true))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        json["audioVersion"] = "3"; json.removeValue(forKey: "introDelivery")
        let decoded = try JSONDecoder().decode(PlaybackSession.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(decoded.introDelivery, .binaural)
        json["audioVersion"] = "4"
        XCTAssertNil(try JSONDecoder().decode(PlaybackSession.self, from: JSONSerialization.data(withJSONObject: json)).introDelivery)
    }

    func testMonauralContainsBothTonesInBothChannelsAndReturnsToBaseline() {
        let settings = SoundSettings(mode: .beat, volume: 1, timerMinutes: nil, binauralIntro: true)
        var mono = AudioSignal(settings: settings, sampleRate: 1000, introDelivery: .monaural)
        var binaural = AudioSignal(settings: settings, sampleRate: 1000, introDelivery: .binaural)
        var baseline = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: nil), sampleRate: 1000)
        var samples = [Double]()
        for index in 0..<750_100 {
            let value = mono.nextStereo(), stereo = binaural.nextStereo(), original = baseline.nextStereo()
            XCTAssertEqual(value.left, value.right)
            XCTAssertTrue(value.left.isFinite)
            XCTAssertLessThanOrEqual(abs(value.left), AudioSignal.peakLimit)
            if (4000..<5000).contains(index) { samples.append(Double(value.left)) }
            if [719_999, 720_000, 735_000, 749_999].contains(index) {
                let weight = index <= 720_000 ? 1.0 : Double(750_000 - index) / 30_000
                let t = Double(index) / 1000
                let tones = (sin(2 * .pi * 165 * t) + sin(2 * .pi * 179 * t)) * 0.0325
                let expected = tones * weight + Double(original.left) * (1 - weight)
                XCTAssertEqual(Double(value.left), expected, accuracy: 0.00001)
            }
            if index < 720_000 { XCTAssertEqual(value.left, (stereo.left + stereo.right) / 2, accuracy: 0.000001) }
            if index >= 750_000 { XCTAssertEqual(value.left, original.left) }
        }
        for frequency in [165.0, 179.0] {
            var real = 0.0, imaginary = 0.0
            for (index, value) in samples.enumerated() {
                let phase = 2 * Double.pi * frequency * Double(index) / 1000
                real += value * cos(phase); imaginary += value * sin(phase)
            }
            XCTAssertGreaterThan(2 * sqrt(real * real + imaginary * imaginary) / 1000, 0.03)
        }
    }

    func testMonauralKeepsTimersAndStopsAndDoesNotChangeDeliveryMidPlayback() {
        var mono = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: 1, binauralIntro: true), sampleRate: 1000, introDelivery: .monaural)
        mono.update(settings: SoundSettings(volume: 1, timerMinutes: 1, binauralIntro: false, introMode: .binaural))
        XCTAssertTrue(mono.settings.binauralIntro)
        XCTAssertEqual(mono.settings.introMode, .automatic)
        for _ in 0..<60_000 { _ = mono.nextStereo() }
        XCTAssertTrue(mono.isFinished)
        XCTAssertEqual(mono.nextStereo().left, 0); XCTAssertEqual(mono.nextStereo().right, 0)
        var manual = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, binauralIntro: true), sampleRate: 1000, introDelivery: .monaural)
        for _ in 0..<4000 { _ = manual.nextStereo() }
        manual.beginFadeOut(seconds: 2)
        for _ in 0..<2000 { _ = manual.nextStereo() }
        XCTAssertTrue(manual.isFinished)
        XCTAssertEqual(manual.nextStereo().left, 0)
    }

    func testCSVExportsChosenPreferenceAndGeneratedDeliverySeparately() throws {
        var records = StoredRecords()
        records.sessions = [PlaybackSession(settings: SoundSettings(binauralIntro: true, introMode: .automatic), introDelivery: .monaural)]
        let date = Date()
        let range = try ExportDateRange(firstDay: date, lastDay: date)
        let health = HealthExportResult(coverage: HealthCoverage(range: range, status: .noSamplesOrNotAuthorized, sampleCount: 0), samples: [])
        let tables = AnalysisBundle(records: records, health: health, appVersion: "test", buildVersion: "test").csvTables()
        let sessions = try XCTUnwrap(tables["playback_sessions.csv"])
        let changes = try XCTUnwrap(tables["setting_changes.csv"])
        XCTAssertTrue(sessions.contains("introDelivery\r\n")); XCTAssertTrue(sessions.contains(",monaural\r\n"))
        XCTAssertTrue(changes.contains("introMode\r\n")); XCTAssertTrue(changes.contains(",automatic\r\n"))
    }

    func testDeliveryAndPreferenceSurviveSessionRoundTrip() throws {
        let original = PlaybackSession(settings: SoundSettings(binauralIntro: true))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object["introDelivery"] = "monaural"
        var changes = try XCTUnwrap(object["changes"] as? [[String: Any]])
        var settings = try XCTUnwrap(changes[0]["settings"] as? [String: Any])
        settings["introMode"] = "monaural"
        changes[0]["settings"] = settings; object["changes"] = changes
        let decoded = try JSONDecoder().decode(PlaybackSession.self, from: JSONSerialization.data(withJSONObject: object))
        let saved = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? [String: Any])
        XCTAssertEqual(saved["introDelivery"] as? String, "monaural")
        let savedChanges = try XCTUnwrap(saved["changes"] as? [[String: Any]])
        let savedSettings = try XCTUnwrap(savedChanges[0]["settings"] as? [String: Any])
        XCTAssertEqual(savedSettings["introMode"] as? String, "monaural")
    }
}
