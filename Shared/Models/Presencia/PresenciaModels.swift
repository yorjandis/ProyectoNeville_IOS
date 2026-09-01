import Foundation
import CoreData

extension Notification.Name {
    static let presenciaEventsDidChange = Notification.Name("presenciaEventsDidChange")
}

enum PresenciaSettings {
    static let customCelebrationPhraseKey = "presencia.customCelebrationPhrase"
    static let defaultCelebrationPhrase = "Siento mi futuro ahora."
    static let customMainButtonTitleKey = "presencia.customMainButtonTitle"
    static let defaultMainButtonTitle = "Estoy aquí"
}

enum PresenciaEventType: String {
    case presente
    case inconsciente
    case estadoAnimo
}

struct PresenciaMood: Identifiable, Hashable {
    let id: String
    let title: String
    let symbolName: String
    let countsAsInconsciente: Bool

    var localizedTitle: String {
        L10n.exact(title)
    }

    static let common: [PresenciaMood] = [
        PresenciaMood(id: "sientoMiFuturoAhora", title: "Siento mi futuro ahora", symbolName: "sparkles", countsAsInconsciente: false),
        PresenciaMood(id: "pilotoAutomatico", title: "Piloto automático", symbolName: "moon.zzz.fill", countsAsInconsciente: true),
        PresenciaMood(id: "distraido", title: "Distraído", symbolName: "sparkle.magnifyingglass", countsAsInconsciente: true),
        PresenciaMood(id: "sereno", title: "Sereno", symbolName: "leaf.fill", countsAsInconsciente: false),
        PresenciaMood(id: "alegre", title: "Alegre", symbolName: "sun.max.fill", countsAsInconsciente: false),
        PresenciaMood(id: "ansioso", title: "Ansioso", symbolName: "waveform.path.ecg", countsAsInconsciente: false),
        PresenciaMood(id: "triste", title: "Triste", symbolName: "cloud.rain.fill", countsAsInconsciente: false),
        PresenciaMood(id: "enfadado", title: "Enfadado", symbolName: "flame.fill", countsAsInconsciente: false),
        PresenciaMood(id: "cansado", title: "Cansado", symbolName: "battery.25percent", countsAsInconsciente: false),
        PresenciaMood(id: "agradecido", title: "Agradecido", symbolName: "heart.fill", countsAsInconsciente: false)
    ]

    static func title(for id: String?) -> String {
        guard let id else { return "" }
        return common.first { $0.id == id }?.localizedTitle ?? id
    }
}

struct PresenciaDayStats: Identifiable, Hashable {
    let date: Date
    let presentes: Int
    let inconscientes: Int
    let estadosAnimo: Int
    let futuroAhora: Int

    var id: Date { date }
    var total: Int { presentes + inconscientes }
    var ratioPresencia: Double {
        guard total > 0 else { return 0 }
        return Double(presentes) / Double(total)
    }
}

struct PresenciaMoodStats: Identifiable, Hashable {
    let moodID: String
    let count: Int

    var id: String { moodID }
    var title: String { PresenciaMood.title(for: moodID) }
}

struct PresenciaEventPoint: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let dayStart: Date
    let eventType: PresenciaEventType?
    let moodID: String?

    var isPresentReturn: Bool {
        eventType == .presente
    }

    var isAutomaticPilot: Bool {
        moodID == "pilotoAutomatico" || moodID == "distraido"
    }
}

struct PresenciaStreakStats: Hashable {
    let currentDays: Int
    let bestDays: Int

    var hasCurrentStreak: Bool { currentDays > 0 }
    var hasAnyStreak: Bool { bestDays > 0 }
}

@MainActor
final class PresenciaRepository {
    private let context: NSManagedObjectContext
    private let calendar: Calendar

    init(context: NSManagedObjectContext = CoreDataController.shared.context, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func recordPresent(source: String) -> Bool {
        createEvent(type: .presente, moodID: nil, source: source)
    }

    func recordPresent(mood: PresenciaMood, source: String) -> Bool {
        createEvent(type: .presente, moodID: mood.id, source: source)
    }

    func recordMood(_ mood: PresenciaMood, source: String) -> Bool {
        createEvent(
            type: mood.countsAsInconsciente ? .inconsciente : .estadoAnimo,
            moodID: mood.id,
            source: source
        )
    }

    func todayPresentCount() -> Int {
        countEvents(type: .presente, in: calendar.startOfDay(for: Date()))
    }

    func futureFeelingCount(days: Int = 30) -> Int {
        moodCount(moodID: "sientoMiFuturoAhora", days: days)
    }

    func streakStats(days: Int = 90, threshold: Int = 10) -> PresenciaStreakStats {
        let stats = dayStats(days: days)
        var best = 0
        var running = 0

        for day in stats {
            if day.presentes >= threshold {
                running += 1
                best = max(best, running)
            } else {
                running = 0
            }
        }

        var current = 0
        for day in stats.reversed() {
            if day.presentes >= threshold {
                current += 1
            } else {
                break
            }
        }

        return PresenciaStreakStats(currentDays: current, bestDays: best)
    }

    func dayStats(days: Int = 14) -> [PresenciaDayStats] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(format: "dayStart >= %@", start as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "dayStart", ascending: true)]

        let events = (try? context.fetch(request)) ?? []
        var buckets: [Date: (presentes: Int, inconscientes: Int, estados: Int, futuroAhora: Int)] = [:]

        for offset in 0..<max(days, 1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            buckets[day] = (0, 0, 0, 0)
        }

        for event in events {
            let day = (event.value(forKey: "dayStart") as? Date).map { calendar.startOfDay(for: $0) } ?? today
            let type = event.value(forKey: "eventType") as? String
            let mood = event.value(forKey: "mood") as? String
            var bucket = buckets[day, default: (0, 0, 0, 0)]

            switch type {
            case PresenciaEventType.presente.rawValue:
                bucket.presentes += 1
            case PresenciaEventType.inconsciente.rawValue:
                bucket.inconscientes += 1
            case PresenciaEventType.estadoAnimo.rawValue:
                bucket.estados += 1
            default:
                break
            }

            if mood == "sientoMiFuturoAhora" {
                bucket.futuroAhora += 1
            }

            buckets[day] = bucket
        }

        return buckets
            .map {
                PresenciaDayStats(
                    date: $0.key,
                    presentes: $0.value.presentes,
                    inconscientes: $0.value.inconscientes,
                    estadosAnimo: $0.value.estados,
                    futuroAhora: $0.value.futuroAhora
                )
            }
            .sorted { $0.date < $1.date }
    }

    func moodStats(days: Int = 30) -> [PresenciaMoodStats] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(format: "dayStart >= %@ AND mood != nil AND mood != ''", start as NSDate)

        let events = (try? context.fetch(request)) ?? []
        let grouped = Dictionary(grouping: events) { event in
            event.value(forKey: "mood") as? String ?? ""
        }

        return grouped
            .filter { !$0.key.isEmpty }
            .map { PresenciaMoodStats(moodID: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    func eventPoints(days: Int = 14) -> [PresenciaEventPoint] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(format: "dayStart >= %@", start as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        let events = (try? context.fetch(request)) ?? []

        return events.compactMap { event in
            guard let createdAt = event.value(forKey: "createdAt") as? Date else { return nil }
            let id = event.value(forKey: "id") as? UUID ?? UUID()
            let dayStart = (event.value(forKey: "dayStart") as? Date).map { calendar.startOfDay(for: $0) }
                ?? calendar.startOfDay(for: createdAt)
            let type = (event.value(forKey: "eventType") as? String).flatMap(PresenciaEventType.init(rawValue:))
            let moodID = event.value(forKey: "mood") as? String

            return PresenciaEventPoint(id: id, createdAt: createdAt, dayStart: dayStart, eventType: type, moodID: moodID)
        }
    }

    func todayEventPoints() -> [PresenciaEventPoint] {
        eventPoints(days: 1)
    }

    func eventPoints(on date: Date) -> [PresenciaEventPoint] {
        let day = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: day) else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", day as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        return ((try? context.fetch(request)) ?? []).compactMap { event in
            guard let createdAt = event.value(forKey: "createdAt") as? Date else { return nil }
            return PresenciaEventPoint(
                id: event.value(forKey: "id") as? UUID ?? UUID(),
                createdAt: createdAt,
                dayStart: day,
                eventType: (event.value(forKey: "eventType") as? String).flatMap(PresenciaEventType.init(rawValue:)),
                moodID: event.value(forKey: "mood") as? String
            )
        }
    }

    func resetAllEvents() -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")

        do {
            let rows = try context.fetch(request)
            rows.forEach(context.delete)
            if context.hasChanges {
                try context.save()
            }
            NotificationCenter.default.post(name: .presenciaEventsDidChange, object: nil)
            return true
        } catch {
            context.rollback()
            msg("Error al resetear estadísticas de presencia: \(error.localizedDescription)")
            return false
        }
    }

    private func createEvent(type: PresenciaEventType, moodID: String?, source: String) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "PresenciaEventEntity", in: context) else {
            return false
        }

        let now = Date()
        let row = NSManagedObject(entity: entity, insertInto: context)
        row.setValue(UUID(), forKey: "id")
        row.setValue(now, forKey: "createdAt")
        row.setValue(calendar.startOfDay(for: now), forKey: "dayStart")
        row.setValue(type.rawValue, forKey: "eventType")
        row.setValue(moodID, forKey: "mood")
        row.setValue("", forKey: "note")
        row.setValue(source, forKey: "source")

        do {
            try context.save()
            NotificationCenter.default.post(name: .presenciaEventsDidChange, object: nil)
            return true
        } catch {
            context.rollback()
            msg("Error al guardar evento de presencia: \(error.localizedDescription)")
            return false
        }
    }

    private func countEvents(type: PresenciaEventType, in day: Date) -> Int {
        guard let end = calendar.date(byAdding: .day, value: 1, to: day) else { return 0 }
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(
            format: "eventType == %@ AND createdAt >= %@ AND createdAt < %@",
            type.rawValue,
            day as NSDate,
            end as NSDate
        )

        return (try? context.count(for: request)) ?? 0
    }

    private func moodCount(moodID: String, days: Int) -> Int {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(format: "dayStart >= %@ AND mood == %@", start as NSDate, moodID)

        return (try? context.count(for: request)) ?? 0
    }
}
