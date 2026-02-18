//
//  ArchivedGoalDetailView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

import SwiftUI


struct ArchivedGoalDetailView: View {

    @ObservedObject var goal: ArchivedGoalEntity
    @Environment(\.managedObjectContext) private var context


    let columns = Array(repeating: GridItem(.flexible(), spacing:8), count: 3)
    
    @State private var selectedUnit: ArchivedUnitEntity? //Para mostrar inforación de una unidad
    
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
                            Text("Nota:").bold()
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
                            TextEditor(text: self.$note)
                                .font(.platFormSize(iOS: 22, mac: 24))
                                .padding(3)
                                .frame(minHeight: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.3))
                                )
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
                                    Button("Nota de esta Unidad"){
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
