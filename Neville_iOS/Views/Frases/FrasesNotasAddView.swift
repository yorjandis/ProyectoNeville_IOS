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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var frasesModel: FrasesModel
    
    let frase : String
    
    @State var nota : String = "" //Campo del textField
    
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    
    
    var body: some View {
        NavigationStack {
#if os(macOS)
            HStack{
                Button("Guardar"){
                    if !FrasesModel.shared.UpdateNotaAsociada(frase: frase, notaAsociada: nota){
                        self.alertMessage = "No se ha podido guardar la nota."
                        self.showAlert = true
                    }
                    frasesModel.getAllFrases()
                    //Saliendo:
                    if let window = NSApp.keyWindow {
                            window.sheetParent?.endSheet(window)
                    }else{
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue.opacity(0.4))
                
                
                Spacer()
                
                Button("Cancelar"){
                    //Saliendo:
                    if let window = NSApp.keyWindow {
                            window.sheetParent?.endSheet(window)
                    }else{
                        dismiss()
                    }
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.4))
            }.padding()
#endif
            Form{
                    Section("Nota:"){
#if os(macOS)
                        
                            TextEditor(text: $nota)
                                .font(.system(size: 20))
                                .frame(height: 150)
                                .scrollDisabled(false)
                                .padding(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 5)
                        
                        
                    
                        
#else
                    TextField("", text: $nota, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
#endif
                    }
                    .padding(.leading, 5)
            }
            .onAppear{
                nota = frasesModel.GetNotaAsociadaFrase(frase: self.frase)
            }
            Spacer()
            ScrollView(content: {
                Text(frase)
                    .font(.system(size: 20))
                .padding()
            })
            .navigationTitle("Nota en Frase")

            
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !FrasesModel.shared.UpdateNotaAsociada(frase: frase, notaAsociada: nota){
                            self.alertMessage = "No se ha podido guardar la nota."
                            self.showAlert = true
                        }
                        frasesModel.getAllFrases()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button{ dismiss()}label: {
                        Text("Cancelar")
                            .foregroundStyle(.red)
                    }
                }
                #endif
                
               
            }
            .alert(isPresented: self.$showAlert){
                Alert(title: Text("Adicionar Nueva nota"), message: Text(self.alertMessage))
            }
        }
        #if os(macOS)
        .frame(minHeight: 450 ,maxHeight: 500)
        #endif
        
        
    }
}






