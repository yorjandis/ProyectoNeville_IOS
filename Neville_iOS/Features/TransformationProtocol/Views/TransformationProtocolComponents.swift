import SwiftUI

enum TransformationProtocolTheme {
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.18)
    static let secondaryInk = Color(red: 0.25, green: 0.29, blue: 0.36)
    static let tertiaryInk = Color(red: 0.40, green: 0.44, blue: 0.50)
    static let violet = Color(red: 0.38, green: 0.25, blue: 0.72)
    static let blue = Color(red: 0.17, green: 0.48, blue: 0.78)
    static let mint = Color(red: 0.31, green: 0.72, blue: 0.63)
    static let warm = Color(red: 0.96, green: 0.65, blue: 0.39)
    static let accessGradientColors = [
        Color(red: 0.34, green: 0.20, blue: 0.68),
        Color(red: 0.12, green: 0.46, blue: 0.70)
    ]

    static let background = LinearGradient(
        colors: accessGradientColors,
        startPoint: .top,
        endPoint: .bottom
    )

    static func accessGradient(
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        LinearGradient(
            colors: accessGradientColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

struct TransformationProtocolCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .foregroundStyle(TransformationProtocolTheme.ink)
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 1)
            }
            .shadow(color: TransformationProtocolTheme.ink.opacity(0.07), radius: 16, y: 8)
    }
}

struct TransformationProtocolSectionTitle: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    init(_ title: String, eyebrow: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let eyebrow {
                Text(L10n.exact(eyebrow).uppercased(with: AppLanguage.current.locale))
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(TransformationProtocolTheme.violet)
            }
            Text(L10n.exact(title))
                .font(.title2.weight(.bold))
                .foregroundStyle(TransformationProtocolTheme.ink)
            if let subtitle {
                Text(L10n.exact(subtitle))
                    .font(.subheadline)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TransformationProtocolProgressRing: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(TransformationProtocolTheme.violet.opacity(0.13), lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(
                        colors: [
                            TransformationProtocolTheme.violet,
                            TransformationProtocolTheme.blue,
                            TransformationProtocolTheme.mint
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.headline.weight(.bold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
        }
        .frame(width: 92, height: 92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso \(Int((progress * 100).rounded())) por ciento")
    }
}

struct TransformationProtocolField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    var axis: Axis = .vertical

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L10n.exact(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TransformationProtocolTheme.ink)
            TextField(L10n.exact(prompt), text: $text, axis: axis)
                .lineLimit(axis == .vertical ? 2...5 : 1...1)
                .textFieldStyle(.plain)
                .padding(12)
                .background(TransformationProtocolTheme.violet.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }
}

struct TransformationProtocolMetricPicker: View {
    let title: String
    let zero: String
    let one: String
    let two: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value)/2")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.violet)
            }

            Picker(L10n.exact(title), selection: $value) {
                Text("0").tag(0)
                Text("1").tag(1)
                Text("2").tag(2)
            }
            .pickerStyle(.segmented)

            Text(L10n.exact([zero, one, two][max(0, min(2, value))]))
                .font(.caption)
                .foregroundStyle(TransformationProtocolTheme.secondaryInk)
        }
    }
}

extension Date {
    static func transformationProtocolTime(minuteOfDay: Int) -> Date {
        Calendar.current.date(
            bySettingHour: max(0, min(23, minuteOfDay / 60)),
            minute: max(0, min(59, minuteOfDay % 60)),
            second: 0,
            of: Date()
        ) ?? Date()
    }

    var transformationProtocolMinuteOfDay: Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
