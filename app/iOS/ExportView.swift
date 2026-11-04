import SwiftUI
import UIKit
import SomnioCore

struct ExportView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var export = ExportCoordinator()
    @State private var firstDay = Calendar.current.date(byAdding: .day, value: -13, to: Date()) ?? Date()
    @State private var lastDay = Date()
    @State private var sharing = false
    var body: some View {
        Form {
            descriptionSection
            rangeSection
            preparationSection
        }.navigationTitle("分析用データ").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $sharing, onDismiss: { export.clear() }) {
                AnalysisShareSheet(files: export.files) { sharing = false }
            }
            .onChange(of: firstDay) { _, _ in export.clear() }
            .onChange(of: lastDay) { _, _ in export.clear() }
            .onDisappear { if !sharing { export.clear() } }
    }
    private var descriptionSection: some View {
        Section("含まれるデータを確認") {
            Text("アプリ内の全期間の再生履歴（途中の設定変更を含む）、朝の評価、日中の記録、メモ、自動同期した全期間の睡眠区間、以前取り込んだ睡眠記録を含みます。")
            Text("加えて、下で選んだ日付範囲のヘルスケア睡眠データを読み込みます。日中の昼寝や朝の睡眠も対象です。範囲はヘルスケアの読み込みにだけ適用し、アプリ内の記録は全期間を書き出します。")
            Text("JSONが正式なデータです。確認用のCSVも同時に共有できます。共有先に健康情報とメモが渡るため、内容と送信先を確認してください。自動アップロードは行いません。")
            Text("音量はアプリ内の設定値です。端末の実際の音量や耳元の音の大きさは記録していません。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var rangeSection: some View {
        Section("ヘルスケアを読み込む日付範囲") {
            DatePicker("開始日", selection: $firstDay, displayedComponents: .date)
            DatePicker("終了日（この日を含む）", selection: $lastDay, displayedComponents: .date)
            Text("現在のタイムゾーン「\(TimeZone.current.identifier)」の午前0時〜終了日の翌午前0時。境界をまたぐ記録は、元の開始・終了時刻を保って含めます。")
                .font(.caption).foregroundStyle(.secondary)
        }.disabled(export.preparing)
    }
    private var preparationSection: some View {
        Section("書き出し") {
            if export.preparing { ProgressView("ヘルスケアの取得とファイルの準備中…") }
            if let coverage = export.coverage { CoveragePreview(coverage: coverage, fileCount: export.files.count) }
            if let message = export.errorMessage { Text(message).foregroundStyle(.orange).font(.caption) }
            if export.files.isEmpty {
                Button("内容を準備する") {
                    let records = store.exportSnapshot
                    Task { await export.prepare(records: records, firstDay: firstDay, lastDay: lastDay) }
                }.disabled(export.preparing)
            } else {
                Button { sharing = true } label: { Label("確認して共有する", systemImage: "square.and.arrow.up") }
                Button("一時ファイルを削除", role: .destructive) { export.clear() }
            }
            Text("共有を完了・キャンセルするか、この画面を離れると一時ファイルを削除します。共有先に保存したコピーは共有先で管理してください。ヘルスケアの原本は変更しません。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct CoveragePreview: View {
    let coverage: HealthCoverage
    let fileCount: Int
    private var status: String {
        switch coverage.status {
        case .available: return "ヘルスケア \(coverage.sampleCount)区間"
        case .noSamplesOrNotAuthorized: return "ヘルスケアの区間を取得できませんでした"
        case .queryFailed: return "ヘルスケアの取得でエラーがありました"
        case .unavailable: return "この端末ではヘルスケアを利用できません"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("準備できました · \(fileCount)ファイル").font(.headline)
            Text(status)
            Text("アプリ内記録は全期間。自動同期の最終時刻と区間数、今回取得できなかった範囲やエラーもJSONとCSVに含まれます。区間がない場合は、未同期や読み取り不許可などを区別できません。")
                .font(.caption).foregroundStyle(.secondary)
            if let error = coverage.errorDescription { Text(error).font(.caption).foregroundStyle(.orange) }
        }
    }
}

private struct AnalysisShareSheet: UIViewControllerRepresentable {
    let files: [URL]
    let completed: () -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: files, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in DispatchQueue.main.async { completed() } }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
