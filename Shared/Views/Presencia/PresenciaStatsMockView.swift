
#if DEBUG
#if os(iOS)
import SwiftUI

private enum PresenciaMockTimelineLayout {
    static let horizontalHourSpacing: CGFloat = 25
}

private enum PresenciaMockAppearance: String, CaseIterable {
    case dark
    case light

    var title: String {
        switch self {
        case .dark: return "Oscuro"
        case .light: return "Claro"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

private enum PresenciaMockAppearanceStorage {
    static let key = "presenciaStatsAppearance"
    static let defaultValue = PresenciaMockAppearance.dark.rawValue
}

private enum PresenciaMockVisibleCardsStorage {
    static let key = "presenciaStatsVisibleCards"
    static let schemaVersionKey = "presenciaStatsVisibleCardsSchemaVersion"
    static let currentSchemaVersion = 1
    static var defaultValue: String {
        PresenciaMockCard.allCases.map(\.rawValue).joined(separator: ",")
    }
}

private extension AnyTransition {
    static var presenciaMockCardVisibility: AnyTransition {
        .opacity
    }
}

private enum PresenciaMockCard: String, CaseIterable {
    case todayReturns
    case currentStreak
    case weeklyAverage
    case dominantMood
    case practicalInsights
    case dailyEvents
    case dailyTimeline
    case ratio
    case moods

    var title: String {
        switch self {
        case .todayReturns: return "Hoy"
        case .currentStreak: return "Racha"
        case .weeklyAverage: return "Promedio semanal"
        case .dominantMood: return "Estado predominante"
        case .practicalInsights: return "Datos prácticos"
        case .dailyEvents: return "Eventos diarios"
        case .dailyTimeline: return "Momentos de hoy"
        case .ratio: return "Cociente"
        case .moods: return "Estados de ánimo"
        }
    }
}

private struct PresenciaMockTheme {
    let screenTop: Color
    let screenBottom: Color
    let cardTop: Color
    let cardBottom: Color
    let cardStroke: Color
    let cardAccentGlowOpacity: Double
    let cardShadowOpacity: Double
    let primaryText: Color
    let secondaryText: Color
    let rowBackground: Color
    let gridLine: Color
    let pointStroke: Color
}

private enum PresenciaMockPalette {
    static func theme(for rawValue: String? = nil) -> PresenciaMockTheme {
        let rawAppearance = rawValue ?? UserDefaults.standard.string(forKey: PresenciaMockAppearanceStorage.key)
        let appearance = PresenciaMockAppearance(rawValue: rawAppearance ?? PresenciaMockAppearanceStorage.defaultValue) ?? .dark

        switch appearance {
        case .dark:
            return PresenciaMockTheme(
                screenTop: .indigo.opacity(0.95),
                screenBottom: .teal.opacity(0.55),
                cardTop: Color(red: 0.17, green: 0.20, blue: 0.28),
                cardBottom: Color(red: 0.10, green: 0.13, blue: 0.20),
                cardStroke: Color.white.opacity(0.16),
                cardAccentGlowOpacity: 0.14,
                cardShadowOpacity: 0.18,
                primaryText: .white,
                secondaryText: .white.opacity(0.76),
                rowBackground: .white.opacity(0.08),
                gridLine: .white,
                pointStroke: .white.opacity(0.72)
            )
        case .light:
            return PresenciaMockTheme(
                screenTop: Color(red: 0.86, green: 0.93, blue: 0.98),
                screenBottom: Color(red: 0.70, green: 0.82, blue: 0.90),
                cardTop: Color(red: 0.96, green: 0.98, blue: 1.00),
                cardBottom: Color(red: 0.83, green: 0.90, blue: 0.96),
                cardStroke: Color(red: 0.18, green: 0.30, blue: 0.42).opacity(0.18),
                cardAccentGlowOpacity: 0.16,
                cardShadowOpacity: 0.12,
                primaryText: Color(red: 0.08, green: 0.16, blue: 0.24),
                secondaryText: Color(red: 0.08, green: 0.16, blue: 0.24).opacity(0.68),
                rowBackground: Color.white.opacity(0.38),
                gridLine: Color(red: 0.14, green: 0.26, blue: 0.38),
                pointStroke: Color.white.opacity(0.86)
            )
        }
    }

    static var cardTop: Color { theme().cardTop }
    static var cardBottom: Color { theme().cardBottom }
    static var cardStroke: Color { theme().cardStroke }
    static var cardAccentGlowOpacity: Double { theme().cardAccentGlowOpacity }
    static var cardShadowOpacity: Double { theme().cardShadowOpacity }
    static var primaryText: Color { theme().primaryText }
    static var secondaryText: Color { theme().secondaryText }
    static var rowBackground: Color { theme().rowBackground }
    static var gridLine: Color { theme().gridLine }
    static var pointStroke: Color { theme().pointStroke }
}

private struct PresenciaMockCardBackground: View {
    let accent: Color
    let cornerRadius: CGFloat
    @AppStorage(PresenciaMockAppearanceStorage.key) private var appearanceRawValue = PresenciaMockAppearanceStorage.defaultValue

    var body: some View {
        let theme = PresenciaMockPalette.theme(for: appearanceRawValue)

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        theme.cardTop,
                        theme.cardBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.cardStroke, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(accent.opacity(theme.cardAccentGlowOpacity))
                    .frame(height: 54)
                    .blur(radius: 18)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
            }
            .shadow(color: .black.opacity(theme.cardShadowOpacity), radius: 18, y: 10)
    }
}

struct PresenciaStatsMockView: View {
    private let sample = PresenciaMockSample.default
    @State private var dailyEventsRange = 14
    @State private var practicalInsightsRange = 14
    @State private var ratioRange = 14
    @State private var moodRange = 14
    @State private var dominantMoodRange = 14
    @AppStorage(PresenciaMockAppearanceStorage.key) private var appearanceRawValue = PresenciaMockAppearanceStorage.defaultValue
    @AppStorage(PresenciaMockVisibleCardsStorage.key) private var visibleCardsRawValue = PresenciaMockVisibleCardsStorage.defaultValue

    private var selectedAppearance: PresenciaMockAppearance {
        PresenciaMockAppearance(rawValue: appearanceRawValue) ?? .dark
    }

    private var visibleCards: Set<String> {
        Set(visibleCardsRawValue.split(separator: ",").map(String.init))
    }

    var body: some View {
        NavigationStack {
                ScrollView {
                    PresenciaMockContent(
                        sample: sample,
                        dailyEventsRange: $dailyEventsRange,
                        practicalInsightsRange: $practicalInsightsRange,
                        ratioRange: $ratioRange,
                        moodRange: $moodRange,
                        dominantMoodRange: $dominantMoodRange,
                        visibleCards: visibleCards
                    )
                        .padding()
                }
            .id(appearanceRawValue)
            .background(PresenciaMockBackground(appearanceRawValue: appearanceRawValue))
            .navigationTitle("Presencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    visibilityMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(PresenciaMockAppearance.allCases, id: \.rawValue) { appearance in
                            Button {
                                appearanceRawValue = appearance.rawValue
                            } label: {
                                Label(appearance.title, systemImage: selectedAppearance == appearance ? "checkmark" : appearance.icon)
                            }
                        }
                    } label: {
                        Image(systemName: selectedAppearance.icon)
                    }
                    .accessibilityLabel("Cambiar apariencia")
                }
            }
            .onAppear {
                ensureVisibleCardsStorage()
            }
        }
    }

    private var visibilityMenu: some View {
        Menu {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    visibleCardsRawValue = PresenciaMockVisibleCardsStorage.defaultValue
                }
            } label: {
                Label("Mostrar todas", systemImage: "eye")
            }

            Divider()

            ForEach(PresenciaMockCard.allCases, id: \.rawValue) { card in
                Button {
                    toggleCardVisibility(card)
                } label: {
                    Label(card.title, systemImage: isCardVisible(card) ? "checkmark.circle.fill" : "circle")
                }
            }
        } label: {
            Image(systemName: "rectangle.grid.2x2")
        }
        .accessibilityLabel("Seleccionar tarjetas visibles")
    }

    private func isCardVisible(_ card: PresenciaMockCard) -> Bool {
        visibleCards.contains(card.rawValue)
    }

    private func toggleCardVisibility(_ card: PresenciaMockCard) {
        var updatedCards = visibleCards
        if updatedCards.contains(card.rawValue) {
            updatedCards.remove(card.rawValue)
        } else {
            updatedCards.insert(card.rawValue)
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            visibleCardsRawValue = PresenciaMockCard.allCases
                .map(\.rawValue)
                .filter { updatedCards.contains($0) }
                .joined(separator: ",")
        }
    }

    private func ensureVisibleCardsStorage() {
        let defaults = UserDefaults.standard
        let schemaVersion = defaults.integer(forKey: PresenciaMockVisibleCardsStorage.schemaVersionKey)
        guard schemaVersion < PresenciaMockVisibleCardsStorage.currentSchemaVersion else { return }

        var updatedCards = visibleCards
        updatedCards.insert(PresenciaMockCard.practicalInsights.rawValue)
        visibleCardsRawValue = PresenciaMockCard.allCases
            .map(\.rawValue)
            .filter { updatedCards.contains($0) }
            .joined(separator: ",")
        defaults.set(PresenciaMockVisibleCardsStorage.currentSchemaVersion, forKey: PresenciaMockVisibleCardsStorage.schemaVersionKey)
    }
}

private struct PresenciaMockContent: View {
    let sample: PresenciaMockSample
    @Binding var dailyEventsRange: Int
    @Binding var practicalInsightsRange: Int
    @Binding var ratioRange: Int
    @Binding var moodRange: Int
    @Binding var dominantMoodRange: Int
    let visibleCards: Set<String>

    private var dailyEventDays: [PresenciaMockDay] {
        Array(sample.days.suffix(dailyEventsRange))
    }

    private var practicalInsightDays: [PresenciaMockDay] {
        Array(sample.days.suffix(practicalInsightsRange))
    }

    private var ratioDays: [PresenciaMockDay] {
        Array(sample.days.suffix(ratioRange))
    }

    private var visibleMoods: [PresenciaMockMood] {
        sample.moods.map { mood in
            let scaledCount = max(Int((Double(mood.count) * Double(moodRange) / 90.0).rounded()), 1)
            return PresenciaMockMood(id: mood.id, title: mood.title, count: scaledCount)
        }
    }

    private var hasVisibleInsightCards: Bool {
        isCardVisible(.todayReturns)
            || isCardVisible(.currentStreak)
            || isCardVisible(.weeklyAverage)
            || isCardVisible(.dominantMood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PresenciaMockHeader(todayCount: sample.todayCount)
            if hasVisibleInsightCards {
                PresenciaMockCards(sample: sample, selectedRange: $dominantMoodRange, visibleCards: visibleCards)
                    .transition(.presenciaMockCardVisibility)
            }
            if isCardVisible(.practicalInsights) {
                PresenciaMockPracticalInsightsCard(
                    days: practicalInsightDays,
                    events: sample.events,
                    selectedRange: $practicalInsightsRange
                )
                    .transition(.presenciaMockCardVisibility)
            }
            if isCardVisible(.dailyEvents) {
                PresenciaMockBarsCard(days: dailyEventDays, selectedRange: $dailyEventsRange)
                    .transition(.presenciaMockCardVisibility)
            }
            if isCardVisible(.dailyTimeline) {
                PresenciaMockTimelineCard(events: sample.events)
                    .transition(.presenciaMockCardVisibility)
            }
            if isCardVisible(.ratio) {
                PresenciaMockRatioCard(days: ratioDays, selectedRange: $ratioRange)
                    .transition(.presenciaMockCardVisibility)
            }
            if isCardVisible(.moods) {
                PresenciaMockMoodCard(moods: visibleMoods, selectedRange: $moodRange)
                    .transition(.presenciaMockCardVisibility)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: visibleCards)
    }

    private func isCardVisible(_ card: PresenciaMockCard) -> Bool {
        visibleCards.contains(card.rawValue)
    }
}

private struct PresenciaMockBackground: View {
    let appearanceRawValue: String

    var body: some View {
        let theme = PresenciaMockPalette.theme(for: appearanceRawValue)

        LinearGradient(
            colors: [theme.screenTop, theme.screenBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct PresenciaMockHeader: View {
    let todayCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presencia")
                .font(.largeTitle.bold())
                .foregroundStyle(PresenciaMockPalette.primaryText)
            Text("Hoy has vuelto al presente \(todayCount) veces.")
                .font(.headline)
                .foregroundStyle(PresenciaMockPalette.secondaryText)
        }
    }
}

private struct PresenciaMockCards: View {
    let sample: PresenciaMockSample
    @Binding var selectedRange: Int
    let visibleCards: Set<String>

    private var dominantMoodSummary: (title: String, percentage: Int)? {
        let visibleMoods = sample.moods.map { mood in
            let scaledCount = max(Int((Double(mood.count) * Double(selectedRange) / 90.0).rounded()), 1)
            return PresenciaMockMood(id: mood.id, title: mood.title, count: scaledCount)
        }
        guard let dominant = visibleMoods.max(by: { $0.count < $1.count }) else { return nil }
        let total = visibleMoods.reduce(0) { $0 + $1.count }
        let percentage = total > 0 ? Int((Double(dominant.count) / Double(total) * 100).rounded()) : 0
        return (dominant.title, percentage)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if isCardVisible(.todayReturns) {
                    PresenciaMockMetricCard(
                        icon: "sun.max",
                        title: "Hoy",
                        subtitle: "Retornos",
                        value: "\(sample.todayCount)",
                        footer: "Sigue así",
                        accent: .purple,
                        infoMessage: "Cuenta los momentos de presencia consciente registrados desde el inicio del día actual."
                    )
                        .transition(.presenciaMockCardVisibility)
                }
                if isCardVisible(.currentStreak) {
                    PresenciaMockMetricCard(
                        icon: "flame.fill",
                        title: "Racha",
                        subtitle: "actual",
                        value: "\(sample.streakDays)",
                        footer: "días seguidos",
                        accent: .orange,
                        infoMessage: "Cuenta los días consecutivos en los que alcanzaste el mínimo de retornos conscientes definido para sostener la racha."
                    )
                        .transition(.presenciaMockCardVisibility)
                }
            }

            HStack(spacing: 12) {
                if isCardVisible(.weeklyAverage) {
                    PresenciaMockMetricCard(
                        icon: "arrow.up.right",
                        title: "Esta semana",
                        subtitle: "Promedio diario",
                        value: "\(sample.weeklyAverage)",
                        footer: "retornos",
                        accent: .green,
                        infoMessage: "Promedia los retornos conscientes registrados durante la semana actual, de lunes a domingo."
                    )
                        .transition(.presenciaMockCardVisibility)
                }
                if isCardVisible(.dominantMood) {
                    PresenciaMockMetricCard(
                        icon: "heart",
                        title: "Estado de ánimo",
                        subtitle: "predominante",
                        value: dominantMoodSummary?.title ?? sample.dominantMood,
                        footer: "\(dominantMoodSummary?.percentage ?? 0)% de tus registros",
                        accent: .blue,
                        infoMessage: "Muestra el estado de ánimo más frecuente dentro del rango elegido en esta tarjeta y su porcentaje sobre el total de estados registrados.",
                        selectedRange: $selectedRange
                    )
                        .transition(.presenciaMockCardVisibility)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: visibleCards)
    }

    private func isCardVisible(_ card: PresenciaMockCard) -> Bool {
        visibleCards.contains(card.rawValue)
    }
}

private struct PresenciaMockMetricCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let footer: String
    let accent: Color
    let infoMessage: String
    var selectedRange: Binding<Int>? = nil

    private var headerTitle: String {
        switch (title, subtitle) {
        case ("Hoy", "Retornos"):
            return "Hoy: retornos"
        case ("Esta semana", "Promedio diario"):
            return "Esta semana: promedio diario"
        default:
            return "\(title) \(subtitle)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PresenciaMockMetricCardHeader(icon: icon, title: headerTitle, accent: accent) {
                PresenciaMockInfoButton(title: title, message: infoMessage)
                if let selectedRange {
                    PresenciaMockRangeMenu(selectedRange: selectedRange)
                }
            }

            Spacer(minLength: 0)
            PresenciaMockMetricValue(value: value, accent: accent)
            Text(footer)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PresenciaMockPalette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 184, alignment: .topLeading)
        .padding(18)
        .background(PresenciaMockGlassBackground(accent: accent))
    }
}

private struct PresenciaMockMetricCardHeader<Trailing: View>: View {
    let icon: String
    let title: String
    let accent: Color
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                ZStack {
                    Circle().fill(accent.opacity(0.18))
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(accent)
                }
                .frame(width: 44, height: 44)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    trailing
                }
                .fixedSize()
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PresenciaMockPalette.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PresenciaMockInfoButton: View {
    let title: String
    let message: String
    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.headline)
                .foregroundStyle(PresenciaMockPalette.secondaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Información sobre \(title)")
        .alert(title, isPresented: $showInfo) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}

private struct PresenciaMockMetricHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.18))
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(PresenciaMockPalette.primaryText)
        }
    }
}

private struct PresenciaMockMetricValue: View {
    let value: String
    let accent: Color

    var body: some View {
        Text(value)
            .font(.system(size: value.count > 4 ? 24 : 54, weight: .medium, design: .rounded))
            .foregroundStyle(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(maxWidth: .infinity)
    }
}

private struct PresenciaMockGlassBackground: View {
    let accent: Color

    var body: some View {
        PresenciaMockCardBackground(accent: accent, cornerRadius: 20)
    }
}

private struct PresenciaMockPracticalInsightsCard: View {
    let days: [PresenciaMockDay]
    let events: [PresenciaMockEvent]
    @Binding var selectedRange: Int

    private var mostPresentDayText: String {
        guard let day = days.max(by: { $0.presentes < $1.presentes }), day.presentes > 0 else {
            return "Aún no hay un día destacado."
        }

        return "Tu día más consciente fue el \(weekdayName(for: day))."
    }

    private var averageText: String {
        guard !days.isEmpty else { return "0 por día" }
        let total = days.reduce(0) { $0 + $1.presentes }
        let average = Double(total) / Double(days.count)
        return "\(formatAverage(average)) por día"
    }

    private var weeklyTrendText: String {
        let currentWeek = days.suffix(7).reduce(0) { $0 + $1.presentes }
        let previousWeek = days.dropLast(7).suffix(7).reduce(0) { $0 + $1.presentes }

        guard currentWeek > 0 || previousWeek > 0 else {
            return "Sin tendencia suficiente."
        }

        guard previousWeek > 0 else {
            return "Nueva actividad esta semana."
        }

        let percentage = Int(((Double(currentWeek - previousWeek) / Double(previousWeek)) * 100).rounded())
        if percentage == 0 {
            return "Igual que la semana pasada."
        }

        let direction = percentage > 0 ? "más" : "menos"
        return "\(percentage > 0 ? "+" : "")\(percentage)% \(direction) momentos presentes que la semana pasada."
    }

    private var criticalWindowText: String {
        let automaticEvents = events.filter { !$0.present }
        guard !automaticEvents.isEmpty else {
            return "No se detecta una franja crítica."
        }

        let windowCounts = stride(from: 0, through: 21, by: 3).map { startHour in
            let count = automaticEvents.filter { event in
                let hour = event.minuteOfDay / 60
                return hour >= startHour && hour < startHour + 3
            }.count
            return (startHour: startHour, count: count)
        }

        guard let busiestWindow = windowCounts.max(by: { $0.count < $1.count }), busiestWindow.count > 0 else {
            return "No se detecta una franja crítica."
        }

        return "Entre \(hourText(busiestWindow.startHour)) y \(hourText(busiestWindow.startHour + 3)) se concentra más piloto automático."
    }

    private var contextualSuggestionText: String {
        PresenciaMockDailyEventsSuggestion.message(days: days, events: events)
    }

    var body: some View {
        PresenciaMockSectionCard(title: "Datos prácticos", trailingContent: {
            PresenciaMockInfoButton(title: "Datos prácticos", message: infoMessage)
        }) {
            PresenciaMockRangePicker(title: "Rango de datos prácticos", selectedRange: $selectedRange)
            VStack(spacing: 10) {
                insightRow(icon: "calendar.badge.clock", title: "Día con más presencia", value: mostPresentDayText, accent: .mint)
                insightRow(icon: "number", title: "Promedio por día", value: averageText, accent: .cyan)
                insightRow(icon: "chart.line.uptrend.xyaxis", title: "Tendencia semanal", value: weeklyTrendText, accent: .green)
                insightRow(icon: "exclamationmark.triangle.fill", title: "Franja crítica", value: criticalWindowText, accent: .orange)
                PresenciaMockContextualSuggestionRow(message: contextualSuggestionText)
            }
        }
    }

    private var infoMessage: String {
        """
        Se calculan con los últimos \(selectedRange) días seleccionados en esta tarjeta.

        Día con más presencia: día con mayor número de retornos conscientes.
        Promedio por día: total de retornos conscientes dividido entre los días del rango.
        Tendencia semanal: últimos 7 días comparados con los 7 días anteriores.
        Franja crítica: bloque de 3 horas con más registros de Piloto automático o Distraído.
        Sugerencia contextual: recomendación breve derivada de concentración horaria, equilibrio entre presencia/piloto automático y tendencia reciente.
        """
    }

    private func insightRow(icon: String, title: String, value: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 24, height: 24)
                .background(Circle().fill(accent.opacity(0.16)))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PresenciaMockPalette.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PresenciaMockPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(PresenciaMockPalette.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func weekdayName(for day: PresenciaMockDay) -> String {
        let weekdays = ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"]
        return weekdays[day.id % weekdays.count]
    }

    private func formatAverage(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    private func hourText(_ hour: Int) -> String {
        String(format: "%02d:00", min(hour, 24))
    }
}

private struct PresenciaMockBarsCard: View {
    let days: [PresenciaMockDay]
    @Binding var selectedRange: Int

    private var chartWidth: CGFloat {
        max(CGFloat(days.count) * 23, 320)
    }

    var body: some View {
        PresenciaMockSectionCard(title: "Eventos diarios", trailingContent: {
            PresenciaMockInfoButton(
                title: "Eventos diarios",
                message: "Muestra, para cada día del rango seleccionado, cuántos registros fueron Presente y cuántos fueron Piloto automático o Distraído."
            )
        }) {
            PresenciaMockRangePicker(title: "Rango de eventos diarios", selectedRange: $selectedRange)
            ScrollView(.horizontal, showsIndicators: false) {
                PresenciaMockBarsCanvas(days: days)
                    .frame(width: chartWidth, height: 180)
            }
            .frame(height: 180)
            PresenciaMockLegend(left: "Presente", leftColor: .mint, right: "Piloto automático", rightColor: .orange)
        }
    }
}

private struct PresenciaMockContextualSuggestionRow: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.mint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text("Sugerencia contextual")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PresenciaMockPalette.secondaryText)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PresenciaMockPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(PresenciaMockPalette.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private enum PresenciaMockDailyEventsSuggestion {
    static func message(days: [PresenciaMockDay], events: [PresenciaMockEvent]) -> String {
        let presentCount = days.reduce(0) { $0 + $1.presentes }
        let automaticCount = days.reduce(0) { $0 + $1.inconscientes }
        let totalCount = presentCount + automaticCount
        let activeDays = days.filter { $0.total > 0 }.count

        guard totalCount > 0 else {
            return "Aún no hay suficientes registros en este rango. Haz uno o dos retornos conscientes hoy para que aparezca un patrón útil."
        }

        if activeDays <= max(2, days.count / 6) {
            return "Hay pocos días con registros. Prueba una pausa breve a media mañana y otra al final de la tarde para empezar a revelar tu patrón."
        }

        if presentCount == 0 {
            return "Por ahora solo aparecen momentos de piloto automático. Elige una hora fácil, como antes de comer, para registrar un retorno consciente deliberado."
        }

        if automaticCount > presentCount {
            if let window = strongestWindow(events: events.filter { !$0.present }) {
                return "El piloto automático se concentra entre \(hourText(window.start)) y \(hourText(window.end)). Prueba una pausa de 30 segundos justo antes de esa franja."
            }
            return "En este rango hay más piloto automático que presencia. Elige una transición diaria, como antes de abrir una app o comenzar una tarea, para volver al cuerpo."
        }

        if let dominantPeriod = dominantPresencePeriod(events: events), dominantPeriod.count >= 2 {
            switch dominantPeriod.period {
            case .morning:
                return "Tus registros conscientes aparecen más por la mañana. Podrías reforzar ese impulso con una pausa breve antes del mediodía."
            case .afternoon:
                return "Tus registros conscientes se concentran durante la tarde. Prueba un retorno intencional por la mañana para equilibrar el día."
            case .evening:
                return "Tus registros conscientes aparecen más después de las 18:00. Podrías hacer una pausa breve antes del mediodía."
            case .night:
                return "Tus registros conscientes aparecen más tarde en el día. Prueba una señal suave al despertar para llevar presencia al inicio de la jornada."
            }
        }

        if isRecentPresenceImproving(days: days) {
            return "Tus últimos días muestran más presencia que los anteriores. Mantén el gesto que ya funciona y añade una pausa corta en la franja donde sueles olvidarte."
        }

        if automaticCount == 0 {
            return "Este rango muestra presencia sin piloto automático registrado. Añade también los momentos de distracción cuando ocurran para obtener sugerencias más precisas."
        }

        return "Tus registros están bastante equilibrados. Elige una franja concreta del día y repite ahí una pausa consciente para convertirla en hábito."
    }

    private enum Period {
        case night
        case morning
        case afternoon
        case evening
    }

    private static func dominantPresencePeriod(events: [PresenciaMockEvent]) -> (period: Period, count: Int)? {
        let presentEvents = events.filter(\.present)
        guard !presentEvents.isEmpty else { return nil }
        let grouped = Dictionary(grouping: presentEvents) { event in
            period(for: event.minuteOfDay / 60)
        }
        return grouped
            .map { (period: $0.key, count: $0.value.count) }
            .max { $0.count < $1.count }
    }

    private static func strongestWindow(events: [PresenciaMockEvent]) -> (start: Int, end: Int)? {
        guard events.count >= 2 else { return nil }
        let hours = events.map { $0.minuteOfDay / 60 }
        let windows = stride(from: 0, through: 21, by: 3).map { start in
            let end = start + 3
            let count = hours.filter { $0 >= start && $0 < end }.count
            return (start: start, end: end, count: count)
        }
        guard let best = windows.max(by: { $0.count < $1.count }), best.count >= 2 else { return nil }
        return (best.start, best.end)
    }

    private static func isRecentPresenceImproving(days: [PresenciaMockDay]) -> Bool {
        guard days.count >= 8 else { return false }
        let recent = days.suffix(7)
        let previous = days.dropLast(7).suffix(7)
        let recentAverage = Double(recent.reduce(0) { $0 + $1.presentes }) / Double(recent.count)
        let previousAverage = Double(previous.reduce(0) { $0 + $1.presentes }) / Double(max(previous.count, 1))
        return previousAverage > 0 && recentAverage >= previousAverage * 1.2
    }

    private static func period(for hour: Int) -> Period {
        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<24: return .evening
        default: return .night
        }
    }

    private static func hourText(_ hour: Int) -> String {
        String(format: "%02d:00", min(hour, 24))
    }
}

private struct PresenciaMockRangePicker: View {
    let title: String
    @Binding var selectedRange: Int

    var body: some View {
        Picker(title, selection: $selectedRange) {
            Text("14 días").tag(14)
            Text("30 días").tag(30)
            Text("90 días").tag(90)
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
    }
}

private struct PresenciaMockRangeMenu: View {
    @Binding var selectedRange: Int

    var body: some View {
        Menu {
            ForEach([14, 30, 90], id: \.self) { range in
                Button {
                    selectedRange = range
                } label: {
                    Label("\(range) días", systemImage: selectedRange == range ? "checkmark" : "calendar")
                }
            }
        } label: {
            Label("\(selectedRange)d", systemImage: "calendar.badge.clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PresenciaMockPalette.secondaryText)
        }
        .accessibilityLabel("Rango de estado predominante")
    }
}

private struct PresenciaMockTimelineCard: View {
    let events: [PresenciaMockEvent]
    private let horizontalHourSpacing = PresenciaMockTimelineLayout.horizontalHourSpacing

    private var chartWidth: CGFloat {
        horizontalHourSpacing * 24
    }

    var body: some View {
        PresenciaMockSectionCard(title: "Momentos de presencia de hoy", trailingContent: {
            HStack(spacing: 8) {
                PresenciaMockInfoButton(
                    title: "Momentos de hoy",
                    message: "Muestra solo los eventos del día actual distribuidos por hora. Verde indica Presente; naranja indica Piloto automático o Distraído."
                )
                Text("\(events.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PresenciaMockPalette.secondaryText)
            }
        }) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 8) {
                        PresenciaMockTimelineCanvas(events: events)
                            .frame(width: chartWidth, height: 136)
                        PresenciaMockHourLabels(horizontalHourSpacing: horizontalHourSpacing)
                            .frame(width: chartWidth)
                    }
                }
                .frame(height: 160)
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(5, anchor: .leading)
                    }
                }
            }
            PresenciaMockLegend(left: "Presente", leftColor: .mint, right: "Piloto automático", rightColor: .orange)
        }
    }
}

private struct PresenciaMockRatioCard: View {
    let days: [PresenciaMockDay]
    @Binding var selectedRange: Int

    private var chartWidth: CGFloat {
        max(CGFloat(days.count) * 24, 320)
    }

    var body: some View {
        PresenciaMockSectionCard(title: "Cociente presente/inconsciente", trailingContent: {
            PresenciaMockInfoButton(
                title: "Cociente presente/inconsciente",
                message: "Cada punto representa el porcentaje de eventos conscientes frente al total de eventos conscientes e inconscientes de ese día, dentro del rango elegido en esta tarjeta."
            )
        }) {
            PresenciaMockRangePicker(title: "Rango del cociente", selectedRange: $selectedRange)
            ScrollView(.horizontal, showsIndicators: false) {
                PresenciaMockRatioCanvas(days: days)
                    .frame(width: chartWidth, height: 120)
            }
            .frame(height: 120)
            Text("Más alto significa que, entre los eventos registrados, hubo más retornos conscientes.")
                .font(.caption)
                .foregroundStyle(PresenciaMockPalette.secondaryText)
        }
    }
}

private struct PresenciaMockMoodCard: View {
    let moods: [PresenciaMockMood]
    @Binding var selectedRange: Int

    var body: some View {
        PresenciaMockSectionCard(title: "Estados de ánimo", trailingContent: {
            PresenciaMockInfoButton(
                title: "Estados de ánimo",
                message: "Muestra los estados de ánimo más registrados dentro del rango elegido en esta tarjeta. El número indica cuántas veces aparece cada estado."
            )
        }) {
            PresenciaMockRangePicker(title: "Rango de estados de ánimo", selectedRange: $selectedRange)
            ForEach(moods) { mood in
                PresenciaMockMoodRow(mood: mood)
            }
        }
    }
}

private struct PresenciaMockMoodRow: View {
    let mood: PresenciaMockMood

    var body: some View {
        HStack {
            Text(mood.title)
            Spacer()
            Text("\(mood.count)")
                .font(.headline)
        }
        .foregroundStyle(PresenciaMockPalette.primaryText)
        .padding(12)
        .background(PresenciaMockPalette.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PresenciaMockSectionCard<Content: View, TrailingContent: View>: View {
    let title: String
    let trailing: String?
    @ViewBuilder let trailingContent: TrailingContent
    @ViewBuilder let content: Content

    init(title: String, trailing: String? = nil, @ViewBuilder content: () -> Content) where TrailingContent == EmptyView {
        self.title = title
        self.trailing = trailing
        self.trailingContent = EmptyView()
        self.content = content()
    }

    init(title: String, @ViewBuilder trailingContent: () -> TrailingContent, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = nil
        self.trailingContent = trailingContent()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PresenciaMockPalette.primaryText)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PresenciaMockPalette.secondaryText)
                } else {
                    trailingContent
                }
            }
            content
        }
        .padding(14)
        .background(PresenciaMockCardBackground(accent: .cyan, cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PresenciaMockLegend: View {
    let left: String
    let leftColor: Color
    let right: String
    let rightColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Label(left, systemImage: "circle.fill")
                .foregroundStyle(leftColor)
            Label(right, systemImage: "circle.fill")
                .foregroundStyle(rightColor)
        }
        .font(.caption)
    }
}

private struct PresenciaMockBarsCanvas: View {
    let days: [PresenciaMockDay]

    var body: some View {
        Canvas { context, size in
            let maxValue = max(days.map { max($0.presentes, $0.inconscientes) }.max() ?? 1, 1)
            let columnWidth = size.width / CGFloat(max(days.count, 1))
            let baseY = size.height - 22

            for index in days.indices {
                let day = days[index]
                let x = CGFloat(index) * columnWidth + columnWidth * 0.5
                drawBar(value: day.presentes, maxValue: maxValue, x: x - 4, baseY: baseY, color: .mint, context: &context)
                drawBar(value: day.inconscientes, maxValue: maxValue, x: x + 4, baseY: baseY, color: .orange, context: &context)
            }
        }
        .overlay(alignment: .bottom) {
            PresenciaMockDayLabels(days: days)
        }
    }

    private func drawBar(value: Int, maxValue: Int, x: CGFloat, baseY: CGFloat, color: Color, context: inout GraphicsContext) {
        let height = max(CGFloat(value) / CGFloat(maxValue) * 70, value == 0 ? 3 : 8)
        let rect = CGRect(x: x - 3.5, y: baseY - height, width: 7, height: height)
        let path = Path(roundedRect: rect, cornerRadius: 3)
        context.fill(path, with: .color(color.opacity(value == 0 ? 0.2 : 0.9)))
    }
}

private struct PresenciaMockTimelineCanvas: View {
    let events: [PresenciaMockEvent]

    var body: some View {
        Canvas { context, size in
            let plotWidth = size.width
            let plotHeight: CGFloat = 76
            let topPadding: CGFloat = 18
            let centerY = topPadding + plotHeight / 2

            drawTimelineGrid(context: &context, plotWidth: plotWidth, plotHeight: plotHeight, topPadding: topPadding, centerY: centerY)
            drawTimelineDots(context: &context, plotWidth: plotWidth, centerY: centerY)
        }
    }

    private func drawTimelineGrid(context: inout GraphicsContext, plotWidth: CGFloat, plotHeight: CGFloat, topPadding: CGFloat, centerY: CGFloat) {
        for hour in 0...24 {
            let x = CGFloat(hour) / 24.0 * plotWidth
            var path = Path()
            path.move(to: CGPoint(x: x, y: topPadding))
            path.addLine(to: CGPoint(x: x, y: topPadding + plotHeight))
            let opacity = hour == 0 || hour == 24 || hour == 12 ? 0.22 : 0.1
            context.stroke(path, with: .color(PresenciaMockPalette.gridLine.opacity(opacity)), lineWidth: 1)
        }

        var path = Path()
        path.move(to: CGPoint(x: 0, y: centerY))
        path.addLine(to: CGPoint(x: plotWidth, y: centerY))
        context.stroke(path, with: .color(PresenciaMockPalette.gridLine.opacity(0.16)), lineWidth: 1)
    }

    private func drawTimelineDots(context: inout GraphicsContext, plotWidth: CGFloat, centerY: CGFloat) {
        for event in events {
            let x = CGFloat(event.minuteOfDay) / 1_440.0 * plotWidth
            let y = centerY + CGFloat((event.collision % 5) - 2) * 7
            let size: CGFloat = event.present ? 9 : 7
            let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
            let color: Color = event.present ? .mint : .orange
            context.fill(Path(ellipseIn: rect), with: .color(color))
            context.stroke(Path(ellipseIn: rect), with: .color(PresenciaMockPalette.pointStroke), lineWidth: 0.8)
        }
    }
}

private struct PresenciaMockRatioCanvas: View {
    let days: [PresenciaMockDay]

    var body: some View {
        Canvas { context, size in
            let columnWidth = size.width / CGFloat(max(days.count, 1))
            let plotHeight = size.height - 20

            for index in days.indices {
                let day = days[index]
                let x = CGFloat(index) * columnWidth + columnWidth * 0.5
                let y = CGFloat(1.0 - day.ratio) * 80 + 8
                let rect = CGRect(x: x - 4.5, y: min(y, plotHeight), width: 9, height: 9)
                context.fill(Path(ellipseIn: rect), with: .color(.cyan))
            }
        }
        .overlay(alignment: .bottom) {
            PresenciaMockDayLabels(days: days)
        }
    }
}

private struct PresenciaMockDayLabels: View {
    let days: [PresenciaMockDay]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                Text(day.dayLabel)
                    .font(.caption2)
                    .foregroundStyle(PresenciaMockPalette.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 18)
    }
}

private struct PresenciaMockTimelineDayLabels: View {
    let days: [PresenciaMockDay]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(days) { day in
                Text(day.shortLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(PresenciaMockPalette.secondaryText)
                    .frame(width: 28)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(.bottom, 32)
    }
}

private struct PresenciaMockHourLabels: View {
    let horizontalHourSpacing: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text(String(format: "%02d", hour))
                    .frame(width: horizontalHourSpacing, alignment: .center)
                    .id(hour)
            }
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(PresenciaMockPalette.secondaryText)
        .frame(maxWidth: .infinity)
    }
}

private struct PresenciaMockSample {
    let days: [PresenciaMockDay]
    let events: [PresenciaMockEvent]
    let moods: [PresenciaMockMood]
    let todayCount: Int
    let streakDays: Int
    let weeklyAverage: Int
    let dominantMood: String

    static let `default` = PresenciaMockSample(
        days: PresenciaMockFixtures.days,
        events: PresenciaMockFixtures.events,
        moods: PresenciaMockFixtures.moods,
        todayCount: 10,
        streakDays: 6,
        weeklyAverage: 10,
        dominantMood: "Futuro ahora"
    )
}

private struct PresenciaMockDay: Identifiable {
    let id: Int
    let dayLabel: String
    let shortLabel: String
    let presentes: Int
    let inconscientes: Int

    var total: Int { presentes + inconscientes }
    var ratio: Double { total == 0 ? 0 : Double(presentes) / Double(total) }
}

private struct PresenciaMockEvent: Identifiable {
    let id: Int
    let dayIndex: Int
    let minuteOfDay: Int
    let present: Bool
    let collision: Int
}

private struct PresenciaMockMood: Identifiable {
    let id: Int
    let title: String
    let count: Int
}

private enum PresenciaMockFixtures {
    static let days: [PresenciaMockDay] = makeDays()

    private static func makeDays() -> [PresenciaMockDay] {
        let months = ["Mar", "Abr", "May", "Jun"]

        return (0..<90).map { index in
            let dayNumber = ((index + 21) % 30) + 1
            let month = months[min(index / 23, months.count - 1)]
            let presentesPattern = [4, 6, 3, 9, 5, 8, 11, 7, 10, 6, 12, 9, 14, 10]
            let automaticPattern = [1, 2, 3, 1, 2, 2, 1, 3, 2, 2, 1, 2, 1, 2]
            let presentBoost = index > 74 ? 2 : index > 45 ? 1 : 0
            let presentes = presentesPattern[index % presentesPattern.count] + presentBoost
            let inconscientes = automaticPattern[index % automaticPattern.count]

            return PresenciaMockDay(
                id: index,
                dayLabel: "\(dayNumber)",
                shortLabel: "\(dayNumber) \(month)",
                presentes: presentes,
                inconscientes: inconscientes
            )
        }
    }

    static let events: [PresenciaMockEvent] = [
        PresenciaMockEvent(id: 0, dayIndex: 0, minuteOfDay: 425, present: true, collision: 0),
        PresenciaMockEvent(id: 1, dayIndex: 0, minuteOfDay: 482, present: false, collision: 1),
        PresenciaMockEvent(id: 2, dayIndex: 0, minuteOfDay: 535, present: true, collision: 2),
        PresenciaMockEvent(id: 3, dayIndex: 0, minuteOfDay: 612, present: true, collision: 0),
        PresenciaMockEvent(id: 4, dayIndex: 0, minuteOfDay: 725, present: true, collision: 1),
        PresenciaMockEvent(id: 5, dayIndex: 0, minuteOfDay: 760, present: true, collision: 2),
        PresenciaMockEvent(id: 6, dayIndex: 0, minuteOfDay: 917, present: false, collision: 0),
        PresenciaMockEvent(id: 7, dayIndex: 0, minuteOfDay: 1_045, present: true, collision: 1),
        PresenciaMockEvent(id: 8, dayIndex: 0, minuteOfDay: 1_090, present: true, collision: 2),
        PresenciaMockEvent(id: 9, dayIndex: 0, minuteOfDay: 1_187, present: true, collision: 0),
        PresenciaMockEvent(id: 10, dayIndex: 0, minuteOfDay: 1_275, present: true, collision: 1),
        PresenciaMockEvent(id: 11, dayIndex: 0, minuteOfDay: 1_330, present: false, collision: 2)
    ]

    static let moods: [PresenciaMockMood] = [
        PresenciaMockMood(id: 0, title: "Siento mi futuro ahora", count: 18),
        PresenciaMockMood(id: 1, title: "Sereno", count: 12),
        PresenciaMockMood(id: 2, title: "Agradecido", count: 9),
        PresenciaMockMood(id: 3, title: "Alegre", count: 7),
        PresenciaMockMood(id: 4, title: "Piloto automático", count: 5)
    ]
}

#Preview {
    PresenciaStatsMockView()
}
#endif
#endif
