import SwiftUI

enum HealingCenterVisualStyle {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.035, green: 0.075, blue: 0.13),
            Color(red: 0.075, green: 0.15, blue: 0.18),
            Color(red: 0.11, green: 0.09, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func colors(for palette: HealingPalette) -> [Color] {
        switch palette {
        case .ocean: return [.cyan, Color(red: 0.16, green: 0.42, blue: 0.95)]
        case .amber: return [.yellow, .orange]
        case .violet: return [.purple, .indigo]
        case .forest: return [.mint, Color(red: 0.05, green: 0.52, blue: 0.36)]
        case .rose: return [.pink, Color(red: 0.91, green: 0.24, blue: 0.24)]
        case .slate: return [.teal, Color(red: 0.29, green: 0.34, blue: 0.51)]
        }
    }

    static func color(for evidence: HealingEvidenceLevel) -> Color {
        switch evidence {
        case .supported: return .green
        case .promising: return .cyan
        case .complementary: return .orange
        case .experimental: return .purple
        }
    }
}

struct HealingGlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
    }
}

struct HealingSituationCard: View {
    let situation: HealingSituation
    let isFavorite: Bool

    private var colors: [Color] {
        HealingCenterVisualStyle.colors(for: situation.palette)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: situation.symbol)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            .shadow(color: colors.last?.opacity(0.35) ?? .clear, radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(situation.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Text(situation.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [colors.first?.opacity(0.20) ?? .clear, .white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colors.first?.opacity(0.33) ?? .white.opacity(0.15), lineWidth: 1)
        }
    }
}

struct HealingEvidenceBadge: View {
    let level: HealingEvidenceLevel

    var body: some View {
        Label(level.title, systemImage: "checkmark.seal")
            .font(.caption.weight(.semibold))
            .foregroundStyle(HealingCenterVisualStyle.color(for: level))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(HealingCenterVisualStyle.color(for: level).opacity(0.14), in: Capsule())
    }
}

