import Foundation
import CoreData
@preconcurrency import WatchConnectivity
import Combine
import UserNotifications

enum WatchGoalSyncKeys {
    static let snapshot = "ios_goal_units_snapshot_v1"
    static let requestSnapshot = "watch_goal_units_request_v1"
    static let completeUnit = "watch_goal_unit_complete_v1"
    static let expireUnit = "watch_goal_unit_expire_v1"
    static let completionResult = "ios_goal_unit_completion_result_v1"
}

struct WatchGoalUnit: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let goalID: String
    let goalTitle: String
    let unitName: String
    let targetText: String
    let index: Int
    let startDate: Date
    let endDate: Date

    func isAvailable(at date: Date) -> Bool {
        startDate <= date && date <= endDate
    }

    static func fromDictionary(_ value: [String: Any]) -> WatchGoalUnit? {
        guard let id = value["id"] as? String,
              let goalID = value["goalID"] as? String,
              let goalTitle = value["goalTitle"] as? String,
              let unitName = value["unitName"] as? String,
              let targetText = value["targetText"] as? String,
              let startInterval = (value["startDate"] as? NSNumber)?.doubleValue,
              let endInterval = (value["endDate"] as? NSNumber)?.doubleValue else {
            return nil
        }

        return WatchGoalUnit(
            id: id,
            goalID: goalID,
            goalTitle: goalTitle,
            unitName: unitName,
            targetText: targetText,
            index: (value["index"] as? NSNumber)?.intValue ?? 0,
            startDate: Date(timeIntervalSince1970: startInterval),
            endDate: Date(timeIntervalSince1970: endInterval)
        )
    }
}

struct WatchGoalCardItem: Identifiable {
    let id: String
    let title: String
    let activeUnit: WatchGoalUnit?
    let nextUnit: WatchGoalUnit?

    var displayedUnit: WatchGoalUnit? { activeUnit ?? nextUnit }
    var isAvailable: Bool { activeUnit != nil }
}

@MainActor
final class WatchGoalUnitsStore: ObservableObject {
    static let shared = WatchGoalUnitsStore()

    @Published private(set) var units: [WatchGoalUnit] = []
    @Published private(set) var pendingCompletionIDs: Set<String> = []
    @Published var lastError: String?

    private let unitsDefaultsKey = "watch.goalUnits.snapshot.v1"
    private let pendingDefaultsKey = "watch.goalUnits.pending.v1"
    private let expirationDefaultsKey = "watch.goalUnits.expiring.v1"
    private var pendingExpirationIDs: Set<String> = []
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private init() {
        if let data = UserDefaults.standard.data(forKey: unitsDefaultsKey),
           let saved = try? JSONDecoder().decode([WatchGoalUnit].self, from: data) {
            units = saved
        }
        pendingCompletionIDs = Set(UserDefaults.standard.stringArray(forKey: pendingDefaultsKey) ?? [])
        pendingExpirationIDs = Set(UserDefaults.standard.stringArray(forKey: expirationDefaultsKey) ?? [])
    }

    func applySnapshot(_ snapshotUnits: [WatchGoalUnit]) {
        let incoming = snapshotUnits.sorted { $0.startDate < $1.startDate }
        let incomingIDs = Set(incoming.map(\.id))

        units = incoming.filter { !pendingExpirationIDs.contains($0.id) }
        pendingCompletionIDs.formIntersection(incomingIDs)
        pendingExpirationIDs.formIntersection(incomingIDs)
        persist()
        WatchGoalNotificationScheduler.shared.synchronize(with: incoming)
    }

    func requestSnapshot() {
        guard let session else { return }
        let message: [String: Any] = [
            WatchGoalSyncKeys.requestSnapshot: ["requestedAt": Date().timeIntervalSince1970]
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { [weak self] _ in
                Task { @MainActor in
                    if let session = self?.session {
                        _ = session.transferUserInfo(message)
                    }
                }
            }
        } else {
            session.transferUserInfo(message)
        }
    }

    func complete(_ unit: WatchGoalUnit, now: Date = Date()) {
        guard unit.isAvailable(at: now), !pendingCompletionIDs.contains(unit.id), let session else { return }

        pendingCompletionIDs.insert(unit.id)
        persistPending()
        let payload: [String: Any] = [
            "unitID": unit.id,
            "goalID": unit.goalID,
            "completedAt": now.timeIntervalSince1970
        ]
        let message: [String: Any] = [WatchGoalSyncKeys.completeUnit: payload]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { [weak self] _ in
                Task { @MainActor in self?.queueCompletion(message, unitID: unit.id) }
            }
        } else {
            queueCompletion(message, unitID: unit.id)
        }
    }

    func availableUnits(at date: Date) -> [WatchGoalUnit] {
        units.filter { $0.isAvailable(at: date) }
    }

    func nextUnit(after date: Date) -> WatchGoalUnit? {
        units.first { $0.startDate > date }
    }

    func goalCards(at date: Date) -> [WatchGoalCardItem] {
        Dictionary(grouping: units, by: \.goalID)
            .compactMap { goalID, goalUnits in
                let sorted = goalUnits.sorted { $0.startDate < $1.startDate }
                let active = sorted.first { $0.isAvailable(at: date) }
                let next = sorted.first { $0.startDate > date }
                guard active != nil || next != nil else { return nil }
                return WatchGoalCardItem(
                    id: goalID,
                    title: sorted.first?.goalTitle ?? "Meta",
                    activeUnit: active,
                    nextUnit: next
                )
            }
            .sorted { lhs, rhs in
                if lhs.isAvailable != rhs.isAvailable { return lhs.isAvailable }
                let leftDate = lhs.displayedUnit?.startDate ?? .distantFuture
                let rightDate = rhs.displayedUnit?.startDate ?? .distantFuture
                return leftDate < rightDate
            }
    }

    func expireUnitsIfNeeded(at date: Date) {
        let expired = units.filter {
            $0.endDate < date && !pendingExpirationIDs.contains($0.id)
        }
        guard !expired.isEmpty else { return }

        for unit in expired {
            pendingExpirationIDs.insert(unit.id)
            sendExpiration(for: unit, at: date)
        }
        units.removeAll { pendingExpirationIDs.contains($0.id) }
        persist()
        WatchGoalNotificationScheduler.shared.synchronize(with: units)
    }

    private func queueCompletion(_ message: [String: Any], unitID: String) {
        session?.transferUserInfo(message)
        pendingCompletionIDs.insert(unitID)
        persistPending()
    }

    private func sendExpiration(for unit: WatchGoalUnit, at date: Date) {
        guard let session else { return }
        let message: [String: Any] = [
            WatchGoalSyncKeys.expireUnit: [
                "unitID": unit.id,
                "goalID": unit.goalID,
                "detectedAt": date.timeIntervalSince1970
            ]
        ]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                _ = session.transferUserInfo(message)
            }
        } else {
            session.transferUserInfo(message)
        }
    }

    func applyCompletionResult(unitID: String, success: Bool, reason: String?) {
        if success {
            units.removeAll { $0.id == unitID }
            pendingCompletionIDs.remove(unitID)
            persist()
            WatchGoalNotificationScheduler.shared.remove(unitID: unitID)
        } else {
            pendingCompletionIDs.remove(unitID)
            persistPending()
            lastError = reason ?? WatchL10n.exact("No se pudo completar la unidad")
            requestSnapshot()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(units) {
            UserDefaults.standard.set(data, forKey: unitsDefaultsKey)
        }
        persistPending()
    }

    private func persistPending() {
        UserDefaults.standard.set(Array(pendingCompletionIDs), forKey: pendingDefaultsKey)
        UserDefaults.standard.set(Array(pendingExpirationIDs), forKey: expirationDefaultsKey)
    }
}

@MainActor
final class WatchGoalNotificationScheduler {
    static let shared = WatchGoalNotificationScheduler()

    static let categoryID = "GOAL_UNIT_AVAILABLE"
    static let destinationKey = "watchDestination"
    static let destinationValue = "goals"

    private let center = UNUserNotificationCenter.current()
    private let registeredDefaultsKey = "watch.goalUnits.notificationIDs.v1"
    private var registeredIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: registeredDefaultsKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: registeredDefaultsKey) }
    }

    func synchronize(with units: [WatchGoalUnit]) {
        let validIDs = Set(units.map(\.id))
        let registered = registeredIDs.intersection(validIDs)
        let obsolete = registeredIDs.subtracting(validIDs).map(Self.notificationID)
        if !obsolete.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: obsolete)
            center.removeDeliveredNotifications(withIdentifiers: obsolete)
        }

        guard !units.isEmpty else {
            registeredIDs = []
            return
        }

        Task { [weak self] in
            guard let self,
                  (try? await center.requestAuthorization(options: [.alert, .sound])) == true else {
                return
            }

            var updatedRegistered = registered
            let now = Date()
            for unit in units.sorted(by: { $0.startDate < $1.startDate }).prefix(60)
            where !updatedRegistered.contains(unit.id) {
                let content = UNMutableNotificationContent()
                content.title = WatchL10n.exact("Meta disponible")
                content.body = "\(unit.goalTitle): \(unit.targetText)"
                content.sound = .default
                content.categoryIdentifier = Self.categoryID
                content.userInfo = [
                    Self.destinationKey: Self.destinationValue,
                    "unitID": unit.id
                ]

                let delay = max(unit.startDate.timeIntervalSince(now), 1)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                let request = UNNotificationRequest(
                    identifier: Self.notificationID(unit.id),
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                    updatedRegistered.insert(unit.id)
                } catch {
                    continue
                }
            }
            registeredIDs = updatedRegistered
        }
    }

    func remove(unitID: String) {
        let identifier = Self.notificationID(unitID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        var registered = registeredIDs
        registered.remove(unitID)
        registeredIDs = registered
    }

    private static func notificationID(_ unitID: String) -> String {
        "goal-unit-\(unitID)"
    }
}

@MainActor
final class WatchGoalNotificationRouter: NSObject, ObservableObject, @preconcurrency UNUserNotificationCenterDelegate {
    static let shared = WatchGoalNotificationRouter()
    @Published var shouldOpenGoals = false

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let openAction = UNNotificationAction(
            identifier: "OPEN_GOAL_UNITS",
            title: WatchL10n.exact("Ver unidad"),
            options: [.foreground]
        )
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: WatchGoalNotificationScheduler.categoryID,
                actions: [openAction],
                intentIdentifiers: []
            )
        ])
    }

    func consumeRequest() {
        shouldOpenGoals = false
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.userInfo[WatchGoalNotificationScheduler.destinationKey] as? String
            == WatchGoalNotificationScheduler.destinationValue {
            shouldOpenGoals = true
        }
        completionHandler()
    }
}

@MainActor
final class WatchIncomingDataReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchIncomingDataReceiver()

    private enum Keys {
        static let notesBatch = "ios_notes_batch_v1"
        static let noteDelete = "ios_note_delete_v1"
        static let diarioBatch = "ios_diario_batch_v1"
        static let diarioDelete = "ios_diario_delete_v1"
        static let agendaBatch = "ios_agenda_batch_v1"
        static let agendaDelete = "ios_agenda_delete_v1"
        static let presenceBatch = "ios_presence_batch_v1"
        static let presenceReset = "ios_presence_reset_v1"
        static let premiumState = "ios_premium_state_v1"
    }

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingPayload(userInfo)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingPayload(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingPayload(applicationContext)
    }

    private nonisolated func handleIncomingPayload(_ payload: [String: Any]) {
        if let completionResult = payload[WatchGoalSyncKeys.completionResult] as? [String: Any],
           let unitID = completionResult["unitID"] as? String,
           let success = completionResult["success"] as? Bool {
            let reason = completionResult["reason"] as? String
            Task { @MainActor in
                WatchGoalUnitsStore.shared.applyCompletionResult(
                    unitID: unitID,
                    success: success,
                    reason: reason
                )
            }
            return
        }

        if let goalSnapshot = payload[WatchGoalSyncKeys.snapshot] as? [String: Any] {
            let rawUnits = goalSnapshot["units"] as? [[String: Any]] ?? []
            let units = rawUnits.compactMap(WatchGoalUnit.fromDictionary)
            Task { @MainActor in
                WatchGoalUnitsStore.shared.applySnapshot(units)
            }
        }

        if let rawPremiumState = payload[Keys.premiumState] as? [String: Any] {
            let yorjPremium = rawPremiumState["yorjPremium"] as? Bool ?? false
            let purchaseStatus = rawPremiumState["purchaseStatus"] as? Bool ?? false
            Task { @MainActor in
                self.applyPremiumState(yorjPremium: yorjPremium, purchaseStatus: purchaseStatus)
            }
            return
        }

        if payload[Keys.presenceReset] as? [String: Any] != nil {
            Task { @MainActor in
                await self.resetPresenceEvents()
            }
            return
        }

        if let rawDeletedNote = payload[Keys.noteDelete] as? [String: Any],
           let noteID = rawDeletedNote["id"] as? String {
            Task { @MainActor in
                await self.deleteNote(id: noteID)
            }
            return
        }

        if let rawNote = payload[Keys.notesBatch] as? [String: Any],
           let notePayload = WatchNoteTransferPayload.fromDictionary(rawNote) {
            Task { @MainActor in
                await self.upsertNote(payload: notePayload)
            }
            return
        }

        if let rawDiario = payload[Keys.diarioBatch] as? [String: Any],
           let diarioPayload = WatchDiarioTransferPayload.fromDictionary(rawDiario) {
            Task { @MainActor in
                await self.upsertDiario(payload: diarioPayload)
            }
            return
        }

        if let rawDeletedDiario = payload[Keys.diarioDelete] as? [String: Any],
           let diarioID = rawDeletedDiario["id"] as? String {
            Task { @MainActor in
                await self.deleteDiario(id: diarioID)
            }
            return
        }

        if let rawAgenda = payload[Keys.agendaBatch] as? [String: Any],
           let agendaPayload = WatchAgendaTransferPayload.fromDictionary(rawAgenda) {
            Task { @MainActor in
                await self.upsertAgenda(payload: agendaPayload)
            }
            return
        }

        if let rawDeletedAgenda = payload[Keys.agendaDelete] as? [String: Any],
           let agendaID = rawDeletedAgenda["id"] as? String {
            Task { @MainActor in
                await self.deleteAgenda(id: agendaID)
            }
            return
        }

        if let rawPresence = payload[Keys.presenceBatch] as? [String: Any],
           let presencePayload = WatchPresenceTransferPayload.fromDictionary(rawPresence) {
            Task { @MainActor in
                await self.upsertPresence(payload: presencePayload)
            }
        }
    }

    private func deleteNote(id: String) async {
        let noteID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !noteID.isEmpty else { return }

        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para eliminar nota en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Notas> = Notas.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", noteID)

            do {
                let notes = try context.fetch(request)
                guard !notes.isEmpty else { return }

                notes.forEach(context.delete)
                try context.save()

                Task { @MainActor in
                    watchModel.shared.getNotas()
                }
            } catch {
                context.rollback()
                msg("❌ No se pudo eliminar nota en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func upsertNote(payload: WatchNoteTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para sincronizar notas en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Notas> = Notas.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", payload.id)

            let note: Notas
            if let existing = try? context.fetch(request).first {
                let currentModified = (existing.value(forKey: "fechaModificacion") as? Date) ?? .distantPast
                guard payload.fechaModificacion >= currentModified else { return }
                note = existing
            } else {
                note = Notas(context: context)
                note.id = payload.id
            }

            note.title = payload.title
            note.nota = payload.nota
            note.isfav = payload.isfav
            note.setValue(payload.categoria, forKey: "categoria")
            note.setValue(payload.direccionMapa, forKey: "direccionMapa")
            note.setValue(payload.fechaCreacion, forKey: "fechaCreacion")
            note.setValue(payload.fechaModificacion, forKey: "fechaModificacion")

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo aplicar nota entrante en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func upsertDiario(payload: WatchDiarioTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para sincronizar diario en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Diario> = Diario.fetchRequest()
            request.fetchLimit = 1

            if let uuid = UUID(uuidString: payload.id) {
                request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            } else {
                request.predicate = NSPredicate(format: "title == %@ AND fecha == %@", payload.title, payload.fecha as NSDate)
            }

            let diario: Diario
            if let existing = try? context.fetch(request).first {
                let currentModified = existing.fechaM ?? .distantPast
                guard payload.fechaM >= currentModified else { return }
                diario = existing
            } else {
                diario = Diario(context: context)
                diario.id = UUID(uuidString: payload.id) ?? UUID()
            }

            diario.title = payload.title
            diario.content = payload.content
            diario.emotion = payload.emotion
            diario.isFav = payload.isFav
            diario.setValue(payload.direccionMapa, forKey: "direccionMapa")
            diario.fecha = payload.fecha
            diario.fechaM = payload.fechaM

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo aplicar diario entrante en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func deleteDiario(id: String) async {
        let diarioID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: diarioID) else { return }

        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para eliminar diario en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Diario> = Diario.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

            do {
                let entries = try context.fetch(request)
                guard !entries.isEmpty else { return }

                entries.forEach(context.delete)
                try context.save()

                Task { @MainActor in
                    watchModel.shared.getDiarioEntradas()
                }
            } catch {
                context.rollback()
                msg("❌ No se pudo eliminar diario en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func upsertAgenda(payload: WatchAgendaTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para sincronizar agenda en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            guard
                let agendaID = UUID(uuidString: payload.id),
                let entity = NSEntityDescription.entity(forEntityName: "AgendaItemEntity", in: context)
            else {
                return
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", agendaID as CVarArg)

            let row: NSManagedObject
            if let existing = try? context.fetch(request).first {
                let currentModified = (existing.value(forKey: "fechaModificacion") as? Date) ?? .distantPast
                guard payload.fechaModificacion >= currentModified else { return }
                row = existing
            } else {
                row = NSManagedObject(entity: entity, insertInto: context)
                row.setValue(agendaID, forKey: "id")
            }

            row.setValue(payload.titulo, forKey: "titulo")
            row.setValue(payload.fechaCreacion, forKey: "fechaCreacion")
            row.setValue(payload.fechaModificacion, forKey: "fechaModificacion")
            row.setValue(payload.nota, forKey: "nota")
            row.setValue(payload.fechaActividad, forKey: "fechaActividad")
            row.setValue(payload.hora, forKey: "hora")
            row.setValue(payload.lugar, forKey: "lugar")
            row.setValue(payload.contenido, forKey: "contenido")
            row.setValue(payload.prioridad, forKey: "prioridad")
            row.setValue(payload.colorHex, forKey: "colorHex")
            row.setValue(payload.completada, forKey: "completada")
            row.setValue(payload.recordatorioActivo, forKey: "recordatorioActivo")
            row.setValue(payload.reminderID, forKey: "reminderID")
            row.setValue(payload.seriesID.flatMap(UUID.init(uuidString:)), forKey: "seriesID")

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo aplicar agenda entrante en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func deleteAgenda(id: String) async {
        let agendaID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: agendaID) else { return }

        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para eliminar agenda en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

            do {
                let rows = try context.fetch(request)
                guard !rows.isEmpty else { return }

                rows.forEach(context.delete)
                try context.save()

                Task { @MainActor in
                    watchModel.shared.getAgendaEntradas()
                }
            } catch {
                context.rollback()
                msg("❌ No se pudo eliminar agenda en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func upsertPresence(payload: WatchPresenceTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para sincronizar presencia en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            guard
                let presenceID = UUID(uuidString: payload.id),
                let entity = NSEntityDescription.entity(forEntityName: "PresenciaEventEntity", in: context)
            else {
                return
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", presenceID as CVarArg)

            let row: NSManagedObject
            if let existing = try? context.fetch(request).first {
                row = existing
            } else {
                row = NSManagedObject(entity: entity, insertInto: context)
                row.setValue(presenceID, forKey: "id")
            }

            row.setValue(payload.createdAt, forKey: "createdAt")
            row.setValue(payload.dayStart, forKey: "dayStart")
            row.setValue(payload.eventType, forKey: "eventType")
            row.setValue(payload.mood, forKey: "mood")
            row.setValue(payload.note, forKey: "note")
            row.setValue(payload.source, forKey: "source")

            do {
                try context.save()
                Task { @MainActor in
                    watchModel.shared.refreshTodayPresenceReturnCount()
                }
            } catch {
                context.rollback()
                msg("❌ No se pudo aplicar presencia entrante en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func resetPresenceEvents() async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para resetear presencia en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")

            do {
                let rows = try context.fetch(request)
                rows.forEach(context.delete)
                if context.hasChanges {
                    try context.save()
                }

                Task { @MainActor in
                    watchModel.shared.refreshTodayPresenceReturnCount()
                }
            } catch {
                context.rollback()
                msg("❌ No se pudo resetear presencia en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func applyPremiumState(yorjPremium: Bool, purchaseStatus: Bool) {
        let hasPremiumAccess = purchaseStatus || yorjPremium

        UserDefaults.standard.set(yorjPremium, forKey: "yorjPremium")
        UserDefaults.standard.set(hasPremiumAccess, forKey: "purchaseStatus")

        if let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName) {
            sharedDefaults.set(yorjPremium, forKey: "yorjPremium")
            sharedDefaults.set(hasPremiumAccess, forKey: "purchaseStatus")
        }

        let store = NSUbiquitousKeyValueStore.default
        store.set(yorjPremium, forKey: "yorjPremium")
        store.set(hasPremiumAccess, forKey: "purchaseStatus")
        store.synchronize()

        watchModel.shared.refreshPremiumAccessState()
    }
}
