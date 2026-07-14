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
        VStack{
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
                    
                    Text(GoalsL10n.format(
                        "goals.ui.program_summary",
                        fallback: "Programa: {0}.",
                        programa.scheduleSummary
                    ))
                    
                    
                    Text("Detalles de las unidades:")
                        .font(.body)
                        .foregroundStyle(.orange)
                        .bold()
                        .padding(.top, 10)
                    
                    Divider()
                    
                    ForEach(programa.unidadesinfo) { unidad in
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
                                Text(unidad.info)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                        }
                    }
                    
                    
                    
                    
                }
                .padding()
            }
        }
        .toolbar{
            ToolbarItem{
            #if os(macOS)
                
                if ventanaActualEsModal() {
                    Button("Cerrar"){
                        if let windows = NSApp.keyWindow{
                            closeWindow(windows)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            #endif
            }
        }
        
    }
}
