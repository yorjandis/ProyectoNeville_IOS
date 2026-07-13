import SwiftUI

struct HealingGuidanceOrb: View {
    let step: HealingProtocolStep
    let isPaused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetScale: CGFloat {
        guard !isPaused, !reduceMotion else { return 1 }
        switch step.phase {
        case .inhale: return 1.18
        case .exhale: return 0.82
        case .press: return 0.90
        case .sound: return 1.10
        default: return 1
        }
    }

    private var symbol: String {
        switch step.phase {
        case .prepare: return "figure.mind.and.body"
        case .inhale: return "arrow.down.to.line.compact"
        case .exhale: return "arrow.up.from.line.compact"
        case .observe: return "eye.fill"
        case .orient: return "scope"
        case .move: return "figure.walk.motion"
        case .press: return "hand.tap.fill"
        case .sound: return "waveform"
        case .reflect: return "brain.head.profile"
        case .finish: return "checkmark"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.cyan.opacity(0.09))
                .frame(width: 250, height: 250)
                .scaleEffect(targetScale * 1.08)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.72), .mint.opacity(0.55), .cyan.opacity(0.20), .indigo.opacity(0.10)],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 105
                    )
                )
                .frame(width: 188, height: 188)
                .overlay {
                    Circle().stroke(.white.opacity(0.35), lineWidth: 1.2)
                }
                .shadow(color: .cyan.opacity(0.38), radius: 26)
                .scaleEffect(targetScale)

            Image(systemName: isPaused ? "pause.fill" : symbol)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(height: 282)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: min(Double(step.durationSeconds), 8)),
            value: step.id
        )
        .animation(
            reduceMotion ? nil : .easeInOut(duration: min(Double(step.durationSeconds), 8)),
            value: targetScale
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.accessibilityCue ?? step.title)
    }
}

