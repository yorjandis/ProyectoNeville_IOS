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
    
    let frase : Frases?
    @State var nota : String = ""
    
    var body: some View {
        NavigationStack {
            Form{

                    Section("Nota"){
                        TextField("", text: $nota, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
            }
            .onAppear{
                if let tt = frase {
                    nota = tt.nota ?? ""
                }
                
            }
            Spacer()
            ScrollView(content: {
                Text(frase?.frase ?? "")
            })
            .navigationTitle("Nota en Frase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !FrasesModel().UpdateNotaAsociada(fraseID: self.frase?.id ?? "", notaAsociada: nota){
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
