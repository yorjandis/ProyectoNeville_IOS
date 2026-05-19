import Foundation

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
