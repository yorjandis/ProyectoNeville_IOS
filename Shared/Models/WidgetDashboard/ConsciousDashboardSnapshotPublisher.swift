import CoreData
import Foundation
import WidgetKit

@MainActor
enum ConsciousDashboardSnapshotPublisher {
  static func refresh(now: Date = .now) {
    let controller = CoreDataController.shared
    guard !controller.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else {
      return
    }

    let context = controller.context
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: now)
    let dayEnd =
      calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now.addingTimeInterval(86_400)
    let epochDay = Int64(dayStart.timeIntervalSince1970 / 86_400)

    let goals = fetch(entity: "GoalEntity", context: context).filter {
      $0.value(forKey: "isStarted") as? Bool == true
    }
    let units = goals.flatMap { goal -> [NSManagedObject] in
      (goal.value(forKey: "units") as? NSSet)?.allObjects as? [NSManagedObject] ?? []
    }
    let completedUnits = units.filter {
      ($0.value(forKey: "status") as? String) == "completed"
    }.count

    let todayPredicate = NSPredicate(
      format: "fechaActividad >= %@ AND fechaActividad < %@",
      dayStart as NSDate,
      dayEnd as NSDate
    )
    let agenda = fetch(entity: "AgendaItemEntity", predicate: todayPredicate, context: context)

    let journalPredicate = NSPredicate(
      format: "fecha >= %@ AND fecha < %@",
      dayStart as NSDate,
      dayEnd as NSDate
    )
    let journal = fetch(entity: "Diario", predicate: journalPredicate, context: context)

    let presencePredicate = NSPredicate(
      format: "createdAt >= %@ AND createdAt < %@",
      dayStart as NSDate,
      dayEnd as NSDate
    )
    let presence = fetch(
      entity: "PresenciaEventEntity", predicate: presencePredicate, context: context)
    let presenceReturns = presence.filter {
      ($0.value(forKey: "eventType") as? String) == "presente"
    }.count
    let automaticPilotEvents = presence.filter {
      let mood = $0.value(forKey: "mood") as? String
      return mood == "pilotoAutomatico" || mood == "distraido"
    }.count

    let ritualPredicate = NSPredicate(format: "sessionDateEpochDay == %lld", epochDay)
    let rituals = fetch(entity: "RitualSessionEntity", predicate: ritualPredicate, context: context)
    let morningCompleted = rituals.contains {
      ($0.value(forKey: "kind") as? String) == "morning"
        && ($0.value(forKey: "completed") as? Bool == true)
    }
    let eveningCompleted = rituals.contains {
      ($0.value(forKey: "kind") as? String) == "evening"
    }

    let startMillis = Int64(dayStart.timeIntervalSince1970 * 1_000)
    let endMillis = Int64(dayEnd.timeIntervalSince1970 * 1_000)
    let coherencePredicate = NSPredicate(
      format: "dateEpochMillis >= %lld AND dateEpochMillis < %lld",
      startMillis,
      endMillis
    )
    let coherence = fetch(entity: "coherencia", predicate: coherencePredicate, context: context)
    let coherenceMinutes = coherence.reduce(0) {
      $0 + Int($1.value(forKey: "durationMinutes") as? Int16 ?? 0)
    }
    let coherenceScores = coherence.compactMap { row -> Int? in
      let score = Int(row.value(forKey: "afterScore") as? Int16 ?? 0)
      return score > 0 ? score : nil
    }
    let averageCoherenceScore =
      coherenceScores.isEmpty
      ? nil
      : Int((Double(coherenceScores.reduce(0, +)) / Double(coherenceScores.count)).rounded())

    let sharedDefaults = UserDefaults(suiteName: ConsciousDashboardSnapshot.appGroupName)
    let premium =
      UserDefaults.standard.bool(forKey: "purchaseStatus")
      || (sharedDefaults?.bool(forKey: "purchaseStatus") ?? false)
      || (sharedDefaults?.bool(forKey: "yorjPremium") ?? false)

    let snapshot = ConsciousDashboardSnapshot(
      generatedAt: now,
      hasPremiumAccess: premium,
      activeGoals: goals.count,
      completedGoalUnits: completedUnits,
      totalGoalUnits: units.count,
      presenceReturns: presenceReturns,
      automaticPilotEvents: automaticPilotEvents,
      agendaToday: agenda.count,
      agendaCompleted: agenda.filter { $0.value(forKey: "completada") as? Bool == true }.count,
      journalEntriesToday: journal.count,
      morningRitualCompleted: morningCompleted,
      eveningReviewCompleted: eveningCompleted,
      coherenceSessions: coherence.count,
      coherenceMinutes: coherenceMinutes,
      coherenceScore: averageCoherenceScore
    )

    snapshot.save()
    WidgetCenter.shared.reloadTimelines(ofKind: ConsciousDashboardSnapshot.widgetKind)
  }

  private static func fetch(
    entity: String,
    predicate: NSPredicate? = nil,
    context: NSManagedObjectContext
  ) -> [NSManagedObject] {
    let request = NSFetchRequest<NSManagedObject>(entityName: entity)
    request.predicate = predicate
    return (try? context.fetch(request)) ?? []
  }
}
