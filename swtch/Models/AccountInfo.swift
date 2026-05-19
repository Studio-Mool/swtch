import Foundation

struct AccountInfo: Equatable {
    let email: String
    let orgName: String
    let subscriptionType: String

    var initials: String {
        email.prefix(2).uppercased()
    }
}
