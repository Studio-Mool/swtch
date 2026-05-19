import SwiftUI

struct RefreshButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            Task { await appState.refresh() }
        } label: {
            HStack(spacing: 5) {
                if appState.loadState == .loading {
                    ProgressView().scaleEffect(0.65)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                Text(appState.loadState == .loading ? "Refreshing…" : "Refresh")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .disabled(appState.loadState == .loading)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .background(
                configuration.isPressed
                ? Color.accentColor.opacity(0.07)
                : Color.clear
            )
    }
}
