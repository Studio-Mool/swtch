import XCTest
@testable import swtch

final class ModelTests: XCTestCase {
    func test_usageInfo_percentUsed_calculatesCorrectly() {
        let info = UsageInfo(messagesUsed: 3400, messagesLimit: 5000,
                             resetsAt: Date().addingTimeInterval(86400 * 4 + 3600 * 11))
        XCTAssertEqual(info.percentUsed, 0.68, accuracy: 0.001)
    }

    func test_usageInfo_percentUsed_zeroLimitReturnsZero() {
        let info = UsageInfo(messagesUsed: 100, messagesLimit: 0,
                             resetsAt: Date())
        XCTAssertEqual(info.percentUsed, 0.0)
    }

    func test_usageInfo_resetCountdown_daysAndHours() {
        let future = Date().addingTimeInterval(86400 * 4 + 3600 * 11 + 60)
        let info = UsageInfo(messagesUsed: 0, messagesLimit: 5000, resetsAt: future)
        XCTAssertEqual(info.resetCountdown, "Resets in 4d 11h")
    }

    func test_usageInfo_resetCountdown_hoursOnly() {
        let future = Date().addingTimeInterval(3600 * 5 + 60)
        let info = UsageInfo(messagesUsed: 0, messagesLimit: 5000, resetsAt: future)
        XCTAssertEqual(info.resetCountdown, "Resets in 5h")
    }

    func test_usageInfo_barColor_normalIsBlue() {
        let info = UsageInfo(messagesUsed: 3400, messagesLimit: 5000, resetsAt: Date())
        XCTAssertEqual(info.barColor, .blue)
    }

    func test_usageInfo_barColor_amberAt80Percent() {
        let info = UsageInfo(messagesUsed: 4000, messagesLimit: 5000, resetsAt: Date())
        XCTAssertEqual(info.barColor, .amber)
    }

    func test_usageInfo_barColor_redAt90Percent() {
        let info = UsageInfo(messagesUsed: 4500, messagesLimit: 5000, resetsAt: Date())
        XCTAssertEqual(info.barColor, .red)
    }
}
