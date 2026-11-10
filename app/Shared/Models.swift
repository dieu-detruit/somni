import Foundation

public enum SoundMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case ambience, beat
    public var id: String { rawValue }
    public var title: String { self == .ambience ? "やわらかな波音" : "波音 + ゆるやかなビート" }
    public var detail: String { self == .ambience ? "静かなノイズが、寄せては返す" : "波音に穏やかなうなりを重ねる" }
}

public struct SoundSettings: Codable, Equatable, Sendable {
    public static let exploratoryRates: [Double] = [1, 2, 3, 4, 6]
    public var mode: SoundMode
    public var volume: Double
    public var timerMinutes: Int?
    public var ambienceGain: Double
    public var beatGain: Double
    public var beatRateHz: Double
    public var binauralIntro: Bool
    public var introMode: IntroMode
    public init(mode: SoundMode = .ambience, volume: Double = 0.2, timerMinutes: Int? = 30,
                ambienceGain: Double = 1, beatGain: Double = 1, beatRateHz: Double = 4, binauralIntro: Bool = false, introMode: IntroMode = .automatic) {
        self.mode = mode
        self.volume = volume.isFinite ? min(1, max(0, volume)) : 0
        self.timerMinutes = timerMinutes.map { min(480, max(1, $0)) }
        self.ambienceGain = ambienceGain.isFinite ? min(1, max(0, ambienceGain)) : 1
        self.beatGain = beatGain.isFinite ? min(1, max(0, beatGain)) : 1
        self.beatRateHz = beatRateHz.isFinite ? min(6, max(1, beatRateHz)) : 4
        self.binauralIntro = binauralIntro
        self.introMode = introMode
    }
    private enum CodingKeys: String, CodingKey { case mode, volume, timerMinutes, ambienceGain, beatGain, beatRateHz, binauralIntro, introMode }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(mode: try values.decode(SoundMode.self, forKey: .mode),
                  volume: try values.decode(Double.self, forKey: .volume),
                  timerMinutes: try values.decodeIfPresent(Int.self, forKey: .timerMinutes),
                  ambienceGain: try values.decodeIfPresent(Double.self, forKey: .ambienceGain) ?? 1,
                  beatGain: try values.decodeIfPresent(Double.self, forKey: .beatGain) ?? 1,
                  beatRateHz: try values.decodeIfPresent(Double.self, forKey: .beatRateHz) ?? 4,
                  binauralIntro: try values.decodeIfPresent(Bool.self, forKey: .binauralIntro) ?? false,
                  introMode: try values.decodeIfPresent(IntroMode.self, forKey: .introMode) ?? .automatic)
    }
    public var normalized: Self { Self(mode: mode, volume: volume, timerMinutes: timerMinutes, ambienceGain: ambienceGain, beatGain: beatGain, beatRateHz: beatRateHz, binauralIntro: binauralIntro, introMode: introMode) }
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
    public let audioVersion: String
    public let introDelivery: IntroDelivery?
    public init(settings: SoundSettings, startedAt: Date = Date(), introDelivery: IntroDelivery? = nil) {
        id = UUID(); nightID = Night.key(for: startedAt); self.startedAt = startedAt
        playedSeconds = 0; changes = [SettingsChange(settings: settings, at: startedAt)]; audioVersion = AudioSignal.version
        self.introDelivery = settings.binauralIntro ? introDelivery : nil
    }
    private enum CodingKeys: String, CodingKey { case id, nightID, startedAt, endedAt, playedSeconds, endReason, changes, audioVersion, introDelivery }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        nightID = try values.decode(String.self, forKey: .nightID)
        startedAt = try values.decode(Date.self, forKey: .startedAt)
        endedAt = try values.decodeIfPresent(Date.self, forKey: .endedAt)
        playedSeconds = try values.decode(Double.self, forKey: .playedSeconds)
        endReason = try values.decodeIfPresent(PlaybackEnd.self, forKey: .endReason)
        changes = try values.decode([SettingsChange].self, forKey: .changes)
        audioVersion = try values.decodeIfPresent(String.self, forKey: .audioVersion) ?? "1"
        introDelivery = try values.decodeIfPresent(IntroDelivery.self, forKey: .introDelivery)
            ?? (audioVersion == "3" && changes.first?.settings.binauralIntro == true ? .binaural : nil)
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
    public static func label(for key: String, calendar: Calendar = .current) -> String {
        guard let window = window(for: key, calendar: calendar) else { return key }
        let morning = calendar.dateComponents([.month, .day], from: window.end)
        return "\(key) 夜 → \(morning.month ?? 1)/\(morning.day ?? 1) 朝"
    }
    public static func previous(for date: Date = Date(), calendar: Calendar = .current) -> String {
        // Before noon the current night already denotes last evening; after noon go back one day.
        if calendar.component(.hour, from: date) < 12 { return key(for: date, calendar: calendar) }
        return key(for: calendar.date(byAdding: .day, value: -1, to: date) ?? date, calendar: calendar)
    }
}

/// Keeps the latest morning selected until the user explicitly browses an older night.
public struct HistoryNightSelection: Sendable {
    public private(set) var selectedNight: String
    private var currentNight: String
    private var followsLatest = true

    public init(date: Date = Date(), calendar: Calendar = .current) {
        let current = Night.previous(for: date, calendar: calendar)
        currentNight = current; selectedNight = current
    }
    public mutating func select(_ nightID: String) {
        selectedNight = nightID
        followsLatest = nightID == currentNight
    }
    public mutating func refresh(date: Date = Date(), calendar: Calendar = .current) {
        currentNight = Night.previous(for: date, calendar: calendar)
        if followsLatest { selectedNight = currentNight }
    }
}

public enum SleepStage: String, Codable, CaseIterable, Sendable {
    case inBed, awake, unspecified, core, deep, rem, unrecognized
    public var isAsleep: Bool { [.unspecified, .core, .deep, .rem].contains(self) }
    public var title: String {
        switch self {
        case .inBed: return "就床"
        case .awake: return "覚醒"
        case .unspecified: return "段階不明"
        case .core: return "コア"
        case .deep: return "深い睡眠"
        case .rem: return "レム"
        case .unrecognized: return "未対応の段階"
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
    public var sourceBundleIdentifier: String?
    public var sourceVersion: String?
    public var productType: String?
    public var deviceModel: String?
    public var isUserEntered: Bool?
    public var categoryValue: Int?
    public init(id: String, start: Date, end: Date, stage: SleepStage, sourceID: String, sourceName: String, isAppleWatch: Bool,
                sourceBundleIdentifier: String? = nil, sourceVersion: String? = nil, productType: String? = nil, deviceModel: String? = nil, isUserEntered: Bool? = nil, categoryValue: Int? = nil) {
        self.id = id; self.start = start; self.end = end; self.stage = stage
        self.sourceID = sourceID; self.sourceName = sourceName; self.isAppleWatch = isAppleWatch
        self.sourceBundleIdentifier = sourceBundleIdentifier; self.sourceVersion = sourceVersion
        self.productType = productType; self.deviceModel = deviceModel; self.isUserEntered = isUserEntered; self.categoryValue = categoryValue
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
