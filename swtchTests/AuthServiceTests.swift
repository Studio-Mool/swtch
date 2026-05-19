import XCTest
@testable import swtch

final class MockShellRunner: ShellRunner {
    var stubbedResult: Result<String, Error> = .success("")
    private(set) var lastCommand: String?
    private(set) var lastArgs: [String]?

    func run(_ executablePath: String, arguments: [String]) throws -> String {
        lastCommand = executablePath
        lastArgs = arguments
        return try stubbedResult.get()
    }
}

final class AuthServiceTests: XCTestCase {
    func test_fetchAccount_parsesValidJSON() throws {
        let json = """
        {"loggedIn":true,"email":"vt@studiomool.com","orgName":"vt@studiomool.com's Organization","subscriptionType":"pro","authMethod":"claude.ai","apiProvider":"firstParty"}
        """
        let mock = MockShellRunner()
        mock.stubbedResult = .success(json)
        let service = AuthService(shellRunner: mock)

        let account = try service.fetchAccount()

        XCTAssertEqual(account.email, "vt@studiomool.com")
        XCTAssertEqual(account.subscriptionType, "pro")
        XCTAssertEqual(mock.lastCommand, Constants.CLI.claudePath)
        XCTAssertEqual(mock.lastArgs, ["auth", "status"])
    }

    func test_fetchAccount_throwsWhenNotLoggedIn() {
        let json = """
        {"loggedIn":false,"email":"","orgName":"","subscriptionType":"","authMethod":"","apiProvider":""}
        """
        let mock = MockShellRunner()
        mock.stubbedResult = .success(json)
        let service = AuthService(shellRunner: mock)

        XCTAssertThrowsError(try service.fetchAccount()) { error in
            XCTAssertEqual(error as? AuthError, AuthError.notLoggedIn)
        }
    }

    func test_fetchAccount_throwsOnShellFailure() {
        struct FakeError: Error {}
        let mock = MockShellRunner()
        mock.stubbedResult = .failure(FakeError())
        let service = AuthService(shellRunner: mock)

        XCTAssertThrowsError(try service.fetchAccount())
    }
}
