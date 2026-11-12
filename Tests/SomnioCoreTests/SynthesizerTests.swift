import XCTest
@testable import SomnioCore

final class SynthesizerTests: XCTestCase {
    func testLegacyControlsKeepOldSoundAndNewValuesAreNormalized() throws {
        let old = try JSONDecoder().decode(SoundSettings.self, from: Data(#"{"mode":"beat","volume":0.2,"beatRateHz":4}"#.utf8))
        XCTAssertEqual(old.musicGain, 0); XCTAssertEqual(old.toneFrequencyHz, 180); XCTAssertEqual(old.introGain, 1)
        let settings = SoundSettings(beatRateHz: 100, musicGain: .nan, musicBrightness: 3, musicMotion: -.infinity, toneFrequencyHz: .infinity, introGain: -1)
        XCTAssertEqual(settings.beatRateHz, 40); XCTAssertEqual(settings.musicGain, 0)
        XCTAssertEqual(settings.musicBrightness, 1); XCTAssertEqual(settings.musicMotion, 0.3)
        XCTAssertEqual(settings.toneFrequencyHz, 180); XCTAssertEqual(settings.introGain, 0)
    }

    private func amplitude(_ samples: [Double], frequency: Double, sampleRate: Double) -> Double {
        var real = 0.0, imaginary = 0.0
        for (index, value) in samples.enumerated() {
            let phase = 2 * Double.pi * frequency * Double(index) / sampleRate
            real += value * cos(phase); imaginary += value * sin(phase)
        }
        return 2 * sqrt(real * real + imaginary * imaginary) / Double(samples.count)
    }

    func test852PureToneIsTheSelectedPitchWithoutAnotherBeatTone() {
        var signal = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: nil, ambienceGain: 0, beatRateHz: 0, toneFrequencyHz: 852), sampleRate: 4000)
        for _ in 0..<16_000 { _ = signal.nextStereo() }
        let samples = (0..<4000).map { _ in Double(signal.nextStereo().left) }
        XCTAssertGreaterThan(amplitude(samples, frequency: 852, sampleRate: 4000), 0.12)
        XCTAssertLessThan(amplitude(samples, frequency: 866, sampleRate: 4000), 0.001)
        XCTAssertLessThan(amplitude(samples, frequency: 180, sampleRate: 4000), 0.001)
    }

    func testMusicProducesSeveralNotesWithoutToneOrEnvironment() {
        var music = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, ambienceGain: 0, beatGain: 0, musicGain: 1), sampleRate: 4000)
        var muted = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, ambienceGain: 0, beatGain: 0), sampleRate: 4000)
        for _ in 0..<16_000 { _ = music.nextStereo() }
        let samples = (0..<4000).map { _ -> Double in
            XCTAssertEqual(muted.nextStereo().left, 0)
            return Double(music.nextStereo().left)
        }
        for frequency in [130.8128, 195.9977, 246.9417, 293.6648] {
            XCTAssertGreaterThan(amplitude(samples, frequency: frequency, sampleRate: 4000), 0.007)
        }
    }

    func testMusicRemainsAudibleDuringTheTimedIntro() {
        var withIntro = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, ambienceGain: 0, beatGain: 0, binauralIntro: true, musicGain: 1, introGain: 0), sampleRate: 4000)
        var withoutIntro = AudioSignal(settings: SoundSettings(volume: 1, timerMinutes: nil, ambienceGain: 0, beatGain: 0, musicGain: 1), sampleRate: 4000)
        var peak: Float = 0
        for _ in 0..<20_000 {
            let sample = withIntro.nextStereo(), reference = withoutIntro.nextStereo()
            XCTAssertEqual(sample.left, reference.left); XCTAssertEqual(sample.right, reference.right)
            peak = max(peak, abs(sample.left))
        }
        XCTAssertGreaterThan(peak, 0.01)
    }

    func testSoundChangesAreSmoothedAndAllLayersRespectTimerAndLimits() {
        let settings = SoundSettings(mode: .beat, volume: 1, timerMinutes: nil, musicGain: 0.8)
        var baseline = AudioSignal(settings: settings, sampleRate: 4000)
        for _ in 0..<16_000 { _ = baseline.nextStereo() }
        var changed = baseline
        changed.update(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: nil, beatRateHz: 0, musicGain: 1, musicTimbre: .softKeys, musicBrightness: 1, musicMotion: 1, toneFrequencyHz: 852))
        XCTAssertLessThan(abs(changed.nextStereo().left - baseline.nextStereo().left), 0.001)
        for timbre in MusicTimbre.allCases {
            var all = AudioSignal(settings: SoundSettings(mode: .beat, volume: 1, timerMinutes: 1, musicGain: 1, musicTimbre: timbre, musicBrightness: 1, musicMotion: 1, toneFrequencyHz: 1000), sampleRate: 4000)
            for _ in 0..<240_000 {
                let sample = all.nextStereo()
                XCTAssertTrue(sample.left.isFinite && sample.right.isFinite)
                XCTAssertLessThanOrEqual(max(abs(sample.left), abs(sample.right)), AudioSignal.peakLimit)
            }
            XCTAssertTrue(all.isFinished); XCTAssertEqual(all.nextStereo().left, 0)
        }
    }

    func testFavoritesAndTheirSettingsSurviveDiskAndAnalysisExport() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SoundSettings(mode: .beat, beatRateHz: 14, musicGain: 0.6, musicTimbre: .softKeys, toneFrequencyHz: 852, introGain: 0.3)
        let favorite = SoundPreset(name: "My sound", settings: settings)
        var records = StoredRecords(); records.soundPresets = [favorite]
        let disk = RecordDiskStorage(directory: directory)
        try disk.saveUser(records)
        let loaded = try disk.load().records
        XCTAssertEqual(loaded.soundPresets.first?.id, favorite.id)
        XCTAssertEqual(loaded.soundPresets.first?.settings, settings)
        let date = Date(), range = try ExportDateRange(firstDay: Date(), lastDay: Date())
        let health = HealthExportResult(coverage: HealthCoverage(range: range, queriedAt: date, status: .noSamplesOrNotAuthorized, sampleCount: 0), samples: [])
        var exported = loaded
        exported.sessions = [PlaybackSession(settings: settings)]
        let bundle = AnalysisBundle(records: exported, health: health, appVersion: "test", buildVersion: "test")
        let decoded = try AnalysisEncoding.decoder().decode(AnalysisBundle.self, from: AnalysisEncoding.json(bundle))
        XCTAssertEqual(decoded.soundPresets.first?.settings, settings)
        XCTAssertEqual(decoded.playbackSessions.first?.settings, settings)
        let tables = bundle.csvTables()
        XCTAssertTrue(try XCTUnwrap(tables["sound_presets.csv"]).contains("My sound"))
        XCTAssertTrue(try XCTUnwrap(tables["setting_changes.csv"]).contains("musicBrightness"))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(records)) as? [String: Any])
        object.removeValue(forKey: "soundPresets")
        XCTAssertTrue(try JSONDecoder().decode(StoredRecords.self, from: JSONSerialization.data(withJSONObject: object)).soundPresets.isEmpty)
    }

    func testNewSoundControlsSurviveSettingsRoundTrip() throws {
        let json = Data(#"{"mode":"beat","volume":0.2,"musicGain":0.6,"musicTimbre":"softKeys","musicBrightness":0.4,"musicMotion":0.7,"toneFrequencyHz":852,"introGain":0.3}"#.utf8)
        let settings = try JSONDecoder().decode(SoundSettings.self, from: json)
        let saved = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any])
        XCTAssertEqual(saved["musicGain"] as? Double, 0.6)
        XCTAssertEqual(saved["musicTimbre"] as? String, "softKeys")
        XCTAssertEqual(saved["toneFrequencyHz"] as? Double, 852)
        XCTAssertEqual(saved["introGain"] as? Double, 0.3)
    }
}
