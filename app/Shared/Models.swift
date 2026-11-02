import Foundation

public enum SoundMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case ambience, beat
    public var id: String { rawValue }
    public var title: String { self == .ambience ? "やわらかな波音" : "波音 + ゆるやかなビート" }
    public var detail: String { self == .ambience ? "静かなノイズが、寄せては返す" : "波音に穏やかなうなりを重ねる" }
}

public struct SoundSettings: Codable, Equatable, Sendable {
    public var mode: SoundMode
    public var volume: Double
    public var timerMinutes: Int?
    public init(mode: SoundMode = .ambience, volume: Double = 0.2, timerMinutes: Int? = 30) {
        self.mode = mode
        self.volume = volume.isFinite ? min(1, max(0, volume)) : 0
        self.timerMinutes = timerMinutes.map { min(480, max(1, $0)) }
    }
    public var timerLabel: String { timerMinutes.map { "\($0)分" } ?? "連続" }
}

public enum PlaybackEnd: String, Codable, Sendable {
    case timer, stopped, interrupted, routeChanged, failed, unknown
    public var title: String {
        switch self {
        case .timer: return "タイマーで終了"
        case .stopped: return "停止"
        case .interrupted: return "割り込みで停止"
        case .routeChanged: return "出力先の変更で停止"
        case .failed: return "再生エラー"
        case .unknown: return "終了時刻不明"
        }
    }
}

public struct SettingsChange: Codable, Identifiable, Sendable {
    public let id: UUID
    public let at: Date
    public let settings: SoundSettings
    public init(settings: SoundSettings, at: Date = Date()) { id = UUID(); self.at = at; self.settings = settings }
}

public struct PlaybackSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let nightID: String
    public let startedAt: Date
    public var endedAt: Date?
    public var playedSeconds: Double
    public var endReason: PlaybackEnd?
    public var changes: [SettingsChange]
    public init(settings: SoundSettings, startedAt: Date = Date()) {
        id = UUID(); nightID = Night.key(for: startedAt); self.startedAt = startedAt
        playedSeconds = 0; changes = [SettingsChange(settings: settings, at: startedAt)]
    }
    public var settings: SoundSettings { changes.last?.settings ?? SoundSettings() }
}

public struct MorningFeedback: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let nightID: String
    public var refreshed: Int
    public var easeOfSleep: Int?
    public var note: String
    public let createdAt: Date
    public var updatedAt: Date
    public init(id: UUID = UUID(), nightID: String, refreshed: Int, easeOfSleep: Int? = nil, note: String = "", createdAt: Date? = nil, updatedAt: Date = Date()) {
        self.id = id; self.nightID = nightID; self.refreshed = min(5, max(1, refreshed))
        self.easeOfSleep = easeOfSleep.map { min(5, max(1, $0)) }
        self.note = String(note.prefix(2000)); self.createdAt = createdAt ?? updatedAt; self.updatedAt = updatedAt
    }
    public static func latest(_ lhs: Self, _ rhs: Self) -> Self {
        if lhs.updatedAt == rhs.updatedAt { return lhs.id.uuidString > rhs.id.uuidString ? lhs : rhs }
        return lhs.updatedAt > rhs.updatedAt ? lhs : rhs
    }
}

public enum Night {
    /// A night runs from local noon to the following noon; the key names its evening.
    public static func key(for date: Date, calendar: Calendar = .current) -> String {
        let shifted = calendar.date(byAdding: .hour, value: -12, to: date) ?? date
        let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
        return String(format: "%04d-%02d-%02d", parts.year ?? 2000, parts.month ?? 1, parts.day ?? 1)
    }
    public static func window(for key: String, calendar: Calendar = .current) -> DateInterval? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let start = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)),
              let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        return DateInterval(start: start, end: end)
    }
    /// Primary overnight window, separate from daytime naps (18:00–12:00 local time).
    public static func sleepWindow(for key: String, calendar: Calendar = .current) -> DateInterval? {
        guard let whole = window(for: key, calendar: calendar),
              let start = calendar.date(byAdding: .hour, value: 6, to: whole.start) else { return nil }
        return DateInterval(start: start, end: whole.end)
    }
    public static func previous(for date: Date = Date(), calendar: Calendar = .current) -> String {
        // Before noon the current night already denotes last evening; after noon go back one day.
        if calendar.component(.hour, from: date) < 12 { return key(for: date, calendar: calendar) }
        return key(for: calendar.date(byAdding: .day, value: -1, to: date) ?? date, calendar: calendar)
    }
}

public enum SleepStage: String, Codable, CaseIterable, Sendable {
    case inBed, awake, unspecified, core, deep, rem
    public var isAsleep: Bool { self != .inBed && self != .awake }
    public var title: String {
        switch self {
        case .inBed: return "就床"
        case .awake: return "覚醒"
        case .unspecified: return "段階不明"
        case .core: return "コア"
        case .deep: return "深い睡眠"
        case .rem: return "レム"
        }
    }
}

public struct SleepSample: Codable, Identifiable, Sendable {
    public let id: String
    public var start: Date
    public var end: Date
    public let stage: SleepStage
    public let sourceID: String
    public let sourceName: String
    public let isAppleWatch: Bool
    public init(id: String, start: Date, end: Date, stage: SleepStage, sourceID: String, sourceName: String, isAppleWatch: Bool) {
        self.id = id; self.start = start; self.end = end; self.stage = stage
        self.sourceID = sourceID; self.sourceName = sourceName; self.isAppleWatch = isAppleWatch
    }
}

public struct SleepSummary: Codable, Sendable {
    public let samples: [SleepSample]
    public let sourceID: String
    public let fetchedAt: Date
    public var sourceName: String { samples.first?.sourceName ?? "不明なソース" }
    public var isAppleWatch: Bool { samples.contains { $0.isAppleWatch } }
    public var totalSleep: TimeInterval { Self.unionDuration(samples.filter { $0.stage.isAsleep }) }
    public func stageDuration(_ stage: SleepStage) -> TimeInterval { Self.unionDuration(samples.filter { $0.stage == stage }) }

    public init(samples: [SleepSample], sourceID: String, fetchedAt: Date, window: DateInterval? = nil) {
        self.sourceID = sourceID; self.fetchedAt = fetchedAt
        var ids = Set<String>()
        self.samples = samples.compactMap { sample in
            guard sample.sourceID == sourceID, sample.end > sample.start, ids.insert(sample.id).inserted else { return nil }
            var value = sample
            if let window { value.start = max(value.start, window.start); value.end = min(value.end, window.end) }
            return value.end > value.start ? value : nil
        }.sorted { $0.start < $1.start }
    }
    public static func preferred(samples: [SleepSample], fetchedAt: Date, window: DateInterval? = nil) -> Self? {
        let grouped = Dictionary(grouping: samples.filter { $0.stage.isAsleep && $0.end > $0.start }, by: \.sourceID)
        let candidates = grouped.keys.map { Self(samples: samples, sourceID: $0, fetchedAt: fetchedAt, window: window) }
            .filter { $0.totalSleep > 0 }
            .sorted {
                if $0.isAppleWatch != $1.isAppleWatch { return $0.isAppleWatch }
                if $0.totalSleep != $1.totalSleep { return $0.totalSleep > $1.totalSleep }
                return $0.sourceID < $1.sourceID
            }
        return candidates.first
    }
    public static func unionDuration(_ samples: [SleepSample]) -> TimeInterval {
        let intervals = samples.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        guard let first = intervals.first else { return 0 }
        var start = first.start; var end = first.end; var total: TimeInterval = 0
        for interval in intervals.dropFirst() {
            if interval.start <= end { end = max(end, interval.end) }
            else { total += end.timeIntervalSince(start); start = interval.start; end = interval.end }
        }
        return total + end.timeIntervalSince(start)
    }
}

public struct WatchSummary: Codable, Sendable {
    public var nightID: String
    public var sleepSeconds: Double?
    public var playedSeconds: Double
    public var soundTitle: String?
    public var refreshed: Int?
    public var fetchedAt: Date?
    public var acknowledgedFeedbackIDs: [UUID]
    public var generatedAt: Date
    public init(nightID: String, sleepSeconds: Double? = nil, playedSeconds: Double = 0, soundTitle: String? = nil, refreshed: Int? = nil, fetchedAt: Date? = nil, acknowledgedFeedbackIDs: [UUID] = [], generatedAt: Date = Date()) {
        self.nightID = nightID; self.sleepSeconds = sleepSeconds; self.playedSeconds = playedSeconds
        self.soundTitle = soundTitle; self.refreshed = refreshed; self.fetchedAt = fetchedAt
        self.acknowledgedFeedbackIDs = acknowledgedFeedbackIDs; self.generatedAt = generatedAt
    }
}

public enum DisplayFormat {
    public static func duration(_ seconds: Double) -> String {
        let minutes = Int(max(0, seconds.isFinite ? seconds : 0) / 60)
        if minutes < 1 { return "1分未満" }
        return minutes >= 60 ? "\(minutes / 60)時間\(minutes % 60)分" : "\(minutes)分"
    }
}
