//
//  ProgramasPreestablecidosView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//

import SwiftUI

struct ProgramasListView: View {
    
    @StateObject private var viewModel = ProgramasViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text("Programas")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 8)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    
                    ForEach(viewModel.programas) { programa in
                        
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Text(programa.title)
                                .font(.title2)
                                .bold()
                            
                            Text(programa.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            
                            NavigationLink {
                                ProgramaDetailView(programa: programa)
                            } label: {
                                Label("Detalles del Programa", systemImage: "info.circle")
                                    .font(.headline)
                            }
                            .buttonStyle(.bordered)
                            
                            HStack {
                                Spacer()
                                
                                Button("Comenzar Programa") {
                                    viewModel.createProgramaPreestablecido(programa: programa)
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
    }
}
