import SwiftUI

struct AccountHeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 26, height: 26)
                Text(appState.account?.initials ?? "–")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().stroke(Color.accentColor.opacity(0.4), lineWidth: 2).padding(-2))

            VStack(alignment: .leading, spacing: 1) {
                Text(appState.account?.email ?? "Loading…")
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                Text(appState.account.map { "\($0.orgName) · \($0.subscriptionType.capitalized)" } ?? " ")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }
}
