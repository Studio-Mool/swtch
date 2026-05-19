import SwiftUI

struct UsageView: View {
    @EnvironmentObject var appState: AppState
    @State private var animatedPercent: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Group {
            switch appState.loadState {
            case .loading where appState.usage == nil:
                loadingState
            case .error(let msg) where appState.usage == nil:
                errorState(msg)
            default:
                if let usage = appState.usage {
                    if usage.messagesLimit == 0 {
                        Text("Usage data unavailable")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 52)
                    } else {
                        usageContent(usage)
                            .onAppear {
                                animatedPercent = 0
                                setAnimatedPercent(usage.percentUsed)
                            }
                            .onChange(of: usage.percentUsed) { newValue in
                                setAnimatedPercent(newValue)
                            }
                    }
                } else {
                    loadingState
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func setAnimatedPercent(_ value: Double) {
        if reduceMotion {
            animatedPercent = value
        } else {
            withAnimation(.easeOut(duration: 0.4)) {
                animatedPercent = value
            }
        }
    }

    // MARK: - Usage content

    private func usageContent(_ usage: UsageInfo) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(Int(usage.percentUsed * 100))")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white.opacity(0.6)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Usage")
                    .font(.system(size: 10))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .frame(height: 3)
                    Capsule()
                        .fill(barGradient(for: usage))
                        .frame(width: geo.size.width * animatedPercent, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.bottom, 4)

            HStack {
                Text("\(usage.messagesUsed) of \(usage.messagesLimit)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.quaternary)
                Spacer()
                Text(usage.resetCountdown)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.quaternary)
            }
        }
    }

    private func barGradient(for usage: UsageInfo) -> LinearGradient {
        switch usage.barColor {
        case .blue:  return LinearGradient(colors: [Color(hex: "#0A84FF"), Color(hex: "#34aadc")], startPoint: .leading, endPoint: .trailing)
        case .amber: return LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#FFD60A")], startPoint: .leading, endPoint: .trailing)
        case .red:   return LinearGradient(colors: [Color(hex: "#FF3B30"), Color(hex: "#FF6961")], startPoint: .leading, endPoint: .trailing)
        }
    }

    // MARK: - Loading state

    private var loadingState: some View {
        HStack {
            ProgressView().scaleEffect(0.7)
            Text("Loading usage…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
    }

    // MARK: - Error state

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            if case .error = appState.loadState {
                Button("Retry") { Task { await appState.refresh() } }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundStyle(.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Hex color helper

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >>  8) & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
