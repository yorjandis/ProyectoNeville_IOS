//
//  UpdateNotasView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 5/10/23.
//Actualiza el contenido de una nota y recarga el listado de notas

import SwiftUI
import CoreData

struct UpdateNotasView: View {
    @Environment(\.dismiss) var dimiss
    @EnvironmentObject var modelNotas : NotasModel
    
    let NotaId : String //Id de la nota a actualizar
    @State var title : String
    @State var nota : String

    
    var body: some View {
        NavigationStack {
            Divider()
            Form{
                Section("Título"){
                    TextField("", text: $title, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    
                }
                Section("Nota"){
                    TextEditor(text: $nota)
                            .font(.system(size: 22))
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .background(.black.opacity(0.02))
                            .cornerRadius(8)
                }
            }
            .navigationTitle("Actualizar una Nota")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                
                #if os(macOS)
                ToolbarItem(placement: .principal) {
                    Button("Actualizar"){
                        if NotasModel().updateNota(NotaID: NotaId, newTitle: title, newNota: nota){
                            self.modelNotas.getAllNotasToModel()
                            
                            
                            
                        }else{
                            print("Error al actualizar la nota")
                        }
                        
                        //Saliendo de la ventana
                        if let windows = NSApp.keyWindow{
                            if ventanaActualEsModal(){
                                closeWindow(windows)
                            }
                        }

                    }
                }
                
                if ventanaActualEsModal(){
                    ToolbarItem(placement: .navigation) {
                        Button{
                            if let windows = NSApp.keyWindow{
                                    closeWindow(windows)
                            }
                            
                        }label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        
                    }
                }
                #endif
                
                
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Actualizar"){
                        if NotasModel().updateNota(NotaID: NotaId, newTitle: title, newNota: nota){
                            self.modelNotas.getAllNotasToModel()
                        }else{
                            print("Error al actualizar la nota")
                        }
                        dimiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                        Button{
                            dimiss()
                        }label: {
                            Text("Cancelar")
                                .foregroundStyle(.red)
                        }
                }
                #endif
            }
        }
        
    }
    
    
    
}
