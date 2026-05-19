import Foundation
import Security

struct ClaudeCredentials {
    let accessToken: String
    let refreshToken: String
    let subscriptionType: String
    let expiresAtMs: Int

    var isExpired: Bool {
        let expiresAt = Date(timeIntervalSince1970: Double(expiresAtMs) / 1000)
        return expiresAt <= Date()
    }
}

enum KeychainError: Error {
    case itemNotFound
    case unexpectedData
    case readFailed(OSStatus)
}

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    func readCredentials() throws -> ClaudeCredentials {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.credentialsService,
            kSecAttrAccount as String: NSUserName(),
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { throw KeychainError.readFailed(status) }
        guard let data = result as? Data,
              let json = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return try Self.parseCredentials(json)
    }

    static func parseCredentials(_ json: String) throws -> ClaudeCredentials {
        struct Root: Decodable {
            struct OAuth: Decodable {
                let accessToken: String
                let refreshToken: String
                let expiresAt: Int
                let subscriptionType: String
            }
            let claudeAiOauth: OAuth
        }
        guard let data = json.data(using: .utf8) else { throw KeychainError.unexpectedData }
        let root: Root
        do {
            root = try JSONDecoder().decode(Root.self, from: data)
        } catch {
            throw KeychainError.unexpectedData
        }
        return ClaudeCredentials(
            accessToken:      root.claudeAiOauth.accessToken,
            refreshToken:     root.claudeAiOauth.refreshToken,
            subscriptionType: root.claudeAiOauth.subscriptionType,
            expiresAtMs:      root.claudeAiOauth.expiresAt
        )
    }
}
