//
//  FilterByNotaView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 9/2/24.
//
// sheet que permite filtrar el contenido de las notas

import SwiftUI
struct FilterByNotaView: View {
    @StateObject private var modelWatch = watchModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var texto : String   = ""
    @State private var showSheetTitulo  = false     //Abre/Cierra sheet
    @State private var showSheetTexto   = false     //Abre/Cierra sheet
    
    var body: some View {
        VStack{
            Text("Filtrar Notas por...")
            Divider()
            ScrollView {
                Button("Título"){
                    showSheetTitulo = true
                }
                
                Button("Texto"){
                    showSheetTexto = true
                }
                
                Button("Favoritos"){
                    Task{
                        modelWatch.listNotas = modelWatch.getNotasFavoritas()
                        dismiss()
                    }
                }
            }  
        }
        .sheet(isPresented: $showSheetTitulo, content: {
                VStack{
                    TextFieldLink("🔍 Título a buscar",prompt: Text("Texto del título")) { str in
                        Task{
                            modelWatch.listNotas = modelWatch.searchTextInNotas(text:str, donde: .titulo)
                            dismiss()
                        }
                    }
                }
        })
        .sheet(isPresented: $showSheetTexto, content: {
                VStack{
                    TextFieldLink("🔍 Texto a buscar",prompt: Text("Texto de la nota")) { str in
                        Task{
                            modelWatch.listNotas = modelWatch.searchTextInNotas(text:str, donde: .contenido)
                            dismiss()
                        }
                    }
                }
        })
    }

}

