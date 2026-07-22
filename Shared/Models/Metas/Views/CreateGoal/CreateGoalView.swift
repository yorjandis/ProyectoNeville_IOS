

import SwiftUI
import CoreData

struct CreateGoalView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm = CreateGoalViewModel.shared
    
    @State private var showMetasEjemplo : Bool = false
    
    
    @State private var selectedTab : Int = 0
    @State private var showDescription: Bool = false
    
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

    private var summaryText: String {
        let schedule: String
        switch vm.scheduleType {
        case .interval:
            schedule = GoalsL10n.intervalCadence(frequency: vm.frequency, unit: vm.unit)
        case .weekly:
            schedule = "\(GoalsL10n.weeklyCadence(days: vm.weeklyDaysPerWeek)) · \(GoalWeeklySchedule.summary(for: vm.selectedWeeklyDays))"
        case .specificDates:
            schedule = GoalsL10n.specificDatesCadence(count: vm.amount)
        }
        let period = vm.dayPeriod == .anytime
            ? ""
            : GoalsL10n.format("goals.dynamic.period_suffix", fallback: ", {0}", vm.dayPeriod.label)
        let ending: String
        switch vm.completionBasis {
        case .executions:
            ending = GoalsL10n.executionCount(vm.amount)
        case .duration:
            let duration = GoalsL10n.duration(value: vm.durationValue, unit: vm.durationUnit)
            let estimate = GoalsL10n.format(
                "goals.dynamic.planned_execution_count",
                fallback: "({0} ejecuciones previstas)",
                String(vm.estimatedUnitCount())
            )
            ending = "\(duration) \(estimate)"
        }
        return GoalsL10n.format(
            "goals.dynamic.creation_summary",
            fallback: "{0}, {1}{2}, {3}.",
            vm.executionTargetText,
            schedule,
            period,
            ending
        )
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
                                createGoal()
                                dismiss()
                            }
                            .disabled(!vm.isValid)
                        } 
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }
                    
                }
            }
    }
    

    @ViewBuilder
    private func MetasHome() -> some View {
        ZStack{
            
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.94, blue: 0.78),
                    Color(red: 0.73, green: 0.90, blue: 0.69),
                    Color(red: 0.88, green: 0.97, blue: 0.84)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack{
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                            Text("Título de la Meta")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                             
                        TextField(
                            "",
                            text: $vm.title,
                            prompt: Text("Eje. Meditar todos los días"),
                            axis: .vertical
                        )
                        .font(.platFormSize(iOS: 22, mac: 24))
                        .foregroundStyle(.white).bold()
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4))
                        )
                        .focused($focusedField, equals: .title)
                            
                        
                        
                        //Configuración de la Meta
                        VStack(alignment: .leading, spacing: 5){
                            /*
                             Text("Configurar:")
                                 .font(.headline)
                                 .foregroundStyle(.black)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                             */
                           
                                
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Objetivo por ejecución:")
                                    .bold()
                                    .foregroundStyle(.black)
                                HStack {
                                    TextField("10", value: $vm.executionTargetValue, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 85)
                                    TextField("minutos, páginas, km, vasos…", text: $vm.customUnitLabel)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .unitLabel)
                                }
                                Text("Ejemplos: 10 minutos, 3 páginas o 5 km cada vez.")
                                    .font(.caption)
                                    .foregroundStyle(.black.opacity(0.7))
                            }

                            HStack {
                                Text("La meta termina por:")
                                    .bold()
                                    .foregroundStyle(.black)
                                Picker("", selection: $vm.completionBasis) {
                                    ForEach(GoalCompletionBasis.allCases, id: \.self) { basis in
                                        Text(basis.label).tag(basis)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.black)
                                .labelsHidden()
                            }

                            if vm.completionBasis == .executions {
                                HStack {
                                    Text("Cantidad total:")
                                        .bold()
                                        .foregroundStyle(.black)
                                    Picker("", selection: $vm.amount) {
                                        ForEach(1...365, id: \.self) { number in
                                            Text("\(number)").tag(number)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.black)
                                    .labelsHidden()
                                    Text(GoalsL10n.executionCount(vm.amount))
                                        .foregroundStyle(.black)
                                }
                                .padding(.top, 5)
                            } else {
                                HStack {
                                    Text("Duración total:")
                                        .bold()
                                        .foregroundStyle(.black)
                                    Picker("", selection: $vm.durationValue) {
                                        ForEach(1...365, id: \.self) { value in
                                            Text("\(value)").tag(value)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.black)
                                    .labelsHidden()

                                    Picker("", selection: $vm.durationUnit) {
                                        ForEach([TimeUnit.dias, .semanas, .meses, .años], id: \.self) { unit in
                                            Text(unit.label).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.black)
                                    .labelsHidden()
                                }
                            }

                            HStack{
                                Text("Programación:")
                                    .bold()
                                    .foregroundStyle(.black)
                                Picker("", selection: $vm.scheduleType) {
                                    ForEach(GoalScheduleType.allCases.filter {
                                        vm.completionBasis == .executions || $0 != .specificDates
                                    }, id: \.self) { type in
                                        Text(type.label).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.black)
                                .labelsHidden()
                            }

                            switch vm.scheduleType {
                            case .interval:
                                HStack {
                                    Text("Cada:")
                                        .bold()
                                        .foregroundStyle(.black)
                                    Picker("", selection: $vm.frequency) {
                                        ForEach(1...30, id: \.self) { value in
                                            Text("\(value)")
                                                .foregroundStyle(.black)
                                                .tag(value)
                                        }
                                    }
                                    .frame(width: 70)
                                    .foregroundStyle(.black)
                                    .tint(.black)
                                    .labelsHidden()

                                    Picker("", selection: $vm.unit) {
                                        ForEach(TimeUnit.allCases, id: \.self) { unit in
                                            Text(unit.label).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.black)
                                    .labelsHidden()
                                }

                            case .weekly:
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Ejecutar:")
                                            .bold()
                                            .foregroundStyle(.black)
                                        Picker("", selection: $vm.weeklyDaysPerWeek) {
                                            ForEach(1...7, id: \.self) { value in
                                                Text(GoalsL10n.dayCount(value)).tag(value)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.black)
                                        .labelsHidden()
                                        .onChange(of: vm.weeklyDaysPerWeek) { _, newValue in
                                            vm.setWeeklyDayCount(newValue)
                                        }
                                        Text("por semana")
                                            .foregroundStyle(.black)
                                    }

                                    Text("Días específicos:")
                                        .bold()
                                        .foregroundStyle(.black)

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
                                                    .padding(.vertical, 8)
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundStyle(isSelected ? .white : .black)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.black : Color.white.opacity(0.55))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
                                            )
                                            .accessibilityLabel(weekday.label)
                                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                                        }
                                    }
                                }

                            case .specificDates:
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fecha de cada unidad:")
                                        .font(.headline)
                                        .foregroundStyle(.black)

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
                                        .foregroundStyle(.black)
                                    }
                                }
                            }

                            HStack {
                                Text("Momento del día:")
                                    .bold()
                                    .foregroundStyle(.black)
                                Picker("", selection: $vm.dayPeriod) {
                                    ForEach(GoalDayPeriod.allCases, id: \.self) { period in
                                        Text(period.label).tag(period)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.black)
                                .labelsHidden()
                            }

                        }
                        
                        
                        //Resumen:
                        VStack{
                            Text(GoalsL10n.format(
                                "goals.ui.summary_value",
                                fallback: "Resumen: {0}",
                                summaryText
                            ))
                                .foregroundStyle(.black).bold()
                        }

                        // Descripción (última sección y colapsada inicialmente):
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.easeInOut) {
                                    showDescription.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Descripción")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(showDescription ? 180 : 0))
                                }
                                .foregroundStyle(.black)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if showDescription {
                                TextEditor(text: $vm.description)
                                    .font(.platFormSize(iOS: 22, mac: 24))
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .frame(height: 150)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.7))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.4))
                                    )
                                    .focused($focusedField, equals: .description)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                            
                        
                    }
                    .onTapGesture {
                        focusedField = nil
                    }
                }
                .onTapGesture {
                    focusedField = nil
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
        }
        .cornerRadius(20)
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
        }
        .onChange(of: vm.completionBasis) { _, newValue in
            if newValue == .duration, vm.scheduleType == .specificDates {
                vm.scheduleType = .interval
            }
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
    private func createGoal() {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = vm.title
        goal.descriptionText = vm.description
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
        goal.dayPeriod = vm.dayPeriod.rawValue
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
        }catch{
            context.rollback()
            msg("Error al crear una meta nueva")
        }
        
    }
    
    
    
}

#Preview {
    CreateGoalView()
        .environment(\.managedObjectContext, CoreDataController.shared.context)
}
