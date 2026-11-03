import SwiftUI
import UIKit
import SomnioCore

private enum Palette {
    static let background = Color(red: 0.035, green: 0.06, blue: 0.12)
    static let card = Color(red: 0.075, green: 0.11, blue: 0.19)
    static let mint = Color(red: 0.65, green: 0.88, blue: 0.80)
    static let muted = Color(red: 0.60, green: 0.68, blue: 0.77)
}

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var player: AudioPlayer
    var body: some View {
        TabView {
            TonightView().tabItem { Label("今夜", systemImage: "moon.stars") }
            HistoryView().tabItem { Label("朝の記録", systemImage: "sun.horizon") }
            JournalView().tabItem { Label("日中の記録", systemImage: "square.and.pencil") }
            SettingsView().tabItem { Label("このアプリ", systemImage: "slider.horizontal.3") }
        }
        .tint(Palette.mint)
        .alert("記録について", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("閉じる") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }
}

private struct TonightView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var settings = SoundSettings()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack { Text("S O M N I O").font(.caption.weight(.semibold)).tracking(2); Spacer(); Text(Date(), style: .date).font(.caption) }.foregroundStyle(Palette.muted)
                    VStack(alignment: .leading, spacing: 9) {
                        Text("明日の自分に、\nやさしい夜を。").font(.system(size: 33, weight: .medium, design: .serif)).lineSpacing(6)
                        Text("音を選んで、ゆっくりおやすみ。\n朝のすっきり感を、一緒に見つけていこう。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(5)
                    }
                    ZStack {
                        Circle().stroke(Palette.mint.opacity(0.07), lineWidth: 1).frame(width: 230, height: 230)
                        Circle().stroke(Palette.mint.opacity(0.12), lineWidth: 1).frame(width: 190, height: 190)
                        Circle().fill(RadialGradient(colors: [Palette.mint.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: 100)).frame(width: 210, height: 210)
                        Image(systemName: player.active ? "waveform" : "moon.zzz").font(.system(size: 57, weight: .ultraLight)).foregroundStyle(Palette.mint)
                            .symbolEffect(.variableColor, options: .repeating, isActive: player.active)
                    }.frame(maxWidth: .infinity).accessibilityHidden(true)
                    VStack(spacing: 16) {
                        ForEach(SoundMode.allCases) { mode in
                            Button { settings.mode = mode } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: mode == .ambience ? "water.waves" : "waveform.path").font(.title2).frame(width: 30)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(mode.title).font(.subheadline.weight(.semibold))
                                        Text(mode.detail).font(.caption).foregroundStyle(Palette.muted)
                                    }
                                    Spacer()
                                    Image(systemName: settings.mode == mode ? "checkmark.circle.fill" : "circle").foregroundStyle(settings.mode == mode ? Palette.mint : Palette.muted)
                                }.foregroundStyle(.white).padding(17).background(settings.mode == mode ? Palette.mint.opacity(0.09) : Palette.card, in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(settings.mode == mode ? Palette.mint.opacity(0.5) : .clear))
                            }.buttonStyle(.plain).accessibilityAddTraits(settings.mode == mode ? .isSelected : [])
                        }
                    }
                    AudioLayersView(settings: $settings)
                    VStack(alignment: .leading, spacing: 18) {
                        HStack { Label("スリープタイマー", systemImage: "timer"); Spacer(); Text(settings.timerLabel).foregroundStyle(Palette.mint) }.font(.subheadline)
                        HStack(spacing: 8) {
                            ForEach([15, 30, 60, 0], id: \.self) { minutes in
                                Button(minutes == 0 ? "連続" : "\(minutes)分") { settings.timerMinutes = minutes == 0 ? nil : minutes }
                                    .font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 11)
                                    .background(settings.timerMinutes == (minutes == 0 ? nil : minutes) ? Palette.mint.opacity(0.18) : Palette.background, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        Text("全体の音量").font(.subheadline)
                        HStack { Image(systemName: "speaker.wave.1"); Slider(value: $settings.volume, in: 0...1).accessibilityLabel("音の音量"); Image(systemName: "speaker.wave.2") }.foregroundStyle(Palette.muted)
                        Text("小さな音から。端末の音量も調整してください。\n終了前の10秒で、静かにフェードアウトします。").font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                    }.padding(20).background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
                    Button {
                        if player.active { player.stop() } else { player.start(settings: settings) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: player.active ? "stop.fill" : "play.fill")
                            Text(player.state == .stopping ? "ゆっくり停止中…" : player.active ? "音を止める" : "おやすみを始める")
                        }.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 20).foregroundStyle(Palette.background).background(Palette.mint, in: Capsule())
                    }.disabled(player.state == .stopping)
                    if player.active {
                        HStack { Image(systemName: "waveform"); Text("再生中 · " + DisplayFormat.duration(player.elapsed)); Spacer(); Text("ロックしても再生") }.font(.caption).foregroundStyle(Palette.muted)
                    } else if let end = player.lastEnd { Text(end.title).font(.caption).foregroundStyle(Palette.muted) }
                    if let error = player.errorMessage { Text(error).font(.footnote).foregroundStyle(.orange) }
                    Text("ビートの感じ方には個人差があります。\n朝の休息感を記録して、自分に合う夜を探しましょう。").font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                }.padding(24)
            }.background(Palette.background).toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { settings = store.settings }
        .onChange(of: settings) { _, value in store.updateSettings(value); player.update(settings: value) }
    }
}

private struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var health = HealthSleepReader()
    @State private var nightSelection = HistoryNightSelection()
    @State private var showRating = false
    @State private var ratingNight: String?
    private var selectedNight: String { nightSelection.selectedNight }
    private var nights: [String] {
        var values = Set(store.sessions.map(\.nightID) + store.feedback.map(\.nightID))
        values.insert(selectedNight)
        for day in 0..<7 { if let date = Calendar.current.date(byAdding: .day, value: -day, to: Date()) { values.insert(Night.previous(for: date)) } }
        return values.sorted(by: >)
    }
    private var sleep: NightSleepRecord? { store.sleep(for: selectedNight) }
    private var sessions: [PlaybackSession] { store.sessions(for: selectedNight) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("目覚めを、ふりかえる。").font(.system(size: 28, weight: .medium, design: .serif))
                    Text("いちばん大切なのは、朝のあなたの感覚。").font(.subheadline).foregroundStyle(Palette.muted)
                    Picker("夜を選ぶ", selection: Binding(get: { selectedNight }, set: { nightSelection.select($0) })) { ForEach(nights, id: \.self) { Text($0 + " の夜").tag($0) } }.tint(Palette.mint)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("朝のすっきり感", systemImage: "sun.max")
                            Spacer()
                            if let rating = store.rating(for: selectedNight) { Text("\(rating.refreshed) / 5").font(.title2.monospacedDigit()).foregroundStyle(Palette.mint) }
                            else { Text("未記録").foregroundStyle(Palette.muted) }
                        }
                        if let rating = store.rating(for: selectedNight) {
                            if let ease = rating.easeOfSleep { Text("寝つき \(ease) / 5").font(.subheadline).foregroundStyle(Palette.muted) }
                            if !rating.note.isEmpty { Text(rating.note).font(.subheadline) }
                        } else { Text("よく休めた？ ひとことだけでも残せます。").font(.subheadline).foregroundStyle(Palette.muted) }
                        Button(store.rating(for: selectedNight) == nil ? "朝の感覚を記録" : "記録を編集") { ratingNight = selectedNight; showRating = true }.buttonStyle(.borderedProminent).tint(Palette.mint).foregroundStyle(Palette.background)
                    }.cardStyle()
                    VStack(alignment: .leading, spacing: 15) {
                        HStack { Label("睡眠の記録", systemImage: "bed.double"); Spacer(); if health.loading { ProgressView() } }
                        if let summary = sleep?.selected {
                            Text(DisplayFormat.duration(summary.totalSleep)).font(.system(size: 35, weight: .light, design: .rounded)).foregroundStyle(Palette.mint)
                            Text("ヘルスケアによる推定 · " + summary.sourceName).font(.caption).foregroundStyle(Palette.muted)
                            StageBar(summary: summary)
                            Text("段階が重なる場合、合計は重複を除いた時間です。").font(.caption2).foregroundStyle(Palette.muted)
                            if let sleep, sleep.summaries.count > 1 {
                                Picker("表示ソース", selection: Binding(get: { summary.sourceID }, set: { store.selectSource($0, nightID: selectedNight) })) {
                                    ForEach(sleep.summaries, id: \.sourceID) { Text($0.sourceName).tag($0.sourceID) }
                                }.font(.caption)
                                Text("選んだソースだけを集計しています。").font(.caption).foregroundStyle(Palette.muted)
                            }
                        } else {
                            Text("睡眠の記録は、まだありません。").font(.headline)
                            Text("Apple Watchの標準の睡眠記録を表示します。\n同期に時間がかかる場合があります。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                        }
                        if let fetchedAt = sleep?.fetchedAt { Text("取得: " + fetchedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(Palette.muted) }
                        if let message = health.message { Text(message).font(.caption).foregroundStyle(Palette.muted) }
                        Button(sleep == nil ? "ヘルスケアから読み込む" : "睡眠記録を再取得") { Task { await health.refresh(nightID: selectedNight, store: store) } }.disabled(health.loading)
                        Text("夜18時〜翌12時の区間。昼の記録と分けて表示します。").font(.caption2).foregroundStyle(Palette.muted)
                    }.cardStyle()
                    VStack(alignment: .leading, spacing: 14) {
                        Label("この夜の音", systemImage: "waveform")
                        if sessions.isEmpty { Text("再生の記録はありません。").foregroundStyle(Palette.muted).font(.subheadline) }
                        ForEach(sessions) { session in
                            PlaybackSessionRow(session: session)
                        }
                    }.cardStyle()
                    RecentRatingsView()
                }.padding(24)
            }.background(Palette.background).navigationTitle("朝の記録").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showRating) { RatingEditor(nightID: ratingNight ?? selectedNight) }
            .onChange(of: selectedNight) { _, _ in health.message = nil }
            .onAppear { nightSelection.refresh() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { nightSelection.refresh() } }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in nightSelection.refresh() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in nightSelection.refresh() }
        }
    }
}

private struct PlaybackSessionRow: View {
    let session: PlaybackSession

    private var playbackDescription: String {
        let start: String = session.startedAt.formatted(date: .omitted, time: .shortened)
        let duration: String = session.endReason == .unknown ? "再生時間不明" : DisplayFormat.duration(session.playedSeconds)
        let status: String = session.endReason?.title ?? "再生中"
        return [start, duration, status].joined(separator: " · ")
    }

    private var settingsDescription: String {
        let timer: String = session.settings.timerLabel
        let volume: Int = Int(session.settings.volume * 100)
        return "設定: \(timer) / 音量 \(volume)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(session.settings.mode.title).font(.subheadline.weight(.medium))
            Text(playbackDescription).font(.caption).foregroundStyle(Palette.muted)
            Text(settingsDescription).font(.caption).foregroundStyle(Palette.muted)
            if session.changes.count > 1 {
                Text("途中の設定変更 \(session.changes.count - 1)回").font(.caption).foregroundStyle(Palette.muted)
            }
        }
    }
}

private struct StageBar: View {
    let summary: SleepSummary
    private let stages: [SleepStage] = [.core, .deep, .rem, .unspecified, .awake]
    private func color(_ stage: SleepStage) -> Color {
        switch stage { case .core: return .cyan; case .deep: return .indigo; case .rem: return .purple; case .awake: return .orange; default: return .gray }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(stages.filter { summary.stageDuration($0) > 0 }, id: \.self) { stage in
                HStack { Circle().fill(color(stage)).frame(width: 7, height: 7); Text(stage.title); Spacer(); Text(DisplayFormat.duration(summary.stageDuration(stage))).monospacedDigit() }.font(.caption).foregroundStyle(Palette.muted)
            }
        }
    }
}

private struct RecentRatingsView: View {
    @EnvironmentObject private var store: AppStore
    private var recent: [MorningFeedback] { Array(store.feedback.sorted { $0.nightID > $1.nightID }.prefix(7).reversed()) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("最近のすっきり感", systemImage: "chart.bar.xaxis")
            if recent.isEmpty { Text("記録がたまると、朝の感覚をここで見返せます。").font(.subheadline).foregroundStyle(Palette.muted) }
            else {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(recent) { item in
                        VStack(spacing: 7) {
                            Text("\(item.refreshed)").font(.caption).foregroundStyle(Palette.mint)
                            RoundedRectangle(cornerRadius: 5).fill(Palette.mint.opacity(0.65)).frame(height: CGFloat(item.refreshed) * 17)
                            Text(String(item.nightID.suffix(5))).font(.system(size: 9)).foregroundStyle(Palette.muted)
                        }.frame(maxWidth: .infinity)
                    }
                }.frame(height: 120, alignment: .bottom)
                Text("1 = 休めなかった / 5 = すっきり\n音以外にも、生活や体調で眠りは変わります。").font(.caption).foregroundStyle(Palette.muted).lineSpacing(3)
            }
        }.cardStyle()
    }
}

private struct RatingEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let nightID: String
    @State private var refreshed = 3
    @State private var ease = 3
    @State private var note = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("今朝、どれくらいすっきりしていますか？").font(.headline)
                    Picker("すっきり感", selection: $refreshed) { ForEach(1...5, id: \.self) { Text("\($0)").tag($0) } }.pickerStyle(.segmented)
                    Text("1 休めなかった　〜　5 すっきり").font(.caption).foregroundStyle(.secondary)
                } header: { Text("朝の休息感") }
                Section {
                    Picker("寝つき", selection: $ease) { ForEach(1...5, id: \.self) { Text("\($0)").tag($0) } }.pickerStyle(.segmented)
                    Text("1 寝つきにくかった　〜　5 すっと眠れた").font(.caption).foregroundStyle(.secondary)
                } header: { Text("寝つき") }
                Section("ひとことメモ") { TextField("体調、気になった音、昨日のこと…", text: $note, axis: .vertical).lineLimit(4...8).onChange(of: note) { _, value in if value.count > 2000 { note = String(value.prefix(2000)) } } }
                Section { Text(nightID + " の夜の記録").font(.caption) }
            }.navigationTitle("朝の感覚").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            let old = store.rating(for: nightID)
                            store.receive(MorningFeedback(nightID: nightID, refreshed: refreshed, easeOfSleep: ease, note: note, createdAt: old?.createdAt))
                            dismiss()
                        }
                    }
                }
        }.tint(Palette.mint).onAppear {
            if let old = store.rating(for: nightID) { refreshed = old.refreshed; ease = old.easeOfSleep ?? 3; note = old.note }
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var connectivity: PhoneConnectivity
    @State private var confirmDelete = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Somnio") {
                    Text("自分に合う、休まる夜を探す。").font(.headline)
                    Text("朝のすっきり感を主な手がかりに、音の好みや睡眠をふりかえる個人用の記録アプリです。少しずつ、心地よい夜を見つけていきましょう。")
                }
                Section("音について") {
                    Text("波音は端末内で生成したノイズです。ビートは180 Hzの音に、選んだ速さの差をつけた音を重ねています。特殊な音源やネット接続は不要です。")
                    Text("睡眠への効果は確立しておらず、感じ方にも個人差があります。診断や治療を行うものではありません。気になったり不快に感じたら停止してください。")
                }
                Section("Apple Watch") {
                    Text("Watchの標準機能で睡眠を記録し、朝にiPhoneのヘルスケアから読み込みます。Watchアプリを開き続ける必要はありません。Watchでは前夜の要約と、朝のすっきり感を記録できます。")
                    if let message = connectivity.message { Text(message).foregroundStyle(.orange) }
                    Button("Watchに最新の要約を送る") { connectivity.sendSummary() }
                }
                Section("分析用データ") {
                    NavigationLink("データを書き出す") { ExportView() }
                }
                Section("プライバシー") {
                    Text("音の再生と朝の感覚は、この端末内に保存します。ヘルスケアは読み取り専用です。必要な要約と評価だけをペアリングしたWatchと同期します。アカウント、広告、解析SDK、外部サーバーは使いません。端末のバックアップ設定に応じて、記録がバックアップに含まれる場合があります。")
                    Button("Somnioのすべての記録を削除", role: .destructive) { confirmDelete = true }.disabled(player.active)
                    if player.active { Text("再生を停止すると削除できます。").font(.caption) }
                    Text("取り込んだ表示用データと自分の記録を消します。ヘルスケアの原本は変更しません。Watchの古い記録も次の接続時に削除します。").font(.caption)
                }
            }.scrollContentBackground(.hidden).background(Palette.background).navigationTitle("このアプリ")
            .confirmationDialog("Somnioの記録を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("すべての記録を削除", role: .destructive) { store.deleteAll() }
            } message: { Text("この操作は取り消せません。Appleヘルスケアの原本は残ります。") }
        }
    }
}

private extension View {
    func cardStyle() -> some View { self.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Palette.card, in: RoundedRectangle(cornerRadius: 20)) }
}
