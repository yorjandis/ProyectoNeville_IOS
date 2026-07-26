import SwiftUI
import CoreData
import UserNotifications

/// Día en el que se pone a disposición la revisión. Los valores coinciden con
/// `Calendar.Component.weekday` (1 = domingo).
nonisolated enum WeeklyReviewDay: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunday: return L10n.exact("Domingo")
        case .monday: return L10n.exact("Lunes")
        case .tuesday: return L10n.exact("Martes")
        case .wednesday: return L10n.exact("Miércoles")
        case .thursday: return L10n.exact("Jueves")
        case .friday: return L10n.exact("Viernes")
        case .saturday: return L10n.exact("Sábado")
        }
    }
}

nonisolated enum WeeklyReviewSchedule {
    static let availableHour = 6

    static func selectedDay(from rawValue: Int) -> WeeklyReviewDay {
        WeeklyReviewDay(rawValue: rawValue) ?? .sunday
    }

    static func isAvailable(now: Date = .now, weekday: Int, calendar: Calendar = .current) -> Bool {
        calendar.component(.weekday, from: now) == selectedDay(from: weekday).rawValue
            && calendar.component(.hour, from: now) >= availableHour
    }

    /// Devuelve la última semana completa. Cuando llega el día elegido a las
    /// 06:00, la semana que acaba de terminar pasa a ser la revisable.
    static func interval(now: Date = .now, weekday: Int, calendar: Calendar = .current) -> DateInterval {
        let startOfToday = calendar.startOfDay(for: now)
        let selectedWeekday = selectedDay(from: weekday).rawValue
        let currentWeekday = calendar.component(.weekday, from: now)
        let daysSinceSelected = (currentWeekday - selectedWeekday + 7) % 7
        var end = calendar.date(byAdding: .day, value: -daysSinceSelected, to: startOfToday) ?? startOfToday

        if daysSinceSelected == 0, calendar.component(.hour, from: now) < availableHour {
            end = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        }

        let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        return DateInterval(start: start, end: end)
    }

    static func periodKey(for interval: DateInterval, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: interval.end)
    }
}

nonisolated enum WeeklyReviewNotificationManager {
    static let identifier = "weekly_review_reminder"

    static func update(enabled: Bool, weekday: Int) {
        Task {
            await WeeklyReviewNotificationScheduler.shared.update(enabled: enabled, weekday: weekday)
        }
    }
}

private actor WeeklyReviewNotificationScheduler {
    static let shared = WeeklyReviewNotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    func update(enabled: Bool, weekday: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: [WeeklyReviewNotificationManager.identifier])
        guard enabled else { return }

        let settings = await center.notificationSettings()
        let isAuthorized: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            isAuthorized = false
        }
        guard isAuthorized else { return }

        var components = DateComponents()
        components.weekday = WeeklyReviewSchedule.selectedDay(from: weekday).rawValue
        components.hour = WeeklyReviewSchedule.availableHour
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = L10n.string(
            "notification.weekly_review.title",
            fallback: "Tu revisión semanal está lista"
        )
        content.body = L10n.string(
            "notification.weekly_review.body",
            fallback: "Dedica 5–10 minutos a reconocer tus avances y elegir tu foco."
        )
        content.sound = .default
        content.userInfo = ["weeklyReviewDestination": true]

        let request = UNNotificationRequest(
            identifier: WeeklyReviewNotificationManager.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        try? await center.add(request)
    }
}

struct WeeklyReviewView: View {
    @Environment(\.managedObjectContext) private var context

    @AppStorage(AppCons.UD_setting_WeeklyReviewWeekday) private var weekday: Int = WeeklyReviewDay.sunday.rawValue
    @AppStorage(AppCons.UD_setting_WeeklyReviewCompletedPeriod) private var completedPeriodKey = ""
    @AppStorage(AppCons.UD_setting_WeeklyReviewFocus) private var savedFocus = ""
    @AppStorage(AppCons.UD_setting_WeeklyReviewCelebration) private var savedCelebration = ""

    @State private var snapshot = WeeklyReviewSnapshot.empty
    @State private var focus = ""
    @State private var celebration = ""
    @State private var now = Date()
    @State private var closingInputsPeriodKey = ""
    @State private var saveErrorMessage: String?

    private var interval: DateInterval {
        WeeklyReviewSchedule.interval(now: now, weekday: weekday)
    }

    private var periodKey: String {
        WeeklyReviewSchedule.periodKey(for: interval)
    }

    private var isCurrentReviewCompleted: Bool {
        completedPeriodKey == periodKey
    }

    private var reviewContext: NSManagedObjectContext {
        if WeeklyReviewStore(context: context).isAvailable {
            return context
        }
        return CoreDataController.shared.context
    }

    private var periodTitle: String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.dateFormat = "d MMM"
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        return "\(formatter.string(from: interval.start)) – \(formatter.string(from: lastDay))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                overview
                goalsSection
                agendaSection
                wellbeingSection
                practiceSection
                achievementsSection
                guidedClosing
            }
            .padding(20)
        }
        .background(.primary.opacity(0.035))
        .navigationTitle("Revisión semanal")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
            reload()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WeeklyReviewStatsView()
                } label: {
                    Label(L10n.exact("Estadísticas"), systemImage: "chart.xyaxis.line")
                }
            }
        }
        .alert("No se pudo guardar la revisión", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? L10n.exact("Inténtalo de nuevo cuando el almacenamiento esté disponible."))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Tu pausa para mirar con claridad", systemImage: "sparkles.rectangle.stack.fill")
                .font(.headline)
                .foregroundStyle(.indigo)

            Text("Revisión de la semana")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text(periodTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("En 5–10 minutos, reconoce lo que funcionó y elige un foco amable para los próximos días.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [.indigo.opacity(0.18), .purple.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vista rápida")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metric("Metas", "\(snapshot.goalUnitsCompleted)", "unidades avanzadas", "flag.checkered", .green)
                metric("Agenda", "\(snapshot.agendaCompleted)/\(snapshot.agendaTotal)", "completadas", "checkmark.circle", .orange)
                metric("Diario", "\(snapshot.diaryActiveDays)/7", "días con entrada", "book.closed", .purple)
                metric("Presencia", "\(snapshot.presenceReturns)", "momentos conscientes", "heart.fill", .teal)
            }
        }
    }

    private var goalsSection: some View {
        reviewCard(title: "Metas", subtitle: "Avanza y desbloquea lo que se quedó quieto.", symbol: "flag.checkered", color: .green) {
            HStack(spacing: 12) {
                compactMetric(value: "\(snapshot.goalUnitsCompleted)", label: "unidades completadas")
                compactMetric(value: "\(snapshot.stagnantGoalTitles.count)", label: "metas sin avance")
            }

            if snapshot.stagnantGoalTitles.isEmpty {
                positiveLine("Tus metas activas registraron movimiento o son recientes.")
            } else {
                Text("Elige una sola acción pequeña para reactivar:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(snapshot.stagnantGoalTitles.prefix(3), id: \.self) { title in
                    Label(title, systemImage: "arrow.right.circle")
                        .font(.subheadline)
                }
            }
        }
    }

    private var agendaSection: some View {
        reviewCard(title: "Agenda", subtitle: "Lo completado frente a lo que aún pide atención.", symbol: "calendar", color: .orange) {
            ProgressView(value: Double(snapshot.agendaCompleted), total: Double(max(snapshot.agendaTotal, 1)))
                .tint(.orange)

            HStack {
                Text("\(snapshot.agendaCompleted) completadas")
                Spacer()
                Text("\(snapshot.agendaPending) pendientes")
            }
            .font(.subheadline.weight(.medium))

            if snapshot.agendaTotal == 0 {
                emptyLine("No hubo actividades de agenda en esta semana.")
            } else if snapshot.agendaPending > 0 {
                Text("Sugerencia: reprograma o simplifica las pendientes para que sigan teniendo sentido.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var wellbeingSection: some View {
        reviewCard(title: "Diario y estados emocionales", subtitle: "Observa patrones, sin juzgarte.", symbol: "face.smiling", color: .purple) {
            HStack(spacing: 12) {
                compactMetric(value: "\(snapshot.diaryEntries)", label: "entradas de diario")
                compactMetric(value: "\(snapshot.diaryActiveDays)/7", label: "días de escritura")
            }

            if snapshot.diaryEntries == 0 {
                emptyLine("No hay entradas esta semana. Una frase basta para volver a empezar.")
            }

            if !snapshot.moodSummaries.isEmpty {
                Text("Estados predominantes")
                    .font(.subheadline.weight(.semibold))
                FlowLayout(spacing: 8) {
                    ForEach(snapshot.moodSummaries.prefix(4), id: \.title) { mood in
                        Text("\(mood.emoji) \(mood.title) · \(mood.count)")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.purple.opacity(0.11), in: Capsule())
                    }
                }
            } else {
                emptyLine("Aún no hay estados emocionales registrados esta semana.")
            }
        }
    }

    private var practiceSection: some View {
        reviewCard(title: "Presencia y coherencia", subtitle: "Tus prácticas internas también cuentan.", symbol: "waveform.path.ecg", color: .teal) {
            HStack(spacing: 12) {
                compactMetric(value: "\(snapshot.presenceReturns)", label: "retornos a presencia")
                compactMetric(value: "\(snapshot.coherenceSessions)", label: "sesiones de coherencia")
            }

            if snapshot.coherenceMinutes > 0 {
                Text("\(snapshot.coherenceMinutes) minutos de coherencia · cambio medio \(snapshot.coherenceDelta >= 0 ? "+" : "")\(snapshot.coherenceDelta, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if snapshot.automaticPilotEvents > 0 {
                Label("Detectaste \(snapshot.automaticPilotEvents) momento\(snapshot.automaticPilotEvents == 1 ? "" : "s") de piloto automático. Detectarlo ya es volver.", systemImage: "eye")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if snapshot.presenceReturns > 0 {
                positiveLine("Has creado momentos conscientes a lo largo de la semana.")
            } else {
                emptyLine("Prueba a registrar un instante de presencia mañana, sin exigencias.")
            }

            if snapshot.ritualsCompleted > 0 {
                Label("\(snapshot.ritualsCompleted) ritual\(snapshot.ritualsCompleted == 1 ? "" : "es") completado\(snapshot.ritualsCompleted == 1 ? "" : "s")", systemImage: "sunrise.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var achievementsSection: some View {
        reviewCard(title: "Logros de la semana", subtitle: "Da valor a las evidencias, incluso a las pequeñas.", symbol: "trophy.fill", color: .yellow) {
            if snapshot.achievements.isEmpty {
                emptyLine("Todavía no hay logros registrados. Elige uno que quieras reconocer antes de cerrar.")
            } else {
                ForEach(snapshot.achievements.prefix(5), id: \.self) { achievement in
                    Label(achievement, systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var guidedClosing: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Cierre guiado", systemImage: "pencil.and.list.clipboard")
                .font(.title3.bold())

            Text("¿Qué quieres celebrar de esta semana?")
                .font(.subheadline.weight(.medium))
            TextField("Ej.: Fui constante aunque tuve poco tiempo", text: $celebration, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            Text("Elige un foco realista para la próxima semana.")
                .font(.subheadline.weight(.medium))
            TextField("Ej.: Escribir dos días en el diario", text: $focus, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await closeReview()
                }
            } label: {
                Label(
                    L10n.exact(isCurrentReviewCompleted ? "Revisión completada" : "Cerrar revisión semanal"),
                    systemImage: isCurrentReviewCompleted ? "checkmark.circle.fill" : "checkmark.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCurrentReviewCompleted ? .green : .indigo)
        }
        .padding(18)
        .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func reviewCard<Content: View>(
        title: String,
        subtitle: String,
        symbol: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.exact(title), systemImage: symbol)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(L10n.exact(subtitle))
                .font(.footnote)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func metric(_ title: String, _ value: String, _ subtitle: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(L10n.exact(title))
                .font(.subheadline.weight(.medium))
            Text(L10n.exact(subtitle))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(14)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private func compactMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.title2.bold())
            Text(L10n.exact(label)).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func positiveLine(_ text: String) -> some View {
        Label(L10n.exact(text), systemImage: "checkmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.green)
    }

    private func emptyLine(_ text: String) -> some View {
        Text(L10n.exact(text))
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func reload() {
        now = Date()
        snapshot = WeeklyReviewDataLoader(context: reviewContext).load(interval: interval)

        let store = WeeklyReviewStore(context: reviewContext)
        if let review = store.review(for: periodKey) {
            completedPeriodKey = periodKey
            savedFocus = review.focus
            savedCelebration = review.celebration
            loadClosingInputsIfNeeded(focus: review.focus, celebration: review.celebration)
        } else {
            let legacyFocus = completedPeriodKey == periodKey ? savedFocus : ""
            let legacyCelebration = completedPeriodKey == periodKey ? savedCelebration : ""
            loadClosingInputsIfNeeded(focus: legacyFocus, celebration: legacyCelebration)

            // Conserva en CloudKit una revisión cerrada antes de esta versión,
            // en cuanto el almacén de Core Data termine de estar disponible.
            if completedPeriodKey == periodKey {
                _ = store.save(
                    periodKey: periodKey,
                    interval: interval,
                    focus: legacyFocus,
                    celebration: legacyCelebration,
                    snapshot: snapshot
                )
            }
        }
    }

    private func closeReview() async {
        let trimmedFocus = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCelebration = celebration.trimmingCharacters(in: .whitespacesAndNewlines)
        let didSave = await saveReview(
            periodKey: periodKey,
            interval: interval,
            focus: trimmedFocus,
            celebration: trimmedCelebration,
            snapshot: snapshot
        )

        guard didSave else {
            saveErrorMessage = L10n.exact("El almacenamiento todavía no está listo. Tu revisión no se ha marcado como completada; inténtalo de nuevo en unos segundos.")
            return
        }

        savedCelebration = trimmedCelebration
        savedFocus = trimmedFocus
        completedPeriodKey = periodKey
    }

    private func saveReview(
        periodKey: String,
        interval: DateInterval,
        focus: String,
        celebration: String,
        snapshot: WeeklyReviewSnapshot
    ) async -> Bool {
        let initialStore = WeeklyReviewStore(context: reviewContext)
        if initialStore.save(
            periodKey: periodKey,
            interval: interval,
            focus: focus,
            celebration: celebration,
            snapshot: snapshot
        ) {
            return true
        }

        if CoreDataController.shared.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
            do {
                try await CoreDataController.shared.cargarStores()
            } catch {
                return false
            }
        }

        return WeeklyReviewStore(context: CoreDataController.shared.context).save(
            periodKey: periodKey,
            interval: interval,
            focus: focus,
            celebration: celebration,
            snapshot: snapshot
        )
    }

    private func loadClosingInputsIfNeeded(focus storedFocus: String, celebration storedCelebration: String) {
        guard closingInputsPeriodKey != periodKey else { return }
        closingInputsPeriodKey = periodKey
        focus = storedFocus
        celebration = storedCelebration
    }
}

struct WeeklyReviewStatsView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var records: [WeeklyReviewHistoryRecord] = []
    @State private var selectedRange: WeeklyReviewStatsRange = .twelveWeeks

    private var statsContext: NSManagedObjectContext {
        if WeeklyReviewStore(context: context).isAvailable {
            return context
        }
        return CoreDataController.shared.context
    }

    private var displayedRecords: [WeeklyReviewHistoryRecord] {
        selectedRange.records(from: records)
    }

    private var recentRecords: [WeeklyReviewHistoryRecord] {
        displayedRecords
    }

    private var previousRecords: [WeeklyReviewHistoryRecord] {
        guard let count = selectedRange.recordLimit else { return [] }
        let end = max(records.count - count, 0)
        let start = max(end - count, 0)
        return Array(records[start..<end])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if records.isEmpty {
                    emptyState
                } else {
                    rangePicker
                    summaryCards
                    nextActionSection
                    highlightsSection
                    balanceSection
                    trendSection
                    insightsSection
                    moodsSection
                    celebrationsSection
                    focusSection
                }
            }
            .padding(20)
        }
        .background(.primary.opacity(0.035))
        .navigationTitle(L10n.exact("Estadísticas semanales"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
            reload()
        }
    }

    private var rangePicker: some View {
        Picker(L10n.exact("Rango"), selection: $selectedRange) {
            ForEach(WeeklyReviewStatsRange.allCases) { range in
                Text(L10n.exact(range.title)).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.exact("Tu evolución visible"), systemImage: "chart.xyaxis.line")
                .font(.headline)
                .foregroundStyle(.indigo)

            Text(L10n.exact("Resumen de revisiones"))
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text(records.isEmpty ? L10n.exact("Cuando cierres revisiones, aquí aparecerán tendencias e insights.") : savedReviewsSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [.indigo.opacity(0.18), .teal.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.exact("Aún no hay historial"), systemImage: "clock.badge.questionmark")
                .font(.title3.bold())
            Text(L10n.exact("Cierra una revisión semanal para empezar a construir estadísticas de metas, agenda, diario, presencia, coherencia, rituales y estados emocionales."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                title: "Revisiones",
                value: "\(displayedRecords.count)",
                caption: selectedRange == .all ? "cierres guardados" : "en el rango",
                symbol: "checkmark.seal.fill",
                color: .green
            )

            statCard(
                title: "Diario",
                value: "\(formattedAverage(\.snapshot.diaryActiveDays, in: recentRecords))/7",
                caption: "días por semana",
                symbol: "book.closed.fill",
                color: .purple
            )

            statCard(
                title: "Presencia",
                value: formattedAverage(\.snapshot.presenceReturns, in: recentRecords),
                caption: "retornos semanales",
                symbol: "heart.fill",
                color: .teal
            )

            statCard(
                title: "Coherencia",
                value: "\(Int(average(\.snapshot.coherenceMinutes, in: recentRecords))) min",
                caption: "promedio semanal",
                symbol: "waveform.path.ecg",
                color: .indigo
            )
        }
    }

    private var trendSection: some View {
        statsCard(title: selectedRange.title, subtitle: "Una lectura rápida de tus prácticas sostenidas.", symbol: "chart.bar.fill", color: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                trendRow(title: "Metas", value: sum(\.snapshot.goalUnitsCompleted, in: recentRecords), maxValue: max(1, maxSum(\.snapshot.goalUnitsCompleted)))
                trendRow(title: "Agenda completada", value: sum(\.snapshot.agendaCompleted, in: recentRecords), maxValue: max(1, maxSum(\.snapshot.agendaCompleted)))
                trendRow(title: "Diario", value: sum(\.snapshot.diaryActiveDays, in: recentRecords), maxValue: max(1, recentRecords.count * 7))
                trendRow(title: "Presencia", value: sum(\.snapshot.presenceReturns, in: recentRecords), maxValue: max(1, maxSum(\.snapshot.presenceReturns)))
                trendRow(title: "Coherencia", value: sum(\.snapshot.coherenceMinutes, in: recentRecords), maxValue: max(1, maxSum(\.snapshot.coherenceMinutes)))
                trendRow(title: "Rituales", value: sum(\.snapshot.ritualsCompleted, in: recentRecords), maxValue: max(1, maxSum(\.snapshot.ritualsCompleted)))
            }
        }
    }

    private var nextActionSection: some View {
        statsCard(title: "Siguiente mejor acción", subtitle: "Una acción pequeña elegida desde tus patrones recientes.", symbol: "arrow.up.forward.circle.fill", color: .indigo) {
            Label(nextBestAction, systemImage: "sparkle.magnifyingglass")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private var highlightsSection: some View {
        statsCard(title: "Semanas destacadas", subtitle: "Reconoce dónde ya hubo evidencia real.", symbol: "trophy.fill", color: .yellow) {
            VStack(alignment: .leading, spacing: 10) {
                if let best = bestPracticeWeek {
                    highlightRow(
                        title: "Semana más integrada",
                        value: weekTitle(best),
                        caption: balanceLabel(for: best),
                        symbol: "seal.fill"
                    )
                }

                if let strongestPresenceWeek {
                    highlightRow(
                        title: "Mayor presencia",
                        value: countText(strongestPresenceWeek.snapshot.presenceReturns, singularKey: "retorno", pluralKey: "retornos"),
                        caption: weekTitle(strongestPresenceWeek),
                        symbol: "heart.fill"
                    )
                }

                if let strongestCoherenceWeek {
                    highlightRow(
                        title: "Más coherencia",
                        value: countText(strongestCoherenceWeek.snapshot.coherenceMinutes, singularKey: "minuto", pluralKey: "minutos"),
                        caption: weekTitle(strongestCoherenceWeek),
                        symbol: "waveform.path.ecg"
                    )
                }
            }
        }
    }

    private var balanceSection: some View {
        statsCard(title: "Equilibrio semanal", subtitle: "Una lectura amable de cómo se distribuyó la práctica.", symbol: "circle.hexagongrid.fill", color: .teal) {
            VStack(alignment: .leading, spacing: 12) {
                if let latest = displayedRecords.last {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.grid.cross.fill")
                            .font(.title2)
                            .foregroundStyle(.teal)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(balanceLabel(for: latest))
                                .font(.headline)
                            Text(L10n.format("weekly_review.stats.last_review", fallback: "Última revisión: {0}", weekTitle(latest)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    balanceChip("Metas", isActive: latestSnapshot.goalUnitsCompleted > 0)
                    balanceChip("Agenda", isActive: latestSnapshot.agendaCompleted > 0)
                    balanceChip("Diario", isActive: latestSnapshot.diaryActiveDays > 0)
                    balanceChip("Presencia", isActive: latestSnapshot.presenceReturns > 0)
                    balanceChip("Coherencia", isActive: latestSnapshot.coherenceMinutes > 0)
                    balanceChip("Ritual", isActive: latestSnapshot.ritualsCompleted > 0)
                }
            }
        }
    }

    private var insightsSection: some View {
        statsCard(title: "Lectura útil", subtitle: "Pistas para decidir el próximo foco.", symbol: "sparkles", color: .orange) {
            VStack(alignment: .leading, spacing: 9) {
                ForEach(insights, id: \.self) { insight in
                    Label(insight, systemImage: "lightbulb.fill")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var celebrationsSection: some View {
        statsCard(title: "Celebraciones recientes", subtitle: "Evidencias que ya reconociste en tus cierres.", symbol: "hands.sparkles.fill", color: .purple) {
            let celebrations = displayedRecords.reversed().compactMap { record -> String? in
                let text = record.celebration.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            }.prefix(5)

            if celebrations.isEmpty {
                Text(L10n.exact("Aún no hay celebraciones guardadas en el rango seleccionado."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(celebrations), id: \.self) { celebration in
                        Label(celebration, systemImage: "checkmark.seal.fill")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var moodsSection: some View {
        statsCard(title: "Estados predominantes", subtitle: "Lo que más se repite en diario y presencia.", symbol: "face.smiling", color: .pink) {
            let moods = moodFrequency.prefix(6)
            if moods.isEmpty {
                Text(L10n.exact("Todavía no hay estados emocionales suficientes para detectar patrones."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(moods), id: \.title) { mood in
                        HStack {
                            Text("\(mood.emoji) \(mood.title)")
                            Spacer()
                            Text("\(mood.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    private var focusSection: some View {
        statsCard(title: "Focos recientes", subtitle: "Lo que has elegido cuidar semana a semana.", symbol: "target", color: .green) {
            let focuses = records.reversed().compactMap { record -> String? in
                let focus = record.focus.trimmingCharacters(in: .whitespacesAndNewlines)
                return focus.isEmpty ? nil : focus
            }.prefix(5)

            if focuses.isEmpty {
                Text(L10n.exact("Aún no hay focos guardados en tus revisiones."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(focuses), id: \.self) { focus in
                        Label(focus, systemImage: "arrow.forward.circle.fill")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var insights: [String] {
        var result: [String] = []
        let recentDiary = average(\.snapshot.diaryActiveDays, in: recentRecords)
        let previousDiary = average(\.snapshot.diaryActiveDays, in: previousRecords)
        let recentPresence = average(\.snapshot.presenceReturns, in: recentRecords)
        let previousPresence = average(\.snapshot.presenceReturns, in: previousRecords)
        let recentCoherence = average(\.snapshot.coherenceMinutes, in: recentRecords)
        let previousCoherence = average(\.snapshot.coherenceMinutes, in: previousRecords)
        let stagnantWeeks = recentRecords.filter { !$0.snapshot.stagnantGoalTitles.isEmpty }.count

        if !previousRecords.isEmpty {
            result.append(trendText(title: "Diario", current: recentDiary, previous: previousDiary))
            result.append(trendText(title: "Presencia", current: recentPresence, previous: previousPresence))
            result.append(trendText(title: "Coherencia", current: recentCoherence, previous: previousCoherence))
        }

        if stagnantWeeks > max(1, recentRecords.count / 3) {
            result.append(L10n.format(
                "weekly_review.stats.insight_stagnant_goals",
                fallback: "Las metas aparecen estancadas en {0} de las últimas {1} revisiones; conviene elegir una acción muy pequeña.",
                "\(stagnantWeeks)",
                "\(recentRecords.count)"
            ))
        } else if !recentRecords.isEmpty {
            result.append(L10n.exact("Las metas no muestran un patrón fuerte de estancamiento reciente."))
        }

        if let mood = moodFrequency.first {
            result.append(L10n.format(
                "weekly_review.stats.insight_mood",
                fallback: "El estado más repetido ha sido {0} {1}. Úsalo como señal, no como etiqueta fija.",
                mood.emoji,
                mood.title.lowercased()
            ))
        }

        if result.isEmpty {
            result.append(L10n.exact("Cierra algunas revisiones más para generar lecturas comparativas."))
        }

        return Array(result.prefix(5))
    }

    private var nextBestAction: String {
        let recentDiary = average(\.snapshot.diaryActiveDays, in: recentRecords)
        let previousDiary = average(\.snapshot.diaryActiveDays, in: previousRecords)
        let recentPresence = average(\.snapshot.presenceReturns, in: recentRecords)
        let previousPresence = average(\.snapshot.presenceReturns, in: previousRecords)
        let recentCoherence = average(\.snapshot.coherenceMinutes, in: recentRecords)
        let previousCoherence = average(\.snapshot.coherenceMinutes, in: previousRecords)
        let stagnantWeeks = recentRecords.filter { !$0.snapshot.stagnantGoalTitles.isEmpty }.count

        if stagnantWeeks > max(1, recentRecords.count / 3) {
            return L10n.exact("Elige una sola meta y completa una unidad mínima esta semana. Menos ambición, más evidencia.")
        }

        if !previousRecords.isEmpty, recentDiary + 0.2 < previousDiary {
            return L10n.exact("Tu diario bajó respecto al bloque anterior. Programa 2 entradas breves de 3 minutos.")
        }

        if !previousRecords.isEmpty, recentPresence + 0.2 < previousPresence {
            return L10n.exact("La presencia bajó. Prueba 1 retorno consciente al día, aunque sea de 10 segundos.")
        }

        if !previousRecords.isEmpty, recentCoherence + 1 < previousCoherence {
            return L10n.exact("La coherencia bajó. Haz una sesión de 5 minutos después del ritual o antes de dormir.")
        }

        if latestSnapshot.ritualsCompleted == 0 {
            return L10n.exact("Añade un ritual sencillo esta semana: intención, una emoción elegida y una respuesta consciente.")
        }

        if latestRecord?.celebration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return L10n.exact("Mantén lo que ya funcionó y repite la práctica más fácil de sostener esta semana.")
        }

        return L10n.exact("Cierra la próxima semana con una celebración concreta y un foco pequeño. Eso hará más útil tu historial.")
    }

    private var savedReviewsSummary: String {
        if records.count == 1 {
            return L10n.exact("1 revisión guardada")
        }
        return L10n.format(
            "weekly_review.stats.saved_reviews",
            fallback: "{0} revisiones guardadas",
            "\(records.count)"
        )
    }

    private var bestPracticeWeek: WeeklyReviewHistoryRecord? {
        displayedRecords.max { balanceScore(for: $0) < balanceScore(for: $1) }
    }

    private var strongestPresenceWeek: WeeklyReviewHistoryRecord? {
        displayedRecords.max { $0.snapshot.presenceReturns < $1.snapshot.presenceReturns }
    }

    private var strongestCoherenceWeek: WeeklyReviewHistoryRecord? {
        displayedRecords.max { $0.snapshot.coherenceMinutes < $1.snapshot.coherenceMinutes }
    }

    private var latestSnapshot: WeeklyReviewSnapshot {
        displayedRecords.last?.snapshot ?? .empty
    }

    private var latestRecord: WeeklyReviewHistoryRecord? {
        displayedRecords.last
    }

    private var moodFrequency: [(title: String, emoji: String, count: Int)] {
        let grouped = records
            .flatMap(\.snapshot.moodSummaries)
            .reduce(into: [String: (emoji: String, count: Int)]()) { partial, mood in
                let existing = partial[mood.title] ?? (mood.emoji, 0)
                partial[mood.title] = (existing.emoji, existing.count + mood.count)
            }

        return grouped
            .map { key, value in (title: key, emoji: value.emoji, count: value.count) }
            .sorted { $0.count == $1.count ? $0.title < $1.title : $0.count > $1.count }
    }

    private func reload() {
        records = WeeklyReviewHistoryLoader(context: statsContext).load()
    }

    private func statCard(title: String, value: String, caption: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.exact(title), systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(L10n.exact(caption))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func highlightRow(title: String, value: String, caption: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(.yellow)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.headline)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func balanceChip(_ title: String, isActive: Bool) -> some View {
        Label(L10n.exact(title), systemImage: isActive ? "checkmark.circle.fill" : "circle")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isActive ? .green : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.primary.opacity(isActive ? 0.075 : 0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func statsCard<Content: View>(
        title: String,
        subtitle: String,
        symbol: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.exact(title), systemImage: symbol)
                .font(.title3.bold())
                .foregroundStyle(color)

            Text(L10n.exact(subtitle))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        }
    }

    private func trendRow(title: String, value: Int, maxValue: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                let fraction = CGFloat(value) / CGFloat(max(maxValue, 1))
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.primary.opacity(0.08))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.indigo.gradient)
                            .frame(width: max(8, proxy.size.width * min(max(fraction, 0), 1)))
                    }
            }
            .frame(height: 10)
        }
    }

    private func trendText(title: String, current: Double, previous: Double) -> String {
        let delta = current - previous
        if abs(delta) < 0.2 {
            return L10n.format(
                "weekly_review.stats.trend_stable",
                fallback: "{0} se mantiene estable respecto al bloque anterior.",
                L10n.exact(title)
            )
        }
        if delta > 0 {
            return L10n.format(
                "weekly_review.stats.trend_up",
                fallback: "{0} va en aumento respecto a tus revisiones anteriores.",
                L10n.exact(title)
            )
        }
        return L10n.format(
            "weekly_review.stats.trend_down",
            fallback: "{0} bajó respecto al bloque anterior; puede ser buen foco para la próxima semana.",
            L10n.exact(title)
        )
    }

    private func balanceScore(for record: WeeklyReviewHistoryRecord) -> Int {
        var score = 0
        let snapshot = record.snapshot
        if snapshot.goalUnitsCompleted > 0 { score += 1 }
        if snapshot.agendaCompleted > 0 { score += 1 }
        if snapshot.diaryActiveDays > 0 { score += 1 }
        if snapshot.presenceReturns > 0 { score += 1 }
        if snapshot.coherenceMinutes > 0 { score += 1 }
        if snapshot.ritualsCompleted > 0 { score += 1 }
        return score
    }

    private func balanceLabel(for record: WeeklyReviewHistoryRecord) -> String {
        let snapshot = record.snapshot
        let score = balanceScore(for: record)

        if score >= 5 { return L10n.exact("Semana integrada") }
        if snapshot.goalUnitsCompleted > 0 && snapshot.agendaCompleted > 0 { return L10n.exact("Semana de acción") }
        if snapshot.diaryActiveDays > 0 && snapshot.presenceReturns > 0 { return L10n.exact("Semana de presencia interior") }
        if snapshot.coherenceMinutes > 0 || snapshot.ritualsCompleted > 0 { return L10n.exact("Semana de regulación") }
        if score > 0 { return L10n.exact("Semana de continuidad") }
        return L10n.exact("Semana de recuperación")
    }

    private func countText(_ count: Int, singularKey: String, pluralKey: String) -> String {
        let key = count == 1 ? singularKey : pluralKey
        return L10n.format(
            "weekly_review.stats.count_value",
            fallback: "{0} {1}",
            "\(count)",
            L10n.exact(key)
        )
    }

    private func weekTitle(_ record: WeeklyReviewHistoryRecord) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.dateFormat = "d MMM"
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: record.periodEnd) ?? record.periodEnd
        return "\(formatter.string(from: record.periodStart)) – \(formatter.string(from: lastDay))"
    }

    private func average(_ keyPath: KeyPath<WeeklyReviewHistoryRecord, Int>, in records: [WeeklyReviewHistoryRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.reduce(0) { $0 + $1[keyPath: keyPath] }) / Double(records.count)
    }

    private func formattedAverage(_ keyPath: KeyPath<WeeklyReviewHistoryRecord, Int>, in records: [WeeklyReviewHistoryRecord]) -> String {
        String(format: "%.1f", average(keyPath, in: records))
    }

    private func sum(_ keyPath: KeyPath<WeeklyReviewHistoryRecord, Int>, in records: [WeeklyReviewHistoryRecord]) -> Int {
        records.reduce(0) { $0 + $1[keyPath: keyPath] }
    }

    private func maxSum(_ keyPath: KeyPath<WeeklyReviewHistoryRecord, Int>) -> Int {
        let window = max(recentRecords.count, 1)
        let chunks = stride(from: 0, to: records.count, by: window).map { start -> Int in
            let end = min(start + window, records.count)
            return sum(keyPath, in: Array(records[start..<end]))
        }
        return chunks.max() ?? 1
    }
}

private enum WeeklyReviewStatsRange: String, CaseIterable, Identifiable {
    case fourWeeks
    case twelveWeeks
    case twentyFourWeeks
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fourWeeks: return "4 semanas"
        case .twelveWeeks: return "12 semanas"
        case .twentyFourWeeks: return "24 semanas"
        case .all: return "Todo"
        }
    }

    var recordLimit: Int? {
        switch self {
        case .fourWeeks: return 4
        case .twelveWeeks: return 12
        case .twentyFourWeeks: return 24
        case .all: return nil
        }
    }

    func records(from allRecords: [WeeklyReviewHistoryRecord]) -> [WeeklyReviewHistoryRecord] {
        guard let recordLimit else { return allRecords }
        return Array(allRecords.suffix(recordLimit))
    }
}

private struct WeeklyReviewHistoryRecord: Identifiable {
    let id: UUID
    let periodStart: Date
    let periodEnd: Date
    let completedAt: Date
    let focus: String
    let celebration: String
    let snapshot: WeeklyReviewSnapshot
}

@MainActor
private struct WeeklyReviewHistoryLoader {
    private static let entityName = "WeeklyReviewEntity"

    let context: NSManagedObjectContext

    func load() -> [WeeklyReviewHistoryRecord] {
        guard let coordinator = context.persistentStoreCoordinator,
              !coordinator.persistentStores.isEmpty,
              coordinator.managedObjectModel.entitiesByName[Self.entityName] != nil else {
            return []
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "periodEnd", ascending: true)]

        return ((try? context.fetch(request)) ?? []).compactMap(record(from:))
    }

    private func record(from object: NSManagedObject) -> WeeklyReviewHistoryRecord? {
        guard let periodStart = object.value(forKey: "periodStart") as? Date,
              let periodEnd = object.value(forKey: "periodEnd") as? Date else {
            return nil
        }

        return WeeklyReviewHistoryRecord(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            periodStart: periodStart,
            periodEnd: periodEnd,
            completedAt: object.value(forKey: "completedAt") as? Date ?? periodEnd,
            focus: object.value(forKey: "focus") as? String ?? "",
            celebration: object.value(forKey: "celebration") as? String ?? "",
            snapshot: decodedSnapshot(from: object.value(forKey: "snapshotJSON") as? String)
        )
    }

    private func decodedSnapshot(from json: String?) -> WeeklyReviewSnapshot {
        guard let json,
              let data = json.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode(WeeklyReviewSnapshot.self, from: data) else {
            return .empty
        }

        return snapshot
    }
}

private struct WeeklyReviewSnapshot: Codable {
    var goalUnitsCompleted = 0
    var stagnantGoalTitles: [String] = []
    var agendaCompleted = 0
    var agendaPending = 0
    var diaryEntries = 0
    var diaryActiveDays = 0
    var presenceReturns = 0
    var automaticPilotEvents = 0
    var coherenceSessions = 0
    var coherenceMinutes = 0
    var coherenceDelta = 0.0
    var ritualsCompleted = 0
    var moodSummaries: [WeeklyReviewMood] = []
    var achievements: [String] = []

    static let empty = WeeklyReviewSnapshot()

    var agendaTotal: Int { agendaCompleted + agendaPending }
}

private struct WeeklyReviewMood: Codable {
    let title: String
    let emoji: String
    let count: Int
}

private struct WeeklyReviewRecord {
    let focus: String
    let celebration: String
}

@MainActor
private struct WeeklyReviewStore {
    private static let entityName = "WeeklyReviewEntity"

    let context: NSManagedObjectContext

    var isAvailable: Bool {
        isReady
    }

    func review(for periodKey: String) -> WeeklyReviewRecord? {
        guard let object = reviewObject(for: periodKey) else { return nil }
        return WeeklyReviewRecord(
            focus: object.value(forKey: "focus") as? String ?? "",
            celebration: object.value(forKey: "celebration") as? String ?? ""
        )
    }

    func save(
        periodKey: String,
        interval: DateInterval,
        focus: String,
        celebration: String,
        snapshot: WeeklyReviewSnapshot
    ) -> Bool {
        guard isReady else { return false }

        let object = reviewObject(for: periodKey)
            ?? NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context)
        if object.value(forKey: "id") == nil {
            object.setValue(UUID(), forKey: "id")
        }

        object.setValue(periodKey, forKey: "periodKey")
        object.setValue(interval.start, forKey: "periodStart")
        object.setValue(interval.end, forKey: "periodEnd")
        object.setValue(Date(), forKey: "completedAt")
        object.setValue(focus, forKey: "focus")
        object.setValue(celebration, forKey: "celebration")
        object.setValue(encodedSnapshot(snapshot), forKey: "snapshotJSON")

        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    private var isReady: Bool {
        guard let coordinator = context.persistentStoreCoordinator else { return false }
        return !coordinator.persistentStores.isEmpty
            && coordinator.managedObjectModel.entitiesByName[Self.entityName] != nil
    }

    private func reviewObject(for periodKey: String) -> NSManagedObject? {
        guard isReady else { return nil }

        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.predicate = NSPredicate(format: "periodKey == %@", periodKey)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func encodedSnapshot(_ snapshot: WeeklyReviewSnapshot) -> String {
        guard let data = try? JSONEncoder().encode(snapshot) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}

enum WeeklyReviewRetentionPolicy {
    static let defaultRecordsToKeep = 30
    static let minimumRecordsToKeep = 5
    static let maximumRecordsToKeep = 100
    static let recordStep = 5
    private static let entityName = "WeeklyReviewEntity"

    @MainActor
    static func deleteOldRecords(context: NSManagedObjectContext, keeping keepLatest: Int = defaultRecordsToKeep) throws -> Int {
        guard let coordinator = context.persistentStoreCoordinator,
              !coordinator.persistentStores.isEmpty,
              coordinator.managedObjectModel.entitiesByName[entityName] != nil else {
            throw WeeklyReviewRetentionError.storeUnavailable
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.sortDescriptors = [
            NSSortDescriptor(key: "periodEnd", ascending: false),
            NSSortDescriptor(key: "completedAt", ascending: false)
        ]

        let records = try context.fetch(request)
        let recordsToDelete = records.dropFirst(normalizedRecordsToKeep(keepLatest))
        guard !recordsToDelete.isEmpty else { return 0 }

        recordsToDelete.forEach(context.delete)
        try context.save()
        return recordsToDelete.count
    }

    static func normalizedRecordsToKeep(_ value: Int) -> Int {
        let clamped = min(max(value, minimumRecordsToKeep), maximumRecordsToKeep)
        return (clamped / recordStep) * recordStep
    }
}

nonisolated private enum WeeklyReviewRetentionError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        L10n.exact("El almacenamiento de la revisión semanal no está disponible todavía.")
    }
}

@MainActor
private struct WeeklyReviewDataLoader {
    let context: NSManagedObjectContext
    private let calendar = Calendar.current

    func load(interval: DateInterval) -> WeeklyReviewSnapshot {
        var snapshot = WeeklyReviewSnapshot()
        guard let coordinator = context.persistentStoreCoordinator,
              !coordinator.persistentStores.isEmpty else {
            return snapshot
        }

        let start = interval.start
        let end = interval.end

        let goalEvents = fetch("GoalStatsEventEntity", predicate: datePredicate(key: "createdAt", interval: interval))
        let completedGoalEvents = goalEvents.filter {
            ($0.value(forKey: "eventType") as? String) == GoalStatsEventType.unitCompleted.rawValue
        }
        snapshot.goalUnitsCompleted = completedGoalEvents.count

        let activeGoals: [GoalEntity] = (try? context.fetch(GoalEntity.fetchRequest()))?.filter {
            $0.isStarted && !$0.isCompleted
        } ?? []
        snapshot.stagnantGoalTitles = activeGoals.compactMap { goal in
            let startedBeforeThisWeek = (goal.startDate ?? .distantFuture) < end
            let hasProgressThisWeek = goal.unitsArray.contains {
                guard let completedDate = $0.completedDate else { return false }
                return interval.contains(completedDate)
            }
            return startedBeforeThisWeek && !hasProgressThisWeek ? goal.wrappedTitle : nil
        }

        let agendaRows = fetch("AgendaItemEntity", predicate: datePredicate(key: "fechaActividad", interval: interval))
        snapshot.agendaCompleted = agendaRows.filter { ($0.value(forKey: "completada") as? Bool) == true }.count
        snapshot.agendaPending = agendaRows.count - snapshot.agendaCompleted
        let agendaAchievements = agendaRows
            .filter { ($0.value(forKey: "completada") as? Bool) == true }
            .compactMap { ($0.value(forKey: "titulo") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let diaryRows = fetch("Diario", predicate: datePredicate(key: "fecha", interval: interval))
        snapshot.diaryEntries = diaryRows.count
        snapshot.diaryActiveDays = Set(diaryRows.compactMap { ($0.value(forKey: "fecha") as? Date).map(calendar.startOfDay(for:)) }).count
        let diaryMoodCounts = Dictionary(grouping: diaryRows.compactMap { $0.value(forKey: "emotion") as? String }, by: { $0 })
            .map { ($0.key, $0.value.count) }

        let presenceRows = fetch("PresenciaEventEntity", predicate: datePredicate(key: "createdAt", interval: interval))
        snapshot.presenceReturns = presenceRows.filter { ($0.value(forKey: "eventType") as? String) == PresenciaEventType.presente.rawValue }.count
        snapshot.automaticPilotEvents = presenceRows.filter {
            let mood = $0.value(forKey: "mood") as? String
            return mood == "pilotoAutomatico" || mood == "distraido"
        }.count
        let presenceMoodCounts = Dictionary(grouping: presenceRows.compactMap { $0.value(forKey: "mood") as? String }, by: { $0 })
            .map { ($0.key, $0.value.count) }

        let mergedMoods = Dictionary(diaryMoodCounts + presenceMoodCounts, uniquingKeysWith: +)
        snapshot.moodSummaries = mergedMoods
            .map { raw, count in
                let presenceTitle = PresenciaMood.title(for: raw)
                let title = presenceTitle == raw ? Emociones.localizedTitle(from: raw) : presenceTitle
                return WeeklyReviewMood(title: title, emoji: Emociones.emoji(from: raw), count: count)
            }
            .sorted { $0.count == $1.count ? $0.title < $1.title : $0.count > $1.count }

        let epochStart = Int64(start.timeIntervalSince1970 * 1000)
        let epochEnd = Int64(end.timeIntervalSince1970 * 1000)
        let coherenceRows = fetch(
            "coherencia",
            predicate: NSPredicate(format: "dateEpochMillis >= %lld AND dateEpochMillis < %lld", epochStart, epochEnd)
        )
        snapshot.coherenceSessions = coherenceRows.count
        snapshot.coherenceMinutes = coherenceRows.reduce(0) { $0 + Int($1.value(forKey: "durationMinutes") as? Int16 ?? 0) }
        if !coherenceRows.isEmpty {
            snapshot.coherenceDelta = coherenceRows.reduce(0.0) { total, row in
                total + Double((row.value(forKey: "afterScore") as? Int16 ?? 0) - (row.value(forKey: "beforeScore") as? Int16 ?? 0))
            } / Double(coherenceRows.count)
        }

        let rituals = fetch(
            "RitualSessionEntity",
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                datePredicate(key: "createdAt", interval: interval),
                NSPredicate(format: "completed == YES")
            ])
        )
        snapshot.ritualsCompleted = rituals.count

        var achievements = completedGoalEvents
            .compactMap { ($0.value(forKey: "goalTitle") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { L10n.format("weekly.achievement.goal", fallback: "Avanzaste en {0}", $0) }
        achievements += agendaAchievements.map { L10n.format("weekly.achievement.agenda", fallback: "Completaste {0}", $0) }
        if snapshot.diaryEntries > 0 {
            achievements.append(L10n.format(
                snapshot.diaryEntries == 1 ? "weekly.achievement.diary.one" : "weekly.achievement.diary.other",
                fallback: snapshot.diaryEntries == 1 ? "Escribiste {0} entrada en tu diario" : "Escribiste {0} entradas en tu diario",
                String(snapshot.diaryEntries)
            ))
        }
        if snapshot.presenceReturns > 0 {
            achievements.append(L10n.format(
                snapshot.presenceReturns == 1 ? "weekly.achievement.presence.one" : "weekly.achievement.presence.other",
                fallback: snapshot.presenceReturns == 1 ? "Volviste {0} vez a la presencia" : "Volviste {0} veces a la presencia",
                String(snapshot.presenceReturns)
            ))
        }
        if snapshot.coherenceSessions > 0 {
            if snapshot.coherenceMinutes > 0 {
                achievements.append(L10n.format(
                    "weekly.achievement.coherence.timed",
                    fallback: "Practicaste {0} sesiones de coherencia durante {1} minutos",
                    String(snapshot.coherenceSessions), String(snapshot.coherenceMinutes)
                ))
            } else {
                achievements.append(L10n.format(
                    snapshot.coherenceSessions == 1 ? "weekly.achievement.coherence.one" : "weekly.achievement.coherence.other",
                    fallback: snapshot.coherenceSessions == 1 ? "Practicaste {0} sesión de coherencia" : "Practicaste {0} sesiones de coherencia",
                    String(snapshot.coherenceSessions)
                ))
            }
        }
        if snapshot.ritualsCompleted > 0 {
            achievements.append(L10n.format(
                snapshot.ritualsCompleted == 1 ? "weekly.achievement.ritual.one" : "weekly.achievement.ritual.other",
                fallback: snapshot.ritualsCompleted == 1 ? "Completaste {0} ritual consciente" : "Completaste {0} rituales conscientes",
                String(snapshot.ritualsCompleted)
            ))
        }
        snapshot.achievements = Array(NSOrderedSet(array: achievements)) as? [String] ?? achievements

        return snapshot
    }

    private func fetch(_ entityName: String, predicate: NSPredicate? = nil) -> [NSManagedObject] {
        guard let coordinator = context.persistentStoreCoordinator,
              !coordinator.persistentStores.isEmpty,
              coordinator.managedObjectModel.entitiesByName[entityName] != nil else {
            return []
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate
        return (try? context.fetch(request)) ?? []
    }

    private func datePredicate(key: String, interval: DateInterval) -> NSPredicate {
        NSPredicate(format: "%K >= %@ AND %K < %@", key, interval.start as NSDate, key, interval.end as NSDate)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var size = CGSize.zero
        var lineHeight: CGFloat = 0
        var x: CGFloat = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if x + subviewSize.width > maxWidth, x > 0 {
                size.width = max(size.width, x - spacing)
                size.height += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
        }

        size.width = max(size.width, x > 0 ? x - spacing : 0)
        size.height += lineHeight
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
