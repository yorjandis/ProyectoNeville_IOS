//
//  HomeContextualRecommendationCard.swift
//  Neville_iOS
//
//  Created by Codex on 12/07/26.
//

import SwiftUI
import CoreData

/// Una recomendación breve que convierte los registros recientes en una única acción viable.
/// La lectura se limita a los siete días naturales más recientes, incluido hoy.
struct HomeContextualRecommendationCard: View {
    let variant: HomeAlternativoVariant
    let onExpanded: () -> Void

    @Environment(\.managedObjectContext) private var context
    @State private var recommendation = HomeContextualRecommendation.loading
    @State private var isExpanded = false

    private var isDark: Bool { variant == .oscura }
    private var primaryText: Color { isDark ? .white : Color(red: 0.12, green: 0.18, blue: 0.17) }
    private var secondaryText: Color { isDark ? .white.opacity(0.78) : Color(red: 0.27, green: 0.36, blue: 0.34) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    onExpanded()
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recomendación contextual")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("Basada en tus últimos 7 días")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(recommendation.accent)
                        .frame(width: 30, height: 30)
                        .background(recommendation.accent.opacity(0.15), in: Circle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(primaryText)

            if isExpanded {
                Text(recommendation.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text(recommendation.action)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Label("Fuente: \(recommendation.source)", systemImage: "tray.full")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(recommendation.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(recommendation.accent.opacity(0.12), in: Capsule())

                if !recommendation.evidence.isEmpty {
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.caption.weight(.semibold))
                        Text(recommendation.evidence)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(primaryText.opacity(isDark ? 0.09 : 0.06), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(recommendation.accent.opacity(isDark ? 0.42 : 0.28), lineWidth: 1)
        }
        .task {
            reloadRecommendation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
            reloadRecommendation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
            reloadRecommendation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)) { _ in
            reloadRecommendation()
        }
    }

    private var cardBackground: LinearGradient {
        let base = recommendation.accent
        return LinearGradient(
            colors: isDark
                ? [base.opacity(0.25), Color.white.opacity(0.06)]
                : [base.opacity(0.16), Color.white.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor
    private func reloadRecommendation() {
        recommendation = HomeContextualRecommendationEngine(context: context).makeRecommendation()
    }
}

private struct HomeContextualRecommendation {
    let symbol: String
    let accent: Color
    let title: String
    let action: String
    let source: String
    let evidence: String

    static let loading = HomeContextualRecommendation(
        symbol: "sparkles",
        accent: .indigo,
        title: "Preparando tu recomendación",
        action: "Estamos reuniendo tus registros recientes.",
        source: "Mi día",
        evidence: ""
    )
}

@MainActor
private struct HomeContextualRecommendationEngine {
    private let context: NSManagedObjectContext
    private let calendar: Calendar
    private let now: Date

    init(context: NSManagedObjectContext, calendar: Calendar = .current, now: Date = Date()) {
        self.context = context
        self.calendar = calendar
        self.now = now
    }

    func makeRecommendation() -> HomeContextualRecommendation {
        let data = loadData()

        if let overdue = data.overdueAgendaTitle {
            return .init(
                symbol: "checkmark.circle.badge.xmark",
                accent: .orange,
                title: "Desbloquea una tarea pendiente",
                action: "Empieza «\(overdue)» durante solo 10 minutos. Si no corresponde hacerla, reprográmala hoy para liberar atención.",
                source: "Agenda",
                evidence: "Hay \(data.overdueAgendaCount) actividad\(data.overdueAgendaCount == 1 ? "" : "es") sin completar de días anteriores."
            )
        }

        if let unit = data.overdueGoalUnit {
            return .init(
                symbol: "flag.checkered",
                accent: .orange,
                title: "Recupera una unidad de meta",
                action: "Revisa «\(unit)» y decide ahora: complétala si sigue vigente o ajusta la meta para que vuelva a ser realista.",
                source: "Metas",
                evidence: "Hay \(data.lostGoalUnits) unidad\(data.lostGoalUnits == 1 ? "" : "es") de meta fuera de plazo en los últimos 7 días."
            )
        }

        if data.lowEnergyDays >= 3 {
            return .init(
                symbol: "battery.25percent",
                accent: .purple,
                title: "Reduce la exigencia de hoy",
                action: "Elige una sola prioridad importante y reserva una pausa breve antes de la siguiente tarea. Protege energía antes de añadir más compromisos.",
                source: "Ritual matutino",
                evidence: "Tus cierres de ritual registran energía baja en \(data.lowEnergyDays) de los últimos 7 días."
            )
        }

        if data.lowIdentityAlignmentDays >= 3 || data.lowCoherenceSessions >= 2 {
            return .init(
                symbol: "heart.circle",
                accent: .red,
                title: "Recupera coherencia antes de exigirte",
                action: "Haz una sesión breve de coherencia y elige un gesto visible que exprese la identidad que quieres sostener hoy.",
                source: data.lowCoherenceSessions > 0 ? "Coherencia" : "Ritual matutino",
                evidence: data.lowCoherenceSessions > 0
                    ? "\(data.lowCoherenceSessions) sesiones de coherencia cerraron por debajo de 6/10 esta semana."
                    : "La alineación con tu identidad fue baja en \(data.lowIdentityAlignmentDays) cierres de ritual."
            )
        }

        if data.automaticPilotEvents >= 3 || data.negativeMoodEvents + data.negativeDiaryEmotions >= 3 {
            let difficultRecords = max(data.automaticPilotEvents, data.negativeMoodEvents + data.negativeDiaryEmotions)
            let issue = data.automaticPilotEvents >= data.negativeMoodEvents + data.negativeDiaryEmotions ? "piloto automático" : "estados de ánimo difíciles"
            return .init(
                symbol: "heart.text.square",
                accent: .pink,
                title: "Haz una pausa consciente",
                action: "Antes de continuar, respira durante un minuto y registra cómo estás. Después decide la siguiente acción más pequeña que sí puedas sostener.",
                source: data.automaticPilotEvents >= data.negativeMoodEvents + data.negativeDiaryEmotions ? "Presencia" : "Presencia · Diario",
                evidence: "Se registraron \(difficultRecords) eventos de \(issue) durante la última semana."
            )
        }

        if let dueUnit = data.availableGoalUnit {
            return .init(
                symbol: "flag.fill",
                accent: .blue,
                title: "Avanza una unidad concreta",
                action: "Dedica el próximo bloque disponible a «\(dueUnit)». Terminar una unidad acota el esfuerzo y mantiene la meta en movimiento.",
                source: "Metas",
                evidence: "Tienes una unidad de meta disponible ahora y \(data.completedGoalUnits) completada\(data.completedGoalUnits == 1 ? "" : "s") en los últimos 7 días."
            )
        }

        if data.diaryEntries == 0 && data.activeAgendaCount > 0 {
            return .init(
                symbol: "book.closed",
                accent: .teal,
                title: "Convierte lo hecho en aprendizaje",
                action: "Escribe tres líneas: qué funcionó, qué ajustarías y cuál es el siguiente paso. Hazlo antes de cerrar el día.",
                source: "Agenda · Diario",
                evidence: "Tienes \(data.activeAgendaCount) actividad\(data.activeAgendaCount == 1 ? " activa" : "es activas") esta semana, pero no hay entradas de Diario."
            )
        }

        if data.completedGoalUnits >= 2 || data.presenceReturns >= 8 {
            return .init(
                symbol: "sparkles",
                accent: .green,
                title: "Consolida lo que ya funciona",
                action: "Repite hoy el hábito que más te ha sostenido esta semana y deja preparada la primera acción de mañana.",
                source: activeSources(from: data),
                evidence: summaryEvidence(from: data)
            )
        }

        return .init(
            symbol: "scope",
            accent: .indigo,
            title: "Define un punto de apoyo",
            action: "Elige una tarea de Agenda o una unidad de meta y conviértela en el único avance imprescindible de hoy.",
            source: data.hasAnyRecord ? activeSources(from: data) : "Agenda · Metas · Presencia · Diario",
            evidence: data.hasAnyRecord
                ? "Tus registros aún son ligeros esta semana; una acción concreta hará más útil la siguiente recomendación."
                : "Aún no hay registros en los últimos 7 días. Empieza por anotar una tarea, una presencia o una entrada breve."
        )
    }

    private func loadData() -> HomeContextualData {
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        let agenda = fetch(entityName: "AgendaItemEntity", predicate: NSPredicate(format: "fechaActividad >= %@ AND fechaActividad < %@", start as NSDate, tomorrow as NSDate))
        // En Agenda, false equivale al estado de check «Activo». Los valores true
        // (completada) y nil (Off) se excluyen de cualquier recomendación.
        let activeAgenda = agenda.filter { ($0.value(forKey: "completada") as? Bool) == false }
        let overdueAgenda = activeAgenda
            .filter { row in
                guard let date = row.value(forKey: "fechaActividad") as? Date else { return false }
                return date < startOfToday
            }
            .sorted { lhs, rhs in
                let lhsPriority = AgendaPriority(rawValue: lhs.value(forKey: "prioridad") as? String ?? "") == .alta
                let rhsPriority = AgendaPriority(rawValue: rhs.value(forKey: "prioridad") as? String ?? "") == .alta
                return lhsPriority && !rhsPriority
            }

        let diary = fetch(entityName: "Diario", predicate: NSPredicate(format: "fecha >= %@ AND fecha < %@", start as NSDate, tomorrow as NSDate))
        let presence = fetch(entityName: "PresenciaEventEntity", predicate: NSPredicate(format: "dayStart >= %@ AND dayStart < %@", start as NSDate, tomorrow as NSDate))
        let rituals = fetch(entityName: "RitualSessionEntity", predicate: NSPredicate(format: "createdAt >= %@ AND createdAt < %@", start as NSDate, tomorrow as NSDate))
        let startMilliseconds = Int64(start.timeIntervalSince1970 * 1_000)
        let endMilliseconds = Int64(tomorrow.timeIntervalSince1970 * 1_000)
        let coherence = fetch(entityName: "coherencia", predicate: NSPredicate(format: "dateEpochMillis >= %lld AND dateEpochMillis < %lld", startMilliseconds, endMilliseconds))
        let goals = (try? context.fetch(GoalEntity.fetchRequest())) ?? []

        let activeGoals = goals.filter { $0.isStarted && !$0.isCompleted }
        let pendingUnits = activeGoals.flatMap { goal in
            goal.unitsArray.filter { $0.unitStatus == .pending }.map { (goal, $0) }
        }
        let overdueUnits = pendingUnits.filter { _, unit in
            guard let endDate = unit.endDate else { return false }
            return endDate < now
        }
        let availableUnits = pendingUnits.filter { _, unit in
            guard let startDate = unit.startDate, let endDate = unit.endDate else { return false }
            return startDate <= now && now <= endDate
        }

        let goalEvents = fetch(entityName: "GoalStatsEventEntity", predicate: NSPredicate(format: "createdAt >= %@ AND createdAt < %@ AND eventType == %@", start as NSDate, tomorrow as NSDate, GoalStatsEventType.unitCompleted.rawValue))
        let lowEnergyDays = Set(rituals.compactMap { row -> Date? in
            let energy = Int(row.value(forKey: "energy") as? Int16 ?? 0)
            guard energy > 0 && energy <= 2, let date = row.value(forKey: "createdAt") as? Date else { return nil }
            return calendar.startOfDay(for: date)
        }).count
        let lowIdentityAlignmentDays = Set(rituals.compactMap { row -> Date? in
            let score = Int(row.value(forKey: "identityAlignment") as? Int16 ?? 0)
            guard score > 0 && score <= 2, let date = row.value(forKey: "createdAt") as? Date else { return nil }
            return calendar.startOfDay(for: date)
        }).count
        let lowCoherenceSessions = coherence.filter { row in
            let score = Int(row.value(forKey: "afterScore") as? Int16 ?? 0)
            return score > 0 && score < 6
        }.count

        let automaticPilotEvents = presence.filter { row in
            let type = row.value(forKey: "eventType") as? String
            let mood = row.value(forKey: "mood") as? String
            return type == PresenciaEventType.inconsciente.rawValue || mood == "pilotoAutomatico" || mood == "distraido"
        }.count
        let negativeMoodIDs: Set<String> = ["ansioso", "triste", "enfadado", "cansado"]
        let negativeMoodEvents = presence.filter { negativeMoodIDs.contains($0.value(forKey: "mood") as? String ?? "") }.count
        let negativeDiaryEmotions: Set<String> = ["triste", "enfadado", "desanimado", "enfermo", "distraido"]
        let negativeDiaryEmotionCount = diary.filter { negativeDiaryEmotions.contains($0.value(forKey: "emotion") as? String ?? "") }.count

        return HomeContextualData(
            overdueAgendaTitle: title(of: overdueAgenda.first),
            overdueAgendaCount: overdueAgenda.count,
            activeAgendaCount: activeAgenda.count,
            diaryEntries: diary.count,
            presenceReturns: presence.filter { ($0.value(forKey: "eventType") as? String) == PresenciaEventType.presente.rawValue }.count,
            automaticPilotEvents: automaticPilotEvents,
            negativeMoodEvents: negativeMoodEvents,
            negativeDiaryEmotions: negativeDiaryEmotionCount,
            lowEnergyDays: lowEnergyDays,
            lowIdentityAlignmentDays: lowIdentityAlignmentDays,
            lowCoherenceSessions: lowCoherenceSessions,
            overdueGoalUnit: unitTitle(of: overdueUnits.first),
            lostGoalUnits: overdueUnits.count,
            availableGoalUnit: unitTitle(of: availableUnits.first),
            completedGoalUnits: goalEvents.count
        )
    }

    private func fetch(entityName: String, predicate: NSPredicate) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate
        request.includesPendingChanges = true
        return (try? context.fetch(request)) ?? []
    }

    private func title(of row: NSManagedObject?) -> String? {
        guard row != nil else { return nil }
        let title = (row?.value(forKey: "titulo") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "una actividad pendiente" : title
    }

    private func unitTitle(of item: (GoalEntity, UnitEntity)?) -> String? {
        guard let item else { return nil }
        let unit = (item.1.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !unit.isEmpty { return unit }
        return item.0.wrappedTitle.isEmpty ? "una unidad pendiente" : item.0.wrappedTitle
    }

    private func summaryEvidence(from data: HomeContextualData) -> String {
        var parts: [String] = []
        if data.completedGoalUnits > 0 { parts.append("\(data.completedGoalUnits) unidades de meta") }
        if data.presenceReturns > 0 { parts.append("\(data.presenceReturns) regresos a presencia") }
        return "Esta semana: " + parts.joined(separator: " · ") + "."
    }

    private func activeSources(from data: HomeContextualData) -> String {
        var sources: [String] = []
        if data.activeAgendaCount > 0 || data.overdueAgendaCount > 0 { sources.append("Agenda") }
        if data.completedGoalUnits > 0 || data.availableGoalUnit != nil { sources.append("Metas") }
        if data.presenceReturns > 0 || data.automaticPilotEvents > 0 || data.negativeMoodEvents > 0 { sources.append("Presencia") }
        if data.diaryEntries > 0 || data.negativeDiaryEmotions > 0 { sources.append("Diario") }
        if data.lowEnergyDays > 0 || data.lowIdentityAlignmentDays > 0 { sources.append("Ritual") }
        if data.lowCoherenceSessions > 0 { sources.append("Coherencia") }
        return sources.isEmpty ? "Mi día" : sources.joined(separator: " · ")
    }
}

private struct HomeContextualData {
    let overdueAgendaTitle: String?
    let overdueAgendaCount: Int
    let activeAgendaCount: Int
    let diaryEntries: Int
    let presenceReturns: Int
    let automaticPilotEvents: Int
    let negativeMoodEvents: Int
    let negativeDiaryEmotions: Int
    let lowEnergyDays: Int
    let lowIdentityAlignmentDays: Int
    let lowCoherenceSessions: Int
    let overdueGoalUnit: String?
    let lostGoalUnits: Int
    let availableGoalUnit: String?
    let completedGoalUnits: Int

    var hasAnyRecord: Bool {
        overdueAgendaCount + activeAgendaCount + diaryEntries + presenceReturns + automaticPilotEvents + negativeMoodEvents + negativeDiaryEmotions + lowEnergyDays + lowIdentityAlignmentDays + lowCoherenceSessions + completedGoalUnits > 0
    }
}
