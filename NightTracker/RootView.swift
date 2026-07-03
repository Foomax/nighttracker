import SwiftUI

/// Top-level container: bottom tab bar (Tracker / Analysis / Meds) plus shared
/// profile selection that every tab reads from.
struct RootView: View {
    @EnvironmentObject private var store: NightStore
    @State private var selectedBabyID: UUID?
    // Initial tab can be overridden for screenshots/UI tests via `-startTab N`.
    @State private var selectedTab = UserDefaults.standard.integer(forKey: "startTab")

    private var selectedBaby: Baby? {
        store.baby(id: selectedBabyID)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TrackerView(selectedBabyID: $selectedBabyID)
                .tabItem { Label("Tracker", systemImage: "waveform.path.ecg") }
                .tag(0)

            AnalysisView(baby: selectedBaby)
                .tabItem { Label("Analysis", systemImage: "chart.bar.fill") }
                .tag(1)

            MedsView(baby: selectedBaby)
                .tabItem { Label("Meds", systemImage: "cross.case.fill") }
                .tag(2)
        }
        .tint(Theme.accent)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            configureTabBarAppearance()
            if selectedBabyID == nil {
                selectedBabyID = store.sortedBabies.first?.id
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = UIColor(Theme.hairline)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
