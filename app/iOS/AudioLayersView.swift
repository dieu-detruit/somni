import SwiftUI
import SomnioCore

struct AudioLayersView: View {
    @Binding var settings: SoundSettings
    var body: some View {
        VStack(spacing: 18) {
            musicCard
            toneCard
            environmentCard
        }
    }
    private var musicCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(get: { settings.musicGain > 0 }, set: { settings.musicGain = $0 ? 0.7 : 0 })) {
                Label("アンビエント音楽", systemImage: "music.note")
            }
            SynthSlider(title: "音楽の音量", value: $settings.musicGain)
            Picker("音色", selection: $settings.musicTimbre) {
                ForEach(MusicTimbre.allCases) { timbre in Text(timbre.title).tag(timbre) }
            }.pickerStyle(.segmented)
            SynthSlider(title: "音色の明るさ", value: $settings.musicBrightness)
            SynthSlider(title: "和音の移り変わり", value: $settings.musicMotion)
            Text("ゆっくり変わる和音を、好みの音色で。音楽だけでも、ほかの音を重ねても使えます。")
                .font(.caption).foregroundStyle(.secondary)
        }.synthCard()
    }
    private var toneCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(get: { settings.mode == .beat }, set: { enabled in
                settings.mode = enabled ? .beat : .ambience
                if enabled && settings.beatGain == 0 { settings.beatGain = 0.25 }
            })) { Label("純音・うなり", systemImage: "waveform.path") }
            SynthSlider(title: "音の音量", value: $settings.beatGain).disabled(settings.mode != .beat)
            HStack { Text("音の高さ"); Spacer(); Text("\(Int(settings.toneFrequencyHz)) Hz").monospacedDigit() }.font(.subheadline)
            Slider(value: $settings.toneFrequencyHz, in: 80...1000, step: 1).accessibilityLabel("音の高さ")
            HStack(spacing: 8) {
                ForEach([180.0, 432, 528, 852], id: \.self) { frequency in
                    Button("\(Int(frequency))") { settings.toneFrequencyHz = frequency }
                        .font(.caption.monospacedDigit()).frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(settings.toneFrequencyHz == frequency ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.04), in: Capsule())
                        .accessibilityLabel("音の高さを\(Int(frequency))ヘルツにする")
                }
            }
            HStack { Text("うなりの速さ"); Spacer(); Text(settings.beatRateHz == 0 ? "単音" : String(format: "%.1f Hz", settings.beatRateHz)).monospacedDigit() }.font(.subheadline)
            Slider(value: $settings.beatRateHz, in: 0...40, step: 0.5).accessibilityLabel("うなりの速さ")
            HStack {
                ForEach([0.0, 4, 14, 15], id: \.self) { rate in
                    Button(rate == 0 ? "単音" : "\(Int(rate)) Hz") { settings.beatRateHz = rate }
                        .font(.caption).frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color.white.opacity(0.04), in: Capsule())
                }
            }
            Text("音の高さとうなりの速さは別々に調整できます。ここでのうなりは、スピーカーでも使えるモノラルです。")
                .font(.caption).foregroundStyle(.secondary)
        }.synthCard()
    }
    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(get: { settings.ambienceGain > 0 }, set: { settings.ambienceGain = $0 ? 0.3 : 0 })) {
                Label("波のような環境音", systemImage: "water.waves")
            }
            SynthSlider(title: "環境音の音量", value: $settings.ambienceGain)
        }.synthCard()
    }
}

struct SynthSlider: View {
    let title: String
    @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(title); Spacer(); Text("\(Int(value * 100))%").monospacedDigit() }.font(.subheadline)
            Slider(value: $value, in: 0...1).accessibilityLabel(title)
        }
    }
}

extension View {
    func synthCard() -> some View {
        padding(18).background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 20))
    }
}
