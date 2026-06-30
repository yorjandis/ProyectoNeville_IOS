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

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage("HomeAlternativo_AccessIDs") private var storedAccessIDs: String = ""
    @AppStorage("Home_AgendaBadge_HiddenDayKey") private var agendaBadgeHiddenDayKey: String = ""
    @StateObject private var agendaViewModel = AgendaViewModel()
    @State private var phrase = HomeAlternativoPhrases.random(for: .morning)
    @State private var showPremium = false
    @State private var showAccessEditor = false
    @State private var selectedAccessIDs = HomeAlternativoAccess.defaultIDs
    @State private var now = Date()
    @State private var todayPresentCount = 0
    private let presenceRepository = PresenciaRepository()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Diario.fecha, ascending: false)]
    ) private var diaryEntries: FetchedResults<Diario>

    private var theme: HomeAlternativoTheme {
        HomeAlternativoTheme(variant: variant)
    }

    private var tools: [HomeAlternativoTool] {
        selectedAccessIDs.compactMap { id in
            HomeAlternativoAccess(rawValue: id).map(HomeAlternativoTool.init(access:))
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
        goals.contains { goal in
            goal.isStarted
                && !goal.isCompleted
                && goal.timeUntilNextUnit(now: now) == "Listo"
                && goal.nextPendingUnit != nil
        }
    }

    private var greeting: String {
        switch dayMoment {
        case .morning:
            return "Buenos días"
        case .afternoon:
            return "Buenas tardes"
        case .night:
            return "Buenas noches"
        }
    }

    private var dayMoment: HomeAlternativoDayMoment {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return .morning
        case 12..<20:
            return .afternoon
        default:
            return .night
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var progressItems: [HomeAlternativoProgressItem] {
        let calendar = Calendar.current
        let activeGoals = goals.filter { $0.isStarted && !$0.isCompleted }
        let todayDiaryEntries = diaryEntries.filter { entry in
            guard let date = entry.fecha else { return false }
            return calendar.isDateInToday(date)
        }

        return [
            .init(
                title: "Presencia",
                valueText: "\(todayPresentCount) eventos",
                symbol: "heart.text.square",
                progress: min(Double(todayPresentCount) / 12.0, 1.0),
                colors: HomeAlternativoProgressPalette.presence
            ),
            .init(
                title: "Metas",
                valueText: "\(activeGoals.count) activas",
                symbol: "checklist",
                progress: min(Double(activeGoals.count) / 5.0, 1.0),
                colors: HomeAlternativoProgressPalette.goals
            ),
            .init(
                title: "Diario",
                valueText: "\(todayDiaryEntries.count) hoy",
                symbol: "book.closed",
                progress: min(Double(todayDiaryEntries.count) / 3.0, 1.0),
                colors: HomeAlternativoProgressPalette.diary
            )
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 18)

                    mainContent

                    Spacer(minLength: 18)
                }
                .frame(minHeight: max(proxy.size.height - 112, 0))
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 112)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .foregroundStyle(theme.primaryText)
        .onAppear {
            now = Date()
            agendaViewModel.load()
            reloadPresenceProgress()
            phrase = HomeAlternativoPhrases.random(for: dayMoment)
            selectedAccessIDs = HomeAlternativoAccess.normalizedIDs(from: storedAccessIDs)
        }
        .onChange(of: selectedAccessIDs) { _, newValue in
            storedAccessIDs = HomeAlternativoAccess.encode(newValue)
        }
        .sheet(isPresented: $showPremium) {
            PurchaseView()
        }
        .sheet(isPresented: $showAccessEditor) {
            HomeAlternativoAccessEditorView(accessIDs: $selectedAccessIDs)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
            reloadPresenceProgress()
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            toolsGrid
            progressSection
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

            Text("\(greeting), ¿Qué quieres hacer hoy?")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                                shouldShowAgendaBadge ? "Ocultar indicador por hoy" : "Mostrar indicador",
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
            GoalsListView()
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
        case .autorJoeDispenza:
            JoeDispenzaAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
        case .autorBruceLipton:
            BruceLiptonAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
        case .autorGreggBraden:
            GreggBradenAuthorView()
                .environmentObject(frasesModel)
                .environmentObject(settingModel)
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
            TxtListView(typeOfContent: .ayud, title: "Ayudas")
                .environmentObject(clipBoardModel)
                .environmentObject(modelTxt)
                .environmentObject(settingModel)
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

private struct HomeAlternativoTool: Identifiable {
    let access: HomeAlternativoAccess

    var id: String { access.id }
    var title: String { access.title }
    var symbol: String { access.symbol }
    var secondarySymbol: String? { access.secondarySymbol }
    var colors: [Color] { access.colors }
    var requiresPremium: Bool { access.requiresPremium }
    @MainActor var destination: AnyView { access.destination }
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

    var id: String { rawValue }

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
        case .calma: return "Calma"
        case .agenda: return "Agenda"
        case .presencia: return "Presencia"
        case .metas: return "Metas"
        case .diario: return "Diario"
        case .alimentos: return "Alimentos"
        case .notas: return "Notas"
        case .ritual: return "Ritual"
        case .coherencia: return "Coherencia"
        case .lienzo: return "Lienzo"
        case .recordatorios: return "Recordatorios"
        case .lectorQR: return "Lector QR"
        case .autorNeville: return "Autor Neville"
        case .autorJoeDispenza: return "Autor JD"
        case .autorBruceLipton: return "Autor Bruce"
        case .autorGreggBraden: return "Autor Gregg"
        case .frases: return "Frases"
        case .enciclopedia: return "Enciclopedia"
        case .reflexiones: return "Reflexiones"
        case .ayudas: return "Ayudas"
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
        }
    }

    var requiresPremium: Bool {
        switch self {
        case .calma, .agenda, .presencia, .alimentos, .ritual, .coherencia:
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
            return AnyView(TxtListView(typeOfContent: .ayud, title: "Ayudas"))
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
        for id in fallbackIDs where result.count < 9 && !result.contains(id) {
            result.append(id)
        }

        return Array(result.prefix(9))
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
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(accessIDs.enumerated()), id: \.offset) { index, accessID in
                    NavigationLink {
                        HomeAlternativoAccessSelectionView(selectedID: accessID) { selectedAccess in
                            setAccess(selectedAccess.rawValue, at: index)
                        }
                    } label: {
                        Label(
                            HomeAlternativoAccess(rawValue: accessID)?.title ?? "Acceso",
                            systemImage: HomeAlternativoAccess(rawValue: accessID)?.symbol ?? "square.grid.3x3"
                        )
                    }
                }
                .onMove(perform: moveAccess)
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Accesos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Restablecer") {
                        accessIDs = HomeAlternativoAccess.defaultIDs
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
    }

    private func moveAccess(from source: IndexSet, to destination: Int) {
        accessIDs.move(fromOffsets: source, toOffset: destination)
        accessIDs = HomeAlternativoAccess.normalizedIDs(from: HomeAlternativoAccess.encode(accessIDs))
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
    static let diary = [
        Color(red: 0.74, green: 1.00, blue: 0.96),
        Color(red: 0.30, green: 0.82, blue: 0.78),
        Color(red: 0.00, green: 0.50, blue: 0.58)
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
        .shadow(color: tool.colors.first?.opacity(theme.variant == .oscura ? 0.40 : 0.22) ?? theme.cardShadow, radius: 10, y: 6)
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
