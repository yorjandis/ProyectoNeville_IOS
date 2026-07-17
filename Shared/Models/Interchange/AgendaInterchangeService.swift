import Foundation
#if os(iOS)
import EventKit
#endif

@MainActor
enum AgendaInterchangeService {
    static func makeAgendaDraft(
        title: String,
        content: String,
        activityDate: Date = Date(),
        note: String = "",
        place: String = ""
    ) -> AgendaItemData {
        let now = Date()
        return AgendaItemData(
            id: UUID(),
            titulo: title,
            fechaCreacion: now,
            fechaModificacion: now,
            nota: note,
            fechaActividad: activityDate,
            hora: activityDate,
            lugar: place,
            contenido: content,
            prioridad: .neutral,
            colorHex: "#A9D7A4",
            completada: nil,
            recordatorioActivo: false,
            reminderID: nil,
            seriesID: nil
        )
    }

    static func saveAgendaItems(_ items: [AgendaItemData]) {
        guard !items.isEmpty else { return }
        let repository = AgendaRepository()

        for var item in items {
            _ = repository.save(item: item)
            if item.recordatorioActivo {
                let reminder = ReminderNotificationManager.shared.scheduleAndStore(
                    title: item.titulo,
                    message: item.contenido.isEmpty ? item.nota : item.contenido,
                    frequency: .date(mergedDate(item.fechaActividad, item.hora))
                )
                item.reminderID = reminder.id
                _ = repository.save(item: item)
            }
        }
    }

    static func exportAgendaToNotas(_ item: AgendaItemData) -> Bool {
        let notesContent = item.contenido.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? item.nota
            : item.contenido
        return NotasModel().addNote(nota: notesContent, title: item.titulo)
    }

    static func exportAgendaToDiario(_ item: AgendaItemData) -> Bool {
        let body = composeAgendaBody(item)
        return DiarioModel.shared.addItem(
            title: item.titulo,
            emocion: .neutral,
            content: body,
            fechaCreacion: item.fechaActividad,
            isFav: false
        )
    }

#if os(iOS)
    static func exportNoteToAppleCalendar(title: String, content: String) async throws {
        let startDate = Date()
        try await saveAppleCalendarEvent(
            title: normalizedTitle(title, fallback: "Nota"),
            notes: content,
            startDate: startDate,
            endDate: Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate,
            location: ""
        )
    }

    static func exportNoteToAppleReminders(title: String, content: String) async throws {
        try await saveAppleReminder(
            title: normalizedTitle(title, fallback: "Nota"),
            notes: content,
            dueDate: nil
        )
    }

    static func exportAgendaToAppleCalendar(_ item: AgendaItemData) async throws {
        let startDate = mergedDate(item.fechaActividad, item.hora)
        try await saveAppleCalendarEvent(
            title: normalizedTitle(item.titulo, fallback: "Actividad"),
            notes: composeAgendaBody(item),
            startDate: startDate,
            endDate: Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate,
            location: item.lugar
        )
    }

    static func exportAgendaToAppleReminders(_ item: AgendaItemData) async throws {
        try await saveAppleReminder(
            title: normalizedTitle(item.titulo, fallback: "Actividad"),
            notes: composeAgendaBody(item),
            dueDate: mergedDate(item.fechaActividad, item.hora)
        )
    }

    static func exportNotesToAppleCalendar(_ notes: [(title: String, content: String)]) async throws -> Int {
        guard !notes.isEmpty else { return 0 }
        let eventStore = try await authorizedCalendarStore()
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw AppleExportError.calendarUnavailable
        }

        let startDate = Date()
        for (index, note) in notes.enumerated() {
            let eventStart = Calendar.current.date(byAdding: .minute, value: index, to: startDate) ?? startDate
            let event = EKEvent(eventStore: eventStore)
            event.calendar = calendar
            event.title = normalizedTitle(note.title, fallback: "Nota")
            event.notes = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            event.startDate = eventStart
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: eventStart) ?? eventStart.addingTimeInterval(3600)
            try eventStore.save(event, span: .thisEvent, commit: false)
        }
        try eventStore.commit()
        return notes.count
    }

    static func exportNotesToAppleReminders(_ notes: [(title: String, content: String)]) async throws -> Int {
        guard !notes.isEmpty else { return 0 }
        let eventStore = try await authorizedRemindersStore()
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw AppleExportError.remindersListUnavailable
        }

        for note in notes {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.calendar = calendar
            reminder.title = normalizedTitle(note.title, fallback: "Nota")
            reminder.notes = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            try eventStore.save(reminder, commit: false)
        }
        try eventStore.commit()
        return notes.count
    }

    static func exportAgendaItemsToAppleCalendar(_ items: [AgendaItemData]) async throws -> Int {
        guard !items.isEmpty else { return 0 }
        let eventStore = try await authorizedCalendarStore()
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw AppleExportError.calendarUnavailable
        }

        for item in items {
            let startDate = mergedDate(item.fechaActividad, item.hora)
            let event = EKEvent(eventStore: eventStore)
            event.calendar = calendar
            event.title = normalizedTitle(item.titulo, fallback: "Actividad")
            event.notes = composeAgendaBody(item)
            event.location = item.lugar.trimmingCharacters(in: .whitespacesAndNewlines)
            event.startDate = startDate
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
            try eventStore.save(event, span: .thisEvent, commit: false)
        }
        try eventStore.commit()
        return items.count
    }

    static func exportAgendaItemsToAppleReminders(_ items: [AgendaItemData]) async throws -> Int {
        guard !items.isEmpty else { return 0 }
        let eventStore = try await authorizedRemindersStore()
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw AppleExportError.remindersListUnavailable
        }

        for item in items {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.calendar = calendar
            reminder.title = normalizedTitle(item.titulo, fallback: "Actividad")
            reminder.notes = composeAgendaBody(item)
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.calendar, .timeZone, .year, .month, .day, .hour, .minute],
                from: mergedDate(item.fechaActividad, item.hora)
            )
            try eventStore.save(reminder, commit: false)
        }
        try eventStore.commit()
        return items.count
    }

    private static func saveAppleCalendarEvent(
        title: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        location: String
    ) async throws {
        let eventStore = try await authorizedCalendarStore()
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw AppleExportError.calendarUnavailable
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        event.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        event.startDate = startDate
        event.endDate = max(endDate, startDate.addingTimeInterval(60))
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    private static func saveAppleReminder(title: String, notes: String, dueDate: Date?) async throws {
        let eventStore = try await authorizedRemindersStore()
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw AppleExportError.remindersListUnavailable
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = title
        reminder.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.calendar, .timeZone, .year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }
        try eventStore.save(reminder, commit: true)
    }

    private static func authorizedCalendarStore() async throws -> EKEventStore {
        let eventStore = EKEventStore()
        guard try await eventStore.requestFullAccessToEvents() else {
            throw AppleExportError.calendarAccessDenied
        }
        return eventStore
    }

    private static func authorizedRemindersStore() async throws -> EKEventStore {
        let eventStore = EKEventStore()
        guard try await eventStore.requestFullAccessToReminders() else {
            throw AppleExportError.remindersAccessDenied
        }
        return eventStore
    }

    private static func normalizedTitle(_ title: String, fallback: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    enum AppleExportError: LocalizedError {
        case calendarAccessDenied
        case calendarUnavailable
        case remindersAccessDenied
        case remindersListUnavailable

        var errorDescription: String? {
            switch self {
            case .calendarAccessDenied:
                return "No se concedió acceso a Calendario. Puedes activarlo en Ajustes."
            case .calendarUnavailable:
                return "No hay un calendario disponible para guardar el evento."
            case .remindersAccessDenied:
                return "No se concedió acceso a Recordatorios. Puedes activarlo en Ajustes."
            case .remindersListUnavailable:
                return "No hay una lista de Recordatorios disponible."
            }
        }
    }
#endif

    static func exportDiarioToAgenda(_ diario: Diario) -> Bool {
        let date = diario.fecha ?? Date()
        let draft = makeAgendaDraft(
            title: diario.title ?? "Entrada Diario",
            content: diario.content ?? "",
            activityDate: date
        )
        saveAgendaItems([draft])
        return true
    }

    private static func composeAgendaBody(_ item: AgendaItemData) -> String {
        var parts: [String] = []
        if !item.contenido.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(item.contenido)
        }
        if !item.nota.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Nota: \(item.nota)")
        }
        if !item.lugar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Lugar: \(item.lugar)")
        }
        return parts.joined(separator: "\n")
    }

    private static func mergedDate(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let hourMinute = calendar.dateComponents([.hour, .minute], from: time)
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = hourMinute.hour
        components.minute = hourMinute.minute
        return calendar.date(from: components) ?? date
    }
}
