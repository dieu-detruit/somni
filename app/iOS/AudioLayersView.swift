import SwiftUI
import SomnioCore

struct AudioLayersView: View {
    @Binding var settings: SoundSettings
    var body: some View {
        DisclosureGroup("音のバランスを調整") {
            VStack(alignment: .leading, spacing: 18) {
                layerSlider("波音", value: $settings.ambienceGain)
                layerSlider("ビート", value: $settings.beatGain).disabled(settings.mode != .beat)
                Picker("うなりの速さ", selection: $settings.beatRateHz) {
                    ForEach(SoundSettings.exploratoryRates, id: \.self) { rate in Text("\(Int(rate)) Hz").tag(rate) }
                }.disabled(settings.mode != .beat)
                Text("ビートは「波音＋ビート」で有効です。波音を0にするとビートだけを聞けます。速さは試すための値で、睡眠への効果を示しません。")
                    .font(.caption).foregroundStyle(.secondary)
                Button("元のバランスに戻す（波音1・ビート1・4 Hz）") {
                    settings.ambienceGain = 1; settings.beatGain = 1; settings.beatRateHz = 4
                }.font(.caption)
            }.padding(.top, 14)
        }.padding(20).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
    }
    private func layerSlider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(title); Spacer(); Text("\(Int(value.wrappedValue * 100))%").monospacedDigit() }.font(.subheadline)
            Slider(value: value, in: 0...1).accessibilityLabel(title + "の音量")
        }
    }
}
