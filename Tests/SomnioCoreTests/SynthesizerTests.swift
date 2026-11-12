import XCTest
@testable import SomnioCore

final class SynthesizerTests: XCTestCase {
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
