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
        EnciclopediaCategoria(nombre: "Pensamientos & Sentimientos", temas: EnciclopediaTemas.pensamientoYSentimientos),
        EnciclopediaCategoria(nombre: "Hábitos", temas: EnciclopediaTemas.habitos),
        EnciclopediaCategoria(nombre: "Epigenética", temas: EnciclopediaTemas.epigenetica),
        EnciclopediaCategoria(nombre: "Memoria", temas: EnciclopediaTemas.memoria)
    ]
    
    var body: some View {
        NavigationStack {
            List(categorias) { categoria in
                NavigationLink(categoria.nombre) {
                    SubListaView(categoria: categoria)
                }
            }
            Spacer()
            VStack{
                Text("Nota: La información de los artículos esta basada en estudios científicos recientes y la neurociencia. Su finalidad es divulgativa y no médica. No debe sustituir asesoramiento médico profesional.")
                    .font(.body)
            }
            .padding()
            .navigationTitle("Enciclopedia")
        }
        
    }
}


fileprivate struct SubListaView: View {
    let categoria: EnciclopediaCategoria
    
    var body: some View {
        List(categoria.temas, id: \.self) { item in
            NavigationLink(item.rawValue) {
                ContentTxtShowView(title: item.rawValue,
                                   nombreTxt: item.getFileName,
                                   type: .NA)
            }
        }
        .navigationTitle(categoria.nombre)
    }
}


//Modelo para las Categorias:
struct EnciclopediaCategoria: Identifiable {
    let id = UUID()
    let nombre: String
    let temas: [EnciclopediaTemas]
}
