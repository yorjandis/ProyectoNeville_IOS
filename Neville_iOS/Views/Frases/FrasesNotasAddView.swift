//
//  SwiftUIView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Actualiza el campo nota de la frase

import SwiftUI


struct FrasesNotasAddView: View {
    @Environment(\.dismiss) var dimiss

    let idFrase : String
    @State var nota : String = ""
    
    var body: some View {
        NavigationStack {
            Form{

                    Section("Nota"){
                        TextField("", text: $nota, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
            }
            .navigationTitle("Nota en Frase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !FrasesModel().UpdateNotaAsociada(fraseID: idFrase, notaAsociada: nota){
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
