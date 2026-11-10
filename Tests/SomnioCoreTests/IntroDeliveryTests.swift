import XCTest
@testable import SomnioCore

final class IntroDeliveryTests: XCTestCase {
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
