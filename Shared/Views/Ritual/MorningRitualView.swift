import SwiftUI
import Combine
import UserNotifications
import CoreData

private enum RitualL10n {
    static func text(_ key: String, fallback: String) -> String {
        L10n.string(key, fallback: fallback)
    }

    static func exact(_ spanish: String) -> String {
        L10n.string(spanish, fallback: spanish)
    }

    static func format(_ key: String, fallback: String, _ values: String...) -> String {
        var result = text(key, fallback: fallback)
        for (index, value) in values.enumerated() {
            result = result.replacingOccurrences(of: "{\(index)}", with: value)
        }
        return result
    }

    static func localizedIdentityList(_ value: String) -> String {
        value
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { exact(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
            .joined(separator: ", ")
    }

    static func localizedEmotionList(_ values: [String]) -> String {
        values.map(exact).joined(separator: ", ")
    }

    static func localizedMood(_ id: String) -> String {
        exact(PresenciaMood.title(for: id))
    }

    static func localizedSuggestion(_ value: String) -> String {
        let prefix = "Mañana lee al despertar: «Hoy actúo como "
        let suffix = "», y conviértelo en un gesto visible durante la primera hora."
        if value.hasPrefix(prefix), value.hasSuffix(suffix) {
            let identity = String(value.dropFirst(prefix.count).dropLast(suffix.count))
            return format(
                "ritual.evening.identity_suggestion",
                fallback: "Mañana lee al despertar: «Hoy actúo como {0}», y conviértelo en un gesto visible durante la primera hora.",
                localizedIdentityList(identity)
            )
        }
        return exact(value)
    }

    static func formattedDate(_ date: Date, dateStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.dateStyle = dateStyle
        return formatter.string(from: date)
    }

    static func decimal(_ value: Double, fractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

enum RitualNavigationDestination: String, Identifiable {
    case eveningReview
    case wellbeingDashboard

    var id: String { rawValue }
}

@MainActor
final class RitualNavigationCoordinator: ObservableObject {
    static let shared = RitualNavigationCoordinator()
    @Published var destination: RitualNavigationDestination?

    private init() {}

    func open(_ destination: RitualNavigationDestination) {
        self.destination = destination
    }
}

private enum MorningRitualConstants {
    static let sessionsKey = "morning_ritual_sessions"
    static let settingsKey = "morning_ritual_settings"
    static let eveningReviewsKey = "evening_ritual_reviews"
    static let maxItems = 3
    static let maxGoals = 12

    // Conserva aproximadamente la cadencia original (10:00, 14:00 y 19:00
    // para un ritual terminado a las 08:00), pero la desplaza según la hora
    // real de finalización.
    static let dayReminderOffsetsInMinutes = [2 * 60, 6 * 60, 11 * 60]

    static func suggestedDayReminderTimes(
        after date: Date,
        calendar: Calendar = .current
    ) -> [Int] {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let completionMinute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let minutesPerDay = 24 * 60

        return dayReminderOffsetsInMinutes.map {
            (completionMinute + $0) % minutesPerDay
        }
    }
}

private struct MorningRitualSession: Codable, Identifiable, Equatable {
    let id: UUID
    let sessionDateEpochDay: Int
    let completedAtEpochMillis: Int64
    let goals: [String]
    let identity: String
    let emotions: [String]
    let anticipatedSituations: [String]
    let consciousResponses: [String]
    var noteText: String
    let completed: Bool

    init(
        id: UUID = UUID(),
        sessionDateEpochDay: Int,
        completedAtEpochMillis: Int64,
        goals: [String],
        identity: String,
        emotions: [String],
        anticipatedSituations: [String],
        consciousResponses: [String],
        noteText: String = "",
        completed: Bool = true
    ) {
        self.id = id
        self.sessionDateEpochDay = sessionDateEpochDay
        self.completedAtEpochMillis = completedAtEpochMillis
        self.goals = goals
        self.identity = identity
        self.emotions = emotions
        self.anticipatedSituations = anticipatedSituations
        self.consciousResponses = consciousResponses
        self.noteText = noteText
        self.completed = completed
    }
}

private struct MorningRitualSettings: Codable, Equatable {
    var enabled: Bool = false
    var hour: Int = 7
    var minute: Int = 30
    var eveningReminderEnabled: Bool = false
    var eveningReminderHour: Int = 21
    var eveningReminderMinute: Int = 30

    private enum CodingKeys: String, CodingKey {
        case enabled, hour, minute
        case eveningReminderEnabled, eveningReminderHour, eveningReminderMinute
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        hour = try container.decodeIfPresent(Int.self, forKey: .hour) ?? 7
        minute = try container.decodeIfPresent(Int.self, forKey: .minute) ?? 30
        eveningReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .eveningReminderEnabled) ?? false
        eveningReminderHour = try container.decodeIfPresent(Int.self, forKey: .eveningReminderHour) ?? 21
        eveningReminderMinute = try container.decodeIfPresent(Int.self, forKey: .eveningReminderMinute) ?? 30
    }
}

private struct EveningReview: Codable, Identifiable, Equatable {
    let id: UUID
    let sessionDateEpochDay: Int
    let completedAtEpochMillis: Int64
    let energy: Int
    let predominantEmotionID: String
    let whatWentWell: String
    let learning: String
    let autopilotMoment: String
    let gratitude: String
    let tomorrowPreparation: String
    let identityAlignment: Int
    let suggestion: String
    let agendaCompletedCount: Int
    let agendaTotalCount: Int
    let goalUnitsCompletedCount: Int
    let presenceReturns: Int
    let automaticPilotEvents: Int
    let coherenceSessionsCount: Int
    let journalEntryRequested: Bool?
    let journalEntryCreated: Bool
    let journalEntryID: UUID?
}

@MainActor
struct EveningDaySnapshot {
    let agendaCompleted: [AgendaItemData]
    let agendaTotalCount: Int
    let completedGoalUnits: [(goalTitle: String, unitName: String)]
    let presenceReturns: Int
    let automaticPilotEvents: Int
    let coherenceSessionsCount: Int
    let coherenceAverageAfterScore: Int?

    static func load(for date: Date = Date()) -> EveningDaySnapshot {
        let calendar = Calendar.current
        let agenda = AgendaRepository().fetchAll().filter {
            calendar.isDate($0.fechaActividad, inSameDayAs: date)
        }
        let agendaCompleted = agenda.filter { $0.completada == true }

        let context = CoreDataController.shared.context
        let goalRequest: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        let goals = (try? context.fetch(goalRequest)) ?? []
        var completedGoalUnits: [(goalTitle: String, unitName: String)] = []
        for goal in goals {
            for unit in goal.unitsArray {
                guard let completedDate = unit.completedDate,
                      calendar.isDate(completedDate, inSameDayAs: date) else { continue }
                completedGoalUnits.append((
                    goalTitle: goal.wrappedTitle,
                    unitName: unit.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? RitualL10n.exact("Unidad completada")
                ))
            }
        }

        let presence = PresenciaRepository().eventPoints(on: date)
        let coherenceRequest = NSFetchRequest<NSManagedObject>(entityName: "coherencia")
        let coherenceRows = ((try? context.fetch(coherenceRequest)) ?? []).filter { row in
            let milliseconds = row.value(forKey: "dateEpochMillis") as? Int64 ?? 0
            return milliseconds > 0 && calendar.isDate(
                Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000),
                inSameDayAs: date
            )
        }
        let scores = coherenceRows.compactMap { row -> Int? in
            let score = Int(row.value(forKey: "afterScore") as? Int16 ?? 0)
            return score > 0 ? score : nil
        }

        return EveningDaySnapshot(
            agendaCompleted: agendaCompleted,
            agendaTotalCount: agenda.count,
            completedGoalUnits: completedGoalUnits,
            presenceReturns: presence.filter(\.isPresentReturn).count,
            automaticPilotEvents: presence.filter(\.isAutomaticPilot).count,
            coherenceSessionsCount: coherenceRows.count,
            coherenceAverageAfterScore: scores.isEmpty ? nil : Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
        )
    }
}

private struct TriggerResponseInput: Equatable {
    var trigger: String = ""
    var response: String = ""
}

private struct MorningRitualDraft: Equatable {
    let goals: [String]
    let identityValues: [String]
    let emotionValues: [String]
    let triggers: [String]
    let responses: [String]
    let noteText: String
    let dayRemindersEnabled: Bool
    let dayReminderTimes: [Int]
}

private struct MorningRitualFlowState {
    var step: Int = 1
    var goals: [String] = [""]
    var identities: [String] = []
    var customIdentity: String = ""
    var emotions: [String] = []
    var customEmotion: String = ""
    var triggerResponses: [TriggerResponseInput] = [TriggerResponseInput()]
    var dayRemindersEnabled: Bool = true
    var dayReminderTimes: [Int] = []
    var ritualNote: String = ""
    var validationMessage: String?
    var isCompleted: Bool = false
}

@MainActor
private final class MorningRitualStore: ObservableObject {
    @Published private(set) var sessions: [MorningRitualSession] = []
    @Published private(set) var settings: MorningRitualSettings = .init()
    @Published private(set) var eveningReviews: [EveningReview] = []

    private let sharedDefaults: UserDefaults?
    private let standardDefaults: UserDefaults
    private let ritualEntityName = "RitualSessionEntity"
    private let coreDataMigrationKey = "morning_ritual_coredata_migration_v1"
    private var observers = Set<AnyCancellable>()

    init() {
        self.sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        self.standardDefaults = .standard
        NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.loadAll() }
            .store(in: &observers)
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange,
            object: CoreDataController.shared.persistentContainer.persistentStoreCoordinator
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            CoreDataController.shared.context.refreshAllObjects()
            self?.loadAll()
        }
        .store(in: &observers)
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: CoreDataController.shared.context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.loadAll() }
            .store(in: &observers)
        self.loadAll()
    }

    var todayCompleted: Bool {
        let today = epochDay(for: Date())
        return sessions.contains { $0.completed && $0.sessionDateEpochDay == today }
    }

    var todayReview: EveningReview? {
        review(for: Date())
    }

    func review(for date: Date) -> EveningReview? {
        eveningReviews.first { $0.sessionDateEpochDay == epochDay(for: date) }
    }

    func session(for date: Date = Date()) -> MorningRitualSession? {
        sessions.first { $0.sessionDateEpochDay == epochDay(for: date) }
    }

    func saveSession(_ session: MorningRitualSession) {
        sessions.removeAll { $0.sessionDateEpochDay == session.sessionDateEpochDay }
        sessions.insert(session, at: 0)
        persistSessions()
    }

    func updateNote(sessionId: UUID, noteText: String) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[idx].noteText = noteText
        persistSessions()
    }

    func deleteSession(sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        deleteStoredSession(id: sessionId)
    }

    func deleteEveningReview(reviewId: UUID) {
        eveningReviews.removeAll { $0.id == reviewId }
        deleteStoredSession(id: reviewId)
    }

    func saveEveningReview(_ review: EveningReview) {
        eveningReviews.removeAll { $0.sessionDateEpochDay == review.sessionDateEpochDay }
        eveningReviews.insert(review, at: 0)
        persistEveningReviews()
    }

    func applySettings(
        enabled: Bool,
        hour: Int,
        minute: Int,
        eveningReminderEnabled: Bool,
        eveningReminderHour: Int,
        eveningReminderMinute: Int
    ) {
        settings.enabled = enabled
        settings.hour = max(0, min(23, hour))
        settings.minute = max(0, min(59, minute))
        settings.eveningReminderEnabled = eveningReminderEnabled
        settings.eveningReminderHour = max(0, min(23, eveningReminderHour))
        settings.eveningReminderMinute = max(0, min(59, eveningReminderMinute))
        persistSettings()

        Task {
            await MorningRitualNotificationManager.shared.scheduleDailyReminder(settings: settings)
            await MorningRitualNotificationManager.shared.scheduleEveningReminder(settings: settings)
        }
    }

    func scheduleDayReminders(minutesOfDay: [Int], enabled: Bool) {
        Task {
            await MorningRitualNotificationManager.shared.scheduleDayReminders(
                minutesOfDay: enabled ? minutesOfDay : []
            )
        }
    }

    func reload() {
        loadAll()
    }

    private func loadAll() {
        migrateLegacyRitualDataIfNeeded()
        sessions = loadMorningSessionsFromCoreData()
        eveningReviews = loadEveningReviewsFromCoreData()

        let sharedSettings = decodeSettings(from: sharedDefaults)
        let standardSettings = decodeSettings(from: standardDefaults)
        settings = sharedSettings ?? standardSettings ?? .init()

        mirrorSettingsAcrossContainers()
    }

    private func persistSessions() {
        sessions.sort { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
        sessions.forEach(upsertMorningSession)
        saveRitualContext()
    }

    private func persistSettings() {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.settingsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.settingsKey)
    }

    private func persistEveningReviews() {
        eveningReviews.sort { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
        eveningReviews.forEach(upsertEveningReview)
        saveRitualContext()
    }

    private func migrateLegacyRitualDataIfNeeded() {
        guard !standardDefaults.bool(forKey: coreDataMigrationKey) else { return }
        guard !CoreDataController.shared.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else { return }

        let legacySessions = mergeSessions(
            decodeSessions(from: sharedDefaults),
            decodeSessions(from: standardDefaults)
        )
        let legacyReviews = mergeEveningReviews(
            decodeEveningReviews(from: sharedDefaults),
            decodeEveningReviews(from: standardDefaults)
        )

        legacySessions.forEach(upsertMorningSession)
        legacyReviews.forEach(upsertEveningReview)
        saveRitualContext()
        standardDefaults.set(true, forKey: coreDataMigrationKey)
    }

    private func loadMorningSessionsFromCoreData() -> [MorningRitualSession] {
        fetchStoredRows(kind: "morning").compactMap { row in
            guard let id = row.value(forKey: "id") as? UUID else { return nil }
            return MorningRitualSession(
                id: id,
                sessionDateEpochDay: Int(row.value(forKey: "sessionDateEpochDay") as? Int64 ?? 0),
                completedAtEpochMillis: row.value(forKey: "completedAtEpochMillis") as? Int64 ?? 0,
                goals: decodeStringArray(row.value(forKey: "goalsJSON") as? String),
                identity: row.value(forKey: "identity") as? String ?? "",
                emotions: decodeStringArray(row.value(forKey: "emotionsJSON") as? String),
                anticipatedSituations: decodeStringArray(row.value(forKey: "anticipatedSituationsJSON") as? String),
                consciousResponses: decodeStringArray(row.value(forKey: "consciousResponsesJSON") as? String),
                noteText: row.value(forKey: "noteText") as? String ?? "",
                completed: row.value(forKey: "completed") as? Bool ?? true
            )
        }
        .sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
    }

    private func loadEveningReviewsFromCoreData() -> [EveningReview] {
        fetchStoredRows(kind: "evening").compactMap { row in
            guard let id = row.value(forKey: "id") as? UUID else { return nil }
            return EveningReview(
                id: id,
                sessionDateEpochDay: Int(row.value(forKey: "sessionDateEpochDay") as? Int64 ?? 0),
                completedAtEpochMillis: row.value(forKey: "completedAtEpochMillis") as? Int64 ?? 0,
                energy: Int(row.value(forKey: "energy") as? Int16 ?? 0),
                predominantEmotionID: row.value(forKey: "predominantEmotionID") as? String ?? "",
                whatWentWell: row.value(forKey: "whatWentWell") as? String ?? "",
                learning: row.value(forKey: "learning") as? String ?? "",
                autopilotMoment: row.value(forKey: "autopilotMoment") as? String ?? "",
                gratitude: row.value(forKey: "gratitude") as? String ?? "",
                tomorrowPreparation: row.value(forKey: "tomorrowPreparation") as? String ?? "",
                identityAlignment: Int(row.value(forKey: "identityAlignment") as? Int16 ?? 0),
                suggestion: row.value(forKey: "suggestion") as? String ?? "",
                agendaCompletedCount: Int(row.value(forKey: "agendaCompletedCount") as? Int32 ?? 0),
                agendaTotalCount: Int(row.value(forKey: "agendaTotalCount") as? Int32 ?? 0),
                goalUnitsCompletedCount: Int(row.value(forKey: "goalUnitsCompletedCount") as? Int32 ?? 0),
                presenceReturns: Int(row.value(forKey: "presenceReturns") as? Int32 ?? 0),
                automaticPilotEvents: Int(row.value(forKey: "automaticPilotEvents") as? Int32 ?? 0),
                coherenceSessionsCount: Int(row.value(forKey: "coherenceSessionsCount") as? Int32 ?? 0),
                journalEntryRequested: row.value(forKey: "journalEntryRequested") as? Bool,
                journalEntryCreated: row.value(forKey: "journalEntryCreated") as? Bool ?? false,
                journalEntryID: row.value(forKey: "journalEntryID") as? UUID
            )
        }
        .sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
    }

    private func upsertMorningSession(_ session: MorningRitualSession) {
        guard let row = upsertRow(kind: "morning", epochDay: session.sessionDateEpochDay, id: session.id) else { return }
        row.setValue(session.completedAtEpochMillis, forKey: "completedAtEpochMillis")
        row.setValue(session.completed, forKey: "completed")
        row.setValue(encodeStringArray(session.goals), forKey: "goalsJSON")
        row.setValue(session.identity, forKey: "identity")
        row.setValue(encodeStringArray(session.emotions), forKey: "emotionsJSON")
        row.setValue(encodeStringArray(session.anticipatedSituations), forKey: "anticipatedSituationsJSON")
        row.setValue(encodeStringArray(session.consciousResponses), forKey: "consciousResponsesJSON")
        row.setValue(session.noteText, forKey: "noteText")
    }

    private func upsertEveningReview(_ review: EveningReview) {
        guard let row = upsertRow(kind: "evening", epochDay: review.sessionDateEpochDay, id: review.id) else { return }
        row.setValue(review.completedAtEpochMillis, forKey: "completedAtEpochMillis")
        row.setValue(Int16(review.energy), forKey: "energy")
        row.setValue(review.predominantEmotionID, forKey: "predominantEmotionID")
        row.setValue(review.whatWentWell, forKey: "whatWentWell")
        row.setValue(review.learning, forKey: "learning")
        row.setValue(review.autopilotMoment, forKey: "autopilotMoment")
        row.setValue(review.gratitude, forKey: "gratitude")
        row.setValue(review.tomorrowPreparation, forKey: "tomorrowPreparation")
        row.setValue(Int16(review.identityAlignment), forKey: "identityAlignment")
        row.setValue(review.suggestion, forKey: "suggestion")
        row.setValue(Int32(review.agendaCompletedCount), forKey: "agendaCompletedCount")
        row.setValue(Int32(review.agendaTotalCount), forKey: "agendaTotalCount")
        row.setValue(Int32(review.goalUnitsCompletedCount), forKey: "goalUnitsCompletedCount")
        row.setValue(Int32(review.presenceReturns), forKey: "presenceReturns")
        row.setValue(Int32(review.automaticPilotEvents), forKey: "automaticPilotEvents")
        row.setValue(Int32(review.coherenceSessionsCount), forKey: "coherenceSessionsCount")
        row.setValue(review.journalEntryRequested, forKey: "journalEntryRequested")
        row.setValue(review.journalEntryCreated, forKey: "journalEntryCreated")
        row.setValue(review.journalEntryID, forKey: "journalEntryID")
    }

    private func upsertRow(kind: String, epochDay: Int, id: UUID) -> NSManagedObject? {
        let context = CoreDataController.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: ritualEntityName)
        request.predicate = NSPredicate(format: "kind == %@ AND sessionDateEpochDay == %lld", kind, Int64(epochDay))
        request.fetchLimit = 1

        let row: NSManagedObject
        if let existing = try? context.fetch(request).first {
            row = existing
        } else if let entity = NSEntityDescription.entity(forEntityName: ritualEntityName, in: context) {
            row = NSManagedObject(entity: entity, insertInto: context)
            row.setValue(id, forKey: "id")
            row.setValue(kind, forKey: "kind")
            row.setValue(Int64(epochDay), forKey: "sessionDateEpochDay")
            row.setValue(Date(), forKey: "createdAt")
        } else {
            return nil
        }
        row.setValue(Date(), forKey: "updatedAt")
        return row
    }

    private func fetchStoredRows(kind: String) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: ritualEntityName)
        request.predicate = NSPredicate(format: "kind == %@", kind)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAtEpochMillis", ascending: false)]
        return (try? CoreDataController.shared.context.fetch(request)) ?? []
    }

    private func deleteStoredSession(id: UUID) {
        let context = CoreDataController.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: ritualEntityName)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        (try? context.fetch(request))?.forEach(context.delete)
        saveRitualContext()
    }

    private func saveRitualContext() {
        let context = CoreDataController.shared.context
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            msg("No se pudo guardar el ritual: \(error.localizedDescription)")
        }
    }

    private func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let encoded = String(data: data, encoding: .utf8) else { return "[]" }
        return encoded
    }

    private func decodeStringArray(_ encoded: String?) -> [String] {
        guard let encoded, let data = encoded.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func decodeSessions(from defaults: UserDefaults?) -> [MorningRitualSession] {
        guard let defaults,
              let data = defaults.data(forKey: MorningRitualConstants.sessionsKey),
              let decoded = try? JSONDecoder().decode([MorningRitualSession].self, from: data) else {
            return []
        }
        return decoded
    }

    private func decodeSettings(from defaults: UserDefaults?) -> MorningRitualSettings? {
        guard let defaults,
              let data = defaults.data(forKey: MorningRitualConstants.settingsKey),
              let decoded = try? JSONDecoder().decode(MorningRitualSettings.self, from: data) else {
            return nil
        }
        return decoded
    }

    private func decodeEveningReviews(from defaults: UserDefaults?) -> [EveningReview] {
        guard let defaults,
              let data = defaults.data(forKey: MorningRitualConstants.eveningReviewsKey),
              let decoded = try? JSONDecoder().decode([EveningReview].self, from: data) else {
            return []
        }
        return decoded
    }

    private func mergeSessions(_ lhs: [MorningRitualSession], _ rhs: [MorningRitualSession]) -> [MorningRitualSession] {
        var bestByDay: [Int: MorningRitualSession] = [:]

        for session in lhs + rhs {
            if let current = bestByDay[session.sessionDateEpochDay] {
                bestByDay[session.sessionDateEpochDay] =
                    session.completedAtEpochMillis >= current.completedAtEpochMillis ? session : current
            } else {
                bestByDay[session.sessionDateEpochDay] = session
            }
        }

        return bestByDay.values.sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
    }

    private func mergeEveningReviews(_ lhs: [EveningReview], _ rhs: [EveningReview]) -> [EveningReview] {
        var bestByDay: [Int: EveningReview] = [:]
        for review in lhs + rhs {
            if let current = bestByDay[review.sessionDateEpochDay] {
                bestByDay[review.sessionDateEpochDay] =
                    review.completedAtEpochMillis >= current.completedAtEpochMillis ? review : current
            } else {
                bestByDay[review.sessionDateEpochDay] = review
            }
        }
        return bestByDay.values.sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
    }

    private func mirrorSessionsAcrossContainers() {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.sessionsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.sessionsKey)
    }

    private func mirrorSettingsAcrossContainers() {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.settingsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.settingsKey)
    }

    private func mirrorEveningReviewsAcrossContainers() {
        guard let encoded = try? JSONEncoder().encode(eveningReviews) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.eveningReviewsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.eveningReviewsKey)
    }

    private func epochDay(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }
}

private actor MorningRitualNotificationManager {
    static let shared = MorningRitualNotificationManager()

    private let center = UNUserNotificationCenter.current()

    func scheduleDailyReminder(settings: MorningRitualSettings) async {
        center.removePendingNotificationRequests(withIdentifiers: ["morning_ritual_daily"])

        guard settings.enabled else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        var date = DateComponents()
        date.hour = settings.hour
        date.minute = settings.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.morning_ritual.title", fallback: "Ritual Matutino")
        content.body = L10n.string(
            "notification.morning_ritual.body",
            fallback: "Diseña tu día con claridad e intención."
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "morning_ritual_daily",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func scheduleEveningReminder(settings: MorningRitualSettings) async {
        center.removePendingNotificationRequests(withIdentifiers: ["evening_ritual_daily"])

        guard settings.eveningReminderEnabled else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        var date = DateComponents()
        date.hour = settings.eveningReminderHour
        date.minute = settings.eveningReminderMinute

        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.evening_review.title", fallback: "Cierre consciente")
        content.body = L10n.string(
            "notification.evening_review.body",
            fallback: "Dedica unos minutos a integrar tu día y preparar mañana."
        )
        content.sound = .default
        content.userInfo = ["ritualDestination": "eveningReview"]

        let request = UNNotificationRequest(
            identifier: "evening_ritual_daily",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        )
        try? await center.add(request)
    }

    func scheduleDayReminders(minutesOfDay: [Int]) async {
        let existing = await center.pendingNotificationRequests()
            .map(\ .identifier)
            .filter { $0.hasPrefix("morning_ritual_day_") }
        center.removePendingNotificationRequests(withIdentifiers: existing)

        guard !minutesOfDay.isEmpty else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let calendar = Calendar.current
        let now = Date()
        let scheduledDates = Array(Set(minutesOfDay)).compactMap { minuteOfDay -> Date? in
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = minuteOfDay / 60
            components.minute = minuteOfDay % 60
            components.second = 0

            guard let candidate = calendar.date(from: components) else { return nil }
            if candidate > now {
                return candidate
            }
            return calendar.date(byAdding: .day, value: 1, to: candidate)
        }
        .sorted()

        for (index, date) in scheduledDates.enumerated() {
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = L10n.string("notification.morning_ritual.title", fallback: "Ritual Matutino")
            content.body = L10n.string(
                "notification.morning_ritual.follow_up",
                fallback: "Mantén tu intención durante el día."
            )
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "morning_ritual_day_\(index)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
            return true
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}

struct MorningRitualMainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = MorningRitualStore()
    @State private var route: MorningRitualRoute?
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    private var hasPremiumAccess: Bool { purchaseStatus || yorjPremium }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.50, blue: 0.45),
                        Color(red: 0.66, green: 0.50, blue: 0.80),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack{
                    Text("Ritual Matutino")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.black)
                    ScrollView {
                        VStack(spacing: 14) {
                            ritualCard(
                                title: "Diseña con intención este día",
                                subtitle: "Un ritual breve para estructurar tu día con claridad, intención y presencia.",
                                systemImage: "sun.max.fill",
                                iconColor: .black
                            ) {
                                morningRitualStatusLabel
                                HStack {
                                    Spacer()
                                    Button(store.todayCompleted ? "Repetir diálogo" : "Iniciar diálogo") {
                                        route = .flow
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)
                                }
                                .frame(maxWidth: .infinity)

                            }

                            ritualCard(
                                title: "Cierre consciente",
                                subtitle: store.todayReview == nil
                                    ? "Termina el día con claridad, integra lo vivido y deja una única mejora para mañana."
                                    : "Tu día ya tiene un cierre. Vuelve a él para recordar lo que aprendiste.",
                                systemImage: "moon.stars.fill",
                                iconColor: .black
                            ) {
                                ViewThatFits(in: .horizontal) {
                                    eveningReviewActionRow(axis: .horizontal)
                                    eveningReviewActionRow(axis: .vertical)
                                }
                            }

                            ritualCard(
                                title: "Explorar",
                                subtitle: nil,
                                background: LinearGradient(
                                    colors: [
                                        Color(red: 0.97, green: 0.83, blue: 0.66),
                                        Color(red: 0.86, green: 0.68, blue: 0.82),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ) {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 10)], spacing: 10) {
                                    ritualExploreButton("Ajustes", systemImage: "gearshape") { route = .settings }
                                    ritualExploreButton("Historial", systemImage: "clock.arrow.circlepath") { route = .history }
                                    ritualExploreButton("Resumen", systemImage: "chart.bar") { route = .stats }
                                    ritualExploreButton("Mi día", systemImage: "chart.xyaxis.line") { route = .wellbeing }
                                }
                            }
                        }

                    }
                    .padding(16)
                }

            }
            //.navigationTitle("Ritual Matutino")
            .onTapGesture {
                dismissKeyboard()
            }
            .onAppear {
                store.reload()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    store.reload()
                }
            }
            .sheet(item: $route) { selected in
                switch selected {
                case .flow:
                    MorningRitualFlowView(store: store)
                case .history:
                    MorningRitualHistoryView(store: store)
                case .settings:
                    MorningRitualSettingsView(store: store)
                        .presentationDetents([.height(650)])
                        .presentationDragIndicator(.visible)
                case .stats:
                    MorningRitualStatsView(store: store)
                case .eveningReview:
                    RitualEveningReviewEntryView()
                case .premium:
                    PurchaseView()
                case .wellbeing:
                    WellbeingDashboardView()
                }
            }
        }
    }

    private var morningRitualStatusLabel: some View {
        ritualStatusLabel(
            isCompleted: store.todayCompleted,
            pendingText: "Ritual pendiente",
            pendingColor: .orange
        )
    }

    @ViewBuilder
    private func eveningReviewActionRow(axis: Axis) -> some View {
        if axis == .horizontal {
            HStack(alignment: .center, spacing: 12) {
                eveningReviewStatusLabel
                Spacer(minLength: 8)
                eveningReviewButton
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                eveningReviewStatusLabel
                eveningReviewButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var eveningReviewStatusLabel: some View {
        ritualStatusLabel(
            isCompleted: store.todayReview != nil,
            pendingText: "Cierre pendiente",
            pendingColor: .indigo
        )
    }

    private func ritualStatusLabel(isCompleted: Bool, pendingText: String, pendingColor: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {

            Text(LocalizedStringKey(isCompleted ? "Completado hoy" : pendingText))
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var eveningReviewButton: some View {
        Button(store.todayReview == nil ? "Cerrar día" : "Ver cierre") {
            route = hasPremiumAccess ? .eveningReview : .premium
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }

    private func ritualExploreButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
                    Label(LocalizedStringKey(title), systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.black.opacity(0.25))
    }

    @ViewBuilder
    private func ritualCard(
        title: String,
        subtitle: String?,
        systemImage: String? = nil,
        iconColor: Color = .black,
        background: LinearGradient = LinearGradient.Amanecer(),
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 28)
                }

                Text(LocalizedStringKey(title))
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.black)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private enum MorningRitualRoute: String, Identifiable {
    case flow
    case history
    case settings
    case stats
    case eveningReview
    case premium
    case wellbeing

    var id: String { rawValue }
}

private extension View {
    func morningRitualTextFieldStyle() -> some View {
        self
            .font(.system(size: 22))
            .padding(10)
            .foregroundStyle(.white)
            .tint(.white)
#if os(macOS)
            .textFieldStyle(.plain)
#endif
            .background(Color.black.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
    }
}

private struct EveningReviewFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore
    @State private var reviewDate: Date

    @State private var step = 0
    @State private var energy = 3
    @State private var predominantEmotionID = "sereno"
    @State private var whatWentWell = ""
    @State private var learning = ""
    @State private var autopilotMoment = ""
    @State private var gratitude = ""
    @State private var tomorrowPreparation = ""
    @State private var identityAlignment = 3
    @State private var shouldCreateJournalEntry = true
    @State private var snapshot: EveningDaySnapshot?
    @State private var isEditingExistingReview = false

    private let emotions = ["sereno", "alegre", "ansioso", "triste", "enfadado", "cansado", "agradecido"]

    init(store: MorningRitualStore, reviewDate: Date = Date()) {
        self.store = store
        _reviewDate = State(initialValue: Calendar.current.startOfDay(for: reviewDate))
    }

    private var selectedReview: EveningReview? {
        store.review(for: reviewDate)
    }

    private var weeklyClosures: Int {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reviewDate)) ?? reviewDate
        return store.eveningReviews.filter {
            let date = Date(timeIntervalSince1970: TimeInterval($0.sessionDateEpochDay * 86_400))
            return date >= start && date <= reviewDate
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.10, blue: 0.23), Color(red: 0.22, green: 0.14, blue: 0.39), Color(red: 0.46, green: 0.24, blue: 0.49)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if let review = selectedReview, !isEditingExistingReview {
                    EveningReviewCompletedView(
                        review: review,
                        morningSession: store.session(for: reviewDate),
                        currentSnapshot: EveningDaySnapshot.load(for: reviewDate),
                        weeklyClosures: weeklyClosures,
                        edit: { beginEditing(review) }
                    ) {
                        dismiss()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            header
                            if let snapshot {
                                content(snapshot: snapshot)
                            } else {
                                ProgressView("Preparando el cierre de hoy…")
                                    .tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 260)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Cierre consciente")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
#else
            .toolbar {
                ToolbarItem {
                    Button("Cerrar") { dismiss() }
                }
            }
#endif
            .onAppear {
                snapshot = EveningDaySnapshot.load(for: reviewDate)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("El día termina, tu aprendizaje permanece", systemImage: "moon.stars.fill")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.86))
            Text(stepTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))

            DatePicker("Día que revisas", selection: $reviewDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(.white)
                .foregroundStyle(.white)
                .onChange(of: reviewDate) { _, newDate in
                    reviewDate = Calendar.current.startOfDay(for: newDate)
                    snapshot = EveningDaySnapshot.load(for: reviewDate)
                    isEditingExistingReview = false
                    step = 0
                    if selectedReview == nil {
                        resetDraft()
                    }
                }

            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Color.white : Color.white.opacity(0.22))
                        .frame(height: 5)
                }
            }
            .accessibilityLabel(RitualL10n.format(
                "ritual.evening.step_accessibility",
                fallback: "Paso {0} de 4",
                "\(step + 1)"
            ))
        }
    }

    @ViewBuilder
    private func content(snapshot: EveningDaySnapshot) -> some View {
        switch step {
        case 0:
            energyAndEmotion
        case 1:
            reflectionInputs
        case 2:
            integrationInputs
        default:
            daySnapshot(snapshot)
        }
    }

    private var energyAndEmotion: some View {
        VStack(alignment: .leading, spacing: 18) {
            eveningCard {
                Text("¿Cómo estuvo mi energía?")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            energy = value
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: energySymbol(for: value))
                                    .font(.title3)
                                Text("\(value)")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(energy == value ? .indigo : .white.opacity(0.88))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(energy == value ? .white : .white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(energyDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.66))
            }

            eveningCard {
                Text("¿Qué emoción predominó?")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 9)], spacing: 9) {
                    ForEach(emotions, id: \.self) { emotionID in
                        Button {
                            predominantEmotionID = emotionID
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: moodSymbol(for: emotionID))
                                Text(RitualL10n.localizedMood(emotionID))
                                    .lineLimit(1)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(predominantEmotionID == emotionID ? .indigo : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(predominantEmotionID == emotionID ? .white : .white.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            navigationButton(title: "Continuar", action: { step = 1 })
        }
    }

    private var reflectionInputs: some View {
        VStack(spacing: 14) {
            answerCard(title: "¿Qué salió bien?", prompt: "Un logro, un gesto o un momento que quieras reconocer.", text: $whatWentWell)
            answerCard(title: "¿Qué aprendí?", prompt: "Lo que hoy te mostró sobre ti o tu forma de actuar.", text: $learning)
            answerCard(title: "¿Dónde actué en piloto automático?", prompt: "Sin juicio: observa el momento y nómbralo.", text: $autopilotMoment)
            navigationButtons(nextTitle: "Integrar el día") { step = 2 }
        }
    }

    private var integrationInputs: some View {
        VStack(spacing: 14) {
            answerCard(title: "¿Qué agradezco?", prompt: "Una persona, una experiencia o algo pequeño de hoy.", text: $gratitude)
            answerCard(title: "¿Qué dejo preparado para mañana?", prompt: "Una acción concreta que haga más fácil empezar bien.", text: $tomorrowPreparation)

            eveningCard {
                if let session = store.session(for: reviewDate) {
                    Label("Intención matutina", systemImage: "sunrise.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                    Text(session.identity.isEmpty ? RitualL10n.exact("Identidad no indicada") : RitualL10n.localizedIdentityList(session.identity))
                        .font(.headline)
                    if !session.goals.isEmpty {
                        Text(RitualL10n.format("ritual.evening.morning_goals", fallback: "Metas: {0}", session.goals.joined(separator: " · ")))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    Label("Sin ritual matutino", systemImage: "circle.dashed")
                        .font(.headline)
                    Text("Aun así, este cierre convierte la experiencia de hoy en una intención más clara para mañana.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Divider().overlay(.white.opacity(0.18))
                Text("¿Viví de acuerdo con la identidad elegida por la mañana?")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            identityAlignment = value
                        } label: {
                            Text(alignmentLabel(for: value))
                                .font(.caption.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .foregroundStyle(identityAlignment == value ? .indigo : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(identityAlignment == value ? .white : .white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            navigationButtons(nextTitle: "Ver síntesis del día") { step = 3 }
        }
    }

    private func daySnapshot(_ snapshot: EveningDaySnapshot) -> some View {
        VStack(spacing: 14) {
            eveningCard {
                Label("Tu día, en datos", systemImage: "chart.bar.fill")
                    .font(.headline)
                HStack(spacing: 10) {
                    snapshotMetric(value: "\(snapshot.agendaCompleted.count)/\(snapshot.agendaTotalCount)", label: "Agenda", icon: "checkmark.circle.fill")
                    snapshotMetric(value: "\(snapshot.completedGoalUnits.count)", label: "Metas", icon: "flag.checkered")
                    snapshotMetric(value: "\(snapshot.presenceReturns)", label: "Presencia", icon: "sparkles")
                }
                if let score = snapshot.coherenceAverageAfterScore {
                    Label(RitualL10n.format(
                        "ritual.evening.coherence_summary",
                        fallback: "Coherencia: {0} sesión(es), bienestar final medio {1}/10",
                        "\(snapshot.coherenceSessionsCount)", "\(score)"
                    ), systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Label("Sin sesión de coherencia registrada hoy", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.66))
                }
                if snapshot.automaticPilotEvents > 0 {
                    Label(RitualL10n.format(
                        "ritual.evening.autopilot_count",
                        fallback: "{0} registro(s) de piloto automático",
                        "\(snapshot.automaticPilotEvents)"
                    ), systemImage: "moon.zzz.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow.opacity(0.9))
                }
            }

            completedItemsCard(snapshot)

            eveningCard {
                Label("Una mejora para mañana", systemImage: "arrow.up.right.circle.fill")
                    .font(.headline)
                Text(RitualL10n.localizedSuggestion(suggestedImprovement(snapshot: snapshot)))
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.86))
            }

            eveningCard {
                Toggle(isOn: $shouldCreateJournalEntry) {
                    Label("Guardar resumen en Diario", systemImage: "book.closed.fill")
                        .font(.headline)
                }
                .tint(.yellow)
                Text("Incluye tus respuestas y un resumen de Agenda, Metas, Presencia y Coherencia. Puedes desactivarlo y conservar solo el cierre del ritual.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            navigationButtons(nextTitle: isEditingExistingReview ? "Guardar cambios" : (shouldCreateJournalEntry ? "Guardar y crear entrada" : "Guardar cierre")) {
                saveReview(snapshot: snapshot)
            }
        }
    }

    private func completedItemsCard(_ snapshot: EveningDaySnapshot) -> some View {
        eveningCard {
            Label("Completado hoy", systemImage: "checkmark.seal.fill")
                .font(.headline)

            if snapshot.agendaCompleted.isEmpty && snapshot.completedGoalUnits.isEmpty {
                Text("Aún no hay actividades ni unidades de metas marcadas como completadas. Tu reflexión sigue siendo valiosa.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                ForEach(Array(snapshot.agendaCompleted.prefix(3).enumerated()), id: \.element.id) { _, item in
                    Label(item.titulo.isEmpty ? RitualL10n.exact("Actividad sin título") : item.titulo, systemImage: "calendar.badge.checkmark")
                        .font(.subheadline)
                }
                ForEach(Array(snapshot.completedGoalUnits.prefix(3).enumerated()), id: \.offset) { _, item in
                    Label("\(item.goalTitle) · \(item.unitName)", systemImage: "flag.checkered")
                        .font(.subheadline)
                }
            }
        }
    }

    private func answerCard(title: String, prompt: String, text: Binding<String>) -> some View {
        eveningCard {
            Text(LocalizedStringKey(title))
                .font(.headline)
            TextEditor(text: text)
                .font(.body)
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 88)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(LocalizedStringKey(prompt))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.42))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 17)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func snapshotMetric(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(.yellow)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(LocalizedStringKey(label))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.66))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func navigationButtons(nextTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button("Atrás") { step = max(0, step - 1) }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.8))
            navigationButton(title: nextTitle, action: action)
        }
    }

    private func navigationButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(title))
                Spacer()
                Image(systemName: "arrow.right")
            }
            .font(.headline)
            .foregroundStyle(.indigo)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func eveningCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.13))
            .background(.ultraThinMaterial.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.18), lineWidth: 1))
    }

    private var stepTitle: String {
        RitualL10n.exact(["Toma el pulso", "Mira con honestidad", "Integra y prepara", "Tu síntesis"][step])
    }

    private var stepSubtitle: String {
        RitualL10n.exact(["Dos preguntas para aterrizar cómo llegas al final del día.", "Observa lo vivido sin corregirte ni juzgarte.", "Cierra el ciclo entre tu intención y tu experiencia.", "Reconoce lo que avanzó y deja espacio para mañana."][step])
    }

    private var energyDescription: String {
        RitualL10n.exact(["Muy baja", "Baja", "Estable", "Buena", "Muy alta"][energy - 1])
    }

    private func energySymbol(for value: Int) -> String {
        ["battery.0percent", "battery.25percent", "battery.50percent", "battery.75percent", "battery.100percent"][value - 1]
    }

    private func moodSymbol(for id: String) -> String {
        PresenciaMood.common.first { $0.id == id }?.symbolName ?? "face.smiling"
    }

    private func alignmentLabel(for value: Int) -> String {
        RitualL10n.exact(["Nada", "Poco", "A medias", "Mucho", "Por completo"][value - 1])
    }

    private func suggestedImprovement(snapshot: EveningDaySnapshot) -> String {
        let recentReviews = reviewsInLastSevenDays
        if recentReviews.count >= 3 {
            let averageEnergy = Double(recentReviews.reduce(0) { $0 + $1.energy }) / Double(recentReviews.count)
            if averageEnergy < 3 {
                return "Tu energía lleva varios días baja: deja preparada una sola prioridad y protege un inicio de mañana más lento y realista."
            }
            let averageAutopilot = Double(recentReviews.reduce(0) { $0 + $1.automaticPilotEvents }) / Double(recentReviews.count)
            if averageAutopilot >= 2 {
                return "El piloto automático se repite esta semana: elige una señal concreta —una alarma, una respiración o una frase— antes de tu momento más vulnerable."
            }
        }
        if morningClosureRateLastSevenDays < 0.55 {
            return "Has empezado más días de los que has cerrado: programa un cierre breve de un minuto para convertir intención en aprendizaje constante."
        }
        if energy <= 2 {
            return "Protege tu energía: deja preparada solo la primera acción esencial de mañana y date permiso para empezar despacio."
        }
        if !autopilotMoment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || snapshot.automaticPilotEvents > 0 {
            return "Antes del primer momento que suele llevarte al piloto automático, haz una pausa de tres respiraciones y recuerda tu identidad elegida."
        }
        if identityAlignment <= 2, let identity = store.session(for: reviewDate)?.identity, !identity.isEmpty {
            return "Mañana lee al despertar: «Hoy actúo como \(identity)», y conviértelo en un gesto visible durante la primera hora."
        }
        if snapshot.agendaTotalCount > 0 && snapshot.agendaCompleted.isEmpty {
            return "Elige una sola actividad de tu agenda y resérvale un bloque breve, concreto y sin interrupciones mañana."
        }
        return "Conserva el impulso: repite mañana una de las acciones que hoy sí estuvo alineada con la persona que eliges ser."
    }

    private var reviewsInLastSevenDays: [EveningReview] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reviewDate)) ?? reviewDate
        return store.eveningReviews.filter {
            let date = Date(timeIntervalSince1970: TimeInterval($0.sessionDateEpochDay * 86_400))
            return date >= start && date <= reviewDate
        }
    }

    private var morningClosureRateLastSevenDays: Double {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reviewDate)) ?? reviewDate
        let morningDays = Set(store.sessions.compactMap { session -> Int? in
            let date = Date(timeIntervalSince1970: TimeInterval(session.sessionDateEpochDay * 86_400))
            return date >= start && date <= reviewDate ? session.sessionDateEpochDay : nil
        })
        guard !morningDays.isEmpty else { return 1 }
        let reviewDays = Set(reviewsInLastSevenDays.map(\.sessionDateEpochDay))
        return Double(morningDays.intersection(reviewDays).count) / Double(morningDays.count)
    }

    private func saveReview(snapshot: EveningDaySnapshot) {
        let suggestion = suggestedImprovement(snapshot: snapshot)
        let existingReview = isEditingExistingReview ? selectedReview : nil
        let journalResult = shouldCreateJournalEntry
            ? upsertJournalEntry(suggestion: suggestion, snapshot: snapshot, existingID: existingReview?.journalEntryID)
            : (created: existingReview?.journalEntryCreated ?? false, id: existingReview?.journalEntryID)
        let review = EveningReview(
            id: existingReview?.id ?? UUID(),
            sessionDateEpochDay: epochDay(for: reviewDate),
            completedAtEpochMillis: Int64(Date().timeIntervalSince1970 * 1_000),
            energy: energy,
            predominantEmotionID: predominantEmotionID,
            whatWentWell: normalized(whatWentWell),
            learning: normalized(learning),
            autopilotMoment: normalized(autopilotMoment),
            gratitude: normalized(gratitude),
            tomorrowPreparation: normalized(tomorrowPreparation),
            identityAlignment: identityAlignment,
            suggestion: suggestion,
            agendaCompletedCount: snapshot.agendaCompleted.count,
            agendaTotalCount: snapshot.agendaTotalCount,
            goalUnitsCompletedCount: snapshot.completedGoalUnits.count,
            presenceReturns: snapshot.presenceReturns,
            automaticPilotEvents: snapshot.automaticPilotEvents,
            coherenceSessionsCount: snapshot.coherenceSessionsCount,
            journalEntryRequested: shouldCreateJournalEntry,
            journalEntryCreated: journalResult.created,
            journalEntryID: journalResult.id
        )
        store.saveEveningReview(review)
        isEditingExistingReview = false
    }

    private func upsertJournalEntry(
        suggestion: String,
        snapshot: EveningDaySnapshot,
        existingID: UUID?
    ) -> (created: Bool, id: UUID?) {
        let identity = store.session(for: reviewDate)?.identity
        let localizedIdentity = identity.map(RitualL10n.localizedIdentityList)
        let content = [
            RitualL10n.exact("RESUMEN DE CIERRE"),
            "\(RitualL10n.exact("ENERGÍA"))\n\(energy)/5 — \(energyDescription)",
            "\(RitualL10n.exact("EMOCIÓN PREDOMINANTE"))\n\(RitualL10n.localizedMood(predominantEmotionID))",
            "\(RitualL10n.exact("LO QUE SALIÓ BIEN"))\n\(displayValue(whatWentWell))",
            "\(RitualL10n.exact("APRENDIZAJE"))\n\(displayValue(learning))",
            "\(RitualL10n.exact("PILOTO AUTOMÁTICO"))\n\(displayValue(autopilotMoment))",
            "\(RitualL10n.exact("GRATITUD"))\n\(displayValue(gratitude))",
            "\(RitualL10n.exact("PREPARADO PARA MAÑANA"))\n\(displayValue(tomorrowPreparation))",
            "\(RitualL10n.exact("COHERENCIA CON MI IDENTIDAD"))\n\(identityAlignment)/5\(localizedIdentity.map { " — \($0)" } ?? "")",
            "\(RitualL10n.exact("SÍNTESIS DEL DÍA"))\n\(integratedDaySummary(snapshot))",
            "\(RitualL10n.exact("UNA MEJORA PARA MAÑANA"))\n\(RitualL10n.localizedSuggestion(suggestion))"
        ].joined(separator: "\n\n")

        let context = CoreDataController.shared.context
        let request: NSFetchRequest<Diario> = Diario.fetchRequest()
        if let existingID {
            request.predicate = NSPredicate(format: "id == %@", existingID as CVarArg)
        } else {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: reviewDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            request.predicate = NSPredicate(
                format: "capitulo == %@ AND fecha >= %@ AND fecha < %@",
                "Cierre consciente", start as NSDate, end as NSDate
            )
        }

        let entry: Diario
        if let existing = try? context.fetch(request).first {
            entry = existing
        } else {
            entry = Diario(context: context)
            entry.id = UUID()
            entry.fecha = Calendar.current.startOfDay(for: reviewDate)
            entry.setValue("Cierre consciente", forKey: "capitulo")
        }

        entry.title = RitualL10n.format(
            "ritual.evening.journal_title",
            fallback: "Cierre consciente · {0}",
            RitualL10n.formattedDate(reviewDate, dateStyle: .medium)
        )
        entry.emotion = journalEmotion.rawValue
        entry.content = content
        entry.fechaM = Date()

        do {
            try context.save()
            return (true, entry.id)
        } catch {
            context.rollback()
            return (false, existingID)
        }
    }

    private func beginEditing(_ review: EveningReview) {
        energy = max(1, review.energy)
        predominantEmotionID = review.predominantEmotionID.isEmpty ? "sereno" : review.predominantEmotionID
        whatWentWell = review.whatWentWell
        learning = review.learning
        autopilotMoment = review.autopilotMoment
        gratitude = review.gratitude
        tomorrowPreparation = review.tomorrowPreparation
        identityAlignment = max(1, review.identityAlignment)
        shouldCreateJournalEntry = review.journalEntryRequested != false
        snapshot = EveningDaySnapshot.load(for: reviewDate)
        step = 0
        isEditingExistingReview = true
    }

    private func resetDraft() {
        energy = 3
        predominantEmotionID = "sereno"
        whatWentWell = ""
        learning = ""
        autopilotMoment = ""
        gratitude = ""
        tomorrowPreparation = ""
        identityAlignment = 3
        shouldCreateJournalEntry = true
    }

    private func integratedDaySummary(_ snapshot: EveningDaySnapshot) -> String {
        let completedAgenda = snapshot.agendaCompleted
            .map { $0.titulo.isEmpty ? RitualL10n.exact("Actividad sin título") : $0.titulo }
        let completedGoals = snapshot.completedGoalUnits
            .map { "\($0.goalTitle) · \($0.unitName)" }
        let coherence = snapshot.coherenceAverageAfterScore.map {
            RitualL10n.format(
                "ritual.evening.coherence_value",
                fallback: "{0} sesión(es), bienestar final medio {1}/10",
                "\(snapshot.coherenceSessionsCount)", "\($0)"
            )
        } ?? RitualL10n.exact("sin sesión registrada")

        let agendaValues = completedAgenda.isEmpty ? RitualL10n.exact("sin actividades marcadas") : completedAgenda.joined(separator: " · ")
        let goalValues = completedGoals.isEmpty ? RitualL10n.exact("sin unidades completadas") : completedGoals.joined(separator: " · ")

        return [
            RitualL10n.format("ritual.evening.agenda_summary", fallback: "Agenda completada ({0}/{1}): {2}", "\(snapshot.agendaCompleted.count)", "\(snapshot.agendaTotalCount)", agendaValues),
            RitualL10n.format("ritual.evening.goals_summary", fallback: "Metas: {0}", goalValues),
            RitualL10n.format("ritual.evening.presence_summary", fallback: "Presencia: {0} regreso(s) al presente y {1} registro(s) de piloto automático.", "\(snapshot.presenceReturns)", "\(snapshot.automaticPilotEvents)"),
            RitualL10n.format("ritual.evening.coherence_line", fallback: "Coherencia: {0}.", coherence)
        ].joined(separator: "\n")
    }

    private var journalEmotion: Emociones {
        switch predominantEmotionID {
        case "alegre", "agradecido": return .feliz
        case "triste": return .triste
        case "enfadado": return .enfado
        case "cansado": return .desanimado
        case "ansioso": return .distraido
        default: return .pensativo
        }
    }

    private func displayValue(_ value: String) -> String {
        let cleaned = normalized(value)
        return cleaned.isEmpty ? RitualL10n.exact("Sin respuesta") : cleaned
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func epochDay(for date: Date) -> Int {
        Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970 / 86_400)
    }
}

private struct EveningReviewCompletedView: View {
    let review: EveningReview
    let morningSession: MorningRitualSession?
    let currentSnapshot: EveningDaySnapshot
    let weeklyClosures: Int
    let edit: () -> Void
    let close: () -> Void
    @State private var showJournalEntry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
                Text("Día cerrado con conciencia")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Tu reflexión quedó guardada en el Diario y ya forma parte del aprendizaje de mañana.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.74))
                Text(RitualL10n.format(
                    "ritual.evening.completed_weekly",
                    fallback: "Ciclo integrado · {0}/7 cierres en los últimos siete días",
                    "\(weeklyClosures)"
                ))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .center)

                summaryCard(title: "Tu intención y tu experiencia", icon: "arrow.triangle.2.circlepath") {
                    if let morningSession, !morningSession.identity.isEmpty {
                        Text(RitualL10n.format(
                            "ritual.evening.completed_identity",
                            fallback: "Identidad elegida: {0}",
                            RitualL10n.localizedIdentityList(morningSession.identity)
                        ))
                    } else {
                        Text("Hoy no registraste una identidad matutina.")
                    }
                    Text(RitualL10n.format("ritual.evening.perceived_coherence", fallback: "Coherencia percibida: {0}/5", "\(review.identityAlignment)"))
                }

                summaryCard(title: "Una mejora para mañana", icon: "arrow.up.right.circle.fill") {
                    Text(RitualL10n.localizedSuggestion(review.suggestion))
                        .font(.body)
                }

                summaryCard(title: "Huella del día", icon: "chart.bar.fill") {
                    Text(RitualL10n.format(
                        "ritual.day_footprint",
                        fallback: "Agenda {0}/{1} · Metas {2} · Presencia {3}",
                        "\(review.agendaCompletedCount)", "\(review.agendaTotalCount)", "\(review.goalUnitsCompletedCount)", "\(review.presenceReturns)"
                    ))
                    Text(journalStatus)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                if review.journalEntryCreated, review.journalEntryID != nil {
                    Button {
                        showJournalEntry = true
                    } label: {
                        Label("Ver entrada de Diario", systemImage: "book.closed.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.indigo)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                if hasContextChanges {
                    Button {
                        edit()
                    } label: {
                        Label("Tu día ha cambiado · actualizar resumen", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.bold())
                            .foregroundStyle(.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.yellow.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button("Editar cierre", action: edit)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button("Volver", action: close)
                        .font(.headline)
                        .foregroundStyle(.indigo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .sheet(isPresented: $showJournalEntry) {
            if let journalEntryID = review.journalEntryID {
                RitualJournalEntryView(entryID: journalEntryID)
            }
        }
    }

    private func summaryCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(LocalizedStringKey(title), systemImage: icon)
                .font(.headline)
            content()
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.18), lineWidth: 1))
    }

    private var journalStatus: String {
        guard review.journalEntryRequested != false || review.journalEntryCreated else {
            return RitualL10n.exact("Elegiste conservar el cierre sin crear una entrada de Diario.")
        }
        return review.journalEntryCreated
            ? RitualL10n.exact("Entrada estructurada creada en tu Diario.")
            : RitualL10n.exact("La entrada de Diario no se pudo crear; puedes guardar esta reflexión manualmente.")
    }

    private var hasContextChanges: Bool {
        review.agendaCompletedCount != currentSnapshot.agendaCompleted.count
            || review.agendaTotalCount != currentSnapshot.agendaTotalCount
            || review.goalUnitsCompletedCount != currentSnapshot.completedGoalUnits.count
            || review.presenceReturns != currentSnapshot.presenceReturns
            || review.automaticPilotEvents != currentSnapshot.automaticPilotEvents
            || review.coherenceSessionsCount != currentSnapshot.coherenceSessionsCount
    }
}

private struct RitualJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let entryID: UUID
    @State private var entry: Diario?

    var body: some View {
        NavigationStack {
            Group {
                if let entry {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(entry.title ?? RitualL10n.exact("Cierre consciente")).font(.title2.bold())
                            Text(entry.fecha?.formatted(date: .long, time: .omitted) ?? "")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(entry.content ?? "").textSelection(.enabled)
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView("Entrada no disponible", systemImage: "book.closed")
                }
            }
            .navigationTitle("Diario")
            .toolbar { ToolbarItem { Button("Cerrar") { dismiss() } } }
            .onAppear {
                let request: NSFetchRequest<Diario> = Diario.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", entryID as CVarArg)
                entry = try? CoreDataController.shared.context.fetch(request).first
            }
        }
    }
}

struct RitualEveningReviewEntryView: View {
    let reviewDate: Date
    @StateObject private var store = MorningRitualStore()
    @AppStorage("ritual_private_reflections_protected") private var privacyEnabled = false
    @State private var unlocked = false

    init(reviewDate: Date = Date()) {
        self.reviewDate = reviewDate
    }

    var body: some View {
        Group {
            if privacyEnabled && !unlocked {
                RitualPrivacyUnlockView(unlocked: $unlocked)
            } else {
                EveningReviewFlowView(store: store, reviewDate: reviewDate)
            }
        }
    }
}

private enum WellbeingDashboardRoute: Hashable, Identifiable {
    case agenda
    case goals
    case presence
    case coherence
    case morningRitual

    var id: Self { self }
}

struct WellbeingDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = MorningRitualStore()
    @AppStorage("ritual_private_reflections_protected") private var privacyEnabled = false
    @State private var unlocked = false
    @State private var selectedDate = Date()
    @State private var showReview = false
    @State private var activeRoute: WellbeingDashboardRoute?

    var body: some View {
        Group {
            if privacyEnabled && !unlocked {
                RitualPrivacyUnlockView(unlocked: $unlocked)
            } else {
                dashboard
            }
        }
    }

    private var dashboard: some View {
        let day = Calendar.current.startOfDay(for: selectedDate)
        let snapshot = EveningDaySnapshot.load(for: day)
        let morning = store.session(for: day)
        let review = store.review(for: day)

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Mi día")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Una vista única para observar intención, acciones y aprendizaje.")
                        .foregroundStyle(.white.opacity(0.76))
                    DatePicker("Día", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(.white)
                        .foregroundStyle(.white)

                    dashboardCard(title: "Intención", icon: "sunrise.fill", route: .morningRitual) {
                        Text(morning?.identity.isEmpty == false
                             ? RitualL10n.localizedIdentityList(morning!.identity)
                             : RitualL10n.exact("Sin ritual matutino registrado"))
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)

                        if let goals = morning?.goals, !goals.isEmpty {
                            Text(goals.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(RitualL10n.exact(morning == nil ? "Toca el acceso para registrar tu intención." : "Abre el ritual para revisar o repetir tu diseño del día."))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 10) {
                        dashboardMetric("Agenda", "\(snapshot.agendaCompleted.count)/\(snapshot.agendaTotalCount)", "checkmark.circle.fill", route: .agenda)
                        dashboardMetric("Metas", "\(snapshot.completedGoalUnits.count)", "flag.checkered", route: .goals)
                        dashboardMetric("Presencia", "\(snapshot.presenceReturns)", "sparkles", route: .presence)
                    }

                    dashboardCard(title: "Agenda", icon: "calendar", route: .agenda) {
                        if snapshot.agendaCompleted.isEmpty {
                            Text("Sin actividades completadas para este día.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(snapshot.agendaCompleted.prefix(4)) { item in
                                dashboardPlainLine(
                                    title: item.titulo.isEmpty ? RitualL10n.exact("Actividad completada") : item.titulo,
                                    subtitle: RitualL10n.exact("Actividad completada")
                                )
                            }
                        }
                    }

                    dashboardCard(title: "Metas", icon: "flag.checkered", route: .goals) {
                        if snapshot.completedGoalUnits.isEmpty {
                            Text("Sin unidades de metas completadas para este día.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(Array(snapshot.completedGoalUnits.prefix(4).enumerated()), id: \.offset) { _, unit in
                                dashboardPlainLine(title: unit.unitName, subtitle: unit.goalTitle)
                            }
                        }
                    }

                    dashboardCard(title: "Presencia", icon: "sparkles", route: .presence) {
                        Text(RitualL10n.format("ritual.dashboard.presence_returns", fallback: "Retornos conscientes: {0}", "\(snapshot.presenceReturns)"))
                            .font(.body)
                        Text(RitualL10n.format("ritual.dashboard.autopilot", fallback: "Piloto automático: {0} registro(s)", "\(snapshot.automaticPilotEvents)"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    dashboardCard(title: "Coherencia", icon: "heart.text.square.fill", route: .coherence) {
                        Text(snapshot.coherenceAverageAfterScore.map {
                            RitualL10n.format("ritual.dashboard.average_score", fallback: "Puntuación media: {0}/10", "\($0)")
                        } ?? RitualL10n.exact("Sin sesión de coherencia registrada"))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(RitualL10n.format("ritual.dashboard.coherence_sessions", fallback: "{0} sesión(es) en el día", "\(snapshot.coherenceSessionsCount)"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    dashboardCard(title: "Aprendizaje", icon: "moon.stars.fill", action: { showReview = true }) {
                        if let review {
                            Text(RitualL10n.format(
                                "ritual.dashboard.learning_scores",
                                fallback: "Energía {0}/5 · Coherencia con mi identidad {1}/5",
                                "\(review.energy)", "\(review.identityAlignment)"
                            ))
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(RitualL10n.localizedSuggestion(review.suggestion))
                                .foregroundStyle(.white.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Aún no has cerrado este día.")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
            }
            .background(LinearGradient(colors: [Color(red: 0.06, green: 0.13, blue: 0.26), Color(red: 0.38, green: 0.18, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
            .toolbar { ToolbarItem { Button("Cerrar") { dismiss() }.foregroundStyle(.white) } }
            .sheet(item: $activeRoute) { route in
                dashboardDestination(for: route, selectedDate: day, morning: morning)
            }
            .sheet(isPresented: $showReview) { RitualEveningReviewEntryView(reviewDate: day) }
        }
    }

    @ViewBuilder
    private func dashboardDestination(
        for route: WellbeingDashboardRoute,
        selectedDate: Date,
        morning: MorningRitualSession?
    ) -> some View {
        switch route {
        case .agenda:
            AgendaMainView()
        case .goals:
            GoalsListView()
        case .presence:
            #if os(iOS)
            PresenciaView()
            #else
            ContentUnavailableView(
                "Presencia",
                systemImage: "iphone",
                description: Text("Esta herramienta está disponible en iPhone y Apple Watch.")
            )
            #endif
        case .coherence:
            CardioCoherenceWelcomeFlowView()
        case .morningRitual:
            if morning == nil {
                MorningRitualFlowView(store: store, ritualDate: selectedDate)
            } else {
                MorningRitualMainView()
            }
        }
    }

    private func dashboardCard<Content: View>(
        title: String,
        icon: String,
        route: WellbeingDashboardRoute? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(LocalizedStringKey(title), systemImage: icon).font(.headline)
            content()
        }
        .foregroundStyle(.white)
        .padding(16)
        .padding(.top, route == nil && action == nil ? 0 : 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topTrailing) {
            if let route {
                dashboardAccessButton(size: 22, iconSize: 8, padding: 8) {
                    activeRoute = route
                }
            } else if let action {
                dashboardAccessButton(size: 22, iconSize: 8, padding: 8, action: action)
            }
        }
    }

    private func dashboardMetric(_ title: String, _ value: String, _ icon: String, route: WellbeingDashboardRoute) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.yellow)
            Text(value).font(.headline.monospacedDigit())
            Text(LocalizedStringKey(title)).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            dashboardAccessButton(size: 20, iconSize: 7, padding: 7) {
                activeRoute = route
            }
            .offset(x: 3, y: -3)
        }
    }

    private func dashboardPlainLine(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dashboardAccessButton(
        size: CGFloat = 28,
        iconSize: CGFloat = 10,
        padding: CGFloat = 10,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.28))
                .frame(width: size, height: size)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.16), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .padding(padding)
        .accessibilityLabel("Abrir herramienta")
    }
}

private struct RitualPrivacyUnlockView: View {
    @Binding var unlocked: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.heart.fill").font(.system(size: 46)).foregroundStyle(.indigo)
            Text("Reflexiones protegidas").font(.title2.bold())
            Text("Desbloquea tus reflexiones de cierre con biometría o el código de tu dispositivo.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("Desbloquear") {
                UtilFuncs.authenticateDeviceOwner(reason: RitualL10n.exact("Desbloquea tus reflexiones de cierre")) { success, _ in
                    unlocked = success
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(28)
    }
}

private struct MorningRitualFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore
    let ritualDate: Date

    private enum FocusedField: Hashable {
        case goal(Int)
    }

    @State private var state = MorningRitualFlowState()
    @State private var showingTimePicker = false
    @State private var showingNoteEditor = false
    @State private var reminderPickerValue = Date()
    @State private var lastSavedDraft: MorningRitualDraft?
    @State private var generatedDayReminderTimes: [Int]?
    @FocusState private var focusedField: FocusedField?

    private let identitySuggestions = [
        "Enfocado", "Calmado", "Disciplinado", "Valiente", "Presente",
        "Compasivo","Curioso","Reflexivo","Proactivo","Consciente","Observador",
        "Intencional","Constante","Organizado","Persistente","Productivo","Comprometido",
        "Auténtico","Visionario","Autodidacta","Explorador", "Innovador"
    ]

    private let emotionSuggestions = [
        "Calma", "Confianza", "Gratitud", "Claridad", "Energía", "Apertura",
        "Serenidad","Empatía", "Autoestima","Alegría","Paz", "Amor", "Compasión","Esperanza",
        "Entusiasmo","Seguridad","Asombro","Satisfacción", "Fluidez", "Conexión", "Fortaleza",
        "Resiliencia"
    ]

    init(store: MorningRitualStore, ritualDate: Date = Date()) {
        self.store = store
        self.ritualDate = ritualDate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [
                    Color(red: 0.20, green: 0.20, blue: 0.30),
                    Color(red: 0.76, green: 0.60, blue: 0.90)],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView(value: Double(state.step), total: 6)
                        .tint(.mint)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            contentForCurrentStep

                            if let message = state.validationMessage {
                                Text(message)
                                    .font(.body)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissKeyboard()
                        }
                    }

                    HStack(spacing: 12) {
#if os(macOS)
                        Button("Cerrar") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .tint(.black)
                        
                        Spacer()
                        
#endif

                        Button("Atrás") {
                            state.validationMessage = nil
                            state.step = max(1, state.step - 1)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .tint(.black)
                        .disabled(state.step == 1)

                        if state.step < 6 {
                            Button("Continuar") {
                                guard validateCurrentStep() == nil else { return }
                                prepareDayReminderSuggestionsIfNeeded()
                                state.step += 1
                                state.validationMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .tint(.black)
                        } else if hasPendingChanges {
                            Button("Guardar Ritual") {
                                completeRitual()
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .tint(.black)
                        }
                    }
                    .padding([.top, .bottom], 6)
                    .padding(.horizontal, 12)

                    if state.isCompleted {
                        Button("Volver al inicio") { dismiss() }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .tint(.black)
                            .padding(.bottom, 10)
                    }
                }
            }
            .navigationTitle("Diseña tu día")
            .toolbarTitleDisplayMode(.inline)
            .onTapGesture {
                dismissKeyboard()
            }
            .sheet(isPresented: $showingTimePicker) {
                NavigationStack {
                    VStack(spacing: 14) {
                        DatePicker("Hora", selection: $reminderPickerValue, displayedComponents: .hourAndMinute)
#if os(iOS)
                            .datePickerStyle(.wheel)
#endif
                            .labelsHidden()

                        Button("Añadir hora") {
                            let minuteOfDay = minuteOfDay(from: reminderPickerValue)
                            if !state.dayReminderTimes.contains(minuteOfDay) {
                                state.dayReminderTimes.append(minuteOfDay)
                                state.dayReminderTimes.sort()
                            }
                            showingTimePicker = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingNoteEditor) {
                MorningRitualDraftNoteSheet(
                    noteText: $state.ritualNote
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var contentForCurrentStep: some View {
        switch state.step {
        case 1:
            cardBlock(title: "Antes de empezar, vuelve a ti", body: "Cierra los ojos y respira profundo... Acalla tus pensamientos y solo siente tu respiración. Eres importante, este momento es tuyo.") {
                Text("Hoy no reaccionas por inercia, hoy eliges.")
                    .foregroundStyle(.black.opacity(0.85))
                    .font(.title3)
                HStack{
                    Spacer()
                    Button("Estoy presente") { state.step = 2 }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)
                }
                
            }
        case 2:
            cardBlock(title: "Metas del día", body: "Comienza por el final. Si hoy fuera un buen día para ti, ¿qué habría ocurrido?") {
                HStack {
                    Spacer()
                    Button("Añadir meta") {
                        state.goals.append("")
                        let newIndex = state.goals.count - 1
                        DispatchQueue.main.async {
                            focusedField = .goal(newIndex)
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.black)
                    .tint(.black)
                    .disabled(state.goals.count >= MorningRitualConstants.maxGoals)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(state.goals.enumerated()), id: \.offset) { index, _ in
                            HStack {
                                TextField(
                                    RitualL10n.format("ritual.morning.goal_placeholder", fallback: "Meta {0}", "\(index + 1)"),
                                    text: Binding(
                                    get: { state.goals[index] },
                                    set: { state.goals[index] = $0 }
                                ))
                                .morningRitualTextFieldStyle()
                                .focused($focusedField, equals: .goal(index))

                                if state.goals.count > 1 {
                                    Button(role: .destructive) {
                                        state.goals.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 200)
            }
        case 3:
            cardBlock(title: "Identidad", body: "¿Quién decides ser hoy?") {
                chipGrid(items: identitySuggestions, selected: state.identities) { value in
                    toggleValue(value, in: &state.identities)
                }

                TextField("Identidad personalizada", text: $state.customIdentity)
                    .morningRitualTextFieldStyle()
            }
        case 4:
            cardBlock(title: "Emoción", body: "¿Qué emoción quieres sostener hoy?") {
                chipGrid(items: emotionSuggestions, selected: state.emotions) { value in
                    toggleValue(value, in: &state.emotions)
                }

                TextField("Emoción personalizada", text: $state.customEmotion)
                    .morningRitualTextFieldStyle()
            }
        case 5:
            cardBlock(title: "Anticipación (Opcional)", body: "¿Qué podría desafiarte hoy y cómo responderás conscientemente?") {
                ForEach(Array(state.triggerResponses.enumerated()), id: \.offset) { index, _ in
                    VStack(spacing: 6) {
                        TextField("Si sucede x...", text: Binding(
                            get: { state.triggerResponses[index].trigger },
                            set: { state.triggerResponses[index].trigger = $0 }
                        ))
                        .morningRitualTextFieldStyle()

                        TextField("Responderé con y...", text: Binding(
                            get: { state.triggerResponses[index].response },
                            set: { state.triggerResponses[index].response = $0 }
                        ))
                        .morningRitualTextFieldStyle()

                        if state.triggerResponses.count > 1 {
                            Button("Quitar") {
                                state.triggerResponses.remove(at: index)
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.black)
                            .tint(.red)
                        }
                    }
                    .padding(8)
                    .background(.black.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if state.triggerResponses.count < MorningRitualConstants.maxItems {
                    Button("Añadir situación") { state.triggerResponses.append(.init()) }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)
                }
            }
        default:
            cardBlock(title: "Resumen", body: "Hoy eliges tu estado interno y comportamiento. No serás un efecto de tu entorno.") {
                Group {
                    summarySection(title: "Metas", text: compactGoals)
                    summarySection(title: "Identidad", text: compactIdentity)
                    summarySection(title: "Emociones", text: compactEmotions)
                    summarySection(title: "Anticipación", text: compactAnticipation)
                }

                Button(state.ritualNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Añadir una nota (opcional)" : "Editar nota del ritual") {
                    showingNoteEditor = true
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.black)

                if !state.ritualNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    summarySection(title: "Nota", text: state.ritualNote)
                }

                Toggle(
                    "Recordatorios durante el día",
                    isOn: Binding(
                        get: { state.dayRemindersEnabled },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.28)) {
                                state.dayRemindersEnabled = newValue
                            }
                        }
                    )
                )
                .toggleStyle(.switch)
                .foregroundStyle(.black)

                if state.dayRemindersEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(state.dayReminderTimes, id: \.self) { minuteOfDay in
                            HStack {
                                Text(timeString(from: minuteOfDay))
                                    .foregroundStyle(.black)
                                Spacer()
                                Button(role: .destructive) {
                                    state.dayReminderTimes.removeAll { $0 == minuteOfDay }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }

                        Button("Añadir hora") {
                            reminderPickerValue = Date()
                            showingTimePicker = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    private var compactGoals: String {
        state.goals.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    private var compactIdentity: String {
        let custom = state.customIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = state.identities + (custom.isEmpty ? [] : [custom])
        return values.map(RitualL10n.exact).joined(separator: ", ")
    }

    private var compactEmotions: String {
        let custom = state.customEmotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = state.emotions + (custom.isEmpty ? [] : [custom])
        return values.map(RitualL10n.exact).joined(separator: ", ")
    }

    private var compactAnticipation: String {
        let validPairs = state.triggerResponses
            .map {
                TriggerResponseInput(
                    trigger: $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                    response: $0.response.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.trigger.isEmpty && !$0.response.isEmpty }

        return validPairs
            .map { "\($0.trigger) → \($0.response)" }
            .joined(separator: "\n")
    }

    private func validateCurrentStep() -> String? {
        let message: String?
        switch state.step {
        case 2:
            let valid = state.goals.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            message = valid.isEmpty ? RitualL10n.exact("Añade al menos 1 meta para hoy.") : nil
        case 3:
            let hasCustom = !state.customIdentity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            message = (state.identities.isEmpty && !hasCustom) ? RitualL10n.exact("Elige al menos una identidad o añade una personalizada.") : nil
        case 4:
            let hasCustom = !state.customEmotion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            message = (state.emotions.isEmpty && !hasCustom) ? RitualL10n.exact("Elige al menos una emoción o añade una personalizada.") : nil
        case 5:
            let normalizedPairs = state.triggerResponses.map {
                TriggerResponseInput(
                    trigger: $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                    response: $0.response.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            let hasAnyInput = normalizedPairs.contains { !$0.trigger.isEmpty || !$0.response.isEmpty }
            let hasIncompletePair = normalizedPairs.contains { ($0.trigger.isEmpty && !$0.response.isEmpty) || (!$0.trigger.isEmpty && $0.response.isEmpty) }

            if !hasAnyInput {
                message = nil
            } else if hasIncompletePair {
                message = RitualL10n.exact("Completa situación y respuesta en cada bloque usado, o déjalos vacíos.")
            } else {
                message = nil
            }
        case 6:
            message = state.dayRemindersEnabled && state.dayReminderTimes.isEmpty
                ? RitualL10n.exact("Añade al menos una hora o desactiva los recordatorios del día.")
                : nil
        default:
            message = nil
        }

        state.validationMessage = message
        return message
    }

    private func completeRitual() {
        guard validateCurrentStep() == nil else { return }

        refreshUnmodifiedDayReminderSuggestions()

        let nowMillis = Int64(Date().timeIntervalSince1970 * 1_000)
        let todayEpoch = epochDay(for: ritualDate)

        let session = MorningRitualSession(
            sessionDateEpochDay: todayEpoch,
            completedAtEpochMillis: nowMillis,
            goals: currentDraft.goals,
            identity: currentDraft.identityValues.joined(separator: ", "),
            emotions: currentDraft.emotionValues,
            anticipatedSituations: currentDraft.triggers,
            consciousResponses: currentDraft.responses,
            noteText: currentDraft.noteText
        )

        store.saveSession(session)
        store.scheduleDayReminders(minutesOfDay: state.dayReminderTimes, enabled: state.dayRemindersEnabled)
        lastSavedDraft = currentDraft
        state.isCompleted = true
        state.validationMessage = nil
        state.step = 6
    }

    private func prepareDayReminderSuggestionsIfNeeded() {
        guard state.step == 5, generatedDayReminderTimes == nil else { return }
        let suggestions = MorningRitualConstants.suggestedDayReminderTimes(after: Date())
        state.dayReminderTimes = suggestions
        generatedDayReminderTimes = suggestions
    }

    private func refreshUnmodifiedDayReminderSuggestions() {
        guard let generatedDayReminderTimes,
              state.dayReminderTimes == generatedDayReminderTimes else { return }

        let refreshedSuggestions = MorningRitualConstants.suggestedDayReminderTimes(after: Date())
        state.dayReminderTimes = refreshedSuggestions
        self.generatedDayReminderTimes = refreshedSuggestions
    }

    private var hasPendingChanges: Bool {
        lastSavedDraft != currentDraft
    }

    private var currentDraft: MorningRitualDraft {
        let validGoals = state.goals
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let customIdentity = state.customIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        let identityValues = Array(Set(state.identities + (customIdentity.isEmpty ? [] : [customIdentity]))).sorted()

        let customEmotion = state.customEmotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let emotionValues = Array(Set(state.emotions + (customEmotion.isEmpty ? [] : [customEmotion]))).sorted()

        let validPairs = state.triggerResponses
            .map {
                TriggerResponseInput(
                    trigger: $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                    response: $0.response.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.trigger.isEmpty && !$0.response.isEmpty }

        return MorningRitualDraft(
            goals: validGoals,
            identityValues: identityValues,
            emotionValues: emotionValues,
            triggers: validPairs.map(\.trigger),
            responses: validPairs.map(\.response),
            noteText: state.ritualNote.trimmingCharacters(in: .whitespacesAndNewlines),
            dayRemindersEnabled: state.dayRemindersEnabled,
            dayReminderTimes: Array(Set(state.dayReminderTimes)).sorted()
        )
    }

    private func timeString(from minuteOfDay: Int) -> String {
        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func minuteOfDay(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func epochDay(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }

    private func toggleValue(_ value: String, in array: inout [String]) {
        if let idx = array.firstIndex(of: value) {
            array.remove(at: idx)
        } else {
            array.append(value)
        }
    }

    @ViewBuilder
    private func summarySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.body).bold()
                .foregroundStyle(.black)
            Text(text.isEmpty ? "-" : text)
                .font(.body)
                .foregroundStyle(.black.opacity(0.85))
        }
    }

    @ViewBuilder
    private func chipGrid(items: [String], selected: [String], onToggle: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                let isOn = selected.contains(item)
                Button {
                    onToggle(item)
                } label: {
                    Text(RitualL10n.exact(item))
                        .font(.body)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(isOn ? Color.blue.opacity(0.8) : Color.black.opacity(0.15))
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func cardBlock(title: String, body: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(title))
                .font(.title3.bold())
                .foregroundStyle(.black)
            Text(LocalizedStringKey(body))
                .font(.title3)
                .foregroundStyle(.black.opacity(0.85))
            content()
        }
        .padding(14)
        .background(LinearGradient.Amanecer())
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualDraftNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var noteText: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nota del ritual")
                    .font(.title3.bold())

                TextEditor(text: $noteText)
                    .frame(minHeight: 220)
                    .padding(10)
                    .background(Color.black.opacity(0.001))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    

                HStack {
                    Spacer()
                    Button("Guardar") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .onTapGesture {
                dismissKeyboard()
            }
            .navigationTitle("Añadir nota")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore

    @State private var stats = MorningRitualStatsSnapshot(sessions: [], reviews: [])

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.26),
                        Color(red: 0.11, green: 0.26, blue: 0.44),
                        Color(red: 0.95, green: 0.46, blue: 0.23)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        MorningRitualHeadlineCards(stats: stats)
                        MorningRitualClosingInsightsSection(stats: stats)
                        MorningRitualWeeklyBars(stats: stats)
                        MorningRitualTopTagsSection(stats: stats)
                        MorningRitualTrendSection(stats: stats)
                    }
                    .padding()
                }
            }
            .navigationTitle("Resumen de Rituales")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem {
                    Button {
                        reloadStats()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                reloadStats()
            }
            .onChange(of: store.sessions) { _, _ in
                reloadStats()
            }
            .onChange(of: store.eveningReviews) { _, _ in
                reloadStats()
            }
        }
    }

    private func reloadStats() {
        stats = MorningRitualStatsSnapshot(sessions: store.sessions, reviews: store.eveningReviews)
    }
}

private struct MorningRitualStatsSnapshot {
    struct WeekdayCount: Identifiable {
        var id: String { dayLabel }
        let dayLabel: String
        let count: Int
    }

    struct DayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let count: Int
    }

    struct NamedCount: Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    let totalRituals: Int
    let daysWithRitual: Int
    let currentStreak: Int
    let longestStreak: Int
    let weeklyAverage: Double
    let monthlyAverage: Double
    let avgGoalsPerRitual: Double
    let avgAnticipationsPerRitual: Double
    let totalEveningReviews: Int
    let closureRate: Double
    let avgEnergy: Double
    let avgIdentityAlignment: Double
    let avgPresenceReturns: Double
    let totalGoalUnitsCompleted: Int
    let weekdayCounts: [WeekdayCount]
    let topIdentities: [NamedCount]
    let topEmotions: [NamedCount]
    let dayPoints: [DayPoint]

    init(sessions: [MorningRitualSession], reviews: [EveningReview]) {
        let calendar = Calendar.current
        let days = sessions.map { Date(timeIntervalSince1970: TimeInterval($0.sessionDateEpochDay * 86_400)) }
            .map { calendar.startOfDay(for: $0) }
        let uniqueDays = Set(days)

        totalRituals = sessions.count
        daysWithRitual = uniqueDays.count

        let totalGoals = sessions.reduce(0) { $0 + $1.goals.count }
        avgGoalsPerRitual = sessions.isEmpty ? 0 : Double(totalGoals) / Double(sessions.count)

        let totalAnticipations = sessions.reduce(0) { partial, session in
            partial + min(session.anticipatedSituations.count, session.consciousResponses.count)
        }
        avgAnticipationsPerRitual = sessions.isEmpty ? 0 : Double(totalAnticipations) / Double(sessions.count)

        totalEveningReviews = reviews.count
        let morningDays = Set(sessions.map(\.sessionDateEpochDay))
        let completedCycles = Set(reviews.map(\.sessionDateEpochDay)).intersection(morningDays).count
        closureRate = morningDays.isEmpty ? 0 : Double(completedCycles) / Double(morningDays.count)
        avgEnergy = reviews.isEmpty ? 0 : Double(reviews.reduce(0) { $0 + $1.energy }) / Double(reviews.count)
        avgIdentityAlignment = reviews.isEmpty ? 0 : Double(reviews.reduce(0) { $0 + $1.identityAlignment }) / Double(reviews.count)
        avgPresenceReturns = reviews.isEmpty ? 0 : Double(reviews.reduce(0) { $0 + $1.presenceReturns }) / Double(reviews.count)
        totalGoalUnitsCompleted = reviews.reduce(0) { $0 + $1.goalUnitsCompletedCount }

        if let firstDate = days.min(), let lastDate = days.max() {
            let dayRange = max((calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0) + 1, 1)
            weeklyAverage = Double(totalRituals) / (Double(dayRange) / 7.0)

            let monthRange = max((calendar.dateComponents([.month], from: firstDate, to: lastDate).month ?? 0) + 1, 1)
            monthlyAverage = Double(totalRituals) / Double(monthRange)
        } else {
            weeklyAverage = 0
            monthlyAverage = 0
        }

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = AppLanguage.current.locale
        let weekdaySymbols = weekdayFormatter.veryShortStandaloneWeekdaySymbols
            ?? weekdayFormatter.veryShortWeekdaySymbols
            ?? ["S", "M", "T", "W", "T", "F", "S"]
        let weekdayMap = Dictionary(grouping: days, by: { calendar.component(.weekday, from: $0) })
            .mapValues(\.count)
        weekdayCounts = weekdaySymbols.enumerated().map { index, label in
            let weekday = index + 1
            return WeekdayCount(dayLabel: label, count: weekdayMap[weekday] ?? 0)
        }

        let identityValues = sessions
            .flatMap { $0.identity.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
            .filter { !$0.isEmpty }
        topIdentities = Dictionary(grouping: identityValues, by: { $0 })
            .map { NamedCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }

        let emotionValues = sessions.flatMap { $0.emotions }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        topEmotions = Dictionary(grouping: emotionValues, by: { $0 })
            .map { NamedCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }

        let dailyCounts = Dictionary(grouping: days, by: { $0 }).mapValues(\.count)
        dayPoints = Self.buildDayPoints(days: 30, calendar: calendar, dailyCounts: dailyCounts)

        longestStreak = Self.calculateLongestStreak(from: uniqueDays, calendar: calendar)
        currentStreak = Self.calculateCurrentStreak(from: uniqueDays, calendar: calendar)
    }

    private static func buildDayPoints(days: Int, calendar: Calendar, dailyCounts: [Date: Int]) -> [DayPoint] {
        var points: [DayPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let target = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: target)
            points.append(DayPoint(date: start, count: dailyCounts[start] ?? 0))
        }
        return points
    }

    private static func calculateCurrentStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), days.contains(yesterday) {
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func calculateLongestStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        let sorted = days.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for idx in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[idx - 1], to: sorted[idx]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }

        return best
    }
}

private struct MorningRitualHeadlineCards: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(spacing: 12) {
            Text("Resumen general")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                metricCard(title: "Mañanas", value: "\(stats.totalRituals)", subtitle: "rituales")
                metricCard(title: "Días activos", value: "\(stats.daysWithRitual)", subtitle: "Con ritual")
            }
            HStack(spacing: 10) {
                metricCard(title: "Racha actual", value: "\(stats.currentStreak)", subtitle: "días")
                metricCard(title: "Mejor racha", value: "\(stats.longestStreak)", subtitle: "días")
            }
            HStack(spacing: 10) {
                metricCard(title: "Prom. semanal", value: RitualL10n.decimal(stats.weeklyAverage), subtitle: "rituales")
                metricCard(title: "Metas/ritual", value: RitualL10n.decimal(stats.avgGoalsPerRitual), subtitle: "media")
            }
        }
    }

    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(LocalizedStringKey(subtitle))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MorningRitualWeeklyBars: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distribución semanal")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 10) {
                let maxCount = max(stats.weekdayCounts.map(\ .count).max() ?? 1, 1)
                ForEach(stats.weekdayCounts) { item in
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.85))
                                .frame(height: max(4, geo.size.height * CGFloat(item.count) / CGFloat(maxCount)))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                        .frame(height: 90)

                        Text(item.dayLabel)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MorningRitualClosingInsightsSection: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ciclo mañana → cierre")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                metric(title: "Cierres", value: "\(stats.totalEveningReviews)", subtitle: "registrados")
                metric(title: "Ciclos completos", value: "\(Int((stats.closureRate * 100).rounded()))%", subtitle: "con intención")
            }
            HStack(spacing: 10) {
                metric(title: "Energía media", value: score(stats.avgEnergy), subtitle: "de 5")
                metric(title: "Coherencia", value: score(stats.avgIdentityAlignment), subtitle: "de 5")
            }
            HStack(spacing: 10) {
                metric(title: "Presencia media", value: RitualL10n.decimal(stats.avgPresenceReturns), subtitle: "regresos/día")
                metric(title: "Metas avanzadas", value: "\(stats.totalGoalUnitsCompleted)", subtitle: "unidades")
            }

            Text(practicalInsight)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.82))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func metric(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.white.opacity(0.76))
            Text(value).font(.title3.bold())
            Text(LocalizedStringKey(subtitle)).font(.caption2).foregroundStyle(.white.opacity(0.66))
        }
        .foregroundStyle(.white)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func score(_ value: Double) -> String {
        value == 0 ? "—" : RitualL10n.decimal(value)
    }

    private var practicalInsight: String {
        guard stats.totalEveningReviews > 0 else {
            return RitualL10n.exact("Completa el cierre nocturno para transformar tu intención de la mañana en aprendizaje práctico.")
        }
        if stats.closureRate < 0.5 {
            return RitualL10n.exact("Tu oportunidad más clara: reserva una hora fija para cerrar más días de los que ya comienzas con intención.")
        }
        if stats.avgIdentityAlignment > 0, stats.avgIdentityAlignment < 3 {
            return RitualL10n.exact("La intención está presente, pero la coherencia aún es baja: elige un gesto visible que exprese tu identidad durante la primera hora del día.")
        }
        if stats.avgEnergy > 0, stats.avgEnergy < 3 {
            return RitualL10n.exact("La energía media es baja: usa la preparación nocturna para reducir fricción y proteger el inicio de mañana.")
        }
        return RitualL10n.exact("Estás cerrando el ciclo con constancia. Conserva tu preparación de mañana y repite las acciones que sostienen tu coherencia.")
    }
}

private struct MorningRitualTopTagsSection: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Enfoques frecuentes")
                .font(.headline)
                .foregroundStyle(.white)

            sectionRow(title: "Identidades", items: stats.topIdentities)
            sectionRow(title: "Emociones", items: stats.topEmotions)
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionRow(title: String, items: [MorningRitualStatsSnapshot.NamedCount]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.9))

            if items.isEmpty {
                Text("Sin datos")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            Text("\(RitualL10n.exact(item.name))  \(item.count)")
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(.white.opacity(0.18))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

private struct MorningRitualTrendSection: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tendencia últimos 30 días")
                .font(.headline)
                .foregroundStyle(.white)

            GeometryReader { geo in
                let points = stats.dayPoints
                let maxCount = max(points.map(\ .count).max() ?? 1, 1)
                let stepX = max(geo.size.width / CGFloat(max(points.count - 1, 1)), 1)

                Path { path in
                    guard !points.isEmpty else { return }
                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height - (CGFloat(point.count) / CGFloat(maxCount) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 90)

            Text(RitualL10n.format(
                "ritual.stats.monthly_average",
                fallback: "Promedio mensual: {0} rituales",
                RitualL10n.decimal(stats.monthlyAverage)
            ))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// Vista del Historial
private struct MorningRitualHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore
    @State private var selectedForNote: MorningRitualSession?
    @State private var expandedSessionId: UUID?
    @State private var expandedReviewId: UUID?
    @State private var searchText: String = ""
    @State private var currentMonth: Date = Date()
    @State private var selectedEpochDay: Int? = nil
    @State private var showCalendar: Bool = false
    @State private var selectedHistoryKind: RitualHistoryKind = .morning

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.50, blue: 0.45),
                        Color(red: 0.66, green: 0.50, blue: 0.80),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCalendar.toggle()
                            }
                        } label: {
                            Image(systemName: showCalendar ? "calendar.badge.minus" : "calendar")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                    }

                    TextField(searchPlaceholder, text: $searchText)
                        .morningRitualTextFieldStyle()

                    if showCalendar {
                        MorningRitualHistoryCalendarView(
                            currentMonth: $currentMonth,
                            markedEpochDays: markedEpochDays,
                            selectedEpochDay: $selectedEpochDay
                        )
                    }

                    if let selectedEpochDay {
                        HStack {
                            Text(RitualL10n.format(
                                "ritual.history.filtering",
                                fallback: "Filtrando: {0}",
                                formattedDateFromEpochDay(selectedEpochDay)
                            ))
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.9))
                            Spacer()
                            Button("Limpiar") {
                                self.selectedEpochDay = nil
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 4)
                    }

                    ScrollView {
                        VStack(spacing: 10) {
                            if activeFilteredCount == 0 {
                                Text(emptyStateText)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.top, 10)
                            }

                            switch selectedHistoryKind {
                            case .morning:
                                morningHistoryList
                            case .evening:
                                eveningHistoryList
                            }
                        }
                        .padding(.bottom, 92)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Historial")
            .toolbar {
                ToolbarItem {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                historyKindBar
            }
            .onTapGesture {
                dismissKeyboard()
            }
            .onChange(of: store.sessions) { _, newSessions in
                guard selectedHistoryKind == .morning else { return }
                if let selectedEpochDay, !newSessions.contains(where: { $0.sessionDateEpochDay == selectedEpochDay }) {
                    self.selectedEpochDay = nil
                }
                if let expandedSessionId, !newSessions.contains(where: { $0.id == expandedSessionId }) {
                    self.expandedSessionId = nil
                }
            }
            .onChange(of: store.eveningReviews) { _, newReviews in
                guard selectedHistoryKind == .evening else { return }
                if let selectedEpochDay, !newReviews.contains(where: { $0.sessionDateEpochDay == selectedEpochDay }) {
                    self.selectedEpochDay = nil
                }
                if let expandedReviewId, !newReviews.contains(where: { $0.id == expandedReviewId }) {
                    self.expandedReviewId = nil
                }
            }
            .onChange(of: selectedHistoryKind) { _, _ in
                selectedEpochDay = nil
                expandedSessionId = nil
                expandedReviewId = nil
            }
            .sheet(item: $selectedForNote) { session in
                MorningRitualNoteView(initialText: session.noteText) { note in
                    store.updateNote(sessionId: session.id, noteText: note)
                    selectedForNote = nil
                }
            }
        }
    }

    private enum RitualHistoryKind: String, CaseIterable, Identifiable {
        case morning
        case evening

        var id: String { rawValue }

        var title: String {
            switch self {
            case .morning: return RitualL10n.exact("Matutinos")
            case .evening: return RitualL10n.exact("Cierre Consciente")
            }
        }
    }

    private var historyKindBar: some View {
        HStack(spacing: 10) {
            ForEach(RitualHistoryKind.allCases) { kind in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedHistoryKind = kind
                    }
                } label: {
                    Text(kind.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedHistoryKind == kind ? .black : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedHistoryKind == kind ? Color.white : Color.white.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.black.opacity(0.35))
    }

    private var searchPlaceholder: String {
        switch selectedHistoryKind {
        case .morning:
            return RitualL10n.exact("Buscar en metas, identidad, emoción o anticipación")
        case .evening:
            return RitualL10n.exact("Buscar en emoción, aprendizaje, gratitud o mejora")
        }
    }

    private var markedEpochDays: Set<Int> {
        switch selectedHistoryKind {
        case .morning:
            return Set(store.sessions.map(\.sessionDateEpochDay))
        case .evening:
            return Set(store.eveningReviews.map(\.sessionDateEpochDay))
        }
    }

    private var activeFilteredCount: Int {
        switch selectedHistoryKind {
        case .morning:
            return filteredSessions.count
        case .evening:
            return filteredEveningReviews.count
        }
    }

    private var emptyStateText: String {
        let hasAnyItems = selectedHistoryKind == .morning ? !store.sessions.isEmpty : !store.eveningReviews.isEmpty
        if hasAnyItems {
            return RitualL10n.exact("No hay rituales que coincidan con el filtro.")
        }
        return selectedHistoryKind == .morning
            ? RitualL10n.exact("Aún no hay rituales matutinos guardados.")
            : RitualL10n.exact("Aún no hay cierres conscientes guardados.")
    }

    private var morningHistoryList: some View {
        ForEach(filteredSessions) { session in
            let isExpanded = expandedSessionId == session.id

            VStack(alignment: .leading, spacing: 8) {
                historyHeader(
                    title: formattedDate(session.completedAtEpochMillis),
                    subtitle: "Ritual matutino",
                    isExpanded: isExpanded
                ) {
                    expandedSessionId = isExpanded ? nil : session.id
                }

                if isExpanded {
                    detailSection(session)
                } else {
                    Text(summaryText(for: session))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(4)
                }

                HStack {
                    Button(session.noteText.isEmpty ? "Crear nota" : "Editar nota") {
                        selectedForNote = session
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Eliminar", role: .destructive) {
                        store.deleteSession(sessionId: session.id)
                        if expandedSessionId == session.id {
                            expandedSessionId = nil
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .historyCardStyle()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSessionId = isExpanded ? nil : session.id
                }
            }
        }
    }

    private var eveningHistoryList: some View {
        ForEach(filteredEveningReviews) { review in
            let isExpanded = expandedReviewId == review.id

            VStack(alignment: .leading, spacing: 8) {
                historyHeader(
                    title: formattedDate(review.completedAtEpochMillis),
                    subtitle: "Cierre consciente",
                    isExpanded: isExpanded
                ) {
                    expandedReviewId = isExpanded ? nil : review.id
                }

                if isExpanded {
                    eveningReviewDetailSection(review)
                } else {
                    Text(summaryText(for: review))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(4)
                }

                HStack {
                    Spacer()
                    Button("Eliminar", role: .destructive) {
                        store.deleteEveningReview(reviewId: review.id)
                        if expandedReviewId == review.id {
                            expandedReviewId = nil
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .historyCardStyle()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedReviewId = isExpanded ? nil : review.id
                }
            }
        }
    }

    private func historyHeader(title: String, subtitle: String, isExpanded: Bool, toggle: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(subtitle))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2), toggle)
            } label: {
                Label(LocalizedStringKey(isExpanded ? "Colapsar" : "Expandir"), systemImage: isExpanded ? "chevron.up" : "chevron.down")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var filteredSessions: [MorningRitualSession] {
        let normalizedQuery = normalizedText(searchText)

        return store.sessions.filter { session in
            if let selectedEpochDay, session.sessionDateEpochDay != selectedEpochDay {
                return false
            }

            guard !normalizedQuery.isEmpty else { return true }

            let searchCorpus = [
                session.goals.joined(separator: " "),
                session.identity,
                session.emotions.joined(separator: " "),
                session.anticipatedSituations.joined(separator: " "),
                session.consciousResponses.joined(separator: " ")
            ].joined(separator: " ")

            return normalizedText(searchCorpus).contains(normalizedQuery)
        }
    }

    private var filteredEveningReviews: [EveningReview] {
        let normalizedQuery = normalizedText(searchText)

        return store.eveningReviews.filter { review in
            if let selectedEpochDay, review.sessionDateEpochDay != selectedEpochDay {
                return false
            }

            guard !normalizedQuery.isEmpty else { return true }

            let searchCorpus = [
                PresenciaMood.title(for: review.predominantEmotionID),
                review.whatWentWell,
                review.learning,
                review.autopilotMoment,
                review.gratitude,
                review.tomorrowPreparation,
                review.suggestion
            ].joined(separator: " ")

            return normalizedText(searchCorpus).contains(normalizedQuery)
        }
    }

    private func normalizedText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedDateFromEpochDay(_ epochDay: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochDay * 86_400))
        return RitualL10n.formattedDate(date, dateStyle: .medium)
    }

    @ViewBuilder
    private func detailSection(_ session: MorningRitualSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            historyItem(title: "Metas", value: session.goals.isEmpty ? "-" : "• " + session.goals.joined(separator: "\n• "))
            historyItem(title: "Identidad", value: session.identity.isEmpty ? "-" : RitualL10n.localizedIdentityList(session.identity))
            historyItem(title: "Emociones", value: session.emotions.isEmpty ? "-" : RitualL10n.localizedEmotionList(session.emotions))
            historyItem(title: "Anticipación", value: anticipationText(for: session))
            historyItem(title: "Nota", value: session.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : session.noteText)
        }
    }

    @ViewBuilder
    private func eveningReviewDetailSection(_ review: EveningReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            historyItem(title: "Energía", value: "\(review.energy)/5")
            historyItem(title: "Emoción predominante", value: RitualL10n.localizedMood(review.predominantEmotionID))
            historyItem(title: "Lo que salió bien", value: displayValue(review.whatWentWell))
            historyItem(title: "Aprendizaje", value: displayValue(review.learning))
            historyItem(title: "Piloto automático", value: displayValue(review.autopilotMoment))
            historyItem(title: "Gratitud", value: displayValue(review.gratitude))
            historyItem(title: "Preparado para mañana", value: displayValue(review.tomorrowPreparation))
            historyItem(title: "Coherencia", value: "\(review.identityAlignment)/5")
            historyItem(title: "Huella del día", value: RitualL10n.format(
                "ritual.day_footprint",
                fallback: "Agenda {0}/{1} · Metas {2} · Presencia {3}",
                "\(review.agendaCompletedCount)", "\(review.agendaTotalCount)", "\(review.goalUnitsCompletedCount)", "\(review.presenceReturns)"
            ))
            historyItem(title: "Mejora para mañana", value: displayValue(RitualL10n.localizedSuggestion(review.suggestion)))
        }
    }

    private func historyItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func anticipationText(for session: MorningRitualSession) -> String {
        let count = min(session.anticipatedSituations.count, session.consciousResponses.count)
        guard count > 0 else { return "-" }

        return (0..<count)
            .map { "• \(session.anticipatedSituations[$0]) → \(session.consciousResponses[$0])" }
            .joined(separator: "\n")
    }

    private func summaryText(for session: MorningRitualSession) -> String {
        let goals = session.goals.isEmpty ? "-" : session.goals.joined(separator: " • ")
        let identity = session.identity.isEmpty ? "-" : RitualL10n.localizedIdentityList(session.identity)
        let emotions = session.emotions.isEmpty ? "-" : RitualL10n.localizedEmotionList(session.emotions)
        return RitualL10n.format(
            "ritual.history.morning_summary",
            fallback: "Metas: {0}\nIdentidad: {1}\nEmociones: {2}",
            goals, identity, emotions
        )
    }

    private func summaryText(for review: EveningReview) -> String {
        let emotion = RitualL10n.localizedMood(review.predominantEmotionID)
        return RitualL10n.format(
            "ritual.history.evening_summary",
            fallback: "Energía: {0}/5 · Emoción: {1}\nAprendizaje: {2}\nMejora: {3}",
            "\(review.energy)", emotion, displayValue(review.learning), displayValue(RitualL10n.localizedSuggestion(review.suggestion))
        )
    }

    private func displayValue(_ text: String) -> String {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? "-" : normalized
    }

    private func formattedDate(_ millis: Int64) -> String {
        RitualL10n.formattedDate(Date(timeIntervalSince1970: TimeInterval(millis) / 1_000), dateStyle: .medium)
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private extension View {
    func historyCardStyle() -> some View {
        self
            .padding(14)
            .background(.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MorningRitualHistoryCalendarView: View {
    @Binding var currentMonth: Date
    let markedEpochDays: Set<Int>
    @Binding var selectedEpochDay: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text(monthTitle)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }

                ForEach(daysInMonth.indices, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        let epoch = epochDay(for: date)
                        let isSelected = selectedEpochDay == epoch
                        let hasSession = markedEpochDays.contains(epoch)

                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 18, weight: hasSession ? .bold : .regular, design: .default))
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(hasSession ? Color.white.opacity(0.18) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(hasSession ? .black : .white)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedEpochDay = (selectedEpochDay == epoch) ? nil : epoch
                                }
                            }
                    } else {
                        Color.clear
                            .frame(height: 34)
                    }
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
    }

    private var daysInMonth: [Date?] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        days += range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
        return days
    }

    private func changeMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = next
        }
    }

    private func epochDay(for date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }
}

private struct MorningRitualNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State var initialText: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $initialText)
                    .padding(8)
                    .background(.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Guardar nota") {
                    onSave(initialText)
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .onTapGesture {
                dismissKeyboard()
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.25, blue: 0.35), Color(red: 0.15, green: 0.16, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Nota del ritual")
        }
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore

    @State private var enabled = false
    @State private var hour = 7
    @State private var minute = 30
    @State private var eveningReminderEnabled = false
    @State private var eveningReminderHour = 21
    @State private var eveningReminderMinute = 30
    @AppStorage("ritual_private_reflections_protected") private var privacyEnabled = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.14, blue: 0.31), Color(red: 0.18, green: 0.32, blue: 0.24)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        reminderSection(
                            title: "Recordatorio matutino",
                            subtitle: "Empieza el día con intención.",
                            icon: "sunrise.fill",
                            enabled: $enabled,
                            hour: $hour,
                            minute: $minute
                        )

                        reminderSection(
                            title: "Recordatorio de cierre",
                            subtitle: "Una pausa para integrar el día y preparar mañana.",
                            icon: "moon.stars.fill",
                            enabled: $eveningReminderEnabled,
                            hour: $eveningReminderHour,
                            minute: $eveningReminderMinute
                        )
                        
                        Toggle(isOn: $privacyEnabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Label("Proteger reflexiones de cierre", systemImage: "lock.heart.fill")
                                    .font(.headline)
                                Text("Pide biometría o código para abrir cierres y el panel Mi día.")
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.68))
                            }
                        }
                        .tint(.green)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Button("Guardar cambios") {
                            store.applySettings(
                                enabled: enabled,
                                hour: hour,
                                minute: minute,
                                eveningReminderEnabled: eveningReminderEnabled,
                                eveningReminderHour: eveningReminderHour,
                                eveningReminderMinute: eveningReminderMinute
                            )
                            dismiss()
                        }
                        .foregroundStyle(.black)
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                    }
                    .padding(.vertical, 4)
                }

                .padding(16)
            }
            .onTapGesture {
                dismissKeyboard()
            }
            //.navigationTitle("Ajustes")
            .onAppear {
                enabled = store.settings.enabled
                hour = store.settings.hour
                minute = store.settings.minute
                eveningReminderEnabled = store.settings.eveningReminderEnabled
                eveningReminderHour = store.settings.eveningReminderHour
                eveningReminderMinute = store.settings.eveningReminderMinute
            }
        }
    }

    private func reminderSection(
        title: String,
        subtitle: String,
        icon: String,
        enabled: Binding<Bool>,
        hour: Binding<Int>,
        minute: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.yellow)
                    .font(.title3)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title)).font(.headline)
                    Text(LocalizedStringKey(subtitle))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(.green)
            }

            HStack(spacing: 12) {
                Picker("Hora", selection: hour) {
                    ForEach(0..<24, id: \.self) { value in
                        Text(String(format: "%02d", value)).tag(value)
                    }
                }
                Picker("Minuto", selection: minute) {
                    ForEach(0..<60, id: \.self) { value in
                        Text(String(format: "%02d", value)).tag(value)
                    }
                }
            }
#if os(iOS)
            .pickerStyle(.menu)
#endif
            .disabled(!enabled.wrappedValue)
            .opacity(enabled.wrappedValue ? 1 : 0.45)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.white.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.14), lineWidth: 1))
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}
