import Foundation

public enum MusicTimbre: String, Codable, CaseIterable, Identifiable, Sendable {
    case warmPad, softKeys
    public var id: String { rawValue }
    public var title: String { self == .warmPad ? "柔らかなパッド" : "淡い鍵盤" }
}

/// Original, deterministic four-chord music. Adjacent chords overlap; all voices keep phase.
struct AmbientMusic {
    private static let notes = [48, 55, 59, 62, 45, 52, 55, 60, 41, 48, 52, 55, 43, 50, 55, 57]
    private var phases = Array(repeating: 0.0, count: 16)
    private let increments: [Double]
    private let sampleRate: Double
    private var position = 0.0

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        increments = Self.notes.map { 2 * .pi * 440 * pow(2, (Double($0) - 69) / 12) / sampleRate }
    }

    mutating func next(keysMix: Double, brightness: Double, motion: Double) -> StereoSample {
        let chord = Int(position) % 4
        let fraction = position - floor(position)
        let fade = min(1, max(0, (fraction - 2.0 / 3) * 3))
        let blend = fade * fade * (3 - 2 * fade)
        var left = 0.0, right = 0.0
        for bank in 0..<2 {
            let weight = bank == 0 ? 1 - blend : blend
            let base = ((chord + bank) % 4) * 4
            for voice in 0..<4 {
                let phase = phases[base + voice]
                let tone = sin(phase) + brightness * (0.25 * sin(2 * phase) + 0.1 * sin(3 * phase))
                let noteCycle = (position * 4 + Double(voice) * 0.2).truncatingRemainder(dividingBy: 1)
                let bell = pow(sin(.pi * noteCycle), 2)
                let articulation = 1 - keysMix + keysMix * bell
                let value = tone * articulation * weight * 0.028
                let pan = (Double(voice) - 1.5) * 0.1
                left += value * (1 - pan); right += value * (1 + pan)
            }
        }
        for index in phases.indices {
            phases[index] = (phases[index] + increments[index]).truncatingRemainder(dividingBy: 2 * .pi)
        }
        position = (position + 1 / (sampleRate * (48 - motion * 24))).truncatingRemainder(dividingBy: 4)
        return StereoSample(left: Float(left), right: Float(right))
    }
}
