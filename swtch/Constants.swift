import Foundation

enum Constants {
    enum Keychain {
        static let credentialsService = "Claude Code-credentials"
        // account key = NSUserName() at runtime
        static let safeStorageService = "Claude Safe Storage"
        static let safeStorageAccount = "Claude"
        static let safeStorageKeyAcct = "Claude Key"
    }
    enum Chrome {
        static let profilesPath = ("~/Library/Application Support/Google/Chrome" as NSString).expandingTildeInPath
    }
    enum Cookies {
        static let dbPath          = ("~/Library/Application Support/Claude/Cookies" as NSString).expandingTildeInPath
        static let pbkdf2Salt: [UInt8] = Array("saltysalt".utf8)
        static let pbkdf2Iterations = 1003
        static let pbkdf2KeyLength  = 16
    }
    enum API {
        static let rateLimitStatus = "https://claude.ai/api/rate_limit_status"
    }
    enum CLI {
        static let claudePath = "/Users/VrushankPersonal/.local/bin/claude"
    }
}
