import SwiftUI
import SomnioCore

struct SleepSyncStatusView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthSleepReader
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let date = store.sleepSync.lastSyncAt { Text("最終同期: " + date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
            if health.loading { ProgressView("未同期の睡眠記録を確認中… \(health.importedCount)区間") }
            if let message = health.message { Text(message).font(.caption).foregroundStyle(.secondary) }
            if store.sleepSync.connection == .enabled {
                Text("日付を選ばなくても、アプリを開くと未同期の記録を読み込みます。履歴に日付の上限はありません。")
                    .font(.caption).foregroundStyle(.secondary)
                Button("未同期の記録を確認") { Task { await health.synchronize() } }.disabled(health.loading)
                Button("全履歴を再確認（許可の変更後など）") { Task { await health.synchronize(fullRescan: true) } }.font(.caption).disabled(health.loading)
            } else {
                Text(store.sleepSync.connection == .pausedAfterDeletion ? "記録を削除したため自動同期を停止しています。再接続するとヘルスケアから読み込みます。" : "最初に接続すると、読み取れる睡眠記録をすべて取り込みます。")
                    .font(.caption).foregroundStyle(.secondary)
                Button("ヘルスケアに接続して取り込む") { Task { await health.connect() } }.disabled(health.loading)
            }
            Text("自動取得はアプリを開いたときと起動中の更新が対象です。読み取り許可や未装着・未同期は判別できません。")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}
