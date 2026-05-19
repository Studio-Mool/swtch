import XCTest
@testable import swtch

final class KeychainServiceTests: XCTestCase {

    func test_parseCredentials_extractsAccessToken() throws {
        let json = """
        {"claudeAiOauth":{"accessToken":"sk-ant-oat01-abc","refreshToken":"sk-ant-ort01-xyz","expiresAt":9999999999999,"scopes":[],"subscriptionType":"pro","rateLimitTier":"default_claude_ai"}}
        """
        let creds = try KeychainService.parseCredentials(json)
        XCTAssertEqual(creds.accessToken, "sk-ant-oat01-abc")
        XCTAssertEqual(creds.refreshToken, "sk-ant-ort01-xyz")
        XCTAssertEqual(creds.subscriptionType, "pro")
    }

    func test_parseCredentials_throwsOnMissingClaudeAiOauth() {
        let json = "{}"
        XCTAssertThrowsError(try KeychainService.parseCredentials(json))
    }

    func test_isExpired_returnsTrueWhenPast() throws {
        let json = """
        {"claudeAiOauth":{"accessToken":"tok","refreshToken":"ref","expiresAt":1,"scopes":[],"subscriptionType":"pro","rateLimitTier":""}}
        """
        let creds = try KeychainService.parseCredentials(json)
        XCTAssertTrue(creds.isExpired)
    }

    func test_isExpired_returnsFalseForFutureToken() throws {
        let farFuture = Int(Date().timeIntervalSince1970 * 1000) + 86_400_000
        let json = """
        {"claudeAiOauth":{"accessToken":"tok","refreshToken":"ref","expiresAt":\(farFuture),"scopes":[],"subscriptionType":"pro","rateLimitTier":""}}
        """
        let creds = try KeychainService.parseCredentials(json)
        XCTAssertFalse(creds.isExpired)
    }
}
