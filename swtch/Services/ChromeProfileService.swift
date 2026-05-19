import Foundation
import AppKit

struct ChromeProfile: Identifiable, Equatable {
    let id: String          // profile directory name e.g. "Default", "Profile 1"
    let email: String
    let displayName: String

    var initials: String { String(email.prefix(while: { $0 != "@" }).prefix(2)).uppercased() }
}

final class ChromeProfileService {
    static let shared = ChromeProfileService()
    private init() {}

    func enumerate() -> [ChromeProfile] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(atPath: Constants.Chrome.profilesPath) else {
            return []
        }
        return dirs.compactMap { dir in
            let prefPath = "\(Constants.Chrome.profilesPath)/\(dir)/Preferences"
            guard let data = fm.contents(atPath: prefPath),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accountInfoArr = json["account_info"] as? [[String: Any]],
                  let first = accountInfoArr.first,
                  let email = first["email"] as? String,
                  !email.isEmpty else { return nil }
            let displayName = (first["full_name"] as? String) ?? email
            return ChromeProfile(id: dir, email: email, displayName: displayName)
        }.sorted { $0.id < $1.id }
    }

    func open(_ profile: ChromeProfile) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Google Chrome", "--args",
                             "--profile-directory=\(profile.id)"]
        try? process.run()
    }
}
