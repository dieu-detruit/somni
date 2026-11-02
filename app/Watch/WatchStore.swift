import Foundation
import Combine
import WatchConnectivity
import SomnioCore

private struct WatchSavedState: Codable {
    var summary: WatchSummary?
    var pending: [MorningFeedback] = []
    var resetAt: Date?
}

@MainActor
final class WatchStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private var saved = WatchSavedState()
    @Published var errorMessage: String?
    private var session: WCSession?
    private let fileURL: URL
    var summary: WatchSummary { saved.summary ?? WatchSummary(nightID: Night.previous()) }
    var pendingCount: Int { saved.pending.count }
    var refreshed: Int? {
        let local = saved.pending.filter { $0.nightID == summary.nightID }.max {
            if $0.updatedAt == $1.updatedAt { return $0.id.uuidString < $1.id.uuidString }
            return $0.updatedAt < $1.updatedAt
        }
        return local?.refreshed ?? summary.refreshed
    }
    override init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Somnio", isDirectory: true)
        fileURL = directory.appendingPathComponent("watch.json")
        super.init()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) { saved = try JSONDecoder().decode(WatchSavedState.self, from: Data(contentsOf: fileURL)) }
        } catch { errorMessage = "記録を読み込めませんでした。" }
        if WCSession.isSupported() { session = .default; session?.delegate = self; session?.activate() }
    }
    @discardableResult private func persist() -> Bool {
        do { try JSONEncoder().encode(saved).write(to: fileURL, options: .atomic); return true }
        catch { errorMessage = "記録を保存できませんでした。もう一度お試しください。"; return false }
    }
    func rate(_ value: Int) {
        let event = MorningFeedback(nightID: summary.nightID, refreshed: value)
        saved.pending.append(event)
        guard persist() else { saved.pending.removeAll { $0.id == event.id }; return }
        errorMessage = nil; flush()
    }
    func flush() {
        guard let session, session.activationState == .activated else { return }
        let queuedIDs = Set(session.outstandingUserInfoTransfers.compactMap { transfer -> UUID? in
            guard let data = transfer.userInfo["feedback"] as? Data else { return nil }
            return (try? JSONDecoder().decode(MorningFeedback.self, from: data))?.id
        })
        for event in saved.pending where !queuedIDs.contains(event.id) {
            do { session.transferUserInfo(["feedback": try JSONEncoder().encode(event)]) }
            catch { errorMessage = "iPhoneへの同期を待っています。" }
        }
    }
    private func receive(_ context: [String: Any]) {
        guard let data = context["summary"] as? Data else { return }
        do {
            let incoming = try JSONDecoder().decode(WatchSummary.self, from: data)
            if let raw = context["resetAt"] as? Double {
                let cutoff = Date(timeIntervalSince1970: raw)
                if saved.resetAt.map({ cutoff > $0 }) ?? true {
                    saved.resetAt = cutoff
                    saved.pending.removeAll { $0.updatedAt < cutoff }
                    for transfer in session?.outstandingUserInfoTransfers ?? [] {
                        if let data = transfer.userInfo["feedback"] as? Data,
                           let event = try? JSONDecoder().decode(MorningFeedback.self, from: data), event.updatedAt < cutoff { transfer.cancel() }
                    }
                }
            }
            if saved.summary.map({ incoming.generatedAt >= $0.generatedAt }) ?? true { saved.summary = incoming }
            let acknowledged = Set(incoming.acknowledgedFeedbackIDs)
            saved.pending.removeAll { acknowledged.contains($0.id) }
            if persist() { errorMessage = nil }
            flush()
        } catch { errorMessage = "iPhoneの要約を読み込めませんでした。" }
    }
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error { self.errorMessage = "接続を待っています。\(error.localizedDescription)" }
            else { self.receive(session.receivedApplicationContext); self.flush() }
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.receive(applicationContext) }
    }
    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if error != nil { Task { @MainActor in self.errorMessage = "iPhoneへの同期を待っています。記録はWatchに保存されています。" } }
        // Only an explicit iPhone receipt removes a persisted event.
    }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) { Task { @MainActor in self.flush() } }
}
