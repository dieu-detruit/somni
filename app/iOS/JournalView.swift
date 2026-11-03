import SwiftUI
import SomnioCore

struct JournalView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editing: JournalEvent?
    @State private var adding = false
    @State private var deleting: JournalEvent?
    private var events: [JournalEvent] { store.journal.sorted { $0.start > $1.start } }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("眠気や眠った時間を、その日の記録として。あとから時刻を直すこともできます。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button { adding = true } label: { Label("記録を追加", systemImage: "plus.circle") }
                }
                Section("自分で記録したできごと") {
                    if events.isEmpty { Text("まだ記録はありません。").foregroundStyle(.secondary) }
                    ForEach(events) { event in
                        Button { editing = event } label: { JournalRow(event: event) }.buttonStyle(.plain)
                            .swipeActions { Button("削除", role: .destructive) { deleting = event } }
                    }
                }
                Section { Text("ヘルスケアの推定睡眠や音の再生開始とは別の、自己申告の記録です。時刻は記録に保存したタイムゾーンで表示します。")
                    .font(.caption).foregroundStyle(.secondary) }
            }.navigationTitle("日中と就寝の記録")
                .toolbar { ToolbarItem(placement: .primaryAction) { Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("記録を追加") } }
                .sheet(isPresented: $adding) { JournalEditor() }
                .sheet(item: $editing) { JournalEditor(existing: $0) }
                .confirmationDialog("この記録を削除しますか？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                    Button("削除", role: .destructive) { if let event = deleting { store.deleteJournal(event.id) }; deleting = nil }
                }
        }
    }
}

private struct JournalRow: View {
    let event: JournalEvent
    private func time(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: event.timeZoneIdentifier) ?? .current
        formatter.dateFormat = "M月d日 H:mm"
        return formatter.string(from: date)
    }
    private var interval: String { event.end.map { time(event.start) + " 〜 " + time($0) } ?? time(event.start) }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(event.kind.title, systemImage: event.kind.symbol).font(.headline)
            Text(interval).font(.subheadline)
            if let severity = event.severity { Text("眠気の強さ \(severity) / 5").font(.caption).foregroundStyle(.secondary) }
            if !event.note.isEmpty { Text(event.note).font(.subheadline).lineLimit(3) }
            Text(event.timeZoneIdentifier + " · 自己申告").font(.caption2).foregroundStyle(.secondary)
        }.padding(.vertical, 6)
    }
}

private struct JournalEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let existing: JournalEvent?
    @State private var kind: JournalKind
    @State private var start: Date
    @State private var end: Date
    @State private var severity: Int
    @State private var note: String
    @State private var timeZoneIdentifier: String
    @State private var errorMessage: String?
    init(existing: JournalEvent? = nil) {
        self.existing = existing
        let now = Date()
        _kind = State(initialValue: existing?.kind ?? .sleepiness)
        _start = State(initialValue: existing?.start ?? now)
        _end = State(initialValue: existing?.end ?? now.addingTimeInterval(20 * 60))
        _severity = State(initialValue: existing?.severity ?? 0)
        _note = State(initialValue: existing?.note ?? "")
        _timeZoneIdentifier = State(initialValue: existing?.timeZoneIdentifier ?? TimeZone.current.identifier)
    }
    private var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .current }
    var body: some View {
        NavigationStack {
            Form {
                Section("できごと") {
                    Picker("種類", selection: $kind) { ForEach(JournalKind.allCases) { Text($0.title).tag($0) } }
                    DatePicker(kind.isInterval ? "開始" : "時刻", selection: $start)
                    if kind.isInterval { DatePicker("終了", selection: $end) }
                    if kind == .sleepiness {
                        Picker("眠気の強さ", selection: $severity) {
                            Text("未記録").tag(0)
                            ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                        }
                        Text("1 わずかな眠気 〜 5 強い眠気").font(.caption).foregroundStyle(.secondary)
                    }
                    Text("タイムゾーン: " + timeZoneIdentifier).font(.caption).foregroundStyle(.secondary)
                }
                Section("メモ") { TextField("体調や、覚えておきたいこと", text: $note, axis: .vertical).lineLimit(3...8).onChange(of: note) { _, value in if value.count > 4000 { note = String(value.prefix(4000)) } } }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
                Section { Text("過去の日時も記録できます。就寝は自己申告の時刻で、実際の入眠時刻を測定するものではありません。")
                    .font(.caption).foregroundStyle(.secondary) }
            }.environment(\.timeZone, timeZone)
                .navigationTitle(existing == nil ? "記録を追加" : "記録を編集").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
                }
        }
    }
    private func save() {
        do {
            let event = try JournalEvent(id: existing?.id ?? UUID(), kind: kind, start: start, end: kind.isInterval ? end : nil,
                severity: severity == 0 ? nil : severity, note: note, createdAt: existing?.createdAt, timeZone: timeZone)
            if store.saveJournal(event) { dismiss() } else { errorMessage = store.errorMessage }
        } catch { errorMessage = error.localizedDescription }
    }
}
