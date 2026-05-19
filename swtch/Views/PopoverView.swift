import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            AccountHeaderView()
            Divider().opacity(0.15)
            UsageView()
            Divider().opacity(0.15)
            AccountSwitcherView()
            Divider().opacity(0.15)
            RefreshButton()
        }
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .onAppear { Task { await appState.refresh() } }
    }
}
