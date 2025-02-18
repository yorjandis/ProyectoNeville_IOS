//
//  SwiftUIView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Actualiza el campo nota de la frase

import SwiftUI
import CoreData


struct FrasesNotasAddView: View {
    @Environment(\.dismiss) var dimiss
    
    let frase : String
    
    @State private var nota : String = "" //Campo del textField
    
    var body: some View {
        NavigationStack {
            Form{
                    Section("Nota"){
                        TextField("", text: $nota, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
            }
            .onAppear{
                nota = FrasesModel().GetNotaAsociadaFrase(frase: self.frase)
            }
            Spacer()
            ScrollView(content: {
                Text(frase)
            })
            .navigationTitle("Nota en Frase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !FrasesModel.shared.UpdateNotaAsociada(frase: frase, notaAsociada: nota){
                            print("se ha producido un error al guardar la nota")
                        }
                        FrasesModel().getfrasesArrayFromTxtFile()
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
