//
//  ArchivedGoalDetailView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

import SwiftUI


struct ArchivedGoalDetailView: View {

    @ObservedObject var goal: ArchivedGoalEntity
    #if os(macOS)
    let context = CoreDataController.shared.context
    #else
    @Environment(\.managedObjectContext) private var context
    #endif
    


    let columns = Array(repeating: GridItem(.flexible(), spacing:8), count: 3)
    
    @State private var selectedUnit: ArchivedUnitEntity? //Para mostrar inforación de una unidad
    
    @State private var showNoteOrInfo : Bool = false //true para mostrar las notas, false para mostrar la info de la unidad
    @State private var note : String = ""
    
    @State private var showAlert: Bool = false
    
    //Genera un cadena legible a partir de una fecha
   private func getDateFormated(date : Date?) -> String{
        return date?.formatted(
            .dateTime
                .day()
                .month()
                .year()
                .hour()
                .minute()
        ) ?? ""
    }


    var body: some View {
        VStack{
            
            
            if let showUnit = self.selectedUnit {
                VStack(alignment: .leading){
                    HStack{
                        Text("Unidad \(showUnit.name  ?? "") \(showUnit.status == "lost" ? "🟠" : "🟢" )").bold()
                        Spacer()
                        Text("Fichado:").bold()
                        Text("\(self.getDateFormated(date: showUnit.completedDate))")
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Button("Notas:"){self.showNoteOrInfo = true}
                                .buttonStyle(.bordered)
                                .foregroundStyle(self.showNoteOrInfo == true ? .green : Color.primary)
                            
                            Button("info"){self.showNoteOrInfo = false}
                                .buttonStyle(.bordered)
                                .foregroundStyle(self.showNoteOrInfo == false ? .green : Color.primary)
                            
                            Spacer()
                            Button("Cerrar"){
                                //Guardar la nota si esta se ha modificado
                                if self.note != self.selectedUnit?.note ?? ""{
                                    do{
                                        self.selectedUnit?.note = self.note
                                        try context.save()
                                    }catch{
                                        self.showAlert = true
                                    }
                                }
                                withAnimation {
                                    self.selectedUnit = nil //Cerrar la ventana de info para esta unidad
                                }
                                
                            }
                            .buttonStyle(.bordered)
                            .padding(1)
                        }
                        
                        //Contenido de la nota
                        ScrollView{
                            if self.showNoteOrInfo{
                                TextEditor(text: self.$note)
                                    .font(.platFormSize(iOS: 22, mac: 24))
                                    .padding(3)
                                    .frame(maxWidth: .infinity, minHeight: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.3))
                                    )
                            }else{
                                Text(self.selectedUnit?.info ?? "")
                                    .font(.platFormSize(iOS: 22, mac: 24))
                                    .padding(3)
                                    .frame(maxWidth: .infinity, minHeight: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.3))
                                    )
                            }
                            
                        }
                        
                            
                    }
                    .onAppear{
                        self.note = self.selectedUnit?.note ?? ""
                    }
                    
                    Spacer()
                }
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .center)
                .background{
                    RoundedRectangle(cornerRadius: 16).fill(.gray)
                }
                
                
                
                Spacer()
                
            }else{
                ScrollView{
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(goal.unitsArray) { unit in
                            ArchivedUnitCellView(unit: unit)
                                .contextMenu{
                                    Button("Datos de la Unidad"){
                                        withAnimation {
                                            selectedUnit = unit
                                        }
                                        
                                    }
                                }
                        }
                    }
                }
            }
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("La ley - Metas"), message: Text("No se puede actualizar la nota"))
        }
        
    }
    



}
