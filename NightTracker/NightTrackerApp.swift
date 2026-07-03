import SwiftUI

@main
struct NightTrackerApp: App {
    @StateObject private var store = NightStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
