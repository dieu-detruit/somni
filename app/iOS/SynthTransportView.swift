import SwiftUI
import SomnioCore

struct SynthTransportView: View {
    @EnvironmentObject private var player: AudioPlayer
    @Binding var settings: SoundSettings
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                Button {
                    if player.active { player.stop() } else { player.start(settings: settings) }
                } label: {
                    Image(systemName: player.active ? "stop.fill" : "play.fill")
                        .font(.title3).frame(width: 52, height: 52)
                        .foregroundStyle(Color(red: 0.035, green: 0.06, blue: 0.12))
                        .background(Color.accentColor, in: Circle())
                }.disabled(player.state == .stopping)
                    .accessibilityLabel(player.active ? "音を止める" : "音を再生する")
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.state == .stopping ? "ゆっくり停止中…" : player.active ? "再生中 · " + DisplayFormat.duration(player.elapsed) : "聴きながら音をつくる")
                        .font(.subheadline)
                    if player.active && settings.binauralIntro {
                        Text(introStatus).font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("タイマー：" + settings.timerLabel).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            if let error = player.errorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
            else if !player.active, let end = player.lastEnd { Text(end.title).font(.caption).foregroundStyle(.secondary) }
        }
    }
    private var introStatus: String {
        if player.elapsed < AudioSignal.introDuration { return "14 Hzの導入 · " + (player.introDelivery?.title ?? "") }
        if player.elapsed < AudioSignal.introDuration + AudioSignal.introTransitionDuration { return "通常の音へ切り替え中" }
        return "導入終了 · 通常の音を再生中"
    }
}
