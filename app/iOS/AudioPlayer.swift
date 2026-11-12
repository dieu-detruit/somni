import AVFoundation
import MediaPlayer
import Combine
import UIKit
import SomnioCore

private final class RenderState: @unchecked Sendable {
    private let lock = NSLock()
    private var signal: AudioSignal
    private var announcedEnd = false
    init(settings: SoundSettings, sampleRate: Double, introDelivery: IntroDelivery) {
        signal = AudioSignal(settings: settings, sampleRate: sampleRate, introDelivery: introDelivery)
    }
    var elapsed: Double { lock.lock(); defer { lock.unlock() }; return signal.elapsedSeconds }
    func update(_ settings: SoundSettings) { lock.lock(); signal.update(settings: settings); lock.unlock() }
    func fade() { lock.lock(); signal.beginFadeOut(); lock.unlock() }
    func render(_ frames: AVAudioFrameCount, into buffers: UnsafeMutablePointer<AudioBufferList>) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let list = UnsafeMutableAudioBufferListPointer(buffers)
        for frame in 0..<Int(frames) {
            let sample = signal.nextStereo()
            for (channel, buffer) in list.enumerated() {
                guard let data = buffer.mData else { continue }
                data.assumingMemoryBound(to: Float.self)[frame] = channel == 0 ? sample.left : sample.right
            }
        }
        if signal.isFinished && !announcedEnd { announcedEnd = true; return true }
        return false
    }
}

@MainActor
final class AudioPlayer: ObservableObject {
    enum State { case idle, playing, stopping, stopped, interrupted, failed }
    @Published private(set) var state: State = .idle
    @Published private(set) var elapsed: Double = 0
    @Published var errorMessage: String?
    @Published private(set) var lastEnd: PlaybackEnd?
    @Published private(set) var introDelivery: IntroDelivery?
    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var renderState: RenderState?
    private weak var store: AppStore?
    private var sessionID: UUID?
    private var stoppingReason: PlaybackEnd?
    private var pollTimer: Timer?
    private var observers: [NSObjectProtocol] = []
    var active: Bool { state == .playing || state == .stopping }

    init(store: AppStore) {
        self.store = store
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            Task { @MainActor in self?.finish(reason: .interrupted) }
        })
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: raw),
                  [.oldDeviceUnavailable, .newDeviceAvailable, .override, .routeConfigurationChange].contains(reason) else { return }
            Task { @MainActor in if self?.active == true { self?.finish(reason: .routeChanged) } }
        })
        observers.append(NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            Task { @MainActor in
                if let self, self.active, !self.engine.isRunning { self.finish(reason: .failed); self.errorMessage = "音声の構成が変わったため停止しました。もう一度再生できます。" }
            }
        })
        observers.append(NotificationCenter.default.addObserver(forName: UIAccessibility.monoAudioStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in if self?.active == true { self?.finish(reason: .routeChanged) } }
        })
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.stop() }; return .success
        }
        MPRemoteCommandCenter.shared().stopCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.stop() }; return .success
        }
    }
    func start(settings: SoundSettings) {
        guard !active else { return }
        errorMessage = nil; lastEnd = nil; elapsed = 0; stoppingReason = nil; introDelivery = nil
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            let delivery = IntroDelivery.resolve(mode: settings.introMode, headphonesLikely: hasExternalAudioRoute,
                stereoAvailable: audioSession.outputNumberOfChannels >= 2, monoAudioEnabled: UIAccessibility.isMonoAudioEnabled)
            guard let id = store?.begin(settings: settings, introDelivery: settings.binauralIntro ? delivery : nil) else { throw PlayerError.recordingUnavailable }
            sessionID = id
            introDelivery = settings.binauralIntro ? delivery : nil
            let rate = audioSession.sampleRate
            guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2) else { throw PlayerError.invalidFormat }
            let render = RenderState(settings: settings, sampleRate: rate, introDelivery: delivery)
            renderState = render
            let node = AVAudioSourceNode(format: format) { [weak self, render] _, _, frameCount, buffers in
                if render.render(frameCount, into: buffers) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self, self.renderState === render else { return }
                        self.finish(reason: self.stoppingReason ?? .timer)
                    }
                }
                return noErr
            }
            source = node; engine.attach(node); engine.connect(node, to: engine.mainMixerNode, format: format)
            engine.prepare(); try engine.start(); state = .playing
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.elapsed = self.renderState?.elapsed ?? self.elapsed
                }
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: "Somnio · " + settings.title,
                MPMediaItemPropertyArtist: "今夜のやすらぎ", MPNowPlayingInfoPropertyPlaybackRate: 1.0]
        } catch {
            errorMessage = "音を再生できませんでした。\(error.localizedDescription)"
            if sessionID != nil { finish(reason: .failed) }
            else {
                state = .failed; introDelivery = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
    }
    func update(settings: SoundSettings) {
        guard active, state != .stopping else { return }
        renderState?.update(settings)
        if let sessionID { store?.changeSession(sessionID, settings: settings) }
    }
    func stop() {
        guard state == .playing else { return }
        stoppingReason = .stopped; state = .stopping; renderState?.fade()
    }
    private func finish(reason: PlaybackEnd) {
        guard sessionID != nil else { return }
        elapsed = renderState?.elapsed ?? elapsed
        engine.stop()
        if let source { engine.detach(source) }
        source = nil; renderState = nil; pollTimer?.invalidate(); pollTimer = nil
        if let sessionID { store?.end(sessionID, seconds: elapsed, reason: reason) }
        sessionID = nil; lastEnd = reason
        state = reason == .failed ? .failed : reason == .interrupted ? .interrupted : .stopped
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private var hasExternalAudioRoute: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains {
            [.headphones, .bluetoothA2DP, .bluetoothLE, .usbAudio].contains($0.portType)
        }
    }
    private enum PlayerError: LocalizedError {
        case invalidFormat, recordingUnavailable
        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "音声の形式を準備できませんでした。"
            case .recordingUnavailable: return "再生の記録を保存できませんでした。保存エラーを確認してください。"
            }
        }
    }
}
