import XCTest
@testable import swtch

final class ChromeCookieServiceTests: XCTestCase {

    func test_deriveKey_producesCorrectLength() throws {
        let key = try ChromeCookieService.deriveKey(from: "test-password")
        XCTAssertEqual(key.count, 16)
    }

    func test_decryptValue_roundTrip() throws {
        let password = "test-password"
        let key = try ChromeCookieService.deriveKey(from: password)
        let plaintext = "hello-cookie-value"
        let iv = Data(repeating: 0x20, count: 16)

        let encrypted = try ChromeCookieService.testEncrypt(plaintext, key: key, iv: iv)
        let prefixed = Data([0x76, 0x31, 0x30]) + encrypted  // "v10" prefix

        let decrypted = try ChromeCookieService.decryptValue(prefixed, key: key)
        XCTAssertEqual(decrypted, plaintext)
    }

    func test_decryptValue_throwsOnTooShortData() {
        XCTAssertThrowsError(try ChromeCookieService.decryptValue(Data([0x76, 0x31]), key: [UInt8](repeating: 0, count: 16)))
    }
}
