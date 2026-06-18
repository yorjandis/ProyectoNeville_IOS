import Foundation
import CoreData

extension Notification.Name {
    static let presenciaEventsDidChange = Notification.Name("presenciaEventsDidChange")
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

    static let common: [PresenciaMood] = [
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
        return common.first { $0.id == id }?.title ?? id
    }
}

struct PresenciaDayStats: Identifiable, Hashable {
    let date: Date
    let presentes: Int
    let inconscientes: Int
    let estadosAnimo: Int

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

    func dayStats(days: Int = 14) -> [PresenciaDayStats] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: today) ?? today
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(format: "dayStart >= %@", start as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "dayStart", ascending: true)]

        let events = (try? context.fetch(request)) ?? []
        var buckets: [Date: (presentes: Int, inconscientes: Int, estados: Int)] = [:]

        for offset in 0..<max(days, 1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            buckets[day] = (0, 0, 0)
        }

        for event in events {
            let day = (event.value(forKey: "dayStart") as? Date).map { calendar.startOfDay(for: $0) } ?? today
            let type = event.value(forKey: "eventType") as? String
            var bucket = buckets[day, default: (0, 0, 0)]

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

            buckets[day] = bucket
        }

        return buckets
            .map { PresenciaDayStats(date: $0.key, presentes: $0.value.presentes, inconscientes: $0.value.inconscientes, estadosAnimo: $0.value.estados) }
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
}
