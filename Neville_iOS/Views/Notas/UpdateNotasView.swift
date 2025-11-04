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
    
    let NotaId : String //Id de la nota a actualizar
    @State var title : String
    @State var nota : String
    @Binding var notas : [Notas]

    
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
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                }
            }
            .navigationTitle("Actualizar una Nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Actualizar"){
                        if NotasModel().updateNota(NotaID: NotaId, newTitle: title, newNota: nota){
                            notas.removeAll()
                            notas.append(contentsOf: NotasModel().getAllNotas())
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
            }
        }
        
    }
    
    
    
}

#Preview {
    ContentView()
}
