//
//  ProgramasPreestablecidosView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//

import SwiftUI

struct ProgramasListView: View {

    @StateObject private var viewModel = ProgramasViewModel()

    var body: some View {

        NavigationStack {
            ZStack{
                
                LinearGradient.FondoOscuro()
                    .ignoresSafeArea()
                
                List {

                    ForEach(viewModel.programasAgrupados,id: \.0) { grupo, programas in
                        #if os(macOS)
                        
                        Button( programas.count == 1 ? programas.first!.title : tituloLegible(grupo)){
                            showWindow(for: SubMenuView(programas: programas),
                                       environmentObjects: [],
                                       title: "",
                                       size: .absolute(CGSize(width: 500, height: 600)),
                                       isModal: true)
                        }
                        
                        #else
                        
                        NavigationLink(
                            programas.count == 1 ? programas.first!.title : tituloLegible(grupo)

                        ) {

                            SubMenuView(programas: programas)
                        }
                        
                        #endif
                        
                        
                    }

                }
                .scrollContentBackground(.hidden)   // 🔥 clave
                .background(Color.clear) 
            }
            
            .navigationTitle("Programas")
        }
    }

    private func tituloLegible(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "prog_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    
    
    
    struct SubMenuView: View {
        
        let programas: [ProgramasPreestablecido]
        @Environment(\.dismiss) private var dismiss
        @StateObject private var viewModel = ProgramasViewModel()
        
        
        
        var body: some View {
            ZStack{
                
                LinearGradient.FondoOscuro()
                    .ignoresSafeArea()
                VStack{
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            
                            ForEach(programas) { programa in
                                
                                ProgramCard(programa: programa)
                                    .padding(.horizontal, 3)
                            }
                        }
                    }
                    
                    #if os(macOS)
                    if ventanaActualEsModal() {
                        Button("Cerrar"){
                            if let window = NSApp.keyWindow {
                                closeWindow(window)
                                
                            }
                        }
                        .padding()
                        .help("Cerrar")
                    }
                    #endif
                    
                    
                }
                
                
            }
            
            .navigationTitle("Subprogramas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    
    struct ProgramCard :  View {
        
        @Environment(\.dismiss) var dismiss
        
        @StateObject private var viewModel = ProgramasViewModel()
        
        
        let programa : ProgramasPreestablecido
        
        var body: some View {


                VStack(alignment: .leading, spacing: 12) {
                    
                    Text(programa.title)
                        .font(.title3)
                        .foregroundStyle(.black)
                        .bold()
                    
                    Text(programa.description)
                        .font(.body)
                        .bold()
                        .foregroundStyle(.black)
                        .lineLimit(3)
                    
                   
                    
                    HStack {
                        #if os(macOS)
                        Button{
                            showWindow(for: ProgramaDetailView(programa: programa),
                            environmentObjects: [],
                                       title: "Información del Programa",
                                       size: .percentage(width: 0.4, height: 0.7),
                                       isModal: true
                            )
                            
                        } label: {
                            Label("Detalles...", systemImage: "info.circle")
                                .font(.headline)
                        }
                        .tint(.black)
                        .buttonStyle(.bordered)
                        
                        #else
                        NavigationLink {
                            ProgramaDetailView(programa: programa)
                        } label: {
                            Label("Detalles...", systemImage: "info.circle")
                                .font(.headline)
                        }
                        .tint(.black)
                        .buttonStyle(.bordered)
                        
                        #endif
                        

                        Spacer()
                        
                        Button{
                            viewModel.createProgramaPreestablecido(programa: programa)
                            dismiss()
                        }label: {
                            Label("Comenzar Programa", systemImage: "figure.run.circle")
                                .font(.headline)
                        }
                        .tint(.black)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient.Oceano())
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                )
  
        }
        
        
    }
    
    
}
