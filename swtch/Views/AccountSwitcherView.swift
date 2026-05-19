import SwiftUI

struct AccountSwitcherView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Switch Account")
                .font(.system(size: 10))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(.quaternary)

            ForEach(appState.chromeProfiles) { profile in
                accountRow(profile: profile)
            }

            if appState.chromeProfiles.isEmpty {
                Text("No Chrome profiles found")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func accountRow(profile: ChromeProfile) -> some View {
        let isActive = profile.email == appState.account?.email
        return Button {
            appState.openChromeProfile(for: profile.email)
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Text(profile.initials)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                Text(profile.email)
                    .font(.system(size: 11.5))
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .lineLimit(1)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.accent)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.001))
            )
        }
        .buttonStyle(.plain)
    }
}
