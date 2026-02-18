

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
                        .tabItem {
                            Label("Personalizado", systemImage: "gear")
                        }
                        .tag(0)
                    
                    MetasPreestablecidasView()
                        .tabItem {
                            Label("Metas Saludables", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    ProgramasPreestablecidos()
                        .tabItem {
                            Label("Programas", systemImage: "list.bullet")
                        }
                        .tag(2)

                   
                }
                .navigationTitle("Nueva Meta")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Crear Meta") {
                            createGoal()
                            dismiss()
                        }
                        .disabled(!vm.isValid)
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
        VStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                        Text("Título de la Meta")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                         
                    TextField("", text: $vm.title, prompt: Text("Eje. Meditar todos los días"), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .title)
                    
                    
                    //Configuración de la Meta
                    VStack(alignment: .leading, spacing: 5){
                        Text("Configurar:")
                            .font(.headline)
                            .foregroundStyle(.orange)
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
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextEditor(text: $vm.description)
                            .font(.platFormSize(iOS: 22, mac: 24))
                            .frame(height: 130)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray.opacity(0.4))
                            )
                            .focused($focusedField, equals: .description)
                    }

                    //Resumen:
                    VStack{
                        Text("Resumen: Meta a completar en \(vm.amount) \(vm.getTextoForUNidades(number: vm.amount)). Cada unidad deberá realizarse cada \(vm.frequency) \(vm.unit.description(for: vm.frequency))")
                    }
                        
                    
                }

            }
            .onTapGesture {
                focusedField = nil
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    
    @ViewBuilder
    private func MetasPreestablecidasView() -> some View {
        //Listado de Metas Preestablecidas
        VStack(alignment: .leading){
            Text("Seleccione una Meta Personalizada:")
               .font(.title2)
            List(self.metasOrdenadas, id: \.self) { meta in
                    VStack(alignment: .leading, spacing: 5){
                        Text("\(meta.getMeta.titulo)")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .bold()
                        
                        Text("\(meta.getMeta.description)")
                            .font(.title3)
                        
                        Button("Preparar esta Meta"){
                            self.vm.title = meta.getDescription
                            self.vm.description = meta.getMeta.description
                            self.vm.amount = meta.getMeta.noUnidades
                            self.vm.unidadesInfo = meta.getMeta.unidadesInfo
                            self.selectedTab = 0
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
    
                }
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


