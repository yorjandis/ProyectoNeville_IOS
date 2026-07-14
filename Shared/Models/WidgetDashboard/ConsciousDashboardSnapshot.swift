import Foundation

struct ConsciousDashboardSnapshot: Codable, Hashable {
  static let appGroupName = "group.com.ypg.nev.group"
  static let storageKey = "conscious_dashboard_snapshot_v1"
  static let widgetKind = "ConsciousDashboardWidget"

  let generatedAt: Date
  let hasPremiumAccess: Bool
  let activeGoals: Int
  let completedGoalUnits: Int
  let totalGoalUnits: Int
  let presenceReturns: Int
  let automaticPilotEvents: Int
  let agendaToday: Int
  let agendaCompleted: Int
  let journalEntriesToday: Int
  let morningRitualCompleted: Bool
  let eveningReviewCompleted: Bool
  let coherenceSessions: Int
  let coherenceMinutes: Int
  let coherenceScore: Int?

  var goalProgress: Double {
    guard totalGoalUnits > 0 else { return 0 }
    return min(max(Double(completedGoalUnits) / Double(totalGoalUnits), 0), 1)
  }

  var agendaProgress: Double {
    guard agendaToday > 0 else { return 0 }
    return min(max(Double(agendaCompleted) / Double(agendaToday), 0), 1)
  }

  var consciousPulse: Int {
    let goalValue = activeGoals > 0 ? max(goalProgress, 0.15) : 0
    let presenceValue = min(Double(presenceReturns) / 5, 1)
    let agendaValue = agendaToday > 0 ? agendaProgress : 0
    let journalValue = journalEntriesToday > 0 ? 1.0 : 0
    let morningValue = morningRitualCompleted ? 1.0 : 0
    let eveningValue = eveningReviewCompleted ? 1.0 : 0
    let coherenceValue = coherenceSessions > 0 ? 1.0 : 0
    let average =
      (goalValue + presenceValue + agendaValue + journalValue + morningValue + eveningValue
        + coherenceValue) / 7
    return Int((average * 100).rounded())
  }

  static var placeholder: ConsciousDashboardSnapshot {
    ConsciousDashboardSnapshot(
      generatedAt: .now,
      hasPremiumAccess: true,
      activeGoals: 3,
      completedGoalUnits: 7,
      totalGoalUnits: 12,
      presenceReturns: 5,
      automaticPilotEvents: 1,
      agendaToday: 4,
      agendaCompleted: 2,
      journalEntriesToday: 1,
      morningRitualCompleted: true,
      eveningReviewCompleted: false,
      coherenceSessions: 2,
      coherenceMinutes: 15,
      coherenceScore: 8
    )
  }

  static var empty: ConsciousDashboardSnapshot {
    ConsciousDashboardSnapshot(
      generatedAt: .now,
      hasPremiumAccess: false,
      activeGoals: 0,
      completedGoalUnits: 0,
      totalGoalUnits: 0,
      presenceReturns: 0,
      automaticPilotEvents: 0,
      agendaToday: 0,
      agendaCompleted: 0,
      journalEntriesToday: 0,
      morningRitualCompleted: false,
      eveningReviewCompleted: false,
      coherenceSessions: 0,
      coherenceMinutes: 0,
      coherenceScore: nil
    )
  }

  static func load() -> ConsciousDashboardSnapshot {
    guard let defaults = UserDefaults(suiteName: appGroupName),
      let data = defaults.data(forKey: storageKey),
      let snapshot = try? JSONDecoder().decode(ConsciousDashboardSnapshot.self, from: data)
    else {
      return .empty
    }
    return snapshot
  }

  func normalized(for date: Date, calendar: Calendar = .current) -> ConsciousDashboardSnapshot {
    guard !calendar.isDate(generatedAt, inSameDayAs: date) else { return self }

    return ConsciousDashboardSnapshot(
      generatedAt: date,
      hasPremiumAccess: hasPremiumAccess,
      activeGoals: activeGoals,
      completedGoalUnits: completedGoalUnits,
      totalGoalUnits: totalGoalUnits,
      presenceReturns: 0,
      automaticPilotEvents: 0,
      agendaToday: 0,
      agendaCompleted: 0,
      journalEntriesToday: 0,
      morningRitualCompleted: false,
      eveningReviewCompleted: false,
      coherenceSessions: 0,
      coherenceMinutes: 0,
      coherenceScore: nil
    )
  }

  func save() {
    guard let data = try? JSONEncoder().encode(self) else { return }
    UserDefaults(suiteName: Self.appGroupName)?.set(data, forKey: Self.storageKey)
  }
}
