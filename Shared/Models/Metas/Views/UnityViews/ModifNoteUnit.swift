//
//  modifNoteUnity.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 9/1/26.
//

//
//  ModifyGoal.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//La modificación solo abarca el título y la descripción de un Objetivo

import SwiftUI
import CoreData

struct ModifNoteUnit: View {
    @Environment(\.dismiss) private var dismiss
    
    let unit : UnitEntity
    
    @State private var note : String = ""
    
    @State private var showAlert: Bool = false
    
    private var unitDateComplete : String{
        return unit.completedDate?.formatted(
            .dateTime
                .day()
                .month()
                .year()
                .hour()
                .minute()
        ) ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading){
            
            
            HStack(alignment: .top){
                //Nombre de la unidad
                Text(GoalsL10n.unitDisplayName(unit.name, index: Int(unit.index))).bold()
                Spacer()
                Text(GoalsL10n.format(
                    "goals.ui.completed_at",
                    fallback: "Fichado: {0}",
                    self.unitDateComplete
                ))
            }.padding(.bottom, 5)
            
            
            VStack(alignment: .leading, spacing: 2){
                Text("Nota:").bold()
                TextEditor(text: self.$note)
                    .font(.body)
            }
            
            Button("Actualizar"){
                do{
                    try unit.updateNoteUnit(note: self.note)
                }catch{
                    self.showAlert = true
                }
                
                dismiss()
            }
            .buttonStyle(.bordered)
            
            
        }
        .padding()
        .onAppear{
            self.note = self.unit.note ?? ""
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("La Ley - Objetivos"), message: Text("No se ha podido actualizar la nota de la unidad. Inténtalo más tarde."))
        }
    }
    
}
