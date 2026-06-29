import SwiftUI
import AppIntents
import CoreData
#if !os(watchOS)
import UserNotifications
#endif

struct CrearEntradaAgendaIntent: AppIntent, ProvidesDialog {
    var value: Never?

    static let title: LocalizedStringResource = "Crear Entrada Agenda"
    static let description = IntentDescription("Crea una nueva actividad en la Agenda")
    static var parameterSummary: some ParameterSummary {
        Summary("Crear actividad \(\.$titulo), fecha \(\.$fecha), contenido \(\.$contenido), recordatorio \(\.$activarRecordatorio)")
    }

    @AppStorage("yorjPremium", store: UserDefaults(suiteName: "group.com.ypg.nev.group")) var yorjPremium: Bool = false

    @Parameter(
        title: "Título",
        description: "El título de la actividad",
        requestValueDialog: IntentDialog("¿Qué título deseas para la actividad?")
    )
    var titulo: String

    @Parameter(
        title: "Fecha",
        description: "Fecha y hora de la actividad",
        requestValueDialog: IntentDialog("¿Qué fecha y hora deseas para la actividad?")
    )
    var fecha: Date

    @Parameter(
        title: "Contenido",
        description: "El contenido de la actividad",
        requestValueDialog: IntentDialog("¿Qué contenido deseas guardar?")
    )
    var contenido: String

    @Parameter(
        title: "Activar recordatorio",
        description: "Indica si deseas activar un recordatorio",
        requestValueDialog: IntentDialog("¿Deseas activar un recordatorio para esta actividad?")
    )
    var activarRecordatorio: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        guard (hasPremium || self.yorjPremium) else {
            throw PremiumError.noSubscription
        }

        let coordinator = await CoreDataController.shared
            .persistentContainer
            .persistentStoreCoordinator

        if coordinator.persistentStores.isEmpty {
            try await CoreDataController.shared.cargarStores()
        }

        let context = await CoreDataController.shared.persistentContainer.newBackgroundContext()
        let now = Date()

        #if os(watchOS)
        let shouldEnableReminder = false
        #else
        let shouldEnableReminder = activarRecordatorio && fecha > now
        #endif
        var reminderID: String?

        #if !os(watchOS)
        if shouldEnableReminder {
            reminderID = await MainActor.run {
                Self.scheduleAgendaReminder(
                    title: titulo,
                    message: contenido,
                    date: fecha
                )
            }
        }
        #endif

        guard let entity = NSEntityDescription.entity(forEntityName: "AgendaItemEntity", in: context) else {
            return .result(dialog: IntentDialog("No se pudo crear la actividad en Agenda."))
        }

        let item = NSManagedObject(entity: entity, insertInto: context)
        item.setValue(UUID(), forKey: "id")
        item.setValue(titulo, forKey: "titulo")
        item.setValue(now, forKey: "fechaCreacion")
        item.setValue(now, forKey: "fechaModificacion")
        item.setValue("", forKey: "nota")
        item.setValue(fecha, forKey: "fechaActividad")
        item.setValue(fecha, forKey: "hora")
        item.setValue("", forKey: "lugar")
        item.setValue(contenido, forKey: "contenido")
        item.setValue("neutral", forKey: "prioridad")
        item.setValue("#A9D7A4", forKey: "colorHex")
        item.setValue(nil, forKey: "completada")
        item.setValue(shouldEnableReminder, forKey: "recordatorioActivo")
        item.setValue(reminderID, forKey: "reminderID")

        do {
            try context.save()
            return .result(dialog: IntentDialog("La actividad «\(titulo)» ha sido creada en Agenda."))
        } catch {
            #if !os(watchOS)
            if let reminderID {
                await MainActor.run {
                    Self.cancelAgendaReminder(id: reminderID)
                }
            }
            #endif
            return .result(dialog: IntentDialog("No se pudo guardar la actividad en Agenda."))
        }
    }

    #if !os(watchOS)
    @MainActor
    private static func scheduleAgendaReminder(title: String, message: String, date: Date) -> String {
        let identifier = UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.userInfo = [
            "reminderId": identifier,
            "message": message
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        return identifier
    }

    @MainActor
    private static func cancelAgendaReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    #endif
}
