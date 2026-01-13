

import SwiftUI
import CoreData

struct CreateGoalView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm = CreateGoalViewModel()
    
    
    
    //Ocultar el teclado:
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case title
        case description
    }
    
    var body: some View {
        NavigationStack {
            VStack{
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        
                        sectionTitle("Título")
                        
                        TextField("", text: $vm.title, prompt: Text("Eje. Meditar todos los días"), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .title)
                        
                        
                        
                        sectionTitle("Configurar")
                        
                        //Encabezados
                        HStack{
                            
                            
                            Text("Unidades")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Tipo")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Frecuencia")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                                
                        }
                        
                        
                        //Picker Unidad & Cantidad & Frecuencia:
                        HStack(alignment: .top, spacing: 16) {
                            
                            
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
                            
                            Spacer()
                            
                            //Tipo: Minuos, horas, dias, meses, años
                            Picker("", selection: $vm.unit) {
                                ForEach(TimeUnit.allCases, id: \.self) {
                                    Text($0.rawValue.capitalized)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            
                            Spacer()
                            
                            
                            HStack {
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
                            
                            Spacer()
                        }
                        
                        
                        Text("Resumen: Meta a completar en \(vm.amount) unidades. Cada unidad deberá realizarse cada \(vm.frequency) \(vm.unit.rawValue)")

                        
                        
                        
                        // Notas
                        sectionTitle("Nota Adjunta")
                        TextEditor(text: $vm.description)
                            .frame(height: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray.opacity(0.4))
                            )
                            .focused($focusedField, equals: .description)
                            
                        
                    }

                }
                .onTapGesture {
                    focusedField = nil
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .navigationTitle("Nueva Meta")
            .toolbarRole(.editor)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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
    
    // Helpers
    
    @ViewBuilder
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func createGoal() {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = vm.title
        goal.descriptionText = vm.description
        goal.totalUnits = Int32(vm.amount)
        goal.unitType = vm.unit.rawValue
        goal.frequency = Int32(vm.frequency)
        goal.isStarted = false
        
        try? context.save()
    }
}


