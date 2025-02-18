//
//  ReflexEditView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 8/12/23.
//
//Permite modificar ujna reflexión
import SwiftUI
import CoreData

struct ReflexEditView: View {
    @Binding var reflex : Reflex
    @State private var textTitulo = ""
    @State private var textAutor = ""
    @State private var textReflex = ""
    
    @State var showAlert = false
    @State var AlertMessage = ""
    
    @FocusState var focus : Bool
    
    var body: some View {
        NavigationStack {
            Form{
                Section("Título"){
                    TextField("Título", text: $textTitulo, axis: .vertical)
                        .focused($focus)
                }
                Section("Autor"){
                    TextField("Autor", text: $textAutor, axis: .vertical)
                        .focused($focus)
                }
                Section("Texto"){
                    TextField("Texto de la reflexión", text: $textReflex, axis: .vertical)
                        .focused($focus)
                }
                
            }
            .onAppear{
                
                    textTitulo = reflex.title ?? ""
                    textAutor = reflex.autor ?? ""
                    textReflex = reflex.texto ?? ""
                
            }
            
            .toolbar{
                /*
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        
                        if  RefexModel().EditReflex(reflex: reflex, title: self.textTitulo, autor: self.textAutor, texto: self.textReflex) {
                            AlertMessage = "Se ha actualizado la reflexión"
                            showAlert = true
                        }else{
                            AlertMessage = "Ha ocurrido un error al actualizar la reflexión"
                            showAlert = true
                        }
                        
                        focus = false
                       
                    }
                }
                */
            }
            .navigationTitle("Editar una Reflexión")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("La Ley"), message: Text(AlertMessage))
            })
            
        }
        
    }
}

#Preview {
    Home()
}
