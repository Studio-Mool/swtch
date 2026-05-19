import SwiftUI

struct UsageInfo {
    let messagesUsed: Int
    let messagesLimit: Int
    let resetsAt: Date

    var percentUsed: Double {
        guard messagesLimit > 0 else { return 0 }
        return Double(messagesUsed) / Double(messagesLimit)
    }

    var resetCountdown: String {
        let comps = Calendar.current.dateComponents([.day, .hour], from: Date(), to: resetsAt)
        let days = comps.day ?? 0
        let hours = comps.hour ?? 0
        if days > 0 { return "Resets in \(days)d \(hours)h" }
        return "Resets in \(hours)h"
    }

    enum BarColor { case blue, amber, red }
    var barColor: BarColor {
        if percentUsed >= 0.9 { return .red }
        if percentUsed >= 0.8 { return .amber }
        return .blue
    }
}
