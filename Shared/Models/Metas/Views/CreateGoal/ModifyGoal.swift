//
//  ModifyGoal.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//La modificación solo abarca el título y la descripción de un Objetivo

import SwiftUI
import CoreData

struct ModifyGoal: View {
    @Environment(\.dismiss) private var dismiss
    
    let goal : GoalEntity
    
    @State private var title : String = ""
    @State private var description: String = ""
    
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading){
            
            Text("Título:")
            TextEditor(text: self.$title)
            
            Text("Nota Adjunta:")
            TextEditor(text: self.$description)
            
            
            Button("Actualizar"){
                do{
                    try goal.update(title: self.title, description: self.description)
                }catch{
                    self.showAlert = true
                }
                
                dismiss()
            }
            .buttonStyle(.bordered)
            
            
        }
        .padding()
        .onAppear{
            self.title = self.goal.title ?? ""
            self.description = self.goal.descriptionText ?? ""
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("La Ley - Objetivos"), message: Text("No se ha podido actualizar el objetivo. Inténtalo de nuevo."))
        }
    }
    
}
