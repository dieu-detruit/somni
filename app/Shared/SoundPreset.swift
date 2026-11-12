import Foundation

public struct SoundPreset: Codable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let settings: SoundSettings
    public let createdAt: Date
    public init(id: UUID = UUID(), name: String, settings: SoundSettings, createdAt: Date = Date()) {
        self.id = id
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = String((clean.isEmpty ? "お気に入り" : clean).prefix(80))
        self.settings = settings.normalized; self.createdAt = createdAt
    }
}

public enum StarterSound: String, CaseIterable, Identifiable {
    case music, musicBeat, musicIntro, pure852, original
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .music: return "淡い和音"
        case .musicBeat: return "音楽とゆっくりしたうなり"
        case .musicIntro: return "音楽と14 Hzの導入"
        case .pure852: return "852 Hzの単音"
        case .original: return "もとの波とビート"
        }
    }
    public var settings: SoundSettings {
        switch self {
        case .music: return SoundSettings(ambienceGain: 0, beatGain: 0, musicGain: 0.8)
        case .musicBeat: return SoundSettings(mode: .beat, ambienceGain: 0, beatGain: 0.25, beatRateHz: 4, musicGain: 0.8)
        case .musicIntro: return SoundSettings(mode: .beat, ambienceGain: 0, beatGain: 0.2, binauralIntro: true, musicGain: 0.8, introGain: 0.35)
        case .pure852: return SoundSettings(mode: .beat, ambienceGain: 0, beatGain: 0.4, beatRateHz: 0, toneFrequencyHz: 852)
        case .original: return SoundSettings(mode: .beat)
        }
    }
}
