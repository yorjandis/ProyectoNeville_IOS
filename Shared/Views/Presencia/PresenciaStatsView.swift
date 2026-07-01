#if os(iOS)
import SwiftUI
import UIKit

private enum PresenciaDailyTimelineLayout {
    static let horizontalHourSpacing: CGFloat = 40
}

private enum PresenciaStatsAppearance: String, CaseIterable {
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

private enum PresenciaStatsAppearanceStorage {
    static let key = "presenciaStatsAppearance"
    static let defaultValue = PresenciaStatsAppearance.dark.rawValue
}

private enum PresenciaStatsVisibleCardsStorage {
    static let key = "presenciaStatsVisibleCards"
    static let schemaVersionKey = "presenciaStatsVisibleCardsSchemaVersion"
    static let currentSchemaVersion = 1
    static var defaultValue: String {
        PresenciaStatsCard.allCases.map(\.rawValue).joined(separator: ",")
    }
}

private extension AnyTransition {
    static var presenciaCardVisibility: AnyTransition {
        .opacity
    }
}

private enum PresenciaStatsCard: String, CaseIterable {
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

private struct PresenciaStatsTheme {
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

private enum PresenciaStatsPalette {
    static func theme(for rawValue: String? = nil) -> PresenciaStatsTheme {
        let rawAppearance = rawValue ?? UserDefaults.standard.string(forKey: PresenciaStatsAppearanceStorage.key)
        let appearance = PresenciaStatsAppearance(rawValue: rawAppearance ?? PresenciaStatsAppearanceStorage.defaultValue) ?? .dark

        switch appearance {
        case .dark:
            return PresenciaStatsTheme(
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
            return PresenciaStatsTheme(
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

private struct PresenciaStatsCardBackground: View {
    let accent: Color
    let cornerRadius: CGFloat
    @AppStorage(PresenciaStatsAppearanceStorage.key) private var appearanceRawValue = PresenciaStatsAppearanceStorage.defaultValue

    var body: some View {
        let theme = PresenciaStatsPalette.theme(for: appearanceRawValue)

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

struct PresenciaStatsView: View {
    private let embeddedInNavigation: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var dayStats: [PresenciaDayStats] = []
    @State private var moodStats: [PresenciaMoodStats] = []
    @State private var dominantMoodStats: [PresenciaMoodStats] = []
    @State private var eventPoints: [PresenciaEventPoint] = []
    @State private var rangeEventPoints: [PresenciaEventPoint] = []
    @State private var practicalStats: [PresenciaDayStats] = []
    @State private var ratioStats: [PresenciaDayStats] = []
    @State private var todayPresentCount = 0
    @State private var dailyEventsRange = 14
    @State private var practicalInsightsRange = 14
    @State private var ratioRange = 14
    @State private var moodRange = 14
    @State private var dominantMoodRange = 14
    @State private var futureFeelingCount = 0
    @State private var streakStats = PresenciaStreakStats(currentDays: 0, bestDays: 0)
    @State private var showResetConfirmation = false

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage(PresenciaStatsAppearanceStorage.key) private var appearanceRawValue = PresenciaStatsAppearanceStorage.defaultValue
    @AppStorage(PresenciaStatsVisibleCardsStorage.key) private var visibleCardsRawValue = PresenciaStatsVisibleCardsStorage.defaultValue

    private let repository = PresenciaRepository()

    init(embeddedInNavigation: Bool = false) {
        self.embeddedInNavigation = embeddedInNavigation
    }

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    private var selectedAppearance: PresenciaStatsAppearance {
        PresenciaStatsAppearance(rawValue: appearanceRawValue) ?? .dark
    }

    private var theme: PresenciaStatsTheme {
        PresenciaStatsPalette.theme(for: appearanceRawValue)
    }

    private var visibleCards: Set<String> {
        Set(visibleCardsRawValue.split(separator: ",").map(String.init))
    }

    private var hasVisibleInsightCards: Bool {
        isCardVisible(.todayReturns)
            || isCardVisible(.currentStreak)
            || isCardVisible(.weeklyAverage)
            || isCardVisible(.dominantMood)
    }

    var body: some View {
        Group {
            if embeddedInNavigation {
                content
            } else {
                NavigationStack {
                    content
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
            if hasPremiumAccess {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        insightCards
                        if isCardVisible(.practicalInsights) {
                            PresenciaPracticalInsightsCard(
                                stats: practicalStats,
                                events: rangeEventPoints,
                                selectedRange: $practicalInsightsRange
                            )
                                .transition(.presenciaCardVisibility)
                        }
                        if isCardVisible(.dailyEvents) {
                            PresenciaBarsView(stats: dayStats, selectedRange: $dailyEventsRange)
                                .transition(.presenciaCardVisibility)
                        }
                        if isCardVisible(.dailyTimeline) {
                            PresenciaDailyDotTimelineView(events: eventPoints)
                                .transition(.presenciaCardVisibility)
                        }
                        if isCardVisible(.ratio) {
                            PresenciaRatioDotsView(stats: ratioStats, selectedRange: $ratioRange)
                                .transition(.presenciaCardVisibility)
                        }
                        if isCardVisible(.moods) {
                            moodSection
                                .transition(.presenciaCardVisibility)
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.22), value: visibleCardsRawValue)
                }
                .id(appearanceRawValue)
                .background(
                    LinearGradient(colors: [theme.screenTop, theme.screenBottom], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
                .navigationTitle("Presencia")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        visibilityMenu
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(PresenciaStatsAppearance.allCases, id: \.rawValue) { appearance in
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
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Resetear estadísticas")
                    }
                }
                .confirmationDialog(
                    "Resetear estadísticas de Presencia",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Borrar historial completo", role: .destructive) {
                        resetPresenceStats()
                    }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Esta acción borrará todo el historial de Presencia. No se puede deshacer.")
                }
                .onAppear {
                    ensureVisibleCardsStorage()
                    reload()
                }
                .onChange(of: dailyEventsRange) { _, _ in reloadDailyEvents() }
                .onChange(of: practicalInsightsRange) { _, _ in reloadPracticalInsights() }
                .onChange(of: ratioRange) { _, _ in reloadRatioStats() }
                .onChange(of: moodRange) { _, _ in reloadMoodStats() }
                .onChange(of: dominantMoodRange) { _, _ in reloadDominantMoodStats() }
                .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
                    reload()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    reload()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        reload()
                    }
                }
            } else {
                PurchaseView()
            }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presencia")
                .font(.largeTitle.bold())
                .foregroundStyle(PresenciaStatsPalette.primaryText)
            Text("Hoy has vuelto al presente \(todayPresentCount) veces.")
                .font(.headline)
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
        }
    }

    private var insightCards: some View {
        Group {
            if hasVisibleInsightCards {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 12)], spacing: 12) {
                    if isCardVisible(.todayReturns) {
                        TodayReturnsCard(count: todayPresentCount)
                            .transition(.presenciaCardVisibility)
                    }
                    if isCardVisible(.currentStreak) {
                        CurrentStreakCard(days: streakStats.currentDays)
                            .transition(.presenciaCardVisibility)
                    }
                    if isCardVisible(.weeklyAverage) {
                        WeeklyAverageCard(weekStats: currentWeekStats)
                            .transition(.presenciaCardVisibility)
                    }
                    if isCardVisible(.dominantMood) {
                        DominantMoodCard(summary: dominantMoodSummary, selectedRange: $dominantMoodRange)
                            .transition(.presenciaCardVisibility)
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: visibleCardsRawValue)
                .transition(.presenciaCardVisibility)
            }
        }
    }

    private var visibilityMenu: some View {
        Menu {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    visibleCardsRawValue = PresenciaStatsVisibleCardsStorage.defaultValue
                }
            } label: {
                Label("Mostrar todas", systemImage: "eye")
            }

            Divider()

            ForEach(PresenciaStatsCard.allCases, id: \.rawValue) { card in
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

    private func isCardVisible(_ card: PresenciaStatsCard) -> Bool {
        visibleCards.contains(card.rawValue)
    }

    private func toggleCardVisibility(_ card: PresenciaStatsCard) {
        var updatedCards = visibleCards
        if updatedCards.contains(card.rawValue) {
            updatedCards.remove(card.rawValue)
        } else {
            updatedCards.insert(card.rawValue)
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            visibleCardsRawValue = PresenciaStatsCard.allCases
                .map(\.rawValue)
                .filter { updatedCards.contains($0) }
                .joined(separator: ",")
        }
    }

    private func ensureVisibleCardsStorage() {
        let defaults = UserDefaults.standard
        let schemaVersion = defaults.integer(forKey: PresenciaStatsVisibleCardsStorage.schemaVersionKey)
        guard schemaVersion < PresenciaStatsVisibleCardsStorage.currentSchemaVersion else { return }

        var updatedCards = visibleCards
        updatedCards.insert(PresenciaStatsCard.practicalInsights.rawValue)
        visibleCardsRawValue = PresenciaStatsCard.allCases
            .map(\.rawValue)
            .filter { updatedCards.contains($0) }
            .joined(separator: ",")
        defaults.set(PresenciaStatsVisibleCardsStorage.currentSchemaVersion, forKey: PresenciaStatsVisibleCardsStorage.schemaVersionKey)
    }

    private var ratioText: String {
        let presentes = dayStats.reduce(0) { $0 + $1.presentes }
        let inconscientes = dayStats.reduce(0) { $0 + $1.inconscientes }
        let total = presentes + inconscientes
        guard total > 0 else { return "0%" }
        return "\(Int((Double(presentes) / Double(total) * 100).rounded()))%"
    }

    private var currentWeekStats: [PresenciaDayStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            return dayStats.first { calendar.isDate($0.date, inSameDayAs: date) }
                ?? PresenciaDayStats(date: date, presentes: 0, inconscientes: 0, estadosAnimo: 0, futuroAhora: 0)
        }
    }

    private var dominantMoodSummary: DominantMoodSummary? {
        guard let dominant = dominantMoodStats.first else { return nil }
        let total = dominantMoodStats.reduce(0) { $0 + $1.count }
        let percentage = total > 0 ? Int((Double(dominant.count) / Double(total) * 100).rounded()) : 0
        return DominantMoodSummary(title: dominant.title, percentage: percentage)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Estados de ánimo")
                    .font(.headline)
                    .foregroundStyle(PresenciaStatsPalette.primaryText)
                Spacer()
                PresenciaInfoButton(
                    title: "Estados de ánimo",
                    message: "Muestra los estados de ánimo más registrados dentro del rango elegido en esta tarjeta. El número indica cuántas veces aparece cada estado."
                )
            }

            PresenciaRangePicker(title: "Rango de estados de ánimo", selectedRange: $moodRange)

            if moodStats.isEmpty {
                Text("Aún no hay estados registrados.")
                    .font(.subheadline)
                    .foregroundStyle(PresenciaStatsPalette.secondaryText)
            } else {
                ForEach(moodStats.prefix(8)) { item in
                    HStack {
                        Text(item.title)
                        Spacer()
                        Text("\(item.count)")
                            .font(.headline)
                    }
                    .foregroundStyle(PresenciaStatsPalette.primaryText)
                    .padding(12)
                    .background(PresenciaStatsPalette.rowBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(PresenciaStatsCardBackground(accent: .pink, cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reload() {
        reloadDailyEvents()
        reloadPracticalInsights()
        reloadRatioStats()
        reloadMoodStats()
        reloadDominantMoodStats()
        eventPoints = repository.todayEventPoints()
        todayPresentCount = repository.todayPresentCount()
        let widestRange = [dailyEventsRange, practicalInsightsRange, ratioRange, moodRange, dominantMoodRange].max() ?? 30
        futureFeelingCount = repository.futureFeelingCount(days: widestRange)
        streakStats = repository.streakStats(days: 90)
    }

    private func reloadDailyEvents() {
        dayStats = repository.dayStats(days: dailyEventsRange)
    }

    private func reloadPracticalInsights() {
        practicalStats = repository.dayStats(days: practicalInsightsRange)
        rangeEventPoints = repository.eventPoints(days: practicalInsightsRange)
    }

    private func reloadRatioStats() {
        ratioStats = repository.dayStats(days: ratioRange)
    }

    private func reloadMoodStats() {
        moodStats = repository.moodStats(days: moodRange)
    }

    private func reloadDominantMoodStats() {
        dominantMoodStats = repository.moodStats(days: dominantMoodRange)
    }

    private func resetPresenceStats() {
        guard repository.resetAllEvents() else { return }
        WatchDataSyncToWatch.shared.sendPresenceReset()
        reload()
    }
}

private struct DominantMoodSummary: Hashable {
    let title: String
    let percentage: Int
}

private struct PresenceGlassCard<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, minHeight: 184, alignment: .topLeading)
        .padding(18)
        .background(PresenciaStatsCardBackground(accent: accent, cornerRadius: 20))
    }
}

private struct PresenceCardHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
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
            .foregroundStyle(PresenciaStatsPalette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PresenceMetricCardHeader<Trailing: View>: View {
    let icon: String
    let title: String
    let accent: Color
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
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
                .foregroundStyle(PresenciaStatsPalette.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PresenciaInfoButton: View {
    let title: String
    let message: String
    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.headline)
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
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

private struct TodayReturnsCard: View {
    let count: Int

    var body: some View {
        PresenceGlassCard(accent: .purple) {
            PresenceMetricCardHeader(icon: "sun.max", title: "Hoy: retornos", accent: .purple) {
                PresenciaInfoButton(
                    title: "Hoy",
                    message: "Cuenta los momentos de presencia consciente registrados desde el inicio del día actual."
                )
            }

            Spacer(minLength: 0)

            Text("\(count)")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)

            Text(count >= 10 ? "¡Sigue así!" : "Vuelve cuando lo notes")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct CurrentStreakCard: View {
    let days: Int

    var body: some View {
        PresenceGlassCard(accent: .orange) {
            PresenceMetricCardHeader(icon: "flame.fill", title: "Racha actual", accent: .orange) {
                PresenciaInfoButton(
                    title: "Racha",
                    message: "Cuenta los días consecutivos en los que alcanzaste el mínimo de retornos conscientes definido para sostener la racha."
                )
            }

            Spacer(minLength: 0)

            Text("\(days)")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)

            Text("días seguidos")
                .font(.subheadline)
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
                .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index < min(days, 7) ? .orange : .clear)
                        .overlay(Circle().stroke(.orange, lineWidth: 1))
                        .frame(width: 11, height: 11)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct WeeklyAverageCard: View {
    let weekStats: [PresenciaDayStats]

    private var average: Int {
        guard !weekStats.isEmpty else { return 0 }
        let total = weekStats.reduce(0) { $0 + $1.presentes }
        return Int((Double(total) / Double(weekStats.count)).rounded())
    }

    private var maxValue: Int {
        max(weekStats.map(\.presentes).max() ?? 1, 1)
    }

    var body: some View {
        PresenceGlassCard(accent: .green) {
            PresenceMetricCardHeader(icon: "arrow.up.right", title: "Esta semana: promedio diario", accent: .green) {
                PresenciaInfoButton(
                    title: "Promedio semanal",
                    message: "Promedia los retornos conscientes registrados durante la semana actual, de lunes a domingo."
                )
            }

            Spacer(minLength: 0)

            Text("\(average)")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)

            Text("retornos")
                .font(.subheadline)
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
                .frame(maxWidth: .infinity)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(weekStats.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.green.opacity(day.presentes == 0 ? 0.28 : 0.62))
                            .frame(width: 8, height: max(CGFloat(day.presentes) / CGFloat(maxValue) * 28, day.presentes == 0 ? 5 : 9))
                        Text(weekdayLetter(for: day.date))
                            .font(.caption2)
                            .foregroundStyle(PresenciaStatsPalette.secondaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func weekdayLetter(for date: Date) -> String {
        let symbol = Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        return String(symbol.prefix(1)).uppercased()
    }
}

private struct DominantMoodCard: View {
    let summary: DominantMoodSummary?
    @Binding var selectedRange: Int

    var body: some View {
        PresenceGlassCard(accent: .blue) {
            PresenceMetricCardHeader(icon: "heart", title: "Estado de ánimo predominante", accent: .blue) {
                PresenciaInfoButton(
                    title: "Estado predominante",
                    message: "Muestra el estado de ánimo más frecuente dentro del rango elegido en esta tarjeta y su porcentaje sobre el total de estados registrados."
                )
                PresenciaRangeMenu(selectedRange: $selectedRange)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                Circle()
                    .stroke(.blue.opacity(0.82), lineWidth: 3)
                Image(systemName: summary == nil ? "face.dashed" : "face.smiling")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.blue)
            }
            .frame(width: 74, height: 74)
            .frame(maxWidth: .infinity)

            Text(summary?.title ?? "Sin registros")
                .font(.headline)
                .foregroundStyle(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            Text(summary.map { "\($0.percentage)% de tus registros" } ?? "Registra un estado")
                .font(.subheadline)
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct PresenciaPracticalInsightsCard: View {
    let stats: [PresenciaDayStats]
    let events: [PresenciaEventPoint]
    @Binding var selectedRange: Int

    private var mostPresentDayText: String {
        guard let day = stats.max(by: { $0.presentes < $1.presentes }), day.presentes > 0 else {
            return "Aún no hay un día destacado."
        }

        return "Tu día más consciente fue el \(weekdayName(for: day.date))."
    }

    private var averageText: String {
        guard !stats.isEmpty else { return "0 por día" }
        let total = stats.reduce(0) { $0 + $1.presentes }
        let average = Double(total) / Double(stats.count)
        return "\(formatAverage(average)) por día"
    }

    private var weeklyTrendText: String {
        let currentWeek = stats.suffix(7).reduce(0) { $0 + $1.presentes }
        let previousWeek = stats.dropLast(7).suffix(7).reduce(0) { $0 + $1.presentes }

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
        let automaticEvents = events.filter(\.isAutomaticPilot)
        guard !automaticEvents.isEmpty else {
            return "No se detecta una franja crítica."
        }

        let calendar = Calendar.current
        let windowCounts = stride(from: 0, through: 21, by: 3).map { startHour in
            let count = automaticEvents.filter { event in
                let hour = calendar.component(.hour, from: event.createdAt)
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
        PresenciaDailyEventsSuggestion.message(stats: stats, events: events)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Datos prácticos")
                    .font(.headline)
                    .foregroundStyle(PresenciaStatsPalette.primaryText)
                Spacer()
                PresenciaInfoButton(title: "Datos prácticos", message: infoMessage)
            }

            PresenciaRangePicker(title: "Rango de datos prácticos", selectedRange: $selectedRange)

            VStack(spacing: 10) {
                insightRow(icon: "calendar.badge.clock", title: "Día con más presencia", value: mostPresentDayText, accent: .mint)
                insightRow(icon: "number", title: "Promedio por día", value: averageText, accent: .cyan)
                insightRow(icon: "chart.line.uptrend.xyaxis", title: "Tendencia semanal", value: weeklyTrendText, accent: .green)
                insightRow(icon: "exclamationmark.triangle.fill", title: "Franja crítica", value: criticalWindowText, accent: .orange)
                PresenciaContextualSuggestionRow(message: contextualSuggestionText)
            }
        }
        .padding(14)
        .background(PresenciaStatsCardBackground(accent: .cyan, cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                    .foregroundStyle(PresenciaStatsPalette.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PresenciaStatsPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(PresenciaStatsPalette.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
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

private struct PresenciaBarsView: View {
    let stats: [PresenciaDayStats]
    @Binding var selectedRange: Int

    private var maxValue: Int {
        max(stats.map { max($0.presentes, $0.inconscientes) }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Eventos diarios")
                        .font(.headline)
                        .foregroundStyle(PresenciaStatsPalette.primaryText)
                    Spacer()
                    PresenciaInfoButton(
                        title: "Eventos diarios",
                        message: "Muestra, para cada día del rango seleccionado, cuántos registros fueron Presente y cuántos fueron Piloto automático o Distraído."
                    )
                }
                PresenciaRangePicker(title: "Rango de eventos diarios", selectedRange: $selectedRange)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(stats) { day in
                        VStack(spacing: 3) {
                            Spacer(minLength: 0)
                            bar(value: day.presentes, color: .mint)
                            bar(value: day.inconscientes, color: .orange)
                            Text(day.date, format: .dateTime.day())
                                .font(.caption2)
                                .foregroundStyle(PresenciaStatsPalette.secondaryText)
                        }
                        .frame(width: 16)
                    }
                }
                .frame(minWidth: minChartWidth, minHeight: 180, alignment: .bottomLeading)
            }
            .frame(height: 180)
            legend
        }
        .padding(14)
        .background(PresenciaStatsCardBackground(accent: .mint, cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func bar(value: Int, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color.opacity(value == 0 ? 0.2 : 0.9))
            .frame(width: 7, height: max(CGFloat(value) / CGFloat(maxValue) * 70, value == 0 ? 3 : 8))
    }

    private var minChartWidth: CGFloat {
        max(CGFloat(stats.count) * 23, 320)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            Label("Presente", systemImage: "circle.fill")
                .foregroundStyle(.mint)
            Label("Piloto automático", systemImage: "circle.fill")
                .foregroundStyle(.orange)
        }
        .font(.caption)
    }
}

private struct PresenciaContextualSuggestionRow: View {
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
                    .foregroundStyle(PresenciaStatsPalette.secondaryText)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PresenciaStatsPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(PresenciaStatsPalette.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private enum PresenciaDailyEventsSuggestion {
    static func message(stats: [PresenciaDayStats], events: [PresenciaEventPoint]) -> String {
        let presentCount = stats.reduce(0) { $0 + $1.presentes }
        let automaticCount = stats.reduce(0) { $0 + $1.inconscientes }
        let totalCount = presentCount + automaticCount
        let activeDays = stats.filter { $0.total > 0 }.count

        guard totalCount > 0 else {
            return "Aún no hay suficientes registros en este rango. Haz uno o dos retornos conscientes hoy para que aparezca un patrón útil."
        }

        if activeDays <= max(2, stats.count / 6) {
            return "Hay pocos días con registros. Prueba una pausa breve a media mañana y otra al final de la tarde para empezar a revelar tu patrón."
        }

        if presentCount == 0 {
            return "Por ahora solo aparecen momentos de piloto automático. Elige una hora fácil, como antes de comer, para registrar un retorno consciente deliberado."
        }

        if automaticCount > presentCount {
            if let window = strongestWindow(events: events.filter(\.isAutomaticPilot)) {
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

        if isRecentPresenceImproving(stats: stats) {
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

    private static func dominantPresencePeriod(events: [PresenciaEventPoint]) -> (period: Period, count: Int)? {
        let presentEvents = events.filter(\.isPresentReturn)
        guard !presentEvents.isEmpty else { return nil }

        let grouped = Dictionary(grouping: presentEvents) { event in
            period(for: Calendar.current.component(.hour, from: event.createdAt))
        }

        return grouped
            .map { (period: $0.key, count: $0.value.count) }
            .max { $0.count < $1.count }
    }

    private static func strongestWindow(events: [PresenciaEventPoint]) -> (start: Int, end: Int)? {
        guard events.count >= 2 else { return nil }
        let hours = events.map { Calendar.current.component(.hour, from: $0.createdAt) }
        let windows = stride(from: 0, through: 21, by: 3).map { start in
            let end = start + 3
            let count = hours.filter { $0 >= start && $0 < end }.count
            return (start: start, end: end, count: count)
        }
        guard let best = windows.max(by: { $0.count < $1.count }), best.count >= 2 else { return nil }
        return (best.start, best.end)
    }

    private static func isRecentPresenceImproving(stats: [PresenciaDayStats]) -> Bool {
        guard stats.count >= 8 else { return false }
        let recent = stats.suffix(7)
        let previous = stats.dropLast(7).suffix(7)
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

private struct PresenciaRangePicker: View {
    let title: String
    @Binding var selectedRange: Int
    @AppStorage(PresenciaStatsAppearanceStorage.key) private var appearanceRawValue = PresenciaStatsAppearanceStorage.defaultValue

    private var pickerColorScheme: ColorScheme {
        let appearance = PresenciaStatsAppearance(rawValue: appearanceRawValue) ?? .dark
        return appearance == .light ? .light : .dark
    }

    var body: some View {
        Picker(title, selection: $selectedRange) {
            Text("14 días").tag(14)
            Text("30 días").tag(30)
            Text("90 días").tag(90)
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
        .environment(\.colorScheme, pickerColorScheme)
    }
}

private struct PresenciaRangeMenu: View {
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
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
        }
        .accessibilityLabel("Rango de estado predominante")
    }
}

private struct PresenciaDailyDotTimelineView: View {
    let events: [PresenciaEventPoint]

    private let calendar = Calendar.current
    private let chartHeight: CGFloat = 136
    private let plotHeight: CGFloat = 76
    private let topPadding: CGFloat = 18
    private let horizontalHourSpacing = PresenciaDailyTimelineLayout.horizontalHourSpacing

    private var timelineEvents: [PresenciaEventPoint] {
        events.filter { $0.isPresentReturn || $0.isAutomaticPilot }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if timelineEvents.isEmpty {
                Text("Aún no hay eventos de presencia registrados hoy.")
                    .font(.subheadline)
                    .foregroundStyle(PresenciaStatsPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            timelineCanvas
                                .frame(width: minChartWidth, height: chartHeight)

                            hourLabels
                                .frame(width: minChartWidth, alignment: .leading)
                        }
                    }
                    .frame(height: chartHeight + 24)
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo(5, anchor: .leading)
                        }
                    }
                }

                legend
            }
        }
        .padding(14)
        .background(PresenciaStatsCardBackground(accent: .cyan, cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Momentos de presencia de hoy")
                .font(.headline)
                .foregroundStyle(PresenciaStatsPalette.primaryText)
            Spacer()
            PresenciaInfoButton(
                title: "Momentos de hoy",
                message: "Muestra solo los eventos del día actual distribuidos por hora. Verde indica Presente; naranja indica Piloto automático o Distraído."
            )
            Text("\(timelineEvents.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
        }
    }

    private var timelineCanvas: some View {
        Canvas { context, size in
            let plotWidth = size.width
            drawGrid(context: &context, plotWidth: plotWidth)
            drawEvents(context: &context, plotWidth: plotWidth)
        }
    }

    private var hourLabels: some View {
        HStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text(String(format: "%02d", hour))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(PresenciaStatsPalette.secondaryText)
                    .frame(width: horizontalHourSpacing, alignment: .center)
                    .id(hour)
            }
        }
    }

    private var centerY: CGFloat {
        topPadding + plotHeight / 2
    }

    private var legend: some View {
        HStack(spacing: 14) {
            Label("Presente", systemImage: "circle.fill")
                .foregroundStyle(.mint)
            Label("Piloto automático", systemImage: "circle.fill")
                .foregroundStyle(.orange)
        }
        .font(.caption)
    }

    private var minChartWidth: CGFloat {
        horizontalHourSpacing * 24
    }

    private func drawGrid(context: inout GraphicsContext, plotWidth: CGFloat) {
        for hour in 0...24 {
            let x = CGFloat(hour) / 24.0 * plotWidth
            var path = Path()
            path.move(to: CGPoint(x: x, y: topPadding))
            path.addLine(to: CGPoint(x: x, y: topPadding + plotHeight))
            let opacity = hour == 0 || hour == 24 || hour == 12 ? 0.22 : 0.1
            context.stroke(path, with: .color(PresenciaStatsPalette.gridLine.opacity(opacity)), lineWidth: 1)
        }

        var centerLine = Path()
        centerLine.move(to: CGPoint(x: 0, y: centerY))
        centerLine.addLine(to: CGPoint(x: plotWidth, y: centerY))
        context.stroke(centerLine, with: .color(PresenciaStatsPalette.gridLine.opacity(0.16)), lineWidth: 1)
    }

    private func drawEvents(context: inout GraphicsContext, plotWidth: CGFloat) {
        for event in timelineEvents {
            let size: CGFloat = event.isPresentReturn ? 10 : 8
            let x = xPosition(for: event.createdAt, width: plotWidth)
            let y = centerY + collisionOffset(for: event)
            let rect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
            let color: Color = event.isPresentReturn ? .mint : .orange

            context.fill(Path(ellipseIn: rect), with: .color(color))
            context.stroke(Path(ellipseIn: rect), with: .color(PresenciaStatsPalette.pointStroke), lineWidth: 0.8)
        }
    }

    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let seconds = Double((components.hour ?? 0) * 3_600 + (components.minute ?? 0) * 60 + (components.second ?? 0))
        return CGFloat(seconds / 86_400.0) * width
    }

    private func collisionOffset(for event: PresenciaEventPoint) -> CGFloat {
        let nearbyEvents = timelineEvents.filter {
            calendar.component(.hour, from: $0.createdAt) == calendar.component(.hour, from: event.createdAt)
        }
        guard let index = nearbyEvents.firstIndex(where: { $0.id == event.id }) else { return 0 }
        return CGFloat((index % 5) - 2) * 7
    }
}

private struct PresenciaRatioDotsView: View {
    let stats: [PresenciaDayStats]
    @Binding var selectedRange: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Cociente presente/inconsciente")
                    .font(.headline)
                    .foregroundStyle(PresenciaStatsPalette.primaryText)
                Spacer()
                PresenciaInfoButton(
                    title: "Cociente presente/inconsciente",
                    message: "Cada punto representa el porcentaje de eventos conscientes frente al total de eventos conscientes e inconscientes de ese día, dentro del rango elegido en esta tarjeta."
                )
            }
            PresenciaRangePicker(title: "Rango del cociente", selectedRange: $selectedRange)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(stats) { day in
                        VStack(spacing: 6) {
                            Spacer(minLength: 0)
                            Circle()
                                .fill(day.total == 0 ? PresenciaStatsPalette.rowBackground : .cyan)
                                .frame(width: 9, height: 9)
                                .offset(y: CGFloat(1 - day.ratioPresencia) * 80)
                            Text(day.date, format: .dateTime.day())
                                .font(.caption2)
                                .foregroundStyle(PresenciaStatsPalette.secondaryText)
                        }
                        .frame(width: 16)
                    }
                }
                .frame(minWidth: minChartWidth, minHeight: 120, alignment: .bottomLeading)
            }
            .frame(height: 120)
            Text("Más alto significa que, entre los eventos registrados, hubo más retornos conscientes.")
                .font(.caption)
                .foregroundStyle(PresenciaStatsPalette.secondaryText)
        }
        .padding(14)
        .background(PresenciaStatsCardBackground(accent: .blue, cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var minChartWidth: CGFloat {
        max(CGFloat(stats.count) * 24, 320)
    }
}
#endif


#Preview{
    PresenciaStatsView()
}
