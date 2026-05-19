import Foundation

enum AuthError: Error, Equatable {
    case notLoggedIn
    case invalidOutput
    case cliNotFound
}

private struct AuthStatusResponse: Decodable {
    let loggedIn: Bool
    let email: String
    let orgName: String
    let subscriptionType: String
}

final class AuthService {
    private let shellRunner: ShellRunner

    init(shellRunner: ShellRunner = DefaultShellRunner()) {
        self.shellRunner = shellRunner
    }

    func fetchAccount() throws -> AccountInfo {
        guard FileManager.default.fileExists(atPath: Constants.CLI.claudePath) else {
            throw AuthError.cliNotFound
        }
        let output = try shellRunner.run(Constants.CLI.claudePath, arguments: ["auth", "status"])
        guard let data = output.data(using: .utf8) else { throw AuthError.invalidOutput }
        let response = try JSONDecoder().decode(AuthStatusResponse.self, from: data)
        guard response.loggedIn else { throw AuthError.notLoggedIn }
        return AccountInfo(
            email: response.email,
            orgName: response.orgName,
            subscriptionType: response.subscriptionType
        )
    }
}
