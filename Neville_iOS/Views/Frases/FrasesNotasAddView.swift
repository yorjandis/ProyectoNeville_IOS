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
    @EnvironmentObject private var frasesModel: FrasesModel
    
    let frase : String
    
    @State var nota : String = "" //Campo del textField
    
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    
    
    var body: some View {
        NavigationStack {
            Form{
                    Section("Nota"){
                        TextField("", text: $nota, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            
                    }
            }
            .onAppear{
                nota = frasesModel.GetNotaAsociadaFrase(frase: self.frase)
            }
            Spacer()
            ScrollView(content: {
                Text(frase)
                .padding()
            })
            .navigationTitle("Nota en Frase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !FrasesModel.shared.UpdateNotaAsociada(frase: frase, notaAsociada: nota){
                            self.alertMessage = "No se ha podido guardar la nota."
                            self.showAlert = true
                        }
                        frasesModel.getAllFrases()
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
            .alert(isPresented: self.$showAlert){
                Alert(title: Text("Adicionar Nueva nota"), message: Text(self.alertMessage))
            }
        }
        
    }
}







#Preview {
    ContentView()
}
