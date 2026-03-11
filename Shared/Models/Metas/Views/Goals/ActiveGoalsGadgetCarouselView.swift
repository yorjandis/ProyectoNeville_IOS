//
//  ActiveGoalsGadgetCarouselView.swift
//  Neville_iOS
//
//  Created by Codex on 3/11/26.
//

import SwiftUI
import CoreData

struct GoalsGadgetWidgetListView: View {
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    @Environment(\.managedObjectContext) private var context
    @State private var goals: [GoalEntity] = []

    private var activeGoals: [GoalEntity] {
        goals
            .filter { $0.isStarted }
            .sorted(by: GoalEntity.urgencySort)
    }

    var body: some View {
        if purchaseStatus || yorjPremium {
            Group {
                if activeGoals.isEmpty {
                    NavigationLink("No existen Metas Activas"){
                        GoalsListView()
                            .environment(\.managedObjectContext, context)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                        
                } else {
                    ActiveGoalsGadgetCarouselView(goals: activeGoals)
                }
            }
            .onAppear {
                reloadGoals()
            }
            .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
                reloadGoals()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
                reloadGoals()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                DispatchQueue.main.async {
                    reloadGoals()
                }
            }
        } else {
            EmptyView()
        }
    }

    private func reloadGoals() {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]

        let fetched = (try? context.fetch(request)) ?? []
        goals = fetched
    }
}




struct ActiveGoalsGadgetCarouselView: View {
    let goals: [GoalEntity]

    var body: some View {
        if !goals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { proxy in
                    let cardWidth = max(220, min(320, proxy.size.width * 0.72))
                    let cardHeight: CGFloat = 152

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(goals) { goal in
                                ActiveGoalGadgetCard(goal: goal)
                                    .frame(width: cardWidth, height: cardHeight)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .frame(height: 160)
            }
            .padding(.horizontal, 8)
        }
    }
}




private struct ActiveGoalGadgetCard: View {
    @ObservedObject var goal: GoalEntity

    @Environment(\.managedObjectContext) private var context
    @ObservedObject private var clock = GlobalClock.shared

    @State private var showDetails = false
    @State private var showAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showArchiveConfirmation = false
    @State private var alertMessage = ""

    private var progressPercent: Int {
        Int((goal.progressRatio * 100).rounded())
    }

    private var progressText: String {
        let completed = goal.unitsSet.filter { $0.unitStatus == .completed }.count
        return "\(completed)/\(goal.totalUnits)"
    }

    private var completedUnitsCount: Int {
        goal.unitsSet.filter { $0.unitStatus == .completed }.count
    }

    private var lostUnitsCount: Int {
        goal.unitsSet.filter { $0.unitStatus == .lost }.count
    }

    private var currentTimeRemaining: String? {
        goal.timeUntilNextUnit(now: clock.now)
    }

    private var hasUnitAvailableForFichaje: Bool {
        guard !goal.isCompleted else { return false }
        return goal.timeUntilNextUnit(now: clock.now) == "Listo" && goal.nextPendingUnit != nil
    }

    private var nextPendingFutureUnit: UnitEntity? {
        goal.unitsSet
            .filter { unit in
                guard unit.unitStatus == .pending else { return false }
                return (unit.startDate ?? .distantPast) > clock.now
            }
            .min(by: { $0.index < $1.index })
    }

    private var nextWindowLabelText: String? {
        guard let startDate = nextPendingFutureUnit?.startDate else { return nil }
        return "Próxima unidad en \(timeRemainingUntil(until: startDate))"
    }

    private var statusLabelText: String? {
        if goal.isCompleted {
            return "Fichadas: \(completedUnitsCount) | Perdidas: \(lostUnitsCount)"
        }

        if let nextWindowLabelText {
            return nextWindowLabelText
        }

        return currentTimeRemaining
    }

    private func timeRemainingUntil(until date: Date) -> String {
        let interval = max(0, Int(ceil(date.timeIntervalSince(clock.now))))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        NavigationLink {
                            GoalsListView()
                                .environment(\.managedObjectContext, context)
                        } label: {
                            Text(goal.wrappedTitle)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(goal.isCompleted ? "Completada" : "Progreso: \(progressText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 6)

                Menu{
                    Button("Detalles") {
                        
                        #if os(macOS)
                        showWindow(for: GoalWidgetMetaDetailView(goal: goal),
                                   environmentObjects: [],
                                   title: "Detalles de la meta",
                                   size: WindowSize.percentage(width: 0.6, height: 0.8),
                                   isModal: true
                        )
                        
                        #else
                        showDetails = true
                        #endif
                    }
                    .buttonStyle(.bordered)
  
                    
                }label:{
                    CircularGoalProgressView(
                        progress: goal.progressRatio,
                        percentage: progressPercent,
                        lostUnits: goal.lostUnitIndexes,
                        totalUnits: Int(goal.totalUnits)
                    )
                }
                
                
            }

            
            HStack(spacing: 0){
                if let statusLabelText, hasUnitAvailableForFichaje == false {
                    Label(statusLabelText, systemImage: goal.isCompleted ? "chart.bar.fill" : "clock")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: statusLabelText)
                }else{
                    //Botón para fichar una unidad, si existe una unidad pendiente (hasUnitAvailableForFichaje)
                    Button{
                        goal.nextPendingUnit?.markCompleted(context: self.context)
                    }label:{
                        Label("Fichar!", systemImage: "checkmark.circle")
                        .font(.system(size: 24))
                    }
                    .tint(.green)
                }
                
                Spacer()
                
                //Botón de archivar:
                if goal.isCompleted {
                    Button {
                        showArchiveConfirmation = true
                    } label: {
                        Image(systemName: "tray.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                }
                
                
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        }
        .sheet(isPresented: $showDetails) {
            GoalWidgetMetaDetailView(goal: goal)
        }
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Eliminar Meta", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Archivar Meta",
            isPresented: $showArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archivar", role: .destructive) {
                archiveGoal()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("La meta se moverá al archivo y dejará de mostrarse entre las metas activas.")
        }
        .confirmationDialog(
            "Eliminar Meta",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                deleteGoalFromWidget()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta acción borrará la meta y todas sus unidades.")
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("La Ley"), message: Text(alertMessage))
        }
        .onReceive(clock.$now) { now in
            if goal.refreshLostUnits(now: now), context.hasChanges {
                try? context.save()
            }
        }
    }

    private func archiveGoal() {
        do {
            try goal.archive(context: context)
            goal.deleteGoal(context: context)
            alertMessage = "La Meta ha sido archivada"
            showAlert = true
        } catch {
            alertMessage = "La Meta no ha podido archivarse. Inténtelo más tarde"
            showAlert = true
        }
    }

    private func deleteGoalFromWidget() {
        goal.deleteGoal(context: context)
        alertMessage = "La Meta ha sido eliminada"
        showAlert = true
    }
}

private struct CircularGoalProgressView: View {
    let progress: Double
    let percentage: Int
    let lostUnits: [Int]
    let totalUnits: Int

    private var safeProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: safeProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.fitnessMint, .fitnessAqua, .fitnessBlue]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: safeProgress)

            if totalUnits > 0 {
                ForEach(lostUnits, id: \.self) { index in
                    let normalized = (Double(index) + 0.5) / Double(totalUnits)
                    let angle = (normalized * 360) - 90

                    Circle()
                        .fill(Color.black)
                        .frame(width: 5, height: 5)
                        .offset(y: -26)
                        .rotationEffect(.degrees(angle))
                }
            }

            Text("\(percentage)%")
                .font(.caption.bold())
                .monospacedDigit()
        }
        .frame(width: 52, height: 52)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso")
        .accessibilityValue("\(percentage)%")
    }
}

private struct GoalWidgetMetaDetailView: View {
    @ObservedObject var goal: GoalEntity

    private var completedUnits: Int {
        goal.unitsSet.filter { $0.unitStatus == .completed }.count
    }

    private var pendingUnits: Int {
        goal.unitsSet.filter { $0.unitStatus == .pending }.count
    }

    private var lostUnits: Int {
        goal.unitsSet.filter { $0.unitStatus == .lost }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.55), .orange.opacity(0.45), .mint.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(goal.wrappedTitle)
                            .font(.title3.bold())

                        HStack(spacing: 8) {
                            Text("Total: \(goal.unitsArray.count)")
                            Text("Completadas: \(completedUnits)")
                            Text("Pendientes: \(pendingUnits)")
                            if lostUnits > 0 {
                                Text("Perdidas: \(lostUnits)")
                            }
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())

                        GoalDetailView(goal: goal)
                            .frame(height: 260)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Información")
                                .font(.headline)

                            Text((goal.descriptionText ?? "").isEmpty ? "Sin información disponible" : (goal.descriptionText ?? ""))
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(12)
                }
            }
            .navigationTitle("Detalle de Meta")
            #if os(macOS)
            .toolbar{
                Button("Cerrar"){
                    if let window = NSApp.keyWindow {
                        closeWindow(window)
                        window.sheetParent?.endSheet(window)
                    }
                }
            }
            #endif
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
