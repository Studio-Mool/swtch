import Foundation

enum UsageError: Error {
    case httpError(Int)
    case parseError
    case missingCookie
}

final class UsageService {
    private let keychainService: KeychainService
    private let cookieService: ChromeCookieService
    private let session: URLSession

    init(keychainService: KeychainService = .shared,
         cookieService: ChromeCookieService = ChromeCookieService(),
         session: URLSession = .shared) {
        self.keychainService = keychainService
        self.cookieService = cookieService
        self.session = session
    }

    func fetchUsage() async throws -> UsageInfo {
        let creds = try keychainService.readCredentials()
        let cfClearance = try cookieService.readCookie(named: "cf_clearance")

        var request = URLRequest(url: URL(string: Constants.API.rateLimitStatus)!)
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("cf_clearance=\(cfClearance)", forHTTPHeaderField: "Cookie")
        request.setValue("claude.ai", forHTTPHeaderField: "Origin")
        request.setValue("claude-code/2.1.138", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        let status = (response as! HTTPURLResponse).statusCode
        guard (200..<300).contains(status) else { throw UsageError.httpError(status) }

        guard let json = String(data: data, encoding: .utf8) else { throw UsageError.parseError }
        return try Self.parseResponse(json)
    }

    // Static for testability — field names match confirmed API response shape
    static func parseResponse(_ json: String) throws -> UsageInfo {
        struct Response: Decodable {
            let resetsAt: String
            let messagesRemaining: Int
            let messagesLimit: Int

            enum CodingKeys: String, CodingKey {
                case resetsAt          = "resets_at"
                case messagesRemaining = "messages_remaining"
                case messagesLimit     = "messages_limit"
            }
        }
        guard let data = json.data(using: .utf8) else { throw UsageError.parseError }
        let r: Response
        do {
            r = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw UsageError.parseError
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let resetsAt = formatter.date(from: r.resetsAt) else { throw UsageError.parseError }

        return UsageInfo(
            messagesUsed:  r.messagesLimit - r.messagesRemaining,
            messagesLimit: r.messagesLimit,
            resetsAt:      resetsAt
        )
    }
}
