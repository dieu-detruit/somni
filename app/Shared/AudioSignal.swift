import Foundation

/// State belongs to one audio render thread. All time, including fades, follows rendered samples.
public struct AudioSignal {
    public static let version = "2"
    public static let peakLimit: Float = 0.22
    public private(set) var settings: SoundSettings
    private let sampleRate: Double
    private var frame: Int64 = 0
    private var random: UInt64 = 0xD1B54A32D192ED03
    private var lowNoise: Double = 0
    private var manualEndFrame: Int64?
    private var manualStartFrame: Int64?
    private var phase1: Double = 0
    private var phase2: Double = 0
    private var wavePhase: Double = 0
    private var gain: Double = 0
    private var beatMix: Double = 0
    private var ambienceGain: Double = 1
    private var beatGain: Double = 1
    private var beatRate: Double = 4
    public var elapsedSeconds: Double { Double(frame) / sampleRate }
    private var timerFrames: Int64? { settings.timerMinutes.map { Int64(Double($0) * 60 * sampleRate) } }
    private var endFrame: Int64? {
        switch (timerFrames, manualEndFrame) {
        case let (a?, b?): return min(a, b)
        case let (a?, nil): return a
        case let (nil, b?): return b
        case (nil, nil): return nil
        }
    }
    public var isFinished: Bool { endFrame.map { frame >= $0 } ?? false }

    public init(settings: SoundSettings, sampleRate: Double = 44_100) {
        self.settings = settings.normalized
        ambienceGain = self.settings.ambienceGain; beatGain = self.settings.beatGain; beatRate = self.settings.beatRateHz
        self.sampleRate = sampleRate.isFinite && sampleRate >= 1 ? sampleRate : 44_100
    }
    public mutating func update(settings: SoundSettings) {
        self.settings = settings.normalized
    }
    public mutating func beginFadeOut(seconds: Double = 2) {
        guard manualEndFrame == nil else { return }
        manualStartFrame = frame
        manualEndFrame = frame + Int64(max(0, seconds.isFinite ? seconds : 0) * sampleRate)
    }
    public mutating func next() -> Float {
        guard !isFinished else { return 0 }
        random ^= random << 13; random ^= random >> 7; random ^= random << 17
        let white = Double(random & 0xFFFF) / 32767.5 - 1
        lowNoise = lowNoise * 0.985 + white * 0.015
        let wave = 0.6 + 0.4 * sin(wavePhase)
        wavePhase = (wavePhase + 2 * .pi * 0.07 / sampleRate).truncatingRemainder(dividingBy: 2 * .pi)
        let noise = lowNoise * 3.5 * wave
        beatMix += ((settings.mode == .beat ? 1.0 : 0.0) - beatMix) * min(1, 1 / (sampleRate * 0.25))
        ambienceGain += (settings.ambienceGain - ambienceGain) * min(1, 1 / (sampleRate * 0.15))
        beatGain += (settings.beatGain - beatGain) * min(1, 1 / (sampleRate * 0.15))
        beatRate += (settings.beatRateHz - beatRate) * min(1, 1 / (sampleRate * 0.25))
        let beat = (sin(phase1) + sin(phase2)) * 0.13 * beatMix
        phase1 = (phase1 + 2 * .pi * 180 / sampleRate).truncatingRemainder(dividingBy: 2 * .pi)
        phase2 = (phase2 + 2 * .pi * (180 + beatRate) / sampleRate).truncatingRemainder(dividingBy: 2 * .pi)
        gain += (settings.volume - gain) * min(1, 1 / (sampleRate * 0.15))
        var envelope = min(1, Double(frame) / (sampleRate * 3))
        if let timerFrames { envelope *= min(1, max(0, Double(timerFrames - frame) / (sampleRate * 10))) }
        if let end = manualEndFrame, let start = manualStartFrame {
            envelope *= min(1, max(0, Double(end - frame) / Double(max(1, end - start))))
        }
        frame += 1
        let sample = (noise * ambienceGain + beat * beatGain) * gain * envelope * 0.5
        return sample.isFinite ? Float(min(Double(Self.peakLimit), max(-Double(Self.peakLimit), sample))) : 0
    }
}
