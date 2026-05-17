import Foundation
import Combine
import CoreData

@MainActor
final class AgendaViewModel: ObservableObject {
    enum QuickFilter: String, CaseIterable, Identifiable {
        case hoy = "Hoy"
        case sieteDias = "Próx. 7 días"
        case conRecordatorio = "Con recordatorio"
        case todos = "Todos"

        var id: String { rawValue }
    }

    @Published var selectedDate: Date = Date()
    @Published var items: [AgendaItemData] = []
    @Published var quickFilter: QuickFilter = .hoy

    private let repository = AgendaRepository()
    private var cancellables = Set<AnyCancellable>()
    private var reloadWorkItem: DispatchWorkItem?

    var itemsForSelectedDay: [AgendaItemData] {
        filteredItems(for: quickFilter)
            .sorted { lhs, rhs in
                if Calendar.current.isDate(lhs.fechaActividad, inSameDayAs: rhs.fechaActividad) {
                    return lhs.hora < rhs.hora
                }
                return lhs.fechaActividad < rhs.fechaActividad
            }
    }

    var collapsedSectionsForActiveFilter: [(date: Date, items: [AgendaItemData])] {
        let calendar = Calendar.current
        let sourceItems: [AgendaItemData]

        // Conserva la vista mensual para "Todos" cuando el calendario está colapsado.
        if quickFilter == .todos {
            return collapsedSectionsCurrentMonth
        } else {
            sourceItems = filteredItems(for: quickFilter)
        }

        let grouped = Dictionary(grouping: sourceItems) { item in
            calendar.startOfDay(for: item.fechaActividad)
        }

        return grouped.keys.sorted().map { day in
            let dayItems = (grouped[day] ?? []).sorted { a, b in
                a.hora < b.hora
            }
            return (date: day, items: dayItems)
        }
    }

    private func filteredItems(for filter: QuickFilter) -> [AgendaItemData] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfSevenDays = calendar.date(byAdding: .day, value: 7, to: startOfToday) ?? startOfToday

        switch filter {
        case .hoy:
            return items.filter { calendar.isDate($0.fechaActividad, inSameDayAs: Date()) }
        case .sieteDias:
            return items.filter {
                let day = calendar.startOfDay(for: $0.fechaActividad)
                return day >= startOfToday && day < endOfSevenDays
            }
        case .conRecordatorio:
            return items.filter { $0.recordatorioActivo }
        case .todos:
            return items.filter { calendar.isDate($0.fechaActividad, inSameDayAs: selectedDate) }
        }
    }

    var reminderItems: [AgendaItemData] {
        items.filter { $0.recordatorioActivo }
            .sorted { $0.fechaActividad < $1.fechaActividad }
    }

    init() {
        load()
        observeStoreChanges()
    }

    var collapsedSectionsCurrentMonth: [(date: Date, items: [AgendaItemData])] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth) ?? now

        let monthItems = items.filter { item in
            item.fechaActividad >= startOfMonth && item.fechaActividad < startOfNextMonth
        }

        let grouped = Dictionary(grouping: monthItems) { item in
            calendar.startOfDay(for: item.fechaActividad)
        }

        let sortedDates = grouped.keys.sorted()
        let pivot = calendar.startOfDay(for: now)

        // Prioriza desde hoy hacia adelante, manteniendo posibilidad de navegar hacia días previos del mes.
        let orderedDates = sortedDates.sorted { lhs, rhs in
            let lhsOffset = (lhs < pivot) ? 10_000 + Int(pivot.timeIntervalSince(lhs)) : Int(lhs.timeIntervalSince(pivot))
            let rhsOffset = (rhs < pivot) ? 10_000 + Int(pivot.timeIntervalSince(rhs)) : Int(rhs.timeIntervalSince(pivot))
            return lhsOffset < rhsOffset
        }

        return orderedDates.map { day in
            let dayItems = (grouped[day] ?? []).sorted { a, b in
                if calendar.isDate(a.fechaActividad, inSameDayAs: b.fechaActividad) {
                    return a.hora < b.hora
                }
                return a.fechaActividad < b.fechaActividad
            }
            return (date: day, items: dayItems)
        }
    }

    func load() {
        scheduleLoad(delay: 0)
    }

    private func scheduleLoad(delay: TimeInterval) {
        reloadWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let fetched = repository.fetchAll()
            if fetched != self.items {
                self.items = fetched
            }
        }

        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func create(selectedDate: Date? = nil) -> AgendaItemData {
        let now = Date()
        return AgendaItemData(
            id: UUID(),
            titulo: "",
            fechaCreacion: now,
            fechaModificacion: now,
            nota: "",
            fechaActividad: selectedDate ?? now,
            hora: now,
            lugar: "",
            contenido: "",
            prioridad: .neutral,
            colorHex: "#A9D7A4",
            completada: nil,
            recordatorioActivo: false,
            reminderID: nil
        )
    }

    func save(_ item: AgendaItemData) {
        _ = repository.save(item: item)
        load()
    }

    func delete(_ item: AgendaItemData) {
        if let reminderID = item.reminderID {
            ReminderNotificationManager.shared.cancel(id: reminderID)
        }
        repository.delete(itemID: item.id)
        load()
    }

    func updateReminder(for item: AgendaItemData, enabled: Bool) {
        var updated = item
        if enabled {
            let reminder = ReminderNotificationManager.shared.scheduleAndStore(
                title: item.titulo,
                message: item.contenido.isEmpty ? item.nota : item.contenido,
                frequency: .date(mergedDate(item.fechaActividad, item.hora))
            )
            updated.recordatorioActivo = true
            updated.reminderID = reminder.id
        } else {
            if let reminderID = updated.reminderID {
                ReminderNotificationManager.shared.cancel(id: reminderID)
            }
            updated.recordatorioActivo = false
            updated.reminderID = nil
        }
        updated.fechaModificacion = Date()
        save(updated)
    }

    func reminderCanBeEnabled(for item: AgendaItemData) -> Bool {
        mergedDate(item.fechaActividad, item.hora) > Date()
    }

    private func observeStoreChanges() {
        let center = NotificationCenter.default

        Publishers.Merge3(
            center.publisher(for: .coreDataStoresDidLoad),
            center.publisher(for: .NSPersistentStoreRemoteChange),
            center.publisher(
                for: NSPersistentCloudKitContainer.eventChangedNotification,
                object: CoreDataController.shared.persistentContainer
            )
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.scheduleLoad(delay: 0.2)
        }
        .store(in: &cancellables)
    }

    private func mergedDate(_ date: Date, _ time: Date) -> Date {
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
