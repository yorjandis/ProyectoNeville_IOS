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
        NavigationStack {
            List(viewModel.programas) { programa in
                VStack(alignment: .leading, spacing: 5){
                    Text(programa.title)
                        .font(.headline)
                    Text(programa.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    NavigationLink {
                        ProgramaDetailView(programa: programa)
                    } label: {
                        HStack{
                            Text("Detalles del Programa")
                                .font(.headline)
                        }
                    }
                    .padding(5)
                    
                    HStack{
                       Spacer()
                        Button("Comenzar Programa"){
                            viewModel.createProgramaPreestablecido(programa: programa)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                }
                
            }
            .navigationTitle("Programas")
        }
    }
}
