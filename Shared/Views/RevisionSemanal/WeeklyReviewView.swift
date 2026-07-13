import SwiftUI
import CoreData
import UserNotifications

/// Día en el que se pone a disposición la revisión. Los valores coinciden con
/// `Calendar.Component.weekday` (1 = domingo).
enum WeeklyReviewDay: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunday: return "Domingo"
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        case .saturday: return "Sábado"
        }
    }
}

enum WeeklyReviewSchedule {
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

enum WeeklyReviewNotificationManager {
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
        content.title = "Tu revisión semanal está lista"
        content.body = "Dedica 5–10 minutos a reconocer tus avances y elegir tu foco."
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

    private var periodTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
            reload()
        }
        .alert("No se pudo guardar la revisión", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "Inténtalo de nuevo cuando el almacenamiento esté disponible.")
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
                closeReview()
            } label: {
                Label(
                    isCurrentReviewCompleted ? "Revisión completada" : "Cerrar revisión semanal",
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
            Label(title, systemImage: symbol)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(subtitle)
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
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(subtitle)
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
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func positiveLine(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.green)
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func reload() {
        now = Date()
        snapshot = WeeklyReviewDataLoader(context: context).load(interval: interval)

        let store = WeeklyReviewStore(context: context)
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

    private func closeReview() {
        let trimmedFocus = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCelebration = celebration.trimmingCharacters(in: .whitespacesAndNewlines)
        let didSave = WeeklyReviewStore(context: context).save(
            periodKey: periodKey,
            interval: interval,
            focus: trimmedFocus,
            celebration: trimmedCelebration,
            snapshot: snapshot
        )

        guard didSave else {
            saveErrorMessage = "El almacenamiento todavía no está listo. Tu revisión no se ha marcado como completada; inténtalo de nuevo en unos segundos."
            return
        }

        savedCelebration = trimmedCelebration
        savedFocus = trimmedFocus
        completedPeriodKey = periodKey
    }

    private func loadClosingInputsIfNeeded(focus storedFocus: String, celebration storedCelebration: String) {
        guard closingInputsPeriodKey != periodKey else { return }
        closingInputsPeriodKey = periodKey
        focus = storedFocus
        celebration = storedCelebration
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

private enum WeeklyReviewRetentionError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        "El almacenamiento de la revisión semanal no está disponible todavía."
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
                let title = presenceTitle == raw ? raw.capitalized : presenceTitle
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
            .map { "Avanzaste en \($0)" }
        achievements += agendaAchievements.map { "Completaste \($0)" }
        if snapshot.diaryEntries > 0 { achievements.append("Escribiste \(snapshot.diaryEntries) entrada\(snapshot.diaryEntries == 1 ? "" : "s") en tu diario") }
        if snapshot.presenceReturns > 0 { achievements.append("Volviste \(snapshot.presenceReturns) vez\(snapshot.presenceReturns == 1 ? "" : "es") a la presencia") }
        if snapshot.coherenceSessions > 0 {
            let sessionText = "\(snapshot.coherenceSessions) sesión\(snapshot.coherenceSessions == 1 ? "" : "es")"
            if snapshot.coherenceMinutes > 0 {
                achievements.append("Practicaste \(sessionText) de coherencia durante \(snapshot.coherenceMinutes) minuto\(snapshot.coherenceMinutes == 1 ? "" : "s")")
            } else {
                achievements.append("Practicaste \(sessionText) de coherencia")
            }
        }
        if snapshot.ritualsCompleted > 0 {
            achievements.append("Completaste \(snapshot.ritualsCompleted) ritual\(snapshot.ritualsCompleted == 1 ? "" : "es") consciente\(snapshot.ritualsCompleted == 1 ? "" : "s")")
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
