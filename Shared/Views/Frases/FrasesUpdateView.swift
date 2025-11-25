//
//  FrasesUpdateView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//

import SwiftUI
import CoreData

struct FrasesUpdateView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var frasesModel: FrasesModel
    let frase : Frases?
    
    @State private var text = ""
    @State private var nota = ""
    @State private var favorito : Bool = false
    
    var body: some View {
        NavigationStack {
            VStack{
                Form{
                    
                    Section("Favorito"){
                        Toggle("Favorito \(self.favorito ? "ON" : "OFF")", isOn: self.$favorito)
                    }
                    
                    Section("Frase"){
                        TextEditor(text:  $text)
                            .font(.system(size: 22))
                            .multilineTextAlignment(.leading)
                            .frame(height: 120)
                            
                    }
                    Section("Nota"){
                        TextEditor(text:  $nota)
                            .font(.system(size: 22))
                            .multilineTextAlignment(.leading)
                            .frame(height: 80)
                    }
                }
                .onAppear{
                    if let frase = self.frase {
                        self.text = frase.frase ?? ""
                        self.nota = frase.nota ?? ""
                        self.favorito = frase.isfav
                    }
                    
                }
                
            }
            .navigationTitle("Actualizar Frase")
            .padding(15)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                
                #if os(macOS)
                ToolbarItem(placement: .navigation) {
                    Button{
                        if let windows = NSApp.keyWindow{
                            closeWindow(windows)
                        }
                        
                    }label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                #endif
                
                ToolbarItem(placement: .automatic) {
                    Button("Actualizar"){
                        if self.frasesModel.updateFrasePersonal(frase: self.frase!, newText: self.text, newNota: self.nota, newIsfav: self.favorito){
                                Task{
                                   await self.frasesModel.FiltrarListado()
                                    dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.blue))
                }
               
            }
        }
    }
}

#Preview {
    FraseAddView()
}
