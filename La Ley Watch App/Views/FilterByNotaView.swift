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
    @State private var showSheetCategoria = false
    
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

                Button("Categoría"){
                    showSheetCategoria = true
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
                VStack {
                    TextField("Texto del título", text: $texto)
                    Button("Buscar") {
                        modelWatch.listNotas = modelWatch.searchTextInNotas(text: texto, donde: .titulo)
                        showSheetTitulo = false
                        dismiss()
                    }
                }
                .padding()
                .onAppear {
                    texto = ""
                }
        })
        .sheet(isPresented: $showSheetTexto, content: {
                VStack {
                    TextField("Texto de la nota", text: $texto)
                    Button("Buscar") {
                        modelWatch.listNotas = modelWatch.searchTextInNotas(text: texto, donde: .contenido)
                        showSheetTexto = false
                        dismiss()
                    }
                }
                .padding()
                .onAppear {
                    texto = ""
                }
        })
        .sheet(isPresented: $showSheetCategoria, content: {
                VStack {
                    TextField("Categoría", text: $texto)
                    Button("Buscar") {
                        modelWatch.listNotas = modelWatch.searchTextInNotas(text: texto, donde: .categoria)
                        showSheetCategoria = false
                        dismiss()
                    }
                }
                .padding()
                .onAppear {
                    texto = ""
                }
        })
    }

}
