//
//  RespondView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 20/10/25.
//

import SwiftUI
import RichText


@available(iOS 26.0, *)
struct RespondView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model : IAModel = IAModel()
    @State private var isloading : Bool = false
    @State private var bounce = false //Para animar la imagend de IA en el centro de la pantalla
    
    let nameConference : String
    let texto : String
    
    //Convierte el contenido de salida en un único texto. Para poder ser exportado
    var createContent : String {
        self.model.parrafos.map{ item in
                "\(item.encabezado)\n\(item.contenido)"
            }
            .joined(separator: "\n\n")
    }
    
    
    var body: some View {
        ZStack{
            LinearGradient(colors: [.orange.opacity(0.7),  .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .bottom)
            
            if self.isloading{
                VStack{
                    VStack{
                        Image(systemName: "sparkles")
                            .padding()
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .offset(y: bounce ? -5 : 5) // movimiento hacia arriba y abajo
                                        .animation(
                                            .easeInOut(duration: 0.8)
                                                .repeatForever(autoreverses: true),
                                            value: bounce
                                        )
                                        .onAppear {
                                            bounce = true
                                        }
                        Text("Creando  Resumen")
                        Text("Etapa \(self.model.fragmentoActual) de \(self.model.noFragmentos)")
                    }
                    //Barra de Progreso
                    ProgressView(value: Double(self.model.fragmentoActual),
                                 total: max(Double(self.model.noFragmentos), 1))
                    .progressViewStyle(.linear)
                    .animation(.easeInOut(duration: 0.35), value: self.model.fragmentoActual)
                    .tint(.black)
                    .frame(maxWidth: 300)
                }
                .font(.system(size: 24))
                
            }else{
                //Contenido de la respuesta
                ScrollView {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(self.model.parrafos.indices, id: \.self) { index in
                            let parrafo = self.model.parrafos[index]
                            VStack(alignment: .leading, spacing: 8) {
                                Text(parrafo.encabezado)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.black)
                                    .textSelection(.enabled)
                                    .contentTransition(.opacity)
                                
                                Text(parrafo.contenido)
                                    .font(.title3)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .textSelection(.enabled)
                                    .contentTransition(.opacity)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeInOut(duration: 0.35), value: self.model.parrafos.count)
                            
                        }
                        
                    }
                }
                
            }
            
            
        }
        .onAppear{
            Task { @MainActor in
                withAnimation {
                    self.isloading = true
                }
                await self.model.executeRequest(texto: self.texto)
                withAnimation {
                    self.isloading = false
                }
                
            }
        }
        .toolbar{
            
            if !self.model.parrafos.isEmpty {
                ToolbarItem {
                    Button{
                        Task { @MainActor in
                            withAnimation {
                                self.isloading = true
                            }
                            await self.model.executeRequest(texto: self.texto)
                            withAnimation {
                                self.isloading = false
                            }
                            
                        }
                       
                    }label: {
                        Label("",systemImage: "wand.and.sparkles")
                    }
                    .tint(.orange)
                }
                
                ToolbarSpacer(.fixed)
                
                //Share the text
                ToolbarItem {
                    ShareLink(item: self.createContent){
                        Label("", systemImage: "square.and.arrow.up")
                    }
                }
            }
            
            
        }
    }
    
    //Función que convierte los saltos de líneas en etiquetas <br>
    
    func convertToBr(_ text: String) -> String{
        
        return texto.replacingOccurrences(of: "\n", with: "<br>")
        
    }
    
    
    
}


#Preview {
    if #available(iOS 26.0, *) {
        RespondView(nameConference: "NameConference", texto: "Esto es un ejemplo Yor")
    }
   
}

