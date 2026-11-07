import XCTest
@testable import SomnioCore

final class BinauralIntroTests: XCTestCase {
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
