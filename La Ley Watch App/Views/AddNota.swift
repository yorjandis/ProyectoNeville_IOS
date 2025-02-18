//
//  AddNota.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 8/2/24.
//

import Foundation
import SwiftUI
import CoreData


struct AddNota : View {
    
    private let context : NSManagedObjectContext = CoreDataController.shared.context
    @Environment(\.dismiss) private var dismiss
    @State private var title : String = ""
    @State private var texto : String = ""
    @State private var isfav : Bool = false
    @State private var showAlert = false
    @State private var alertMesage = ""
    @State private var isWorking = false
    
    
    var body: some View {
        ZStack {
            VStack(spacing: 10){
                Text("Nueva Nota")
                    .foregroundStyle(.orange).bold()
                    .padding(.top, 5)
                Divider()
                    .padding(.top, 20)
                ScrollView{
                    
                    TextFieldLink("título: \(title)", prompt: Text("Título de nota")) { str in
                        title = str
                    }
                    .frame(width: .infinity ,  height: 40)
                    .cornerRadius(20)
                    .padding([.leading, .trailing], 5)
                    
                    TextFieldLink("Nota: \(texto)", prompt: Text("Título de nota")) { str in
                        texto = str
                    }
                    .frame(width: .infinity ,  height: 40)
                        .cornerRadius(20)
                        .padding([.leading, .trailing], 5)
                    
                    
                    Toggle(isOn: $isfav, label: {
                        Text("Favorito")
                    })
                    .padding(.horizontal, 10)
                    
                    Button{
                        Task{
                            if title.isEmpty || texto.isEmpty {
                                self.alertMesage = "Debe colocar un titulo y un texto para la nota" ; showAlert = true
                            }else{
                                //Crear una entidad Nota
                                let newNota = Notas(context: self.context)
                                newNota.id = UUID().uuidString
                                newNota.title = title
                                newNota.nota = texto
                                newNota.isfav = isfav
                                
                                do {
                                    try self.context.save()
                                    self.alertMesage = "Nota Creada"
                                    self.showAlert = true
                                    
                                }catch{
                                    self.context.rollback()
                                    self.alertMesage = "Error al Crear Nota"
                                    self.showAlert = true
                                    
                                }
                                
                                dismiss()
                                
                            }
                             
                        }
                        
                    }label: {
                        Label("Guardar", systemImage: "plus")
                            .padding(.vertical, 10)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .opacity(self.isWorking ? 0 : 1)
                    .overlay(content: { if self.isWorking { ProgressView() }
                    })
                    .padding([.horizontal, .vertical])
                    .buttonStyle(PlainButtonStyle())
                }
               
                   
            }
            
        }
        .ignoresSafeArea()
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Notas"), message: Text(self.alertMesage))
        })
        
    }
}


#Preview {
    AddNota()
}
