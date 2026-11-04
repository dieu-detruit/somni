import SwiftUI
import SomnioCore

@main
struct SomnioWatchApp: App {
    @StateObject private var store = WatchStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            WatchHomeView().environmentObject(store)
                .onChange(of: scenePhase) { _, phase in if phase == .active { store.flush() } }
        }
    }
}

private struct WatchHomeView: View {
    @EnvironmentObject private var store: WatchStore
    private let mint = Color(red: 0.65, green: 0.88, blue: 0.80)
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    HStack { Image(systemName: "sun.horizon"); Text("おはよう。").font(.headline) }.foregroundStyle(mint)
                    Text(Night.label(for: store.summary.nightID)).font(.caption2).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("睡眠の記録").font(.caption).foregroundStyle(.secondary)
                        if let seconds = store.summary.sleepSeconds { Text(DisplayFormat.duration(seconds)).font(.title3.weight(.medium)).foregroundStyle(mint) }
                        else { Text("まだ取得していません").font(.footnote) }
                        if let fetchedAt = store.summary.fetchedAt { Text("取得 " + fetchedAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 10)).foregroundStyle(.secondary) }
                    }
                    if let sound = store.summary.soundTitle {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sound).font(.caption)
                            Text("再生 " + DisplayFormat.duration(store.summary.playedSeconds)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                    Text("今朝のすっきり感は？").font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                        ForEach(1...5, id: \.self) { value in
                            Button { store.rate(value) } label: {
                                Text("\(value)").font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(store.refreshed == value ? mint : Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
                                    .foregroundStyle(store.refreshed == value ? Color.black : .white)
                            }.buttonStyle(.plain).accessibilityLabel("すっきり感 \(value)、5段階")
                        }
                    }
                    Text("1 休めなかった　5 すっきり").font(.system(size: 10)).foregroundStyle(.secondary)
                    if store.pendingCount > 0 {
                        Label("iPhoneへの同期待ち", systemImage: "arrow.triangle.2.circlepath").font(.caption2).foregroundStyle(mint)
                        Text("記録はWatchに保存されています。接続後に送信します。").font(.caption2).foregroundStyle(.secondary)
                    } else if store.refreshed != nil { Label("記録済み", systemImage: "checkmark.circle").font(.caption2).foregroundStyle(mint) }
                    if let error = store.errorMessage { Text(error).font(.caption2).foregroundStyle(.orange) }
                    if let syncedAt = store.lastSyncedAt { Text("iPhone同期 " + syncedAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 10)).foregroundStyle(.secondary) }
                    Text("詳しい睡眠記録は、iPhoneのSomnioで読み込めます。").font(.caption2).foregroundStyle(.secondary)
                }.padding(.horizontal, 4)
            }.navigationTitle("Somnio")
        }.tint(mint)
    }
}
