import SwiftUI

@main
struct SomnioApp: App {
    @StateObject private var store: AppStore
    @StateObject private var player: AudioPlayer
    @StateObject private var connectivity: PhoneConnectivity
    @StateObject private var health: HealthSleepReader
    @Environment(\.scenePhase) private var scenePhase
    init() {
        let store = AppStore()
        _store = StateObject(wrappedValue: store)
        _player = StateObject(wrappedValue: AudioPlayer(store: store))
        _connectivity = StateObject(wrappedValue: PhoneConnectivity(store: store))
        _health = StateObject(wrappedValue: HealthSleepReader(store: store))
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store).environmentObject(player).environmentObject(connectivity).environmentObject(health)
                .preferredColorScheme(.dark)
                .task { await health.foreground() }
                .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await health.foreground() } } }
        }
    }
}
