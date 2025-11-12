//
//  AddReflexView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 11/11/25.
//


import SwiftUI
import CoreData

struct AddReflexView : View {
        @Environment(\.dismiss) private var dimiss
        @StateObject private var modelReflex = ReflexModel.shared
        @State private var textFielTitle = ""
        @State private var textFielTexto = ""
        @State private var textFielAutor = ""
        @State private var isfav : Bool = false
        
        @State var showAlert = false
        @State var alertMessage = ""
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 10){
                    Form{
                        Section("Título"){
                            HStack{
                                TextField("", text: $textFielTitle, axis: .vertical)
                                    .multilineTextAlignment(.leading)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                                Spacer()
                            }
                            
                        }
                        Section("Autor"){
                            HStack{
                                TextField("", text: $textFielAutor, axis: .vertical)
                                    .multilineTextAlignment(.leading)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                                Spacer()
                            }
                            
                        }
                        Section("Favorito"){
                            Toggle(isOn: self.$isfav) {
                                Label("Favorito", systemImage: "heart.fill")
                                    .foregroundStyle( self.isfav ?  .orange : .primary)
                            }
                        }
                    }
                    
                    Text("Contenido")
                    
                    TextEditor(text: $textFielTexto)
                   .font(.system(size: 22))
                   .multilineTextAlignment(.leading)
                   .background(
                       RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.05))
                   )
                   .overlay(
                       RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                   )
                   .frame(height: 250)
                   .padding(6)
                    
                    
                    Spacer()
                }
                .navigationTitle("Adicionar una reflexión")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .preferredColorScheme(.dark)
                .toolbar{
                    
                    ToolbarItem {
                        Button("Guardar"){
                            //Validando campos
                            guard !(self.textFielTitle).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  !(self.textFielAutor).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  !(self.textFielTexto).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                alertMessage = "Debes rellenar todos los campos"
                                showAlert = true
                                return
                            }
                            
                            if modelReflex.savePersonalReflex(title: self.textFielTitle, autor: self.textFielAutor, texto: self.textFielTexto, isfav: self.isfav){
                                alertMessage = "Se ha guardado la reflexión"
                                showAlert = true
                                modelReflex.getArrayReflexOfTxtFile()
                                dimiss()
                            }else{
                                alertMessage = "Se ha producido un error al guardar la reflexión"
                                showAlert = true
                            }
                        }
                    }
                }
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text("La Ley"), message: Text(self.alertMessage))
                })
            }
            #if os(macOS)
            .frame(minWidth: 400, idealWidth: 600, maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
            #endif
        }
    }
