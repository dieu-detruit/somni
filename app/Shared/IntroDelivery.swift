import Foundation

public enum IntroMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic, binaural, monaural
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .automatic: return "自動"
        case .binaural: return "バイノーラル"
        case .monaural: return "モノラル"
        }
    }
}

/// Generated channel format; this does not certify sound delivery to each ear.
public enum IntroDelivery: String, Codable, Sendable {
    case binaural, monaural
    public var title: String { self == .binaural ? "バイノーラル" : "モノラル" }
    public static func resolve(mode: IntroMode, headphonesLikely: Bool, stereoAvailable: Bool, monoAudioEnabled: Bool) -> Self {
        guard stereoAvailable, !monoAudioEnabled else { return .monaural }
        switch mode {
        case .automatic: return headphonesLikely ? .binaural : .monaural
        case .binaural: return .binaural
        case .monaural: return .monaural
        }
    }
}
