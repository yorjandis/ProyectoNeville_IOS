//
//  GoaldDetailView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//DETALLE DE OBJETIVO + GRID DE UNIDADES

import SwiftUI

struct GoalDetailView: View {

    @ObservedObject var goal: GoalEntity
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject var clock = GlobalClock.shared //Reloj

    let columns = Array(repeating: GridItem(.flexible(), spacing:8), count: 3)
    
    @State private var selectedUnit: UnitEntity? //Para mostrar inforación de una unidad
    
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
                        Text("Unidad \(showUnit.name ?? "") \(showUnit.unitStatus == .lost ? "🟠" : "🟢" )").bold()
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
                                        try self.selectedUnit?.updateNoteUnit(note: self.note)
                                    }catch{
                                        self.showAlert = true
                                    }
                                }
                                
                                self.selectedUnit = nil //Cerrar la ventana de info para esta unidad
                            }
                            .buttonStyle(.bordered)
                            .padding(1)
                        }
                        
                        //Contenido de la nota
                        ScrollView{
                            TextEditor(text: self.$note)
                                .padding(3)
                                    .frame(minHeight: 100)
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
                            UnitCellView(unit: unit)
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
        .onAppear {
            //Actualiza el estado de las unidades perdidas:
            updateLostUnits()
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("La ley - Metas"), message: Text("No se puede actualizar la nota"))
        }
        
    }
    


private func updateLostUnits() {
    for unit in goal.unitsArray {
        unit.updateLostIfNeeded(now: clock.now)
    }
    try? context.save()
}
}
