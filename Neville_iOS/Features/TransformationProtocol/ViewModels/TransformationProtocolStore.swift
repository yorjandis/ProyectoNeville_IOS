import Combine
import Foundation

@MainActor
final class TransformationProtocolStore: ObservableObject {
    @Published private(set) var state: TransformationProtocolState
    @Published var presentedError: String?

    private let persistence: TransformationProtocolPersisting
    private let notifications: TransformationProtocolNotificationService
    private let calendar: Calendar

    init(
        persistence: TransformationProtocolPersisting = TransformationProtocolFilePersistence(),
        notifications: TransformationProtocolNotificationService = .shared,
        calendar: Calendar = .current
    ) {
        self.persistence = persistence
        self.notifications = notifications
        self.calendar = calendar

        do {
            state = try persistence.load()
        } catch {
            state = .empty
            presentedError = error.localizedDescription
        }
    }

    var configuration: TransformationProtocolConfiguration? {
        state.configuration
    }

    var currentDayNumber: Int {
        guard let startedAt = configuration?.startedAt else { return 1 }
        let start = calendar.startOfDay(for: startedAt)
        let today = calendar.startOfDay(for: Date())
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return min(21, max(1, elapsed + 1))
    }

    var completedDays: Int {
        state.entries.filter(\.isCompleted).count
    }

    var progress: Double {
        Double(completedDays) / 21.0
    }

    var averageScore: Double {
        let scored = state.entries.filter { $0.eveningCompleted || $0.score.total > 0 }
        guard !scored.isEmpty else { return 0 }
        return Double(scored.map(\.score.total).reduce(0, +)) / Double(scored.count)
    }

    var totalPARAPauses: Int {
        state.paraEvents.count
    }

    func start(_ configuration: TransformationProtocolConfiguration) {
        state = TransformationProtocolState(configuration: configuration)
        persist()
        applyNotifications(configuration)
    }

    func entry(for day: Int) -> TransformationProtocolDayEntry {
        state.entries.first(where: { $0.day == day })
            ?? TransformationProtocolDayEntry(day: day)
    }

    func update(_ entry: TransformationProtocolDayEntry) {
        var updated = entry
        updated.updatedAt = Date()
        if let index = state.entries.firstIndex(where: { $0.day == entry.day }) {
            state.entries[index] = updated
        } else {
            state.entries.append(updated)
            state.entries.sort { $0.day < $1.day }
        }

        if state.entries.filter(\.isCompleted).count == 21 {
            state.completedAt = state.completedAt ?? Date()
        }
        persist()
    }

    func markMorningCompleted(day: Int) {
        var entry = entry(for: day)
        entry.morningCompleted = true
        update(entry)
    }

    func recordPARA(
        perceivedSignal: String,
        emotion: String,
        alternativeAction: String,
        pauseSeconds: Int
    ) {
        let event = TransformationProtocolPARAEvent(
            perceivedSignal: perceivedSignal,
            emotion: emotion,
            alternativeAction: alternativeAction,
            pauseSeconds: pauseSeconds
        )
        state.paraEvents.insert(event, at: 0)
        if state.paraEvents.count > 250 {
            state.paraEvents = Array(state.paraEvents.prefix(250))
        }
        persist()
    }

    func updateConfiguration(_ configuration: TransformationProtocolConfiguration) {
        state.configuration = configuration
        persist()
        applyNotifications(configuration)
    }

    func reset() {
        state = .empty
        persist()
        Task {
            await notifications.cancel()
        }
    }

    private func persist() {
        do {
            try persistence.save(state)
        } catch {
            presentedError = L10n.format(
                "transformation.error.save",
                fallback: "No se pudo guardar el progreso: {0}",
                error.localizedDescription
            )
        }
    }

    private func applyNotifications(_ configuration: TransformationProtocolConfiguration) {
        Task {
            let accepted = await notifications.apply(configuration)
            if configuration.remindersEnabled && !accepted {
                presentedError = L10n.exact(
                    "Los recordatorios no están autorizados. Puedes activarlos en Ajustes del sistema."
                )
            }
        }
    }
}
