import CoreData
import SwiftUI

struct GoalStatsView: View {
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ArchivedGoalEntity.completionDate, ascending: false)]
    ) private var archivedGoals: FetchedResults<ArchivedGoalEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalStatsEventEntity.createdAt, ascending: false)]
    ) private var events: FetchedResults<GoalStatsEventEntity>

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.18, blue: 0.30),
                        Color(red: 0.13, green: 0.34, blue: 0.46),
                        Color(red: 0.91, green: 0.48, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        GoalStatsHeadlineCards(stats: stats)
                        GoalStatsWeeklyBarChart(stats: stats)
                        GoalStatsStatusRingsSection(stats: stats)
                        GoalStatsFocusSection(stats: stats)
                        GoalStatsDotTrendSection(stats: stats)
                    }
                    .padding()
                }
            }
            .navigationTitle("Estadísticas de Metas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cerrar")
                    }
                }
            }
        }
    }

    private var stats: GoalStatsSnapshot {
        GoalStatsSnapshot(
            goals: Array(goals),
            archivedGoals: Array(archivedGoals),
            events: Array(events)
        )
    }
}

private struct GoalStatsSnapshot {
    struct WeekdayCount: Identifiable {
        var id: String { dayLabel }
        let dayLabel: String
        let count: Int
    }

    struct StatusShare: Identifiable {
        var id: String { title }
        let title: String
        let value: Int
        let color: Color
        let systemImage: String
    }

    struct UnitTypeCount: Identifiable {
        var id: String { title }
        let title: String
        let count: Int
    }

    struct DayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let count: Int
    }

    let activeGoals: Int
    let completedGoals: Int
    let actionReadyGoals: Int
    let totalUnits: Int
    let completedUnits: Int
    let lostUnits: Int
    let pendingUnits: Int
    let completionRate: Double
    let averageProgress: Double
    let currentStreak: Int
    let longestStreak: Int
    let weekdayCounts: [WeekdayCount]
    let statusShares: [StatusShare]
    let topUnitTypes: [UnitTypeCount]
    let dayPoints: [DayPoint]
    private let dailyCompletionCounts: [Date: Int]

    init(goals: [GoalEntity], archivedGoals: [ArchivedGoalEntity], events: [GoalStatsEventEntity]) {
        let calendar = Calendar.current
        let active = goals.filter { $0.isStarted && !$0.isCompleted }
        activeGoals = active.count
        completedGoals = archivedGoals.count + goals.filter { $0.isStarted && $0.isCompleted }.count
        actionReadyGoals = active.filter { $0.nextPendingUnit != nil }.count

        let liveUnits = goals.flatMap(\.unitsArray)
        let archivedUnits = archivedGoals.flatMap { goal in
            (goal.units as? Set<ArchivedUnitEntity> ?? [])
        }

        let liveCompleted = liveUnits.filter { $0.unitStatus == .completed }.count
        let archivedCompleted = archivedUnits.filter { UnitStatus(rawValue: $0.status ?? "") == .completed }.count
        let liveLost = liveUnits.filter { $0.unitStatus == .lost }.count
        let archivedLost = archivedUnits.filter { UnitStatus(rawValue: $0.status ?? "") == .lost }.count

        totalUnits = liveUnits.count + archivedUnits.count
        completedUnits = liveCompleted + archivedCompleted
        lostUnits = liveLost + archivedLost
        pendingUnits = max(totalUnits - completedUnits - lostUnits, 0)
        completionRate = totalUnits == 0 ? 0 : Double(completedUnits) / Double(totalUnits)

        let progressValues = goals.map(\.progressRatio)
        averageProgress = progressValues.isEmpty ? 0 : progressValues.reduce(0, +) / Double(progressValues.count)

        let completedUnitDatePairs: [(UUID?, Date)] = liveUnits.compactMap { unit -> (UUID?, Date)? in
            guard unit.unitStatus == .completed, let completedDate = unit.completedDate else {
                return nil
            }
            return (unit.id, completedDate)
        } + archivedUnits.compactMap { unit -> (UUID?, Date)? in
            guard UnitStatus(rawValue: unit.status ?? "") == .completed, let completedDate = unit.completedDate else {
                return nil
            }
            return (unit.id, completedDate)
        }
        let completedDates = completedUnitDatePairs.map(\.1)

        let normalizedDays = completedDates.map { calendar.startOfDay(for: $0) }
        let daysWithCompletions = Set(normalizedDays)
        currentStreak = Self.calculateCurrentStreak(from: daysWithCompletions, calendar: calendar)
        longestStreak = Self.calculateLongestStreak(from: daysWithCompletions, calendar: calendar)

        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        let weekdayMap = Dictionary(grouping: normalizedDays, by: { calendar.component(.weekday, from: $0) }).mapValues(\.count)
        weekdayCounts = weekdaySymbols.enumerated().map { index, label in
            WeekdayCount(dayLabel: label, count: weekdayMap[index + 1] ?? 0)
        }

        statusShares = [
            StatusShare(title: "Fichadas", value: completedUnits, color: .green, systemImage: "checkmark.circle.fill"),
            StatusShare(title: "Pendientes", value: pendingUnits, color: .cyan, systemImage: "clock.fill"),
            StatusShare(title: "Perdidas", value: lostUnits, color: .orange, systemImage: "exclamationmark.circle.fill")
        ]

        let unitTypes = goals.compactMap(\.unitType) + archivedGoals.compactMap(\.unitType)
        topUnitTypes = Dictionary(grouping: unitTypes, by: { $0 })
            .map { UnitTypeCount(title: TimeUnit(rawValue: $0.key)?.label ?? $0.key.capitalized, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        let completionEvents = events.filter { $0.eventType == GoalStatsEventType.unitCompleted.rawValue }
        let eventUnitIDs = Set(completionEvents.compactMap(\.unitID))
        let eventDays = completionEvents.compactMap { $0.dayStart ?? $0.createdAt.map { calendar.startOfDay(for: $0) } }
        let unitDaysWithoutEvent = completedUnitDatePairs.compactMap { unitID, date -> Date? in
            if let unitID, eventUnitIDs.contains(unitID) {
                return nil
            }
            return calendar.startOfDay(for: date)
        }
        dailyCompletionCounts = Dictionary(grouping: unitDaysWithoutEvent + eventDays, by: { $0 }).mapValues(\.count)
        dayPoints = Self.buildDayPoints(days: 30, calendar: calendar, dailyCounts: dailyCompletionCounts)
    }

    func dayPoints(for days: Int) -> [DayPoint] {
        Self.buildDayPoints(days: max(days, 1), calendar: Calendar.current, dailyCounts: dailyCompletionCounts)
    }

    private static func buildDayPoints(days: Int, calendar: Calendar, dailyCounts: [Date: Int]) -> [DayPoint] {
        var points: [DayPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: Date.now) else { continue }
            let start = calendar.startOfDay(for: targetDate)
            points.append(DayPoint(date: start, count: dailyCounts[start] ?? 0))
        }
        return points
    }

    private static func calculateCurrentStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: Date.now)

        if !days.contains(cursor),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
           days.contains(yesterday) {
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func calculateLongestStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        let sortedDays = days.sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for index in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[index - 1], to: sortedDays[index]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return best
    }
}

private struct GoalStatsHeadlineCards: View {
    let stats: GoalStatsSnapshot

    var body: some View {
        VStack(spacing: 12) {
            Text("Tu avance en Metas")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                GoalStatsMetricCard(title: "Activas", value: "\(stats.activeGoals)", subtitle: "en marcha")
                GoalStatsMetricCard(title: "Completadas", value: "\(stats.completedGoals)", subtitle: "histórico")
            }

            HStack(spacing: 12) {
                GoalStatsMetricCard(title: "Listas", value: "\(stats.actionReadyGoals)", subtitle: "para fichar")
                GoalStatsMetricCard(title: "Acierto", value: "\(Int(stats.completionRate * 100))%", subtitle: "unidades")
            }

            HStack(spacing: 12) {
                GoalStatsMetricCard(title: "Racha actual", value: "\(stats.currentStreak)", subtitle: "días")
                GoalStatsMetricCard(title: "Mejor racha", value: "\(stats.longestStreak)", subtitle: "días")
            }
        }
    }
}

private struct GoalStatsMetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct GoalStatsWeeklyBarChart: View {
    let stats: GoalStatsSnapshot

    private var maxCount: Int {
        max(stats.weekdayCounts.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fichajes por día")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(stats.weekdayCounts) { item in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.15))
                                .frame(height: 120)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [.green, .yellow], startPoint: .bottom, endPoint: .top))
                                .frame(height: CGFloat(item.count) / CGFloat(maxCount) * 120)
                        }
                        .frame(width: 30)

                        Text(item.dayLabel)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct GoalStatsStatusRingsSection: View {
    let stats: GoalStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Estado de unidades")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                ForEach(stats.statusShares) { share in
                    GoalStatsRingMetric(
                        progress: Double(share.value) / Double(max(stats.totalUnits, 1)),
                        color: share.color,
                        systemImage: share.systemImage,
                        title: share.title,
                        value: share.value
                    )
                }
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct GoalStatsRingMetric: View {
    let progress: Double
    let color: Color
    let systemImage: String
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .frame(width: 76, height: 76)

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(value)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GoalStatsFocusSection: View {
    let stats: GoalStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enfoque")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                GoalStatsMetricCard(
                    title: "Progreso medio",
                    value: "\(Int(stats.averageProgress * 100))%",
                    subtitle: "metas creadas"
                )
                GoalStatsMetricCard(
                    title: "Unidades",
                    value: "\(stats.completedUnits)/\(stats.totalUnits)",
                    subtitle: "fichadas"
                )
            }

            if !stats.topUnitTypes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(stats.topUnitTypes.prefix(3)) { item in
                        HStack {
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
                .padding()
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct GoalStatsDotTrendSection: View {
    let stats: GoalStatsSnapshot
    @State private var selectedDays: Int = 30

    private let dayOptions: [Int] = [7, 15, 30, 45, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actividad de los últimos \(selectedDays) días")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dayOptions, id: \.self) { days in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDays = days
                            }
                        } label: {
                            Text("\(days)d")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedDays == days ? .black : .white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(selectedDays == days ? .white : .white.opacity(0.16))
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(selectedDays == days ? 0 : 0.35), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 12
            ) {
                ForEach(stats.dayPoints(for: selectedDays)) { point in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(dotColor(for: point.count))
                            .frame(width: dotSize(for: point.count), height: dotSize(for: point.count))
                            .overlay {
                                if point.count > 0 {
                                    Text("\(point.count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: point.count)

                        Text(point.date.formatted(.dateTime.day()))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dotSize(for count: Int) -> CGFloat {
        switch count {
        case 0: return 10
        case 1: return 16
        case 2...3: return 20
        default: return 24
        }
    }

    private func dotColor(for count: Int) -> Color {
        switch count {
        case 0: return .white.opacity(0.2)
        case 1: return .green
        case 2...3: return .yellow
        default: return .orange
        }
    }
}
