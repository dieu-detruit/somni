import Foundation
import Combine
import SomnioCore

struct NightSleepRecord: Codable, Identifiable {
    var id: String
    var summaries: [SleepSummary]
    var selectedSourceID: String?
    var fetchedAt: Date
    var selected: SleepSummary? { summaries.first { $0.sourceID == selectedSourceID } ?? summaries.first }
}

private struct SavedState: Codable {
    var settings = SoundSettings()
    var sessions: [PlaybackSession] = []
    var feedback: [MorningFeedback] = []
    var sleep: [NightSleepRecord] = []
    var receivedEvents: [UUID] = []
    var resetAt: Date? = nil
}

@MainActor
final class AppStore: ObservableObject {
    @Published private var state = SavedState()
    @Published var errorMessage: String?
    var onChange: (() -> Void)?
    private let fileURL: URL
    private var writesBlocked = false
    var settings: SoundSettings { state.settings }
    var sessions: [PlaybackSession] { state.sessions }
    var feedback: [MorningFeedback] { state.feedback }
    var resetAt: Date? { state.resetAt }

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Somnio", isDirectory: true)
        fileURL = directory.appendingPathComponent("records.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do { state = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: fileURL)) }
                catch {
                    // Preserve the unreadable original before allowing any replacement writes.
                    let backup = directory.appendingPathComponent("records-unreadable-\(UUID().uuidString).json")
                    do { try FileManager.default.copyItem(at: fileURL, to: backup) }
                    catch { writesBlocked = true }
                    errorMessage = writesBlocked ? "以前の記録を読み込めないため、保存を停止しています。記録の削除で初期化できます。" : "以前の記録を読み込めませんでした。元のファイルを端末内に保全しました。"
                    return
                }
                var recovered = state
                for index in recovered.sessions.indices where recovered.sessions[index].endReason == nil { recovered.sessions[index].endReason = .unknown }
                try write(recovered); state = recovered
            }
        } catch { writesBlocked = true; errorMessage = "記録を読み込めませんでした。\(error.localizedDescription)" }
    }
    private func write(_ next: SavedState) throws {
        try JSONEncoder().encode(next).write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    @discardableResult private func mutate(_ body: (inout SavedState) -> Void) -> Bool {
        guard !writesBlocked else { errorMessage = "保存を停止しています。「このアプリ」で記録を削除すると初期化できます。"; return false }
        var next = state; body(&next)
        do { try write(next); state = next; onChange?(); return true }
        catch { errorMessage = "記録を保存できませんでした。\(error.localizedDescription)"; return false }
    }
    func updateSettings(_ settings: SoundSettings) { mutate { $0.settings = settings } }
    func begin(settings: SoundSettings) -> UUID? {
        let session = PlaybackSession(settings: settings)
        return mutate({ $0.sessions.insert(session, at: 0) }) ? session.id : nil
    }
    func changeSession(_ id: UUID, settings: SoundSettings) {
        mutate { next in
            guard let index = next.sessions.firstIndex(where: { $0.id == id }) else { return }
            next.sessions[index].changes.append(SettingsChange(settings: settings))
        }
    }
    func end(_ id: UUID, seconds: Double, reason: PlaybackEnd) {
        mutate { next in
            guard let index = next.sessions.firstIndex(where: { $0.id == id }) else { return }
            next.sessions[index].endedAt = Date(); next.sessions[index].playedSeconds = seconds; next.sessions[index].endReason = reason
        }
    }
    func rating(for nightID: String) -> MorningFeedback? { state.feedback.first { $0.nightID == nightID } }
    func sleep(for nightID: String) -> NightSleepRecord? { state.sleep.first { $0.id == nightID } }
    func sessions(for nightID: String) -> [PlaybackSession] { state.sessions.filter { $0.nightID == nightID } }
    func setSleep(_ record: NightSleepRecord) { mutate { $0.sleep.removeAll { $0.id == record.id }; $0.sleep.append(record) } }
    func selectSource(_ sourceID: String, nightID: String) {
        mutate { next in
            guard let index = next.sleep.firstIndex(where: { $0.id == nightID }) else { return }
            next.sleep[index].selectedSourceID = sourceID
        }
    }
    func receive(_ rating: MorningFeedback, fromWatch: Bool = false) {
        if fromWatch && state.receivedEvents.contains(rating.id) {
            mutate { next in next.receivedEvents.removeAll { $0 == rating.id }; next.receivedEvents.append(rating.id) }
            return
        }
        mutate { next in
            if fromWatch { next.receivedEvents.append(rating.id) }
            guard next.resetAt.map({ rating.updatedAt >= $0 }) ?? true else { return }
            if let index = next.feedback.firstIndex(where: { $0.nightID == rating.nightID }) {
                let existing = next.feedback[index]
                if MorningFeedback.latest(existing, rating).id == rating.id {
                    var merged = rating
                    if fromWatch { merged.easeOfSleep = existing.easeOfSleep; merged.note = existing.note }
                    next.feedback[index] = merged
                }
            } else { next.feedback.append(rating) }
        }
        // Receipts are published only after the file has been atomically saved.
    }
    func watchSummary() -> WatchSummary {
        let night = Night.previous(); let sessions = sessions(for: night); let sleep = sleep(for: night)
        return WatchSummary(nightID: night, sleepSeconds: sleep?.selected?.totalSleep,
            playedSeconds: sessions.filter { $0.endReason != .unknown }.reduce(0) { $0 + $1.playedSeconds }, soundTitle: sessions.first?.settings.mode.title,
            refreshed: rating(for: night)?.refreshed, fetchedAt: sleep?.fetchedAt, acknowledgedFeedbackIDs: Array(state.receivedEvents.suffix(256)))
    }
    func deleteAll() {
        writesBlocked = false
        guard mutate({ next in next = SavedState(); next.resetAt = Date() }) else { return }
        do {
            let directory = fileURL.deletingLastPathComponent()
            for backup in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                where backup.lastPathComponent.hasPrefix("records-unreadable-") {
                try FileManager.default.removeItem(at: backup)
            }
        } catch { errorMessage = "記録は初期化しましたが、保全ファイルを削除できませんでした。\(error.localizedDescription)" }
    }
}
