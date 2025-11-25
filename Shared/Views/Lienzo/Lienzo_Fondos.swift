//
//  Lienzo_Fondos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/11/25.
//

import SwiftUI

struct GradientTemplate: Identifiable {
    let id = UUID()
    var colors: [Color]
}

struct GradientGridView: View {
    
    @EnvironmentObject var coloresFondo : ColoresFondo
    
    @State private var manualColor1 : Color = .purple
    @State private var manualColor2 : Color = .green
    
    
    // Lista de degradados (3 columnas x 4 filas → 12 elementos)
    let gradients: [GradientTemplate] = [
        GradientTemplate(colors: [.red, .yellow]),
        GradientTemplate(colors: [.blue, .purple]),
        GradientTemplate(colors: [.pink, .orange]),
        GradientTemplate(colors: [.green, .cyan]),
        GradientTemplate(colors: [.mint, .teal]),
        GradientTemplate(colors: [.indigo, .pink]),
        GradientTemplate(colors: [.yellow, .green]),
        GradientTemplate(colors: [.purple, .blue]),
        GradientTemplate(colors: [.orange, .red]),
        GradientTemplate(colors: [.cyan, .indigo]),
        GradientTemplate(colors: [.teal, .pink]),
        GradientTemplate(colors: [.brown, .orange])
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
 

    var body: some View {
        ScrollView {
            
            //Colores personalizaods:
            VStack(spacing: 20) {
                
                // --- Selección Manual ---
                VStack {
                    Text("Selecciona tus colores")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        ColorPicker("Color 1", selection: $manualColor1)
                        ColorPicker("Color 2", selection: $manualColor2)
                    }
                    .padding()
                    .onChange(of: self.manualColor1) { oldValue, newValue in
                        self.coloresFondo.coloresFondo = [newValue, manualColor2]
                    }
                    .onChange(of: self.manualColor2) { oldValue, newValue in
                        self.coloresFondo.coloresFondo = [manualColor1, newValue]
                    }
                }
                .padding()
            }
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(gradients) { gradient in
                    Button {
                        self.coloresFondo.coloresFondo = gradient.colors    
                    } label: {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradient.colors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

