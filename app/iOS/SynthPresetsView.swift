import SwiftUI
import SomnioCore

struct SynthPresetsView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var settings: SoundSettings
    let isPlaying: Bool
    @State private var name = ""
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Menu {
                ForEach(StarterSound.allCases) { sound in
                    Button(sound.title) { settings = sound.settings }
                }
            } label: { Label("音のレシピから始める", systemImage: "slider.horizontal.3") }
                .disabled(isPlaying)
            if isPlaying { Text("レシピの切り替えは停止中に。各つまみは再生しながら調整できます。").font(.caption).foregroundStyle(.secondary) }
            HStack {
                TextField("お気に入りの名前", text: $name).textInputAutocapitalization(.never)
                Button {
                    if store.saveSound(name: name, settings: settings) { name = ""; saved = true }
                } label: { Label("保存", systemImage: "bookmark") }
            }
            if saved { Text("お気に入りに保存しました").font(.caption).foregroundStyle(.secondary) }
            if !store.soundPresets.isEmpty {
                DisclosureGroup("お気に入り（\(store.soundPresets.count)）") {
                    ForEach(store.soundPresets) { preset in
                        HStack {
                            Button { settings = preset.settings } label: {
                                Label(preset.name, systemImage: "play.circle")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }.disabled(isPlaying)
                            Button(role: .destructive) { store.deleteSound(preset.id) } label: { Image(systemName: "trash") }
                                .accessibilityLabel(preset.name + "を削除")
                        }.padding(.vertical, 8)
                    }
                }
            }
        }.synthCard()
    }
}

struct IntroControlView: View {
    @Binding var settings: SoundSettings
    let isPlaying: Bool
    var body: some View {
        DisclosureGroup("時間で音を変える") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("最初の12分に14 Hzを重ねる", isOn: $settings.binauralIntro).disabled(isPlaying)
                if settings.binauralIntro {
                    Picker("導入の方式", selection: $settings.introMode) {
                        ForEach(IntroMode.allCases) { mode in Text(mode.title).tag(mode) }
                    }.pickerStyle(.segmented).disabled(isPlaying)
                    SynthSlider(title: "14 Hzの導入の音量", value: $settings.introGain)
                }
                Text("音楽を重ねたまま、12分後に30秒かけて通常の音へ戻します。波と通常のうなりは導入後に加わります。")
                    .font(.caption).foregroundStyle(.secondary)
                if settings.binauralIntro {
                    Text("自動は出力先から推定します。Bluetoothスピーカー・片耳ではモノラルを選べます。バイノーラルは両耳イヤホン用です。")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(.top, 12)
        }.synthCard()
    }
}
