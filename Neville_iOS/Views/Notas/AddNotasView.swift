//
//  AddNotasView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 2/10/23.
//
//Views Permite adicionar una nota a la BD

import SwiftUI
import CoreData

struct AddNotasView: View {
    @Environment(\.dismiss) var dimiss
    @State      var title : String = ""
    @State      var nota : String = ""
    @Binding    var  notas : [Notas]
    
    var body: some View {
        NavigationStack {
            Form{
                    Section("Título"){
                        TextField("", text: $title, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        
                    }
                    Section("Nota"){
                        TextField("", text: $nota, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
            }
            .navigationTitle("Adicionar una nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if NotasModel.AddNota(title: title, nota: nota) {
                            notas.removeAll()
                            notas.append(contentsOf: manageNotas().getAllNotas())
                        }else{
                            print("se ha producido un error al guardar la nota")
                        }
                        dimiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button{ dimiss()}label: {
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
