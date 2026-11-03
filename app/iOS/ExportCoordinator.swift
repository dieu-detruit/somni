import Foundation
import Combine
import SomnioCore

@MainActor
final class ExportCoordinator: ObservableObject {
    @Published private(set) var preparing = false
    @Published private(set) var files: [URL] = []
    @Published private(set) var coverage: HealthCoverage?
    @Published var errorMessage: String?
    private let directory: URL
    private let reader = HealthSleepReader()
    private var generation = UUID()
    init() {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("SomnioAnalysisExports", isDirectory: true)
        cleanFiles()
    }
    func prepare(records: StoredRecords, firstDay: Date, lastDay: Date) async {
        guard !preparing else { return }
        clear(); let token = generation
        preparing = true
        defer { if generation == token { preparing = false } }
        do {
            let range = try ExportDateRange(firstDay: firstDay, lastDay: lastDay)
            let health = await reader.export(range: range)
            guard generation == token, !Task.isCancelled else { return }
            let bundle = AnalysisBundle(records: records, health: health,
                appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                buildVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete])
            var prepared: [URL] = []
            let json = directory.appendingPathComponent("analysis.json")
            try AnalysisEncoding.json(bundle).write(to: json, options: [.atomic, .completeFileProtection])
            prepared.append(json)
            let tables = bundle.csvTables()
            for name in tables.keys.sorted() {
                let url = directory.appendingPathComponent(name)
                try Data((tables[name] ?? "").utf8).write(to: url, options: [.atomic, .completeFileProtection])
                prepared.append(url)
            }
            files = prepared; coverage = health.coverage
        } catch { cleanFiles(); errorMessage = "書き出しを準備できませんでした。\(error.localizedDescription)" }
    }
    func clear() {
        generation = UUID(); preparing = false; files = []; coverage = nil; errorMessage = nil; cleanFiles()
    }
    private func cleanFiles() {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        do { try FileManager.default.removeItem(at: directory) }
        catch { errorMessage = "一時ファイルを削除できませんでした。\(error.localizedDescription)" }
    }
}
