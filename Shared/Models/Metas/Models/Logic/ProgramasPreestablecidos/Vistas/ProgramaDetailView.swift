//
//  ProgramaDetails.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//

import SwiftUI

struct ProgramaDetailView: View {
    
    let programa: ProgramasPreestablecido
    
    @State private var showExpanded: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                Text(programa.title)
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                    .bold()
                
                Text(programa.description)
                    .font(.body)
                
                
                Text("Resumen:")
                    .font(.body)
                    .foregroundStyle(.orange)
                    .bold()
                
                Text("Programa a completar en \(programa.noUnidades) \(programa.tipoUnidad.description(for: programa.noUnidades)), cada unidad deberá completarse cada \(programa.frecuencia) \(programa.tipoUnidad.description(for: programa.frecuencia))")
                
                
                Text("Detalles de las unidades:")
                    .font(.body)
                    .foregroundStyle(.orange)
                    .bold()
                    .padding(.top, 10)
                
                Divider()
                
                ForEach(programa.unidadesNotes) { unidad in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(unidad.name) \(self.showExpanded == unidad.name ? "v" : ">")")
                            .font(.headline)
                            .onTapGesture {
                                withAnimation {
                                    if showExpanded == unidad.name {
                                        showExpanded = nil
                                    }else{
                                        showExpanded = unidad.name
                                    }
                                    
                                }
                                
                            }
                        
                        if showExpanded == unidad.name {
                            Text(unidad.note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                }
            }
            .padding()
        }
    }
}
