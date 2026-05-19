import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var account: AccountInfo?
    @Published var usage: UsageInfo?
    @Published var chromeProfiles: [ChromeProfile] = []
    @Published var loadState: LoadState = .idle

    private let authService = AuthService()
    private let usageService = UsageService()
    private let chromeProfileService = ChromeProfileService.shared

    func refresh() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            // authService.fetchAccount() blocks on subprocess I/O — run off main thread
            let auth = authService
            let fetchedAccount = try await Task.detached(priority: .userInitiated) {
                try auth.fetchAccount()
            }.value
            let fetchedUsage = try await usageService.fetchUsage()
            account = fetchedAccount
            usage = fetchedUsage
            chromeProfiles = chromeProfileService.enumerate()
            loadState = .idle
        } catch AuthError.cliNotFound {
            loadState = .error("Claude CLI not found at \(Constants.CLI.claudePath).")
        } catch AuthError.notLoggedIn {
            loadState = .error("Not logged in. Run claude auth login.")
        } catch {
            loadState = .error("Failed to load: \(error.localizedDescription)")
        }
    }

    func openChromeProfile(for email: String) {
        guard let profile = chromeProfiles.first(where: { $0.email == email }) else { return }
        chromeProfileService.open(profile)
    }
}
