import Foundation
import Combine
import SomnioCore

@MainActor
final class ExportCoordinator: ObservableObject {
    @Published private(set) var preparing = false
    @Published private(set) var files: [URL] = []
    @Published private(set) var coverage: HealthCoverage?
    @Published var errorMessage: String?
    static var temporaryDirectory: URL { FileManager.default.temporaryDirectory.appendingPathComponent("SomnioAnalysisExports", isDirectory: true) }
    private let reader = HealthSleepReader()
    private var generation = UUID()
    private var activeDirectory: URL?
    private var writer: Task<[URL], Error>?

    init() { cleanPreviousExports() }

    func prepare(records: StoredRecords, firstDay: Date, lastDay: Date) async {
        guard !preparing else { return }
        clear(); let token = generation
        preparing = true
        defer { if generation == token { preparing = false; writer = nil } }
        let directory = Self.temporaryDirectory.appendingPathComponent(token.uuidString, isDirectory: true)
        do {
            let range = try ExportDateRange(firstDay: firstDay, lastDay: lastDay)
            let health = await reader.export(range: range)
            guard generation == token, !Task.isCancelled else { return }
            let bundle = AnalysisBundle(records: records, health: health,
                appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                buildVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown")
            activeDirectory = directory
            let task = Task.detached(priority: .userInitiated) {
                try AnalysisFileWorker.write(bundle: bundle, directory: directory)
            }
            writer = task
            let prepared = try await task.value
            guard generation == token, !Task.isCancelled else {
                // This generation owns only its UUID directory, even if a newer export exists.
                try? FileManager.default.removeItem(at: directory)
                return
            }
            files = prepared; coverage = health.coverage
        } catch {
            try? FileManager.default.removeItem(at: directory)
            guard generation == token else { return }
            activeDirectory = nil
            if !(error is CancellationError) { errorMessage = "書き出しを準備できませんでした。\(error.localizedDescription)" }
        }
    }
    func clear() {
        generation = UUID(); writer?.cancel(); writer = nil; preparing = false; files = []; coverage = nil; errorMessage = nil
        if let directory = activeDirectory {
            do { if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) } }
            catch { errorMessage = "一時ファイルを削除できませんでした。\(error.localizedDescription)" }
        }
        activeDirectory = nil
    }
    private func cleanPreviousExports() {
        let directory = Self.temporaryDirectory
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        do { try FileManager.default.removeItem(at: directory) }
        catch { errorMessage = "以前の一時ファイルを削除できませんでした。\(error.localizedDescription)" }
    }
}

/// Pure file generation runs on a detached task; no UI or mutable app state crosses this boundary.
private enum AnalysisFileWorker {
    static func write(bundle: AnalysisBundle, directory: URL) throws -> [URL] {
        do {
            try Task.checkCancellation()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete])
            let jsonData = try AnalysisEncoding.json(bundle)
            try Task.checkCancellation()
            let json = directory.appendingPathComponent("analysis.json")
            try jsonData.write(to: json, options: [.atomic, .completeFileProtection])
            var files = [json]
            let tables = bundle.csvTables()
            for name in tables.keys.sorted() {
                try Task.checkCancellation()
                let url = directory.appendingPathComponent(name)
                try Data((tables[name] ?? "").utf8).write(to: url, options: [.atomic, .completeFileProtection])
                files.append(url)
            }
            try Task.checkCancellation()
            return files
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }
}
