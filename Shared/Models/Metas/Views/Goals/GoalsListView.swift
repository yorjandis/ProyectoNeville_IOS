//
//  GoalsListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI
import CoreData

#if os(iOS)
private enum GoalsIPadLayoutMode: String, CaseIterable {
    case grid
    case list
    case workspace

    var title: String {
        switch self {
        case .grid: return "Cuadrícula"
        case .list: return "Lista"
        case .workspace: return "Doble panel"
        }
    }

    var systemImage: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "rectangle.grid.1x2"
        case .workspace: return "rectangle.split.1x2"
        }
    }
}
#endif

enum GoalsSplitAxis {
    case horizontal
    case vertical
}

struct GoalsListView: View {
    let embeddedInNavigationStack: Bool

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage("MostrarMetasEnHome", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var MostrarMetasEnHome: Bool = false

#if os(iOS)
    @AppStorage("goalsIPadLayoutMode") private var iPadLayoutMode: GoalsIPadLayoutMode = .grid
    @AppStorage("goalsIPadTopPanelFraction") private var iPadTopPanelFraction = 0.48
#endif

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    @State private var showCreateGoal = false
    @State private var showHistorial = false
    @State private var showStats = false
    @State private var searchText = ""

    init(embeddedInNavigationStack: Bool = true) {
        self.embeddedInNavigationStack = embeddedInNavigationStack
    }

    var body: some View {
        if embeddedInNavigationStack {
            NavigationStack {
                content
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if purchaseStatus || yorjPremium {
            ZStack {
                LinearGradient(colors: [.orange, .blue], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

#if os(iOS)
                if isIPadInterface {
                    iPadContent
                } else {
                    goalsScrollView(layout: .list)
                }
#else
                goalsScrollView
#endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Metas")
            .searchable(text: $searchText, prompt: "Buscar meta por título")
            .toolbar {
                goalsToolbar
            }
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalView()
                    .environment(\.managedObjectContext, context)
            }
            .sheet(isPresented: $showHistorial) {
#if os(iOS)
                ArchivedGoalsListView()
#endif
            }
            .sheet(isPresented: $showStats) {
                GoalStatsView()
                    .environment(\.managedObjectContext, context)
            }
        } else {
            PremiumFeaturePreviewView(feature: .goals)
        }
    }

    @ToolbarContentBuilder
    private var goalsToolbar: some ToolbarContent {
#if os(iOS)
        if isIPadInterface && embeddedInNavigationStack {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") {
                    dismiss()
                }
            }
        }

        if isIPadInterface {
            ToolbarItem {
                iPadLayoutMenu
            }
        }
#endif

        ToolbarItem {
            Button {
#if os(macOS)
                showWindow(
                    for: GoalStatsView().environment(\.managedObjectContext, context),
                    environmentObjects: [],
                    title: GoalsL10n.text("goals.ui.statistics_title", fallback: "Estadísticas de Metas"),
                    size: AppCons.windows_size_content,
                    isModal: true
                )
#else
                showStats = true
#endif
            } label: {
                Image(systemName: "chart.bar.xaxis")
            }
            .accessibilityLabel("Estadísticas de Metas")
        }

        if #available(iOS 26.0, macOS 26.0, *) {
            ToolbarSpacer(.fixed)
        }

        ToolbarItem {
            Button {
#if os(macOS)
                showWindow(
                    for: ArchivedGoalsListView(context: context),
                    environmentObjects: [],
                    title: GoalsL10n.text("goals.ui.history_title", fallback: "Historial de Metas"),
                    size: AppCons.windows_size_content,
                    isModal: true
                )
#else
                showHistorial = true
#endif
            } label: {
                Image(systemName: "tray.2")
            }
            .accessibilityLabel("Historial de Metas")
        }

        if #available(iOS 26.0, macOS 26.0, *) {
            ToolbarSpacer(.fixed)
        }

        ToolbarItem {
            Button {
                showCreateGoal = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Crear Meta")
        }
    }

#if os(iOS)
    private var isIPadInterface: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    @ViewBuilder
    private var iPadContent: some View {
        switch iPadLayoutMode {
        case .grid:
            goalsScrollView(layout: .grid)
        case .list:
            goalsScrollView(layout: .list)
        case .workspace:
            iPadWorkspace
        }
    }

    private var iPadWorkspace: some View {
        AdjustableGoalsSplitView(
            axis: .vertical,
            primaryFraction: $iPadTopPanelFraction,
            minimumPrimaryLength: 260,
            minimumSecondaryLength: 330
        ) {
            goalsPanel(title: "Metas activas", systemImage: "target") {
                goalsScrollView(layout: .grid, usesOuterPadding: false)
            }
        } secondary: {
            CreateGoalView(presentation: .iPadWorkspace)
                .environment(\.managedObjectContext, context)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }

    private func goalsPanel<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .padding(.horizontal, 16)
                .frame(height: 46)
            Divider()
            content()
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
    }

    private var iPadLayoutMenu: some View {
        Menu {
            ForEach(GoalsIPadLayoutMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        iPadLayoutMode = mode
                    }
                } label: {
                    Label(
                        mode.title,
                        systemImage: iPadLayoutMode == mode ? "checkmark.circle.fill" : mode.systemImage
                    )
                }
            }
        } label: {
            Image(systemName: iPadLayoutMode.systemImage)
        }
        .accessibilityLabel("Modo de visualización de Metas")
    }

    private enum GoalsCollectionLayout {
        case grid
        case list
    }

    private func goalsScrollView(
        layout: GoalsCollectionLayout,
        usesOuterPadding: Bool = true
    ) -> some View {
        ScrollView {
            Group {
                if filteredGoals.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if layout == .grid {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14, alignment: .top),
                            GridItem(.flexible(), spacing: 14, alignment: .top)
                        ],
                        alignment: .leading,
                        spacing: 14
                    ) {
                        ForEach(filteredGoals) { goal in
                            GoalCardView(goal: goal)
                        }
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredGoals) { goal in
                            GoalCardView(goal: goal)
                        }
                    }
                }
            }
            .padding(.horizontal, usesOuterPadding ? 16 : 10)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
#else
    private var goalsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredGoals) { goal in
                    GoalCardView(goal: goal)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.top, 15)
        }
    }
#endif

    private var filteredGoals: [GoalEntity] {
        let sortedGoals = Array(goals).sorted(by: GoalEntity.urgencySort)
        guard !searchText.isEmpty else { return sortedGoals }
        return sortedGoals.filter { $0.wrappedTitle.localizedCaseInsensitiveContains(searchText) }
    }
}

#if os(iOS)
struct AdjustableGoalsSplitView<Primary: View, Secondary: View>: View {
    @Environment(\.locale) private var locale

    let axis: GoalsSplitAxis
    @Binding var primaryFraction: Double
    let minimumPrimaryLength: CGFloat
    let minimumSecondaryLength: CGFloat
    @ViewBuilder let primary: () -> Primary
    @ViewBuilder let secondary: () -> Secondary

    @GestureState private var dragTranslation: CGFloat = 0
    private let dividerLength: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let totalLength = axis == .horizontal ? proxy.size.width : proxy.size.height
            let availableLength = max(0, totalLength - dividerLength)
            let limits = fractionLimits(availableLength: availableLength)
            let dragFraction = availableLength > 0
                ? Double(dragTranslation / availableLength)
                : 0
            let interactiveFraction = primaryFraction + dragFraction
            let resolvedFraction = min(max(interactiveFraction, limits.lower), limits.upper)
            let primaryLength = availableLength * resolvedFraction

            Group {
                if axis == .horizontal {
                    HStack(spacing: 0) {
                        primary().frame(width: primaryLength)
                        divider(availableLength: availableLength, limits: limits)
                        secondary().frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        primary().frame(height: primaryLength)
                        divider(availableLength: availableLength, limits: limits)
                        secondary().frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private func divider(
        availableLength: CGFloat,
        limits: (lower: Double, upper: Double)
    ) -> some View {
        ZStack {
            Color.clear
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(
                    width: axis == .horizontal ? 1 : nil,
                    height: axis == .vertical ? 1 : nil
                )
            Capsule(style: .continuous)
                .fill(.secondary.opacity(0.55))
                .frame(
                    width: axis == .horizontal ? 4 : 42,
                    height: axis == .horizontal ? 42 : 4
                )
        }
        .frame(
            width: axis == .horizontal ? dividerLength : nil,
            height: axis == .vertical ? dividerLength : nil
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .updating($dragTranslation) { value, state, transaction in
                    transaction.disablesAnimations = true
                    state = axis == .horizontal
                        ? value.translation.width
                        : value.translation.height
                }
                .onEnded { value in
                    guard availableLength > 0 else { return }
                    let translation = axis == .horizontal
                        ? value.translation.width
                        : value.translation.height
                    let candidate = primaryFraction
                        + Double(translation / availableLength)
                    let finalFraction = min(max(candidate, limits.lower), limits.upper)

                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        primaryFraction = finalFraction
                    }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Ajustar tamaño de los paneles")
        .accessibilityValue(
            primaryFraction.formatted(
                .percent.precision(.fractionLength(0)).locale(locale)
            )
        )
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 0.05 : -0.05
            primaryFraction = min(max(primaryFraction + step, limits.lower), limits.upper)
        }
    }

    private func fractionLimits(availableLength: CGFloat) -> (lower: Double, upper: Double) {
        guard availableLength > 0 else { return (0, 1) }
        let effectivePrimaryMinimum = min(minimumPrimaryLength, availableLength * 0.48)
        let effectiveSecondaryMinimum = min(minimumSecondaryLength, availableLength * 0.48)
        let lower = Double(effectivePrimaryMinimum / availableLength)
        let upper = Double((availableLength - effectiveSecondaryMinimum) / availableLength)
        return (lower, max(lower, upper))
    }
}
#endif
