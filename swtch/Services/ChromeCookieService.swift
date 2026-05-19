import Foundation
import Security
import SQLite3
import CommonCrypto

enum CookieError: Error {
    case keyNotFound
    case decryptionFailed
    case dbOpenFailed
    case noCookieFound(String)
}

final class ChromeCookieService {

    // MARK: - Public API

    func readCookie(named name: String) throws -> String {
        let password = try readSafeStoragePassword()
        let key = try Self.deriveKey(from: password)
        let encryptedValue = try readEncryptedCookieValue(named: name)
        return try Self.decryptValue(encryptedValue, key: key)
    }

    // MARK: - Keychain

    private func readSafeStoragePassword() throws -> String {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.safeStorageService,
            kSecAttrAccount as String: Constants.Keychain.safeStorageAccount,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw CookieError.keyNotFound
        }
        return password
    }

    // MARK: - SQLite

    private func readEncryptedCookieValue(named name: String) throws -> Data {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".db")
        try FileManager.default.copyItem(
            atPath: Constants.Cookies.dbPath,
            toPath: tmp.path
        )
        defer { try? FileManager.default.removeItem(at: tmp) }

        var db: OpaquePointer?
        guard sqlite3_open_v2(tmp.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw CookieError.dbOpenFailed
        }
        defer { sqlite3_close(db) }

        let sql = "SELECT encrypted_value FROM cookies WHERE name = ? AND host_key LIKE '%claude.ai%' LIMIT 1"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw CookieError.dbOpenFailed
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw CookieError.noCookieFound(name)
        }

        guard let bytes = sqlite3_column_blob(stmt, 0) else {
            throw CookieError.noCookieFound(name)
        }
        let count = sqlite3_column_bytes(stmt, 0)
        return Data(bytes: bytes, count: Int(count))
    }

    // MARK: - Crypto (static for testability)

    static func deriveKey(from password: String) throws -> [UInt8] {
        let passBytes = Array(password.utf8)
        let salt = Constants.Cookies.pbkdf2Salt
        var derived = [UInt8](repeating: 0, count: Constants.Cookies.pbkdf2KeyLength)
        let result = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password, passBytes.count,
            salt, salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
            UInt32(Constants.Cookies.pbkdf2Iterations),
            &derived, derived.count
        )
        guard result == kCCSuccess else { throw CookieError.decryptionFailed }
        return derived
    }

    static func decryptValue(_ encrypted: Data, key: [UInt8]) throws -> String {
        guard encrypted.count > 3 else { throw CookieError.decryptionFailed }
        let cipher = encrypted.dropFirst(3) // strip "v10"
        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)

        var decrypted = [UInt8](repeating: 0, count: cipher.count + kCCBlockSizeAES128)
        var decryptedLength = 0

        let status = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                cipher.withUnsafeBytes { cipherPtr in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, key.count,
                        ivPtr.baseAddress,
                        cipherPtr.baseAddress, cipher.count,
                        &decrypted, decrypted.count,
                        &decryptedLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw CookieError.decryptionFailed }
        guard let plaintext = String(bytes: Array(decrypted.prefix(decryptedLength)), encoding: .utf8) else {
            throw CookieError.decryptionFailed
        }
        return plaintext
    }

    static func testEncrypt(_ plaintext: String, key: [UInt8], iv: Data) throws -> Data {
        let input = Array(plaintext.utf8)
        var output = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var outputLength = 0
        let status = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                CCCrypt(
                    CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    keyPtr.baseAddress, key.count,
                    ivPtr.baseAddress,
                    input, input.count,
                    &output, output.count,
                    &outputLength
                )
            }
        }
        guard status == kCCSuccess else { throw CookieError.decryptionFailed }
        return Data(output.prefix(outputLength))
    }
}
