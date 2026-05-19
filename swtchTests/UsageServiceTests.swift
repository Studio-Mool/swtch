import XCTest
@testable import swtch

final class UsageServiceTests: XCTestCase {

    func test_parseResponse_extractsUsageInfo() throws {
        let json = """
        {"resets_at":"2026-05-23T10:00:00.000Z","messages_remaining":1600,"messages_limit":5000}
        """
        let info = try UsageService.parseResponse(json)
        XCTAssertEqual(info.messagesUsed, 3400)
        XCTAssertEqual(info.messagesLimit, 5000)
        XCTAssertGreaterThan(info.resetsAt, Date())
    }

    func test_parseResponse_throwsOnMissingFields() {
        let json = "{}"
        XCTAssertThrowsError(try UsageService.parseResponse(json))
    }

    func test_parseResponse_throwsOnInvalidDate() {
        let json = """
        {"resets_at":"not-a-date","messages_remaining":100,"messages_limit":5000}
        """
        XCTAssertThrowsError(try UsageService.parseResponse(json))
    }

    func test_parseResponse_messagesUsed_isLimitMinusRemaining() throws {
        let json = """
        {"resets_at":"2026-05-23T10:00:00.000Z","messages_remaining":0,"messages_limit":5000}
        """
        let info = try UsageService.parseResponse(json)
        XCTAssertEqual(info.messagesUsed, 5000)
        XCTAssertEqual(info.percentUsed, 1.0)
    }
}
