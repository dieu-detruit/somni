import Foundation

public struct NightSleepRecord: Codable, Identifiable, Sendable {
    public var id: String
    public var summaries: [SleepSummary]
    public var selectedSourceID: String?
    public var fetchedAt: Date
    public var selected: SleepSummary? { summaries.first { $0.sourceID == selectedSourceID } ?? summaries.first }
    public init(id: String, summaries: [SleepSummary], selectedSourceID: String?, fetchedAt: Date) {
        self.id = id; self.summaries = summaries; self.selectedSourceID = selectedSourceID; self.fetchedAt = fetchedAt
    }
}

public struct StoredRecords: Codable, Sendable {
    public var schemaVersion = 2
    public var settings = SoundSettings()
    public var sessions: [PlaybackSession] = []
    public var feedback: [MorningFeedback] = []
    public var sleep: [NightSleepRecord] = []
    public var journal: [JournalEvent] = []
    public var receivedEvents: [UUID] = []
    public var resetAt: Date?
    public init() {}
    private enum CodingKeys: String, CodingKey { case schemaVersion, settings, sessions, feedback, sleep, journal, receivedEvents, resetAt }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        settings = try values.decode(SoundSettings.self, forKey: .settings)
        sessions = try values.decode([PlaybackSession].self, forKey: .sessions)
        feedback = try values.decode([MorningFeedback].self, forKey: .feedback)
        sleep = try values.decode([NightSleepRecord].self, forKey: .sleep)
        journal = try values.decodeIfPresent([JournalEvent].self, forKey: .journal) ?? []
        receivedEvents = try values.decodeIfPresent([UUID].self, forKey: .receivedEvents) ?? []
        resetAt = try values.decodeIfPresent(Date.self, forKey: .resetAt)
    }
}
