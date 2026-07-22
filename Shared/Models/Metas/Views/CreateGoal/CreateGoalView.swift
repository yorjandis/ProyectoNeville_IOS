

import SwiftUI
import CoreData

struct CreateGoalView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm = CreateGoalViewModel()
    @State private var showCreateError = false
    
    @State private var selectedTab : Int = 0
    
    private var metasOrdenadas: [MetasPreestablecidas] {
        MetasPreestablecidas.allCases.sorted {
            $0.getMeta.titulo.localizedCaseInsensitiveCompare($1.getMeta.titulo) == .orderedAscending
        }
    }
    
    var getTitulo : String {
        switch selectedTab{
        case 0: return GoalsL10n.text("goals.ui.custom_goal", fallback: "Meta Personalizada")
        case 1: return GoalsL10n.text("goals.ui.healthy_habits", fallback: "Hábitos Saludables")
        case 2: return GoalsL10n.text("goals.ui.programs", fallback: "Programas")
        default: return GoalsL10n.text("goals.ui.custom_goal", fallback: "Meta Personalizada")
        }
    }
    
    
    //Ocultar el teclado:
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case title
        case description
        case unitLabel
    }

    private var scheduleSummary: String {
        switch vm.scheduleType {
        case .interval:
            return GoalsL10n.addingPeriod(
                GoalsL10n.intervalCadence(frequency: vm.frequency, unit: vm.unit),
                period: vm.dayPeriod
            )
        case .weekly:
            let cadence = "\(GoalsL10n.weeklyCadence(days: vm.weeklyDaysPerWeek)) · \(GoalWeeklySchedule.summary(for: vm.selectedWeeklyDays))"
            if let minutes = vm.effectiveWeeklyTimeMinutes {
                return GoalsL10n.addingWeeklyTime(cadence, minutes: minutes)
            }
            return GoalsL10n.addingPeriod(cadence, period: vm.dayPeriod)
        case .specificDates:
            return GoalsL10n.addingPeriod(
                GoalsL10n.specificDatesCadence(count: vm.amount),
                period: vm.dayPeriod
            )
        }
    }

    private var completionSummary: String {
        switch vm.completionBasis {
        case .executions:
            return GoalsL10n.executionCount(vm.amount)
        case .duration:
            return GoalsL10n.duration(value: vm.durationValue, unit: vm.durationUnit)
        }
    }

    private var validationMessage: String? {
        if vm.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Escribe un título para poder crear la meta."
        }
        if vm.executionTargetValue <= 0 {
            return "El objetivo de cada ejecución debe ser mayor que cero."
        }
        if vm.scheduleType == .weekly,
           vm.selectedWeeklyDays.count != vm.weeklyDaysPerWeek {
            return "Selecciona exactamente \(vm.weeklyDaysPerWeek) días de la semana."
        }
        return nil
    }
    
    var body: some View {

            NavigationStack {

                TabView(selection: self.$selectedTab) {

                    MetasHome()
                    #if os(macOS)
                        .frame(width: 500, height: 600)
                    #endif
                        .tabItem {
                            Label("Personalizado", systemImage: "gear")
                        }
                        .tag(0)
                    
                    MetasPreestablecidasView()
                        #if os(macOS)
                        .frame(width: 500, height: 600)
                        #endif
                        .tabItem {
                            Label("Hábitos Saludables", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    ProgramasPreestablecidos()
                        #if os(macOS)
                        .frame(width: 500, height: 600)
                        #endif
                        .tabItem {
                            Label("Programas", systemImage: "list.bullet")
                        }
                        .tag(2)

                   
                }
                #if os(macOS)
                .tabViewStyle(.automatic)   // o .windowToolbarStyle() en macOS 14+
                #else
                .tabViewStyle(.automatic)
                #endif
                .navigationTitle(self.getTitulo)
                .toolbar {
                    if selectedTab == 0 {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Crear Meta") {
                                if createGoal() {
                                    dismiss()
                                }
                            }
                            .disabled(!vm.isValid)
                        } 
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }

#if os(iOS)
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Listo") {
                            focusedField = nil
                        }
                    }
#endif
                    
                }
            }
    }
    

    @ViewBuilder
    private func MetasHome() -> some View {
        Form {
            Section {
                TextField("Ej. Meditar todos los días", text: $vm.title, axis: .vertical)
                    .font(.title3.weight(.semibold))
                    .focused($focusedField, equals: .title)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                TextField("10", value: $vm.executionTargetValue, format: .number)
                        .frame(width: 72)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                    TextField("minutos, páginas, km, vasos…", text: $vm.customUnitLabel)
                        .focused($focusedField, equals: .unitLabel)
                }
                .accessibilityElement(children: .contain)
            } header: {
                Label("Qué quieres lograr", systemImage: "target")
            } footer: {
                Text("Indica el título y cuánto cuenta como un avance. Por ejemplo: 10 minutos en cada ejecución.")
            }

            Section {
                Picker("La meta termina por", selection: $vm.completionBasis) {
                    ForEach(GoalCompletionBasis.allCases, id: \.self) { basis in
                        Text(basis.label).tag(basis)
                    }
                }

                if vm.completionBasis == .executions {
                    Stepper(value: $vm.amount, in: 1...365) {
                        LabeledContent("Cantidad total", value: GoalsL10n.executionCount(vm.amount))
                    }
                } else {
                    HStack {
                        Stepper(value: $vm.durationValue, in: 1...365) {
                            Text("Duración")
                        }
                        Spacer(minLength: 12)
                        Text("\(vm.durationValue)")
                            .foregroundStyle(.secondary)
                        Picker("Unidad de duración", selection: $vm.durationUnit) {
                            ForEach([TimeUnit.dias, .semanas, .meses, .años], id: \.self) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }
                }
            } header: {
                Label("Finalización", systemImage: "flag.checkered")
            } footer: {
                if vm.completionBasis == .duration {
                    Text("Con este ritmo se crearán aproximadamente \(vm.estimatedUnitCount()) oportunidades de avance.")
                }
            }

            Section {
                Picker("Programación", selection: $vm.scheduleType) {
                    ForEach(GoalScheduleType.allCases.filter {
                        vm.completionBasis == .executions || $0 != .specificDates
                    }, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }

                switch vm.scheduleType {
                case .interval:
                    HStack {
                        Stepper(value: $vm.frequency, in: 1...30) {
                            Text("Repetir cada")
                        }
                        Spacer(minLength: 12)
                        Text("\(vm.frequency)")
                            .foregroundStyle(.secondary)
                        Picker("Intervalo", selection: $vm.unit) {
                            ForEach(TimeUnit.allCases, id: \.self) { unit in
                                Text(unit.description(for: vm.frequency)).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }

                case .weekly:
                    Stepper(value: $vm.weeklyDaysPerWeek, in: 1...7) {
                        LabeledContent(
                            "Frecuencia semanal",
                            value: GoalsL10n.weeklyCadence(days: vm.weeklyDaysPerWeek)
                        )
                    }
                    .onChange(of: vm.weeklyDaysPerWeek) { _, newValue in
                        vm.setWeeklyDayCount(newValue)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Elige los días")
                            .font(.subheadline.weight(.semibold))
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                            spacing: 6
                        ) {
                            ForEach(GoalWeekday.mondayFirst) { weekday in
                                let isSelected = vm.selectedWeeklyDays.contains(weekday)
                                Button {
                                    vm.toggleWeeklyDay(weekday)
                                } label: {
                                    Text(weekday.shortLabel)
                                        .font(.callout.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(isSelected ? Color.blue : Color.primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.22))
                                )
                                .accessibilityLabel(weekday.label)
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                    }

                    Toggle(
                        "Fijar una hora",
                        isOn: Binding(
                            get: { vm.usesWeeklyTime },
                            set: { vm.setWeeklyTimeEnabled($0) }
                        )
                    )

                    if vm.usesWeeklyTime {
                        DatePicker(
                            "Hora de ejecución",
                            selection: $vm.weeklyTime,
                            displayedComponents: .hourAndMinute
                        )
                        Label(
                            "Podrás marcar cada ejecución desde esa hora y durante los 60 minutos siguientes.",
                            systemImage: "clock.badge.checkmark"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                case .specificDates:
                    ForEach(Array(vm.specificDates.indices), id: \.self) { index in
                        DatePicker(
                            GoalsL10n.format(
                                "goals.dynamic.indexed_unit_label",
                                fallback: "{0} {1}",
                                vm.getTextoForUNidades(number: 1).localizedCapitalized,
                                String(index + 1)
                            ),
                            selection: $vm.specificDates[index],
                            displayedComponents: .date
                        )
                    }
                }

                if vm.scheduleType != .weekly || !vm.usesWeeklyTime {
                    Picker("Momento del día", selection: $vm.dayPeriod) {
                        ForEach(GoalDayPeriod.allCases, id: \.self) { period in
                            Text(period.label).tag(period)
                        }
                    }
                }
            } header: {
                Label("Ritmo", systemImage: "calendar.badge.clock")
            } footer: {
                if vm.scheduleType == .weekly, vm.usesWeeklyTime {
                    Text("La hora fija sustituye al Momento del día para evitar franjas contradictorias.")
                }
            }

            Section {
                GoalFormSummaryCard(
                    title: vm.title,
                    target: vm.executionTargetText,
                    schedule: scheduleSummary,
                    completion: completionSummary,
                    estimatedExecutions: vm.completionBasis == .duration ? vm.estimatedUnitCount() : nil
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } header: {
                Label("Así quedará tu meta", systemImage: "checklist")
            } footer: {
                Text("Comprueba que el objetivo, el ritmo y la condición de finalización expresen exactamente tu intención.")
            }

            Section {
                TextField("Añade contexto, motivación o instrucciones…", text: $vm.description, axis: .vertical)
                    .lineLimit(3...7)
                    .focused($focusedField, equals: .description)
            } header: {
                Label("Detalles opcionales", systemImage: "text.alignleft")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            if vm.scheduleType == .specificDates {
                vm.syncSpecificDates()
            }
        }
        .onChange(of: vm.amount) { _, _ in
            if vm.scheduleType == .specificDates {
                vm.syncSpecificDates()
            }
        }
        .onChange(of: vm.scheduleType) { _, newValue in
            if newValue == .specificDates {
                vm.syncSpecificDates()
            }
            if newValue != .weekly {
                vm.setWeeklyTimeEnabled(false)
            }
        }
        .onChange(of: vm.completionBasis) { _, newValue in
            if newValue == .duration, vm.scheduleType == .specificDates {
                vm.scheduleType = .interval
            }
        }
        .alert("No se pudo crear la meta", isPresented: $showCreateError) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("Comprueba los datos e inténtalo de nuevo.")
        }
        
    }
    
    
    @ViewBuilder
    private func MetasPreestablecidasView() -> some View {
        ZStack{
            LinearGradient.FondoOscuro()
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                
              
                
                ScrollView {
                    LazyVStack(spacing: 16) {   // 👈 separación entre tarjetas
                        
                        ForEach(self.metasOrdenadas, id: \.self) { meta in
                            
                            VStack(alignment: .leading, spacing: 10) {
                                
                                Text(meta.getMeta.titulo)
                                    .font(.title2)
                                    .foregroundStyle(.black)
                                    .bold()
                                
                                Text(meta.getMeta.description)
                                    .font(.body)
                                    .bold()
                                    .foregroundStyle(.black)

                                Label(meta.getMeta.scheduleSummary, systemImage: "calendar.badge.clock")
                                    .font(.caption)
                                    .foregroundStyle(.black.opacity(0.75))
                                
                                HStack{
                                    Spacer()
                                    Button("Cargar en Metas") {
                                        self.vm.title = meta.getDescription
                                        self.vm.description = meta.getMeta.description
                                        self.vm.amount = meta.getMeta.noUnidades
                                        self.vm.frequency = meta.getMeta.noFrecuencias
                                        self.vm.unit = meta.getMeta.tipoUnidad
                                        self.vm.scheduleType = meta.getMeta.scheduleType
                                        self.vm.setWeeklyDayCount(meta.getMeta.weeklyDaysPerWeek)
                                        self.vm.dayPeriod = meta.getMeta.dayPeriod
                                        self.vm.setWeeklyTimeEnabled(false)
                                        self.vm.customUnitLabel = meta.getMeta.customUnitLabel
                                        self.vm.executionTargetValue = 1
                                        self.vm.completionBasis = .executions
                                        self.vm.durationValue = 30
                                        self.vm.durationUnit = .dias
                                        self.vm.specificDates = meta.getMeta.specificDates
                                        self.vm.unidadesInfo = meta.getMeta.unidadesInfo
                                        if self.vm.scheduleType == .specificDates {
                                            self.vm.syncSpecificDates()
                                        }
                                        self.selectedTab = 0
                                    }
                                    .tint(.black)
                                    .buttonStyle(.bordered)
                                }
                                
                                
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient.Oceano())
                                    .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }.cornerRadius(20)
        
    }
    
    @ViewBuilder
    private func ProgramasPreestablecidos() -> some View {
        ProgramasListView().cornerRadius(20)
    }
    
    
    //Lógica del botón Crear una Meta
    private func createGoal() -> Bool {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = vm.title.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.descriptionText = vm.description.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.totalUnits = Int32(vm.amount)
        switch vm.scheduleType {
        case .interval:
            goal.unitType = vm.unit.rawValue
        case .weekly:
            goal.unitType = TimeUnit.semanas.rawValue
        case .specificDates:
            goal.unitType = TimeUnit.dias.rawValue
        }
        goal.frequency = Int32(vm.frequency)
        goal.scheduleType = vm.scheduleType.rawValue
        goal.weeklyDaysPerWeek = Int16(vm.weeklyDaysPerWeek)
        goal.weeklyDaysMask = GoalWeeklySchedule.mask(for: vm.selectedWeeklyDays)
        goal.weeklyTimeMinutes = Int32(vm.effectiveWeeklyTimeMinutes ?? GoalWeeklyTime.disabledMinutes)
        goal.dayPeriod = (vm.effectiveWeeklyTimeMinutes == nil ? vm.dayPeriod : GoalDayPeriod.anytime).rawValue
        goal.customUnitLabel = vm.customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.executionTargetValue = vm.executionTargetValue
        goal.completionBasis = vm.completionBasis.rawValue
        goal.durationValue = Int32(vm.durationValue)
        goal.durationUnit = vm.durationUnit.rawValue
        goal.isStarted = false

        if vm.completionBasis == .duration {
            goal.totalUnits = Int32(goal.plannedUnitCount(from: Date()))
        }

        goal.generateUnits(
            DetallesUnidades: vm.unidadesInfo,
            specificDates: vm.scheduleType == .specificDates ? vm.specificDates : []
        )
        
        do{
            try context.save()
            return true
        }catch{
            context.rollback()
            msg("Error al crear una meta nueva")
            showCreateError = true
            return false
        }
    }
    
    
    
}

struct GoalFormSummaryCard: View {
    let title: String
    let target: String
    let schedule: String
    let completion: String
    let estimatedExecutions: Int?

    private var cleanTitle: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Meta sin título" : value
    }

    private var summaryParagraph: String {
        let titleValue = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetValue = target.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let scheduleValue = schedule.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let completionValue = completion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let intention = titleValue.isEmpty
            ? "En esta meta te propones completar \(targetValue)."
            : "Con «\(titleValue)» te propones completar \(targetValue)."
        let cadence = "Lo harás \(scheduleValue)."

        if let estimatedExecutions {
            return "\(intention) \(cadence) Mantendrás este plan \(completionValue), con aproximadamente \(estimatedExecutions) oportunidades de avance."
        }

        return "\(intention) \(cadence) Alcanzarás la meta al completar \(completionValue)."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "target")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Tu plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(cleanTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.orange : Color.primary)
                }
            }

            Text(summaryParagraph)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.16), Color.green.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CreateGoalView()
        .environment(\.managedObjectContext, CoreDataController.shared.context)
}
