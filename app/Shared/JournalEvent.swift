import Foundation

public enum JournalKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case sleepiness, bedtime, nap, morningResleep
    public var id: String { rawValue }
    public var isInterval: Bool { self == .nap || self == .morningResleep }
    public var title: String {
        switch self {
        case .sleepiness: return "眠気"
        case .bedtime: return "就寝"
        case .nap: return "昼寝"
        case .morningResleep: return "朝の二度寝"
        }
    }
    public var symbol: String {
        switch self { case .sleepiness: return "eye"; case .bedtime: return "bed.double"; case .nap: return "sun.haze"; case .morningResleep: return "sunrise" }
    }
}

public enum JournalValidationError: LocalizedError {
    case invalidInterval, invalidSeverity
    public var errorDescription: String? {
        switch self { case .invalidInterval: return "終了時刻は開始時刻より後にしてください。"; case .invalidSeverity: return "眠気の強さは1〜5で記録してください。" }
    }
}

public struct JournalEvent: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: JournalKind
    public let start: Date
    public let end: Date?
    public let severity: Int?
    public let note: String
    public let createdAt: Date
    public let updatedAt: Date
    public let timeZoneIdentifier: String
    public let utcOffsetSeconds: Int
    public let provenance: String

    public init(id: UUID = UUID(), kind: JournalKind, start: Date = Date(), end: Date? = nil, severity: Int? = nil,
                note: String = "", createdAt: Date? = nil, updatedAt: Date = Date(), timeZone: TimeZone = .current) throws {
        guard !kind.isInterval || end.map({ $0 > start }) == true else { throw JournalValidationError.invalidInterval }
        guard severity.map({ (1...5).contains($0) }) ?? true else { throw JournalValidationError.invalidSeverity }
        self.id = id; self.kind = kind; self.start = start; self.end = kind.isInterval ? end : nil
        self.severity = kind == .sleepiness ? severity : nil; self.note = String(note.prefix(4000))
        self.createdAt = createdAt ?? updatedAt; self.updatedAt = updatedAt
        timeZoneIdentifier = timeZone.identifier; utcOffsetSeconds = timeZone.secondsFromGMT(for: start)
        provenance = "selfReported"
    }
}
