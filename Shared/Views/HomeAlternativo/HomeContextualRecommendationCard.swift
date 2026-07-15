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

                Label(
                    L10n.format(
                        "home.recommendation.source",
                        fallback: "Fuente: {0}",
                        recommendation.source
                    ),
                    systemImage: "tray.full"
                )
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
        title: L10n.exact("Preparando tu recomendación"),
        action: L10n.exact("Estamos reuniendo tus registros recientes."),
        source: L10n.exact("Mi día"),
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
                title: L10n.exact("Desbloquea una tarea pendiente"),
                action: L10n.format(
                    "home.recommendation.overdue_agenda.action",
                    fallback: "Empieza «{0}» durante solo 10 minutos. Si no corresponde hacerla, reprográmala hoy para liberar atención.",
                    overdue
                ),
                source: L10n.exact("Agenda"),
                evidence: L10n.format(
                    data.overdueAgendaCount == 1
                        ? "home.recommendation.overdue_agenda.evidence.single"
                        : "home.recommendation.overdue_agenda.evidence.multiple",
                    fallback: data.overdueAgendaCount == 1
                        ? "Hay {0} actividad sin completar de días anteriores."
                        : "Hay {0} actividades sin completar de días anteriores.",
                    "\(data.overdueAgendaCount)"
                )
            )
        }

        if let unit = data.overdueGoalUnit {
            return .init(
                symbol: "flag.checkered",
                accent: .orange,
                title: L10n.exact("Recupera una unidad de meta"),
                action: L10n.format(
                    "home.recommendation.overdue_goal.action",
                    fallback: "Revisa «{0}» y decide ahora: complétala si sigue vigente o ajusta la meta para que vuelva a ser realista.",
                    unit
                ),
                source: L10n.exact("Metas"),
                evidence: L10n.format(
                    data.lostGoalUnits == 1
                        ? "home.recommendation.overdue_goal.evidence.single"
                        : "home.recommendation.overdue_goal.evidence.multiple",
                    fallback: data.lostGoalUnits == 1
                        ? "Hay {0} unidad de meta fuera de plazo en los últimos 7 días."
                        : "Hay {0} unidades de meta fuera de plazo en los últimos 7 días.",
                    "\(data.lostGoalUnits)"
                )
            )
        }

        if data.lowEnergyDays >= 3 {
            return .init(
                symbol: "battery.25percent",
                accent: .purple,
                title: L10n.exact("Reduce la exigencia de hoy"),
                action: L10n.exact("Elige una sola prioridad importante y reserva una pausa breve antes de la siguiente tarea. Protege energía antes de añadir más compromisos."),
                source: L10n.exact("Ritual matutino"),
                evidence: L10n.format(
                    "home.recommendation.low_energy.evidence",
                    fallback: "Tus cierres de ritual registran energía baja en {0} de los últimos 7 días.",
                    "\(data.lowEnergyDays)"
                )
            )
        }

        if data.lowIdentityAlignmentDays >= 3 || data.lowCoherenceSessions >= 2 {
            return .init(
                symbol: "heart.circle",
                accent: .red,
                title: L10n.exact("Recupera coherencia antes de exigirte"),
                action: L10n.exact("Haz una sesión breve de coherencia y elige un gesto visible que exprese la identidad que quieres sostener hoy."),
                source: L10n.exact(data.lowCoherenceSessions > 0 ? "Coherencia" : "Ritual matutino"),
                evidence: data.lowCoherenceSessions > 0
                    ? L10n.format(
                        "home.recommendation.low_coherence.evidence",
                        fallback: "{0} sesiones de coherencia cerraron por debajo de 6/10 esta semana.",
                        "\(data.lowCoherenceSessions)"
                    )
                    : L10n.format(
                        "home.recommendation.low_identity.evidence",
                        fallback: "La alineación con tu identidad fue baja en {0} cierres de ritual.",
                        "\(data.lowIdentityAlignmentDays)"
                    )
            )
        }

        if data.automaticPilotEvents >= 3 || data.negativeMoodEvents + data.negativeDiaryEmotions >= 3 {
            let difficultRecords = max(data.automaticPilotEvents, data.negativeMoodEvents + data.negativeDiaryEmotions)
            let issue = L10n.exact(
                data.automaticPilotEvents >= data.negativeMoodEvents + data.negativeDiaryEmotions
                    ? "piloto automático"
                    : "estados de ánimo difíciles"
            )
            return .init(
                symbol: "heart.text.square",
                accent: .pink,
                title: L10n.exact("Haz una pausa consciente"),
                action: L10n.exact("Antes de continuar, respira durante un minuto y registra cómo estás. Después decide la siguiente acción más pequeña que sí puedas sostener."),
                source: L10n.exact(data.automaticPilotEvents >= data.negativeMoodEvents + data.negativeDiaryEmotions ? "Presencia" : "Presencia · Diario"),
                evidence: L10n.format(
                    "home.recommendation.difficult_events.evidence",
                    fallback: "Se registraron {0} eventos de {1} durante la última semana.",
                    "\(difficultRecords)",
                    issue
                )
            )
        }

        if let dueUnit = data.availableGoalUnit {
            return .init(
                symbol: "flag.fill",
                accent: .blue,
                title: L10n.exact("Avanza una unidad concreta"),
                action: L10n.format(
                    "home.recommendation.available_goal.action",
                    fallback: "Dedica el próximo bloque disponible a «{0}». Terminar una unidad acota el esfuerzo y mantiene la meta en movimiento.",
                    dueUnit
                ),
                source: L10n.exact("Metas"),
                evidence: L10n.format(
                    data.completedGoalUnits == 1
                        ? "home.recommendation.available_goal.evidence.single"
                        : "home.recommendation.available_goal.evidence.multiple",
                    fallback: data.completedGoalUnits == 1
                        ? "Tienes una unidad de meta disponible ahora y {0} completada en los últimos 7 días."
                        : "Tienes una unidad de meta disponible ahora y {0} completadas en los últimos 7 días.",
                    "\(data.completedGoalUnits)"
                )
            )
        }

        if data.diaryEntries == 0 && data.activeAgendaCount > 0 {
            return .init(
                symbol: "book.closed",
                accent: .teal,
                title: L10n.exact("Convierte lo hecho en aprendizaje"),
                action: L10n.exact("Escribe tres líneas: qué funcionó, qué ajustarías y cuál es el siguiente paso. Hazlo antes de cerrar el día."),
                source: L10n.exact("Agenda · Diario"),
                evidence: L10n.format(
                    data.activeAgendaCount == 1
                        ? "home.recommendation.no_diary.evidence.single"
                        : "home.recommendation.no_diary.evidence.multiple",
                    fallback: data.activeAgendaCount == 1
                        ? "Tienes {0} actividad activa esta semana, pero no hay entradas de Diario."
                        : "Tienes {0} actividades activas esta semana, pero no hay entradas de Diario.",
                    "\(data.activeAgendaCount)"
                )
            )
        }

        if data.completedGoalUnits >= 2 || data.presenceReturns >= 8 {
            return .init(
                symbol: "sparkles",
                accent: .green,
                title: L10n.exact("Consolida lo que ya funciona"),
                action: L10n.exact("Repite hoy el hábito que más te ha sostenido esta semana y deja preparada la primera acción de mañana."),
                source: activeSources(from: data),
                evidence: summaryEvidence(from: data)
            )
        }

        return .init(
            symbol: "scope",
            accent: .indigo,
            title: L10n.exact("Define un punto de apoyo"),
            action: L10n.exact("Elige una tarea de Agenda o una unidad de meta y conviértela en el único avance imprescindible de hoy."),
            source: data.hasAnyRecord ? activeSources(from: data) : L10n.exact("Agenda · Metas · Presencia · Diario"),
            evidence: data.hasAnyRecord
                ? L10n.exact("Tus registros aún son ligeros esta semana; una acción concreta hará más útil la siguiente recomendación.")
                : L10n.exact("Aún no hay registros en los últimos 7 días. Empieza por anotar una tarea, una presencia o una entrada breve.")
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
        return title.isEmpty ? L10n.exact("una actividad pendiente") : title
    }

    private func unitTitle(of item: (GoalEntity, UnitEntity)?) -> String? {
        guard let item else { return nil }
        let unit = (item.1.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !unit.isEmpty { return unit }
        return item.0.wrappedTitle.isEmpty ? L10n.exact("una unidad pendiente") : item.0.wrappedTitle
    }

    private func summaryEvidence(from data: HomeContextualData) -> String {
        var parts: [String] = []
        if data.completedGoalUnits > 0 {
            parts.append(L10n.format(
                data.completedGoalUnits == 1
                    ? "home.recommendation.summary.goals.single"
                    : "home.recommendation.summary.goals.multiple",
                fallback: data.completedGoalUnits == 1 ? "{0} unidad de meta" : "{0} unidades de meta",
                "\(data.completedGoalUnits)"
            ))
        }
        if data.presenceReturns > 0 {
            parts.append(L10n.format(
                data.presenceReturns == 1
                    ? "home.recommendation.summary.presence.single"
                    : "home.recommendation.summary.presence.multiple",
                fallback: data.presenceReturns == 1 ? "{0} regreso a presencia" : "{0} regresos a presencia",
                "\(data.presenceReturns)"
            ))
        }
        return L10n.format(
            "home.recommendation.summary.week",
            fallback: "Esta semana: {0}.",
            parts.joined(separator: " · ")
        )
    }

    private func activeSources(from data: HomeContextualData) -> String {
        var sources: [String] = []
        if data.activeAgendaCount > 0 || data.overdueAgendaCount > 0 { sources.append(L10n.exact("Agenda")) }
        if data.completedGoalUnits > 0 || data.availableGoalUnit != nil { sources.append(L10n.exact("Metas")) }
        if data.presenceReturns > 0 || data.automaticPilotEvents > 0 || data.negativeMoodEvents > 0 { sources.append(L10n.exact("Presencia")) }
        if data.diaryEntries > 0 || data.negativeDiaryEmotions > 0 { sources.append(L10n.exact("Diario")) }
        if data.lowEnergyDays > 0 || data.lowIdentityAlignmentDays > 0 { sources.append(L10n.exact("Ritual")) }
        if data.lowCoherenceSessions > 0 { sources.append(L10n.exact("Coherencia")) }
        return sources.isEmpty ? L10n.exact("Mi día") : sources.joined(separator: " · ")
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
