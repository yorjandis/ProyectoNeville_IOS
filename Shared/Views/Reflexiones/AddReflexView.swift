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
    @EnvironmentObject private var modelReflex : ReflexModel
        @State private var textFielTitle = ""
        @State private var textFielTexto = ""
        @State private var textFielAutor = ""
        @State private var isfav : Bool = false
    
    let reflexionAActualizar : RefType? //Si es nil es para crear una nuena reflexión y si es para actualizar(solo reflexiones personales) se actualiza la reflexión.
        
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
                                Spacer()
                            }
                            .task {
                                if self.reflexionAActualizar != nil{
                                    self.textFielTitle = self.reflexionAActualizar?.title ?? ""
                                }
                            }
                            
                        }
                        Section("Autor"){
                            HStack{
                                TextField("", text: $textFielAutor, axis: .vertical)
                                    .multilineTextAlignment(.leading)
                                    .textFieldStyle(.roundedBorder)
                                Spacer()
                            }
                            .task {
                                if self.reflexionAActualizar != nil{
                                    self.textFielAutor = self.reflexionAActualizar?.autor ?? ""
                                }
                            }
                            
                        }
                        Section("Favorito"){
                            Toggle(isOn: self.$isfav) {
                                Label("Favorito", systemImage: "heart.fill")
                                    .foregroundStyle( self.isfav ?  .orange : .primary)
                            }
                        }
                        .task {
                            if self.reflexionAActualizar != nil{
                                self.isfav = self.reflexionAActualizar?.isfav ?? false
                            }
                        }
                    }
                    
                    Text("Contenido")
                    
                    TextEditor(text: $textFielTexto)
                        .font(.system(size: 22))
                        .multilineTextAlignment(.leading)
                        .padding(12) // padding interno que mueve el cursor
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                        )
                        .padding(6) // padding externo opcional
                        .task {
                            if self.reflexionAActualizar != nil{
                                self.textFielTexto = self.reflexionAActualizar?.content ?? ""
                            }
                        }
                    
                    
                    Spacer()
                }
                .navigationTitle("Adicionar una reflexión")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .preferredColorScheme(.dark)
                .toolbar{
                    #if os(macOS)
                    if ventanaActualEsModal(){
                        ToolbarItem(placement: .navigation) {
                            Button{
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                }
                            }label:{
                                Label("Cerrar", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .help("Cerrar")
                        }
                    }
                   
                    #endif
                    
                    ToolbarItem {
                        Button(self.reflexionAActualizar == nil ? "Guardar" : "Actualizar"){
                            //Validando campos
                            guard !(self.textFielTitle).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  !(self.textFielAutor).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  !(self.textFielTexto).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                alertMessage = "Debes rellenar todos los campos"
                                showAlert = true
                                return
                            }
                            
                            if self.reflexionAActualizar == nil{
                                if modelReflex.savePersonalReflex(title: self.textFielTitle, autor: self.textFielAutor, texto: self.textFielTexto, isfav: self.isfav){
                                    modelReflex.getArrayReflexOfTxtFile()
                                    #if os(macOS)
                                    if let windows = NSApp.keyWindow{
                                        closeWindow(windows)
                                    }
                                    #else
                                    alertMessage = "Se ha guardado la reflexión"
                                    showAlert = true
                                    dimiss()
                                    #endif
                                    
                                }else{
                                    alertMessage = "Se ha producido un error al guardar la reflexión"
                                    showAlert = true
                                }
                            }else{
                                
                                if modelReflex.updatePersonalReflex(id: self.reflexionAActualizar?.id ?? "", title: self.textFielTitle, autor: self.textFielAutor, texto: self.textFielTexto, isfav: self.isfav){
                                   
                                    modelReflex.getArrayReflexOfTxtFile()
                                    #if os(macOS)
                                    if let windows = NSApp.keyWindow{
                                        closeWindow(windows)
                                    }
                                    #else
                                    alertMessage = "Se ha actualizado la reflexión"
                                    showAlert = true
                                    dimiss()
                                    #endif
                                }else{
                                    alertMessage = "Se ha producido un error al actualizar la reflexión"
                                    showAlert = true
                                }
                                 
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
