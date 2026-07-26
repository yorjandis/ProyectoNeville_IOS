//
//  EvidenciaCientifica.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 13/2/26.
//

import SwiftUI


struct EvidenciaCientificaView: View {
    var body: some View {
        NavigationStack {
            ZStack{
                LinearGradient.FondoListado()
                    .ignoresSafeArea()
                
                
                ScrollView {
                    // 1. Alineación del VStack a la izquierda
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Evidencia Científica que apoya los siguientes temas:").font(.title).padding()
                        ForEach(EvidenciaCientificaListado.allCases, id: \.rawValue) { evidencia in
                            #if os(macOS)
                            Button(evidencia.getTitle){
                                showWindow(for: ContentTxtShowView(title: evidencia.getTitle, nombreTxt: "", type: .NA, blocks: [
                                    ContentBlock(content: .text(UtilFuncs.FileRead(evidencia.rawValue)))
                                ], checkPremium: false),
                                           environmentObjects: [ClipboardObserver()],
                                title: "Evidencia Científica",
                                           size: .absolute(CGSize(width: 1200, height: 800)),
                                isModal: false)
                            }
                            #else
                            NavigationLink("🟢 \(evidencia.getTitle)") {

                                ContentTxtShowView(title: evidencia.getTitle, nombreTxt: "", type: .NA, blocks: [
                                     ContentBlock(content: .text(UtilFuncs.FileRead(evidencia.rawValue)))
                                 ], checkPremium: false)

                            }
                            .font(.body)
                            // 2. Importante: Forzar el alineado del item individual
                            .frame(maxWidth: .infinity, alignment: .leading)
                            #endif
                        }
                    }
                    .padding()
                    // 3. Forzar que el VStack ocupe todo el ancho del ScrollView
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .foregroundStyle(.black).bold()
            
        }
    }
}
