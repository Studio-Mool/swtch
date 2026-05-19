import SwiftUI

@main
struct SwtchApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("swtch", systemImage: "person.circle") {
            PopoverView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
