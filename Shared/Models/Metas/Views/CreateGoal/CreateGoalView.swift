

import SwiftUI
import CoreData

struct CreateGoalView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm = CreateGoalViewModel.shared
    
    @State private var showMetasEjemplo : Bool = false
    
    
    @State private var selectedTab : Int = 0
    
    private var metasOrdenadas: [MetasPreestablecidas] {
        MetasPreestablecidas.allCases.sorted {
            $0.getMeta.titulo.localizedCaseInsensitiveCompare($1.getMeta.titulo) == .orderedAscending
        }
    }
    
    var getTitulo : String {
        switch selectedTab{
        case 0: return "Meta Personalizada"
        case 1: return "Hábitos Saludables"
        case 2: return "Programas"
        default: return "Meta Personalizada"
        }
    }
    
    
    //Ocultar el teclado:
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case title
        case description
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
                .navigationTitle("\(self.getTitulo)")
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
            
            LinearGradient.JadeProfundo()
                .ignoresSafeArea()
            
            VStack{
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

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
                        .foregroundStyle(.black).bold()
                        .padding(12)
                        .background(LinearGradient.JadeProfundo())
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4))
                        )
                        .focused($focusedField, equals: .title)
                            
                        
                        
                        //Configuración de la Meta
                        VStack(alignment: .leading, spacing: 5){
                            Text("Configurar:")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                            
                            HStack{
                                Text("Unidades:")
                                //Cantidad de Unidades
                                Picker("", selection: $vm.amount) {
                                    ForEach(0...365, id: \.self) { number in
                                        Text("\(number)")
                                    }
                                }
                                #if os(macOS)
                                .pickerStyle(.automatic)
                                #else
                                .pickerStyle(.wheel)
                                #endif
                                .frame(width: 80, height: 120)
                                .labelsHidden()
                                
                                Text("Frecuencia:")
                                Picker("", selection: $vm.frequency) {
                                    ForEach(1...30, id: \.self) {
                                        Text("\($0)")
                                    }
                                }
                                #if os(macOS)
                                .pickerStyle(.automatic)
                                #else
                                .pickerStyle(.wheel)
                                #endif
                                .frame(width: 80, height: 120)
                                .labelsHidden()
                            }
                            
                            HStack{
                                Text("Tipo de Unidad:")
                                //Tipo: Minuos, horas, dias, meses, años
                                Picker("", selection: $vm.unit) {
                                    ForEach(TimeUnit.allCases, id: \.self) {
                                        Text($0.rawValue.capitalized)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }

                        }
                        
                        
                        // Descripción:
                        VStack{
                            Text("Descripción:")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextEditor(text: $vm.description)
                                .font(.platFormSize(iOS: 22, mac: 24))
                                .foregroundStyle(.black)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .frame(height: 150)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient.JadeProfundo())
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.4))
                                )
                                .focused($focusedField, equals: .title)
                        }

                        //Resumen:
                        VStack{
                            Text("Resumen: Meta a completar en \(vm.amount) \(vm.getTextoForUNidades(number: vm.amount)). Cada unidad deberá realizarse cada \(vm.frequency) \(vm.unit.description(for: vm.frequency))")
                                .bold()
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
        
    }
    
    
    @ViewBuilder
    private func MetasPreestablecidasView() -> some View {
        ZStack{
            LinearGradient.BarroNatural()
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                
                Text("Listado de Hábitos:")
                    .font(.title2)
                    .padding(.bottom, 8)
                
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
                                
                                HStack{
                                    Spacer()
                                    Button("Cargar en Metas") {
                                        self.vm.title = meta.getDescription
                                        self.vm.description = meta.getMeta.description
                                        self.vm.amount = meta.getMeta.noUnidades
                                        self.vm.unidadesInfo = meta.getMeta.unidadesInfo
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
        }
        
    }
    
    @ViewBuilder
    private func ProgramasPreestablecidos() -> some View {
        ProgramasListView()
    }
    
    
    //Lógica del botón Crear una Meta
    private func createGoal() {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = vm.title
        goal.descriptionText = vm.description
        goal.totalUnits = Int32(vm.amount)
        goal.unitType = vm.unit.rawValue
        goal.frequency = Int32(vm.frequency)
        goal.isStarted = false

        goal.generateUnits(DetallesUnidades: vm.unidadesInfo)
        
        do{
            try context.save()
        }catch{
            context.rollback()
            msg("Error al crear una meta nueva")
        }
        
    }
    
    
    
}


