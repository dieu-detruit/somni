import Foundation
import WatchConnectivity
import Combine
import SomnioCore

@MainActor
final class PhoneConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    @Published var message: String?
    private weak var store: AppStore?
    private var session: WCSession?
    init(store: AppStore) {
        self.store = store; super.init()
        guard WCSession.isSupported() else { return }
        session = .default; session?.delegate = self; session?.activate()
        store.onChange = { [weak self] in self?.sendSummary() }
    }
    func sendSummary() {
        guard let session, session.activationState == .activated, session.isPaired, let store else { return }
        do {
            let data = try JSONEncoder().encode(store.watchSummary())
            var context: [String: Any] = ["summary": data]
            if let resetAt = store.resetAt { context["resetAt"] = resetAt.timeIntervalSince1970 }
            try session.updateApplicationContext(context)
            message = nil
        } catch { message = "Watchへの同期を待っています。\(error.localizedDescription)" }
    }
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error { self.message = "Watchに接続できませんでした。\(error.localizedDescription)" }
            else { self.sendSummary() }
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["feedback"] as? Data else { return }
        Task { @MainActor in
            do { self.store?.receive(try JSONDecoder().decode(MorningFeedback.self, from: data), fromWatch: true) }
            catch { self.message = "Watchの記録を読み込めませんでした。" }
        }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) { Task { @MainActor in self.sendSummary() } }
}
