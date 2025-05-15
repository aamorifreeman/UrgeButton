import SwiftUI

@main
struct UrgeTrackerApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()  // ContentView already has @StateObject UrgeStore
    }
  }
}
