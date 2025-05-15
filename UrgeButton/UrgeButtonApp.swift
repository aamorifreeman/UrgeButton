import SwiftUI

@main
struct UrgeButtonApp: App {
    // 1️⃣ Move your store here so both tabs share it
    @StateObject private var store = UrgeStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                // 2️⃣ Track tab
                ContentView(store: store)
                    .tabItem {
                        Label("Track", systemImage: "hand.raised.fill")
                    }

                // 3️⃣ Stats tab
                StatsView(store: store)
                    .tabItem {
                        Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                    }
            }
        }
    }
}
