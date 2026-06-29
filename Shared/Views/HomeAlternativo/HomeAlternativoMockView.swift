//
//  HomeAlternativoMockView.swift
//  Neville_iOS
//
//  Created by Codex on 28/06/26.
//

import SwiftUI

struct HomeAlternativoMockView: View {
    let variant: HomeAlternativoVariant

    private let tools = HomeAlternativoTool.sampleTools
    private let progressItems = HomeAlternativoProgressItem.sampleItems

    private var theme: HomeAlternativoTheme {
        HomeAlternativoTheme(variant: variant)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                toolsGrid
                progressSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 34)
        }
        .background(theme.background.ignoresSafeArea())
        .foregroundStyle(theme.primaryText)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Hola, este es\ntu momento.")
                .font(.system(size: 39, weight: .semibold, design: .rounded))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Text("¿Qué quieres hacer hoy?")
                    .font(.system(size: 23, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.secondaryText)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
    }

    private var toolsGrid: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(tools) { tool in
                HomeAlternativoToolCard(tool: tool, theme: theme)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
                .overlay(theme.divider)

            HStack {
                Text("Mi progreso")
                    .font(.system(size: 29, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
            }

            HStack(alignment: .top, spacing: 14) {
                ForEach(progressItems) { item in
                    HomeAlternativoProgressCard(item: item, theme: theme)
                }
            }
        }
    }
}

enum HomeAlternativoVariant: String, CaseIterable, Identifiable {
    case clara
    case oscura

    var id: String { rawValue }
}

private struct HomeAlternativoTool: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let secondarySymbol: String?
    let colors: [Color]

    init(title: String, symbol: String, secondarySymbol: String? = nil, colors: [Color]) {
        self.title = title
        self.symbol = symbol
        self.secondarySymbol = secondarySymbol
        self.colors = colors
    }

    static let sampleTools: [HomeAlternativoTool] = [
        .init(title: "Calma", symbol: "sparkles", colors: [.blue, .cyan]),
        .init(title: "Agenda", symbol: "calendar", colors: [.yellow, .orange]),
        .init(title: "Presencia", symbol: "camera.macro", colors: [.teal, .mint]),
        .init(title: "Metas", symbol: "target", colors: [.green, .mint]),
        .init(title: "Diario", symbol: "book.closed", colors: [.purple, .pink]),
        .init(title: "Alimentos", symbol: "qrcode.viewfinder", secondarySymbol: "fork.knife", colors: [.orange, .yellow]),
        .init(title: "Notas", symbol: "note.text", colors: [.cyan, .blue]),
        .init(title: "Ritual", symbol: "sunrise", colors: [.pink, .orange]),
        .init(title: "Coherencia", symbol: "waveform.path.ecg", colors: [.indigo, .teal])
    ]
}

private struct HomeAlternativoProgressItem: Identifiable {
    let id = UUID()
    let title: String
    let valueText: String
    let symbol: String
    let progress: Double
    let colors: [Color]

    static let sampleItems: [HomeAlternativoProgressItem] = [
        .init(
            title: "Presencia",
            valueText: "12 momentos",
            symbol: "heart.text.square",
            progress: 0.68,
            colors: [
                Color(red: 1.00, green: 0.91, blue: 0.54),
                Color(red: 1.00, green: 0.62, blue: 0.10),
                Color(red: 0.74, green: 0.33, blue: 0.95)
            ]
        ),
        .init(
            title: "Metas",
            valueText: "2 activas",
            symbol: "target",
            progress: 0.76,
            colors: [
                Color(red: 1.00, green: 0.94, blue: 0.46),
                Color(red: 0.98, green: 0.68, blue: 0.07),
                Color(red: 0.20, green: 0.72, blue: 0.44)
            ]
        ),
        .init(
            title: "Diario",
            valueText: "1 entrada",
            symbol: "book.closed",
            progress: 0.42,
            colors: [
                Color(red: 0.74, green: 1.00, blue: 0.96),
                Color(red: 0.22, green: 0.78, blue: 0.76),
                Color(red: 0.02, green: 0.48, blue: 0.52)
            ]
        )
    ]
}

private struct HomeAlternativoTheme {
    let variant: HomeAlternativoVariant

    var background: LinearGradient {
        switch variant {
        case .clara:
            return LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.99, blue: 0.97),
                    Color(red: 0.93, green: 0.98, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .oscura:
            return LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.06, blue: 0.18),
                    Color(red: 0.03, green: 0.12, blue: 0.29),
                    Color(red: 0.01, green: 0.04, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var primaryText: Color {
        switch variant {
        case .clara: return Color(red: 0.05, green: 0.06, blue: 0.09)
        case .oscura: return .white
        }
    }

    var secondaryText: Color {
        switch variant {
        case .clara: return Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.72)
        case .oscura: return .white.opacity(0.72)
        }
    }

    var divider: Color {
        switch variant {
        case .clara: return Color.black.opacity(0.10)
        case .oscura: return Color.white.opacity(0.15)
        }
    }

    var cardStroke: Color {
        switch variant {
        case .clara: return Color.white.opacity(0.50)
        case .oscura: return Color.white.opacity(0.36)
        }
    }

    var cardShadow: Color {
        switch variant {
        case .clara: return Color.black.opacity(0.14)
        case .oscura: return Color.black.opacity(0.58)
        }
    }

    var progressTrack: Color {
        switch variant {
        case .clara: return Color.black.opacity(0.14)
        case .oscura: return Color.white.opacity(0.22)
        }
    }

    var cardForeground: Color {
        switch variant {
        case .clara: return .white
        case .oscura: return Color(red: 0.02, green: 0.04, blue: 0.10)
        }
    }

    func cardColors(for colors: [Color]) -> [Color] {
        switch variant {
        case .clara:
            return colors
        case .oscura:
            return colors.map { $0.opacity(0.98) }
        }
    }
}

private struct HomeAlternativoToolCard: View {
    let tool: HomeAlternativoTool
    let theme: HomeAlternativoTheme

    var body: some View {
        VStack(spacing: 9) {
            toolIcon
                .frame(height: 42)

            Text(tool.title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(theme.cardForeground)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: theme.cardColors(for: tool.colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(Color.white.opacity(theme.variant == .oscura ? 0.08 : 0.10))
                .frame(height: 36)
                .blur(radius: 10)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(theme.cardStroke, lineWidth: 1.2)
        }
        .shadow(color: tool.colors.first?.opacity(theme.variant == .oscura ? 0.48 : 0.28) ?? theme.cardShadow, radius: 14, y: 8)
        .shadow(color: theme.cardShadow, radius: 8, y: 4)
    }

    @ViewBuilder
    private var toolIcon: some View {
        if let secondarySymbol = tool.secondarySymbol {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 38, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(theme.cardForeground)

                Image(systemName: secondarySymbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.cardForeground)
                    .padding(5)
                    .background(Circle().fill(Color.white.opacity(theme.variant == .oscura ? 0.30 : 0.22)))
                    .offset(x: 8, y: 5)
            }
        } else {
            Image(systemName: tool.symbol)
                .font(.system(size: 38, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(theme.cardForeground)
        }
    }
}

private struct HomeAlternativoProgressCard: View {
    let item: HomeAlternativoProgressItem
    let theme: HomeAlternativoTheme

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                Circle()
                    .trim(from: 0.08, to: 0.92)
                    .stroke(
                        theme.progressTrack,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(112))

                Circle()
                    .trim(from: 0.08, to: 0.08 + (0.84 * item.progress))
                    .stroke(
                        AngularGradient(
                            colors: item.colors,
                            center: .center,
                            startAngle: .degrees(112),
                            endAngle: .degrees(414)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(112))

                Circle()
                    .fill(item.colors.last?.opacity(theme.variant == .clara ? 0.15 : 0.28) ?? .clear)
                    .frame(width: 48, height: 48)

                Image(systemName: item.symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: item.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 86, height: 86)

            Text(item.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .minimumScaleFactor(0.82)
                .lineLimit(1)

            Text(item.valueText)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .minimumScaleFactor(0.82)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Home Alternativo - Claro y Oscuro") {
    ScrollView(.horizontal, showsIndicators: true) {
        HStack(spacing: 0) {
            HomeAlternativoMockView(variant: .clara)
                .frame(width: 390, height: 844)
                .preferredColorScheme(.light)

            HomeAlternativoMockView(variant: .oscura)
                .frame(width: 390, height: 844)
                .preferredColorScheme(.dark)
        }
    }
}
