//
//  EnciclopediaListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/1/26.
//

import SwiftUI

struct EnciclopediaListView: View {
    
    let categorias: [EnciclopediaCategoria] = [
        EnciclopediaCategoria(nombre: "Temas Generales",temas: EnciclopediaTemas.temasGenerales),
        EnciclopediaCategoria(nombre: "Pensamientos & Sentimientos", temas: EnciclopediaTemas.temasPensamientoYSentimientos),
        EnciclopediaCategoria(nombre: "Hábitos", temas: EnciclopediaTemas.temasHabitos),
        EnciclopediaCategoria(nombre: "Epigenética", temas: EnciclopediaTemas.temasEpigenetica),
        EnciclopediaCategoria(nombre: "Memoria", temas: EnciclopediaTemas.temasMemoria),
        EnciclopediaCategoria(nombre: "Dopamina", temas: EnciclopediaTemas.temasDopamina),
        EnciclopediaCategoria(nombre: "Serotonina", temas: EnciclopediaTemas.temasSerotonina),
        EnciclopediaCategoria(nombre: "Ansiedad", temas: EnciclopediaTemas.temasAnsiedad),
        EnciclopediaCategoria(nombre: "Emociones", temas: EnciclopediaTemas.temasEmociones),
        EnciclopediaCategoria(nombre: "Ritmo Circadiano", temas: EnciclopediaTemas.temasRitmoCircadianos)
        
    ]
    
    #if os(macOS)
    
    @State private var categoriaSeleccionadaID: EnciclopediaCategoria.ID?
    @State private var temaSeleccionado: EnciclopediaTemas?

    private var categoriaSeleccionada: EnciclopediaCategoria? {
        categorias.first { $0.id == categoriaSeleccionadaID }
    }

    var body: some View {
        ZStack{
            
            LinearGradient.FondoListado()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {

                // 🔝 PANEL SUPERIOR
                HStack(spacing: 0) {

                    // COLUMNA IZQUIERDA — CATEGORÍAS
                    List(categorias,
                         selection: $categoriaSeleccionadaID) { categoria in
                        Text(categoria.nombre)
                            .tag(categoria.id)   // 🔥 CLAVE
                    }
                    .frame(minWidth: 250)

                    Divider()

                    // COLUMNA DERECHA — TEMAS
                    Group {
                        if let categoria = categoriaSeleccionada {
                            List(categoria.temas,
                                 id: \.self,
                                 selection: $temaSeleccionado) { tema in
                                Text(tema.rawValue)
                                    .tag(tema)   // 🔥 CLAVE
                            }
                        } else {
                            VStack {
                                Spacer()
                                Text("Selecciona una categoría")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(height: 300)

                Divider()

                // 🔽 PANEL INFERIOR — CONTENIDO
                Group {
                    if let tema = temaSeleccionado {
                        ContentTxtShowView(title: tema.rawValue,nombreTxt: "" ,type: .NA, blocks: [
                            ContentBlock(content: .text(UtilFuncs.FileRead(tema.getFileName)))
                        ]
                        )
                        .id(tema)   // 🔥 CLAVE
                    } else {
                        VStack {
                            Spacer()
                            Text("Selecciona un ítem para ver el contenido")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
        }

        .navigationTitle("Enciclopedia")
        .onAppear {
            if categoriaSeleccionadaID == nil {
                categoriaSeleccionadaID = categorias.first?.id
            }
        }
    }
    
    #else
    
    // 📱 iOS mantiene navegación clásica
    
    private var content: some View {
        VStack{
            Text("Enciclopedia").font(.title)
                .foregroundStyle(.black)
                .bold()
                .padding()
            
            List(categorias) { categoria in
                NavigationLink(categoria.nombre) {
                    SubListaView(categoria: categoria)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            
            Text("""
                Los temas ilustran las últimas investigaciones publicadas en revistas científicas: Nature, Cell, Neuron,Science, PubMed, etc. El contenido de cada tema será revisado y actualizado con frecuencia.
                """)
            .padding()
        }
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack{
                
                LinearGradient.FondoListado()
                    .ignoresSafeArea()
                
                content
                    .foregroundStyle(.black).bold()
            }
           
        }
    }
    
    #endif
}

fileprivate struct SubListaView: View {
    let categoria: EnciclopediaCategoria
    
    var body: some View {
        ZStack{
            LinearGradient.FondoListado()
                .ignoresSafeArea()
            
            List(categoria.temas, id: \.self) { item in
                NavigationLink(item.rawValue) {
                    ContentTxtShowView(title: item.rawValue, nombreTxt: "",type: .NA, blocks: [
                                        ContentBlock(content: .text(UtilFuncs.FileRead(item.getFileName)))
                                       ])
                    
                }
                .listRowBackground(Color.clear)
                .foregroundStyle(.black).bold()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        
        .navigationTitle(categoria.nombre)
    }
}


//Modelo para las Categorias:
struct EnciclopediaCategoria: Identifiable, Hashable {
    let id = UUID()
    let nombre: String
    let temas: [EnciclopediaTemas]
}
