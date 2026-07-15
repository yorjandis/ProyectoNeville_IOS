//
//  HomeAlternativoView.swift
//  Neville_iOS
//
//  Created by Codex on 28/06/26.
//

import SwiftUI
import CoreData

struct HomeAlternativoView: View {
    let variant: HomeAlternativoVariant

    @EnvironmentObject private var settingModel: SettingModel
    @EnvironmentObject private var frasesModel: FrasesModel
    @EnvironmentObject private var securityModel: SecurityModel
    @EnvironmentObject private var clipBoardModel: ClipboardObserver
    @EnvironmentObject private var modelTxt: TxtContentModel
    @EnvironmentObject private var reflexModel: ReflexModel
    @Environment(\.managedObjectContext) private var context

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage("HomeAlternativo_AccessIDs") private var storedAccessIDs: String = ""
    @AppStorage("HomeAlternativo_PaletteIDs") private var storedPaletteIDs: String = ""
    @AppStorage("Home_AgendaBadge_HiddenDayKey") private var agendaBadgeHiddenDayKey: String = ""
    @AppStorage(AppCons.UD_setting_WeeklyReviewWeekday) private var weeklyReviewWeekday: Int = WeeklyReviewDay.sunday.rawValue
    @AppStorage(AppCons.UD_setting_WeeklyReviewCompletedPeriod) private var weeklyReviewCompletedPeriod = ""
    @AppStorage(AppCons.UD_setting_HomeProductividadPresenciaTotal) private var homeProductividadPresenciaTotal: Int = 5
    @AppStorage(AppCons.UD_setting_HomeProductividadMetasTotal) private var homeProductividadMetasTotal: Int = 1
    @AppStorage(AppCons.UD_setting_HomeAlternativoShowHealingCenterCard) private var showHealingCenterCard: Bool = true
    @StateObject private var agendaViewModel = AgendaViewModel()
    @StateObject private var stressMonitor = StressMonitor.shared
    @State private var phrase = HomeAlternativoPhrases.random(for: HomeAlternativoDayMoment.current())
    @State private var showPremium = false
    @State private var showAccessEditor = false
    @State private var selectedAccessIDs = HomeAlternativoAccess.defaultIDs
    @State private var selectedPaletteIDs = HomeAlternativoCardPalette.defaultIDs(for: HomeAlternativoAccess.defaultIDs)
    @State private var now = Date()
    @State private var goalsBadgeVisible = false
    @State private var nextGoalsBadgeRefreshDate: Date?
    @State private var todayPresentCount = 0
    private let presenceRepository = PresenciaRepository()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    private var theme: HomeAlternativoTheme {
        HomeAlternativoTheme(variant: variant)
    }

    private var tools: [HomeAlternativoTool] {
        let normalizedAccessIDs = HomeAlternativoAccess.normalizedIDs(
            from: HomeAlternativoAccess.encode(selectedAccessIDs)
        )
        let normalizedPaletteIDs = HomeAlternativoCardPalette.normalizedIDs(
            from: selectedPaletteIDs,
            accessIDs: normalizedAccessIDs
        )

        return normalizedAccessIDs.enumerated().compactMap { index, id in
            guard let access = HomeAlternativoAccess(rawValue: id) else { return nil }
            let paletteID = normalizedPaletteIDs.indices.contains(index)
                ? normalizedPaletteIDs[index]
                : access.defaultPalette.rawValue
            let palette = HomeAlternativoCardPalette(rawValue: paletteID) ?? access.defaultPalette
            return HomeAlternativoTool(access: access, palette: palette)
        }
    }

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    private var agendaBadgeCurrentDayKey: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private var todayAgendaActivitiesCount: Int {
        agendaViewModel.items.filter {
            Calendar.current.isDate($0.fechaActividad, inSameDayAs: now)
        }.count
    }

    private var shouldShowAgendaBadge: Bool {
        todayAgendaActivitiesCount > 0 && agendaBadgeHiddenDayKey != agendaBadgeCurrentDayKey
    }

    private var shouldShowGoalsBadge: Bool {
        goalsBadgeVisible
    }

    private var shouldPromptWeeklyReview: Bool {
        guard WeeklyReviewSchedule.isAvailable(now: now, weekday: weeklyReviewWeekday) else { return false }
        let interval = WeeklyReviewSchedule.interval(now: now, weekday: weeklyReviewWeekday)
        return weeklyReviewCompletedPeriod != WeeklyReviewSchedule.periodKey(for: interval)
    }

    private var greeting: String {
        switch dayMoment {
        case .morning:
            return L10n.exact("Buenos días")
        case .afternoon:
            return L10n.exact("Buenas tardes")
        case .night:
            return L10n.exact("Buenas noches")
        }
    }

    private var dayMoment: HomeAlternativoDayMoment {
        HomeAlternativoDayMoment.current(for: now)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var progressItems: [HomeAlternativoProgressItem] {
        let activeGoals = goals.filter { $0.isStarted && !$0.isCompleted }
        let presenceTotal = Double(max(homeProductividadPresenciaTotal, 5))
        let goalsTotal = Double(max(homeProductividadMetasTotal, 1))

        return [
            .init(
                title: L10n.exact("Presencia"),
                valueText: L10n.format(
                    todayPresentCount == 1 ? "home.progress.presence.single" : "home.progress.presence.multiple",
                    fallback: todayPresentCount == 1 ? "{0} evento" : "{0} eventos",
                    "\(todayPresentCount)"
                ),
                symbol: "heart.text.square",
                progress: min(Double(todayPresentCount) / presenceTotal, 1.0),
                colors: HomeAlternativoProgressPalette.presence
            ),
            .init(
                title: L10n.exact("Metas"),
                valueText: L10n.format(
                    activeGoals.count == 1 ? "home.progress.goals.single" : "home.progress.goals.multiple",
                    fallback: activeGoals.count == 1 ? "{0} activa" : "{0} activas",
                    "\(activeGoals.count)"
                ),
                symbol: "checklist",
                progress: min(Double(activeGoals.count) / goalsTotal, 1.0),
                colors: HomeAlternativoProgressPalette.goals
            )
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 18)
                            .id(HomeAlternativoScrollTarget.top)

                        mainContent {
                            withAnimation(.easeInOut(duration: 0.32)) {
                                scrollProxy.scrollTo(HomeAlternativoScrollTarget.top, anchor: .top)
                            }
                        }

                        Spacer(minLength: 18)
                    }
                    .frame(minHeight: max(proxy.size.height - 112, 0))
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    .padding(.bottom, 112)
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .foregroundStyle(theme.primaryText)
        .onAppear {
            now = Date()
            agendaViewModel.load()
            reloadPresenceProgress()
            stressMonitor.activateBackgroundObservationIfNeeded()
            phrase = HomeAlternativoPhrases.random(for: dayMoment)
            let normalizedAccessIDs = HomeAlternativoAccess.normalizedIDs(from: storedAccessIDs)
            let normalizedPaletteIDs = HomeAlternativoCardPalette.normalizedIDs(
                from: storedPaletteIDs,
                accessIDs: normalizedAccessIDs
            )
            selectedAccessIDs = normalizedAccessIDs
            selectedPaletteIDs = normalizedPaletteIDs
            updateGoalsBadgeState(at: Date())
        }
        .task {
            await stressMonitor.refresh()
        }
        .task(id: nextGoalsBadgeRefreshDate) {
            guard let refreshDate = nextGoalsBadgeRefreshDate else { return }
            let delay = max(refreshDate.timeIntervalSinceNow, 0.2)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                updateGoalsBadgeState(at: Date())
            }
        }
        .onChange(of: selectedAccessIDs) { _, newValue in
            storedAccessIDs = HomeAlternativoAccess.encode(newValue)
            let normalizedPaletteIDs = HomeAlternativoCardPalette.normalizedIDs(
                from: selectedPaletteIDs,
                accessIDs: newValue
            )

            if selectedPaletteIDs != normalizedPaletteIDs {
                selectedPaletteIDs = normalizedPaletteIDs
            }
        }
        .onChange(of: selectedPaletteIDs) { _, newValue in
            storedPaletteIDs = HomeAlternativoCardPalette.encode(newValue, accessIDs: selectedAccessIDs)
        }
        .sheet(isPresented: $showPremium) {
            PurchaseView()
        }
        .sheet(isPresented: $showAccessEditor) {
            HomeAlternativoAccessEditorView(
                accessIDs: $selectedAccessIDs,
                paletteIDs: $selectedPaletteIDs
            )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
            reloadPresenceProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
            updateGoalsBadgeState(at: Date())
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
            updateGoalsBadgeState(at: Date())
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            updateGoalsBadgeState(at: Date())
        }
    }

    private func mainContent(onRecommendationExpanded: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            if shouldPromptWeeklyReview {
                weeklyReviewPrompt
            }
            if showHealingCenterCard {
                healingCenterPrompt
            }
            toolsGrid
            progressSection
            HomeContextualRecommendationCard(
                variant: variant,
                onExpanded: onRecommendationExpanded
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(phrase)
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("")
            /*
             Text("\(greeting)")
                 .font(.system(size: 20, weight: .regular, design: .rounded))
                 .foregroundStyle(theme.secondaryText)
                 .lineLimit(1)
                 .minimumScaleFactor(0.85)
                 .frame(maxWidth: .infinity, alignment: .leading)
             */
            
        }
    }

    private var weeklyReviewPrompt: some View {
        NavigationLink {
            WeeklyReviewView()
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.indigo, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Tu revisión semanal está lista")
                        .font(.subheadline.bold())
                    Text("5–10 min para ver avances, patrones y elegir tu foco.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(14)
            .background(.indigo.opacity(0.13), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.indigo.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var healingCenterPrompt: some View {
        NavigationLink {
            CentroSanadorView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.mint, .cyan, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)
                .shadow(color: .cyan.opacity(0.30), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Centro Sanador")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Apoyo práctico para un momento difícil")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer(minLength: 2)

                VStack(spacing: 3) {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundStyle(.pink)
                    Text("Ahora")
                        .font(.caption2.bold())
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .foregroundStyle(theme.primaryText)
            .padding(15)
            .background(
                LinearGradient(
                    colors: theme.variant == .oscura
                        ? [.cyan.opacity(0.22), .indigo.opacity(0.16)]
                        : [.cyan.opacity(0.17), .white.opacity(0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 21, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(.cyan.opacity(0.30), lineWidth: 1)
            }
        }
        .buttonStyle(HomeAlternativoPressedButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                showHealingCenterCard = false
            } label: {
                Label("Ocultar de Home", systemImage: "eye.slash")
            }
        }
        .accessibilityHint("Abre guías inmediatas de regulación y recursos de emergencia")
    }

    private var toolsGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(tools) { tool in
                Group {
                    if tool.requiresPremium && !hasPremiumAccess {
                        Button {
                            showPremium = true
                        } label: {
                            toolCard(for: tool)
                        }
                    } else {
                        NavigationLink {
                            destination(for: tool.access)
                                .onDisappear {
                                    now = Date()
                                    agendaViewModel.load()
                                    reloadPresenceProgress()
                                }
                        } label: {
                            toolCard(for: tool)
                        }
                    }
                }
                .buttonStyle(HomeAlternativoPressedButtonStyle())
                .contextMenu {
                    Button {
                        showAccessEditor = true
                    } label: {
                        Label("Editar cuadrícula", systemImage: "slider.horizontal.3")
                    }

                    if tool.access == .agenda && todayAgendaActivitiesCount > 0 {
                        Button {
                            if shouldShowAgendaBadge {
                                agendaBadgeHiddenDayKey = agendaBadgeCurrentDayKey
                            } else {
                                agendaBadgeHiddenDayKey = ""
                            }
                        } label: {
                            Label(
                                L10n.exact(shouldShowAgendaBadge ? "Ocultar indicador por hoy" : "Mostrar indicador"),
                                systemImage: shouldShowAgendaBadge ? "bell.badge.slash" : "bell.badge"
                            )
                        }
                    }
                }
            }
        }
    }

    private func toolCard(for tool: HomeAlternativoTool) -> some View {
        HomeAlternativoToolCard(tool: tool, theme: theme)
            .overlay(alignment: .topTrailing) {
                if tool.access == .agenda && shouldShowAgendaBadge {
                    Text(todayAgendaActivitiesCount > 99 ? "99+" : "\(todayAgendaActivitiesCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.red.opacity(0.90)))
                        .offset(x: 5, y: -5)
                }

                if tool.access == .metas && shouldShowGoalsBadge {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.orange.opacity(0.94)))
                        .offset(x: 5, y: -5)
                }
            }
    }

    private func refreshGoalLostUnitsIfNeeded(at date: Date) {
        var didChange = false

        for goal in goals where goal.refreshLostUnits(now: date) {
            didChange = true
        }

        if didChange && context.hasChanges {
            try? context.save()
        }
    }

    private func updateGoalsBadgeState(at date: Date) {
        refreshGoalLostUnitsIfNeeded(at: date)

        let hasAvailableUnit = goals.contains { goal in
            goal.isStarted
                && !goal.isCompleted
                && goal.timeUntilNextUnit(now: date) == "Listo"
                && goal.nextPendingUnit != nil
        }

        if goalsBadgeVisible != hasAvailableUnit {
            goalsBadgeVisible = hasAvailableUnit
        }

        let nextDate = nextGoalsBadgeTransitionDate(after: date)
        if nextGoalsBadgeRefreshDate != nextDate {
            nextGoalsBadgeRefreshDate = nextDate
        }
    }

    private func nextGoalsBadgeTransitionDate(after date: Date) -> Date? {
        goals
            .filter { $0.isStarted && !$0.isCompleted }
            .flatMap { goal in
                goal.unitsSet.compactMap { unit -> Date? in
                    guard unit.unitStatus == .pending else { return nil }

                    let startDate = unit.startDate
                    let endDate = unit.endDate

                    if let startDate, startDate > date {
                        return startDate
                    }

                    if let endDate, endDate > date {
                        return endDate
                    }

                    return nil
                }
            }
            .min()
    }

    @ViewBuilder
    private func destination(for access: HomeAlternativoAccess) -> some View {
        switch access {
        case .calma:
            EspacioCalmaView()
        case .agenda:
            AgendaMainView()
        case .presencia:
            PresenciaView()
        case .metas:
            GoalsListView(embeddedInNavigationStack: false)
                .environment(\.managedObjectContext, context)
        case .diario:
            DiarioListView()
                .environmentObject(securityModel)
        case .alimentos:
            LectorEtiquetasView()
        case .notas:
            ListNotasViews()
                .environmentObject(settingModel)
        case .ritual:
            MorningRitualMainView()
        case .coherencia:
            CardioCoherenceWelcomeFlowView()
        case .revisionSemanal:
            WeeklyReviewView()
        case .lienzo:
            LienzoMain(texto: "", imagenPrimariaACargar: nil)
        case .recordatorios:
            ReminderListView()
        case .lectorQR:
            CodeScannerView(codeTypes: [.qr]) { _ in }
        case .autorNeville:
            NevilleAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
                .environmentObject(modelTxt)
                .environmentObject(clipBoardModel)
        case .autorJoeDispenza:
            JoeDispenzaAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
                .environmentObject(modelTxt)
                .environmentObject(clipBoardModel)
        case .autorBruceLipton:
            BruceLiptonAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
                .environmentObject(modelTxt)
                .environmentObject(clipBoardModel)
        case .autorGreggBraden:
            GreggBradenAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
                .environmentObject(modelTxt)
                .environmentObject(clipBoardModel)
        case .frases:
            FrasesListView()
                .environmentObject(settingModel)
                .environmentObject(frasesModel)
        case .enciclopedia:
            EnciclopediaListView()
        case .reflexiones:
            ReflexListView()
                .environmentObject(reflexModel)
        case .ayudas:
            TxtListView(typeOfContent: .ayud, title: L10n.exact("Ayudas"))
                .environmentObject(clipBoardModel)
                .environmentObject(modelTxt)
                .environmentObject(settingModel)
        case .centroSanador:
            CentroSanadorView()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .overlay(theme.divider)

            HStack {
                Text("Mi progreso")
                    .font(.system(size: 24, weight: .regular, design: .rounded))
                    .foregroundStyle(.clear)
                    .accessibilityHidden(true)
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(progressItems) { item in
                    HomeAlternativoProgressCard(item: item, theme: theme)
                }

                NavigationLink {
                    StressHistoryView(monitor: stressMonitor)
                } label: {
                    StressHomeIndicator(
                        monitor: stressMonitor,
                        primaryText: theme.primaryText,
                        secondaryText: theme.secondaryText,
                        trackColor: theme.progressTrack
                    )
                }
                .buttonStyle(HomeAlternativoPressedButtonStyle())
            }
        }
    }

    private func reloadPresenceProgress() {
        todayPresentCount = presenceRepository.todayPresentCount()
    }
}

enum HomeAlternativoVariant: String, CaseIterable, Identifiable {
    case clara
    case oscura

    var id: String { rawValue }
}

private enum HomeAlternativoScrollTarget {
    static let top = "homeAlternativoScrollTop"
}

private struct HomeAlternativoTool: Identifiable {
    let access: HomeAlternativoAccess
    let palette: HomeAlternativoCardPalette

    var id: String { access.id }
    var title: String { access.title }
    var symbol: String { access.symbol }
    var secondarySymbol: String? { access.secondarySymbol }
    var colors: [Color] { palette.colors }
    var requiresPremium: Bool { access.requiresPremium }
    @MainActor var destination: AnyView { access.destination }
}

private enum HomeAlternativoCardPalette: String, CaseIterable, Identifiable, Codable {
    case calmaAzul
    case solDorado
    case presenciaTurquesa
    case bosqueVivo
    case violetaMagenta
    case coralNaranja
    case indigoMenta
    case cieloCian
    case rosaAurora
    case verdeLima
    case nocheElectrica
    case bronceCalido

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calmaAzul: return L10n.exact("Calma azul")
        case .solDorado: return L10n.exact("Sol dorado")
        case .presenciaTurquesa: return L10n.exact("Turquesa")
        case .bosqueVivo: return L10n.exact("Bosque")
        case .violetaMagenta: return L10n.exact("Violeta")
        case .coralNaranja: return L10n.exact("Coral")
        case .indigoMenta: return L10n.exact("Índigo")
        case .cieloCian: return L10n.exact("Cielo")
        case .rosaAurora: return L10n.exact("Aurora")
        case .verdeLima: return L10n.exact("Lima")
        case .nocheElectrica: return L10n.exact("Noche")
        case .bronceCalido: return L10n.exact("Bronce")
        }
    }

    var colors: [Color] {
        switch self {
        case .calmaAzul:
            return [Color(red: 0.34, green: 0.70, blue: 1.00), Color(red: 0.13, green: 0.42, blue: 0.92)]
        case .solDorado:
            return [Color(red: 1.00, green: 0.85, blue: 0.23), Color(red: 1.00, green: 0.52, blue: 0.07)]
        case .presenciaTurquesa:
            return [Color(red: 0.34, green: 0.93, blue: 0.88), Color(red: 0.04, green: 0.62, blue: 0.69)]
        case .bosqueVivo:
            return [Color(red: 0.46, green: 0.91, blue: 0.43), Color(red: 0.12, green: 0.58, blue: 0.30)]
        case .violetaMagenta:
            return [Color(red: 0.74, green: 0.45, blue: 0.96), Color(red: 0.79, green: 0.23, blue: 0.70)]
        case .coralNaranja:
            return [Color(red: 1.00, green: 0.54, blue: 0.38), Color(red: 0.98, green: 0.34, blue: 0.12)]
        case .indigoMenta:
            return [Color(red: 0.46, green: 0.55, blue: 1.00), Color(red: 0.15, green: 0.78, blue: 0.70)]
        case .cieloCian:
            return [Color(red: 0.39, green: 0.86, blue: 1.00), Color(red: 0.12, green: 0.54, blue: 0.92)]
        case .rosaAurora:
            return [Color(red: 1.00, green: 0.49, blue: 0.76), Color(red: 0.69, green: 0.31, blue: 0.95)]
        case .verdeLima:
            return [Color(red: 0.77, green: 0.96, blue: 0.32), Color(red: 0.42, green: 0.75, blue: 0.18)]
        case .nocheElectrica:
            return [Color(red: 0.34, green: 0.42, blue: 1.00), Color(red: 0.05, green: 0.83, blue: 0.95)]
        case .bronceCalido:
            return [Color(red: 0.89, green: 0.62, blue: 0.32), Color(red: 0.55, green: 0.31, blue: 0.16)]
        }
    }

    static func defaultIDs(for accessIDs: [String]) -> [String] {
        accessIDs.map { accessID in
            HomeAlternativoAccess(rawValue: accessID)?.defaultPalette.rawValue ?? calmaAzul.rawValue
        }
    }

    static func normalizedIDs(from storedValue: String, accessIDs: [String]) -> [String] {
        let decodedIDs: [String]
        if let data = storedValue.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            decodedIDs = decoded
        } else {
            decodedIDs = []
        }

        return normalizedIDs(from: decodedIDs, accessIDs: accessIDs)
    }

    static func normalizedIDs(from ids: [String], accessIDs: [String]) -> [String] {
        let normalizedAccessIDs = HomeAlternativoAccess.normalizedIDs(
            from: HomeAlternativoAccess.encode(accessIDs)
        )

        return normalizedAccessIDs.enumerated().map { index, accessID in
            if index < ids.count, Self(rawValue: ids[index]) != nil {
                return ids[index]
            }

            return HomeAlternativoAccess(rawValue: accessID)?.defaultPalette.rawValue ?? calmaAzul.rawValue
        }
    }

    static func encode(_ ids: [String], accessIDs: [String]) -> String {
        let normalized = normalizedIDs(from: ids, accessIDs: accessIDs)
        guard let data = try? JSONEncoder().encode(normalized) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

private enum HomeAlternativoAccess: String, CaseIterable, Identifiable, Codable, Hashable {
    case calma
    case agenda
    case presencia
    case metas
    case diario
    case alimentos
    case notas
    case ritual
    case coherencia
    case revisionSemanal
    case lienzo
    case recordatorios
    case lectorQR
    case autorNeville
    case autorJoeDispenza
    case autorBruceLipton
    case autorGreggBraden
    case frases
    case enciclopedia
    case reflexiones
    case ayudas
    case centroSanador

    var id: String { rawValue }

    static let maximumAccessCount = 9

    static let defaultIDs = [
        calma.rawValue,
        agenda.rawValue,
        presencia.rawValue,
        metas.rawValue,
        diario.rawValue,
        alimentos.rawValue,
        notas.rawValue,
        ritual.rawValue,
        coherencia.rawValue
    ]

    var title: String {
        switch self {
        case .calma: return L10n.exact("Calma")
        case .agenda: return L10n.exact("Agenda")
        case .presencia: return L10n.exact("Presencia")
        case .metas: return L10n.exact("Metas")
        case .diario: return L10n.exact("Diario")
        case .alimentos:
            return L10n.string("label_reader.home.title", fallback: "Alimentos")
        case .notas: return L10n.exact("Notas")
        case .ritual: return L10n.exact("Ritual")
        case .coherencia:
            return L10n.string("coherence.home.title", fallback: "Coherencia")
        case .revisionSemanal: return L10n.exact("Revisión")
        case .lienzo: return L10n.exact("Lienzo")
        case .recordatorios: return L10n.exact("Recordatorios")
        case .lectorQR: return L10n.exact("Lector QR")
        case .autorNeville: return "Neville"
        case .autorJoeDispenza: return "JD"
        case .autorBruceLipton: return "Bruce"
        case .autorGreggBraden: return "Gregg"
        case .frases: return L10n.exact("Frases")
        case .enciclopedia: return L10n.exact("Enciclopedia")
        case .reflexiones: return L10n.exact("Reflexiones")
        case .ayudas: return L10n.exact("Ayudas")
        case .centroSanador: return L10n.exact("Sanador")
        }
    }

    var symbol: String {
        switch self {
        case .calma: return "sparkles"
        case .agenda: return "calendar"
        case .presencia: return "camera.macro"
        case .metas: return "checklist"
        case .diario: return "book.closed"
        case .alimentos: return "qrcode.viewfinder"
        case .notas: return "note.text"
        case .ritual: return "sunrise"
        case .coherencia: return "waveform.path.ecg"
        case .revisionSemanal: return "sparkles.rectangle.stack"
        case .lienzo: return "paintbrush.pointed"
        case .recordatorios: return "bell.badge"
        case .lectorQR: return "qrcode"
        case .autorNeville: return "person.text.rectangle"
        case .autorJoeDispenza: return "brain.head.profile"
        case .autorBruceLipton: return "leaf"
        case .autorGreggBraden: return "globe.americas"
        case .frases: return "quote.bubble"
        case .enciclopedia: return "books.vertical"
        case .reflexiones: return "lightbulb"
        case .ayudas: return "questionmark.circle"
        case .centroSanador: return "cross.case.fill"
        }
    }

    var secondarySymbol: String? {
        switch self {
        case .alimentos:
            return "fork.knife"
        default:
            return nil
        }
    }

    var colors: [Color] {
        switch self {
        case .calma: return [.blue, .cyan]
        case .agenda: return [.yellow, .orange]
        case .presencia: return [.teal, .mint]
        case .metas: return [.green, .mint]
        case .diario: return [.purple, .pink]
        case .alimentos: return [.orange, .yellow]
        case .notas: return [.cyan, .blue]
        case .ritual: return [.pink, .orange]
        case .coherencia: return [.indigo, .teal]
        case .revisionSemanal: return [.indigo, .purple]
        case .lienzo: return [.indigo, .purple]
        case .recordatorios: return [.red, .orange]
        case .lectorQR: return [.gray, .cyan]
        case .autorNeville: return [.brown, .orange]
        case .autorJoeDispenza: return [.mint, .blue]
        case .autorBruceLipton: return [.green, .yellow]
        case .autorGreggBraden: return [.blue, .purple]
        case .frases: return [.pink, .purple]
        case .enciclopedia: return [.cyan, .mint]
        case .reflexiones: return [.yellow, .pink]
        case .ayudas: return [.teal, .blue]
        case .centroSanador: return [.mint, .cyan]
        }
    }

    var defaultPalette: HomeAlternativoCardPalette {
        switch self {
        case .calma: return .calmaAzul
        case .agenda: return .solDorado
        case .presencia: return .presenciaTurquesa
        case .metas: return .bosqueVivo
        case .diario: return .violetaMagenta
        case .alimentos: return .coralNaranja
        case .notas: return .cieloCian
        case .ritual: return .rosaAurora
        case .coherencia: return .indigoMenta
        case .revisionSemanal: return .violetaMagenta
        case .lienzo: return .violetaMagenta
        case .recordatorios: return .coralNaranja
        case .lectorQR: return .nocheElectrica
        case .autorNeville: return .bronceCalido
        case .autorJoeDispenza: return .indigoMenta
        case .autorBruceLipton: return .verdeLima
        case .autorGreggBraden: return .nocheElectrica
        case .frases: return .rosaAurora
        case .enciclopedia: return .presenciaTurquesa
        case .reflexiones: return .solDorado
        case .ayudas: return .calmaAzul
        case .centroSanador: return .presenciaTurquesa
        }
    }

    var requiresPremium: Bool {
        switch self {
        case .calma, .agenda, .presencia, .alimentos, .ritual, .coherencia, .revisionSemanal:
            return true
        default:
            return false
        }
    }

    @MainActor
    var destination: AnyView {
        switch self {
        case .calma:
            return AnyView(EspacioCalmaView())
        case .agenda:
            return AnyView(AgendaMainView())
        case .presencia:
            return AnyView(PresenciaView())
        case .metas:
            return AnyView(GoalsListView())
        case .diario:
            return AnyView(DiarioListView())
        case .alimentos:
            return AnyView(LectorEtiquetasView())
        case .notas:
            return AnyView(ListNotasViews())
        case .ritual:
            return AnyView(MorningRitualMainView())
        case .coherencia:
            return AnyView(CardioCoherenceWelcomeFlowView())
        case .revisionSemanal:
            return AnyView(WeeklyReviewView())
        case .lienzo:
            return AnyView(LienzoMain(texto: "", imagenPrimariaACargar: nil))
        case .recordatorios:
            return AnyView(ReminderListView())
        case .lectorQR:
            return AnyView(CodeScannerView(codeTypes: [.qr]) { _ in })
        case .autorNeville:
            return AnyView(NevilleAuthorView())
        case .autorJoeDispenza:
            return AnyView(JoeDispenzaAuthorView())
        case .autorBruceLipton:
            return AnyView(BruceLiptonAuthorView())
        case .autorGreggBraden:
            return AnyView(GreggBradenAuthorView())
        case .frases:
            return AnyView(FrasesListView())
        case .enciclopedia:
            return AnyView(EnciclopediaListView())
        case .reflexiones:
            return AnyView(ReflexListView())
        case .ayudas:
            return AnyView(TxtListView(typeOfContent: .ayud, title: L10n.exact("Ayudas")))
        case .centroSanador:
            return AnyView(CentroSanadorView())
        }
    }

    static func normalizedIDs(from storedValue: String) -> [String] {
        let decodedIDs: [String]
        if let data = storedValue.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            decodedIDs = decoded
        } else {
            decodedIDs = defaultIDs
        }

        var result: [String] = []
        for id in decodedIDs where Self(rawValue: id) != nil && !result.contains(id) {
            result.append(id)
        }

        let fallbackIDs = defaultIDs + Self.allCases.map(\.rawValue)
        for id in fallbackIDs where result.count < maximumAccessCount && !result.contains(id) {
            result.append(id)
        }

        return Array(result.prefix(maximumAccessCount))
    }

    static func encode(_ ids: [String]) -> String {
        let normalized = normalizedIDs(from: String(data: (try? JSONEncoder().encode(ids)) ?? Data(), encoding: .utf8) ?? "")
        guard let data = try? JSONEncoder().encode(normalized) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

private struct HomeAlternativoAccessEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var accessIDs: [String]
    @Binding var paletteIDs: [String]
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(accessIDs.enumerated()), id: \.offset) { index, accessID in
                    VStack(alignment: .leading, spacing: 10) {
                        NavigationLink {
                            HomeAlternativoAccessSelectionView(selectedID: accessID) { selectedAccess in
                                setAccess(selectedAccess.rawValue, at: index)
                            }
                        } label: {
                            Label(
                                HomeAlternativoAccess(rawValue: accessID)?.title ?? L10n.exact("Acceso"),
                                systemImage: HomeAlternativoAccess(rawValue: accessID)?.symbol ?? "square.grid.3x3"
                            )
                        }

                        NavigationLink {
                            HomeAlternativoPaletteSelectionView(selectedID: paletteID(at: index)) { selectedPalette in
                                setPalette(selectedPalette.rawValue, at: index)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                HomeAlternativoPaletteSwatch(colors: palette(at: index).colors)

                                Text(palette(at: index).title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: moveAccess)
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Accesos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Restablecer") {
                        accessIDs = HomeAlternativoAccess.defaultIDs
                        paletteIDs = HomeAlternativoCardPalette.defaultIDs(for: accessIDs)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    HStack {
                        EditButton()

                        Button("OK") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func setAccess(_ newValue: String, at index: Int) {
        guard index < accessIDs.count else { return }
        guard HomeAlternativoAccess(rawValue: newValue) != nil else { return }
        let oldValue = accessIDs[index]

        if let existingIndex = accessIDs.firstIndex(of: newValue), existingIndex != index {
            accessIDs[existingIndex] = oldValue
        }

        accessIDs[index] = newValue
        accessIDs = HomeAlternativoAccess.normalizedIDs(from: HomeAlternativoAccess.encode(accessIDs))
        paletteIDs = HomeAlternativoCardPalette.normalizedIDs(from: paletteIDs, accessIDs: accessIDs)
    }

    private func paletteID(at index: Int) -> String {
        let normalizedPaletteIDs = HomeAlternativoCardPalette.normalizedIDs(from: paletteIDs, accessIDs: accessIDs)
        guard index < normalizedPaletteIDs.count else { return HomeAlternativoCardPalette.calmaAzul.rawValue }
        return normalizedPaletteIDs[index]
    }

    private func palette(at index: Int) -> HomeAlternativoCardPalette {
        HomeAlternativoCardPalette(rawValue: paletteID(at: index)) ?? .calmaAzul
    }

    private func setPalette(_ newValue: String, at index: Int) {
        guard index < accessIDs.count else { return }
        guard HomeAlternativoCardPalette(rawValue: newValue) != nil else { return }

        var normalizedPaletteIDs = HomeAlternativoCardPalette.normalizedIDs(from: paletteIDs, accessIDs: accessIDs)
        normalizedPaletteIDs[index] = newValue
        paletteIDs = normalizedPaletteIDs
    }

    private func moveAccess(from source: IndexSet, to destination: Int) {
        var normalizedPaletteIDs = HomeAlternativoCardPalette.normalizedIDs(from: paletteIDs, accessIDs: accessIDs)
        accessIDs.move(fromOffsets: source, toOffset: destination)
        normalizedPaletteIDs.move(fromOffsets: source, toOffset: destination)
        accessIDs = HomeAlternativoAccess.normalizedIDs(from: HomeAlternativoAccess.encode(accessIDs))
        paletteIDs = HomeAlternativoCardPalette.normalizedIDs(from: normalizedPaletteIDs, accessIDs: accessIDs)
    }
}

private struct HomeAlternativoAccessSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedID: String
    let onSelect: (HomeAlternativoAccess) -> Void

    var body: some View {
        List(HomeAlternativoAccess.allCases) { access in
            Button {
                onSelect(access)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Label(access.title, systemImage: access.symbol)
                        .foregroundStyle(.primary)

                    Spacer()

                    if access.rawValue == selectedID {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.accent)
                    }
                }
            }
        }
        .navigationTitle("Seleccionar acceso")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HomeAlternativoPaletteSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedID: String
    let onSelect: (HomeAlternativoCardPalette) -> Void

    var body: some View {
        List(HomeAlternativoCardPalette.allCases) { palette in
            Button {
                onSelect(palette)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    HomeAlternativoPaletteSwatch(colors: palette.colors)

                    Text(palette.title)
                        .foregroundStyle(.primary)

                    Spacer()

                    if palette.rawValue == selectedID {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.accent)
                    }
                }
            }
        }
        .navigationTitle("Paleta")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HomeAlternativoPaletteSwatch: View {
    let colors: [Color]

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 42, height: 26)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.75), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }
}

private struct HomeAlternativoProgressItem: Identifiable {
    let id = UUID()
    let title: String
    let valueText: String
    let symbol: String
    let progress: Double
    let colors: [Color]
}

private enum HomeAlternativoProgressPalette {
    static let presence = [
        Color(red: 1.00, green: 0.93, blue: 0.66),
        Color(red: 1.00, green: 0.72, blue: 0.22),
        Color(red: 0.96, green: 0.45, blue: 0.06)
    ]
    static let goals = [
        Color(red: 0.76, green: 1.00, blue: 0.78),
        Color(red: 0.38, green: 0.84, blue: 0.48),
        Color(red: 0.10, green: 0.58, blue: 0.26)
    ]
}

private struct HomeAlternativoTheme {
    let variant: HomeAlternativoVariant

    var background: LinearGradient {
        switch variant {
        case .clara:
            return LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.99, blue: 0.97),
                    Color(red: 0.93, green: 0.98, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .oscura:
            return LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.06, blue: 0.18),
                    Color(red: 0.03, green: 0.12, blue: 0.29),
                    Color(red: 0.01, green: 0.04, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var primaryText: Color {
        switch variant {
        case .clara: return Color(red: 0.05, green: 0.06, blue: 0.09)
        case .oscura: return .white
        }
    }

    var secondaryText: Color {
        switch variant {
        case .clara: return Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.72)
        case .oscura: return .white.opacity(0.72)
        }
    }

    var divider: Color {
        switch variant {
        case .clara: return Color.black.opacity(0.10)
        case .oscura: return Color.white.opacity(0.15)
        }
    }

    var cardStroke: Color {
        switch variant {
        case .clara: return Color.white.opacity(0.50)
        case .oscura: return Color.white.opacity(0.36)
        }
    }

    var cardShadow: Color {
        switch variant {
        case .clara: return Color.black.opacity(0.14)
        case .oscura: return Color.black.opacity(0.58)
        }
    }

    var progressTrack: Color {
        switch variant {
        case .clara: return Color.black.opacity(0.14)
        case .oscura: return Color.white.opacity(0.22)
        }
    }

    var cardForeground: Color {
        switch variant {
        case .clara: return .white
        case .oscura: return Color(red: 0.02, green: 0.04, blue: 0.10)
        }
    }

    func cardColors(for colors: [Color]) -> [Color] {
        switch variant {
        case .clara:
            return colors
        case .oscura:
            return colors.map { $0.opacity(0.98) }
        }
    }
}

private struct HomeAlternativoToolCard: View {
    let tool: HomeAlternativoTool
    let theme: HomeAlternativoTheme

    var body: some View {
        VStack(spacing: 9) {
            toolIcon
                .frame(height: 34)

            Text(tool.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.cardForeground)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: theme.cardColors(for: tool.colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(theme.variant == .oscura ? 0.08 : 0.10))
                .frame(height: 30)
                .blur(radius: 8)
                .padding(.horizontal, 7)
                .padding(.top, 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.cardStroke, lineWidth: 1.2)
        }
        .shadow(color: tool.colors.first?.opacity(theme.variant == .oscura ? 0.26 : 0.14) ?? theme.cardShadow, radius: 8, y: 5)
        .shadow(color: theme.cardShadow, radius: 5, y: 3)
    }

    @ViewBuilder
    private var toolIcon: some View {
        if let secondarySymbol = tool.secondarySymbol {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 31, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(theme.cardForeground)

                Image(systemName: secondarySymbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.cardForeground)
                    .padding(5)
                    .background(Circle().fill(Color.white.opacity(theme.variant == .oscura ? 0.30 : 0.22)))
                    .offset(x: 8, y: 5)
            }
        } else {
            Image(systemName: tool.symbol)
                .font(.system(size: 31, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(theme.cardForeground)
        }
    }
}

private struct HomeAlternativoPressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.10 : 0), radius: 2, y: 1)
            .animation(.spring(response: 0.20, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct HomeAlternativoProgressCard: View {
    let item: HomeAlternativoProgressItem
    let theme: HomeAlternativoTheme

    @State private var completionGlow = false

    private var isCompleted: Bool {
        item.progress >= 1.0
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                HomeAlternativoProgressArc(
                    progress: item.progress,
                    colors: progressGradientColors,
                    trackColor: theme.progressTrack
                )

                Circle()
                    .fill(item.colors.last?.opacity(theme.variant == .clara ? 0.15 : 0.28) ?? .clear)
                    .frame(width: 38, height: 38)

                Image(systemName: item.symbol)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: item.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 68, height: 68)
            .overlay {
                if isCompleted {
                    ZStack {
                        Circle()
                            .stroke(completionGlowColor.opacity(completionGlow ? 0.52 : 0.22), lineWidth: 3.2)
                            .blur(radius: completionGlow ? 3.8 : 1.8)
                            .scaleEffect(completionGlow ? 1.075 : 1.02)

                        Circle()
                            .strokeBorder(completionRingColor.opacity(completionGlow ? 0.84 : 0.42), lineWidth: 2.0)
                            .scaleEffect(completionGlow ? 1.035 : 1.0)
                    }
                    .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true), value: completionGlow)
                }
            }
            .onAppear {
                completionGlow = isCompleted
            }
            .onChange(of: item.progress) { _, _ in
                completionGlow = false
                if isCompleted {
                    completionGlow = true
                }
            }

            Text(item.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .minimumScaleFactor(0.82)
                .lineLimit(1)

            Text(item.valueText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .minimumScaleFactor(0.82)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressGradientColors: [Color] {
        guard let firstColor = item.colors.first else { return [] }
        let firstOpacity = theme.variant == .clara ? 0.54 : 0.68
        return [firstColor.opacity(firstOpacity)] + item.colors.dropFirst()
    }

    private var completionGlowColor: Color {
        item.colors.last ?? .orange
    }

    private var completionRingColor: Color {
        item.colors.dropFirst().first ?? completionGlowColor
    }
}

private struct HomeAlternativoProgressArc: View {
    let progress: Double
    let colors: [Color]
    let trackColor: Color

    private let lineWidth: CGFloat = 6
    private let startDegrees: Double = 140.8
    private let totalDegrees: Double = 302.4

    var body: some View {
        Canvas { context, size in
            let clampedProgress = min(max(progress, 0), 1)
            let radius = min(size.width, size.height) / 2 - lineWidth / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let startAngle = Angle.degrees(startDegrees)
            let endAngle = Angle.degrees(startDegrees + totalDegrees)
            let progressEndAngle = Angle.degrees(startDegrees + (totalDegrees * clampedProgress))

            var trackPath = Path()
            trackPath.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            context.stroke(
                trackPath,
                with: .color(trackColor),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

            guard clampedProgress > 0 else { return }

            var progressPath = Path()
            progressPath.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: progressEndAngle,
                clockwise: false
            )
            context.stroke(
                progressPath,
                with: .linearGradient(
                    Gradient(colors: colors.isEmpty ? [.clear] : colors),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
    }
}

#Preview("Home Alternativo - Claro y Oscuro") {
    ScrollView(.horizontal, showsIndicators: true) {
        HStack(spacing: 0) {
            HomeAlternativoView(variant: .clara)
                .frame(width: 390, height: 844)
                .preferredColorScheme(.light)

            HomeAlternativoView(variant: .oscura)
                .frame(width: 390, height: 844)
                .preferredColorScheme(.dark)
        }
    }
    .environment(\.managedObjectContext, CoreDataController.shared.context)
    .environmentObject(SettingModel())
    .environmentObject(FrasesModel.shared)
    .environmentObject(SecurityModel.shared)
    .environmentObject(ClipboardObserver())
    .environmentObject(TxtContentModel.shared)
    .environmentObject(ReflexModel.shared)
}
