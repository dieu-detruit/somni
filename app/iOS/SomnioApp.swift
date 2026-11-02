import SwiftUI

@main
struct SomnioApp: App {
    @StateObject private var store: AppStore
    @StateObject private var player: AudioPlayer
    @StateObject private var connectivity: PhoneConnectivity
    init() {
        let store = AppStore()
        _store = StateObject(wrappedValue: store)
        _player = StateObject(wrappedValue: AudioPlayer(store: store))
        _connectivity = StateObject(wrappedValue: PhoneConnectivity(store: store))
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store).environmentObject(player).environmentObject(connectivity)
                .preferredColorScheme(.dark)
        }
    }
}
