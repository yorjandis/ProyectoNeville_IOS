//
//  FraseAddView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//

import SwiftUI

struct FraseAddView: View {
    @Environment(\.dismiss) var dimiss
    @State private var text = ""
    
    var body: some View {
        NavigationStack {
            VStack{
                Form(){
                    Section("Frase"){
                        TextField("Texto de la frase", text: $text, axis: .vertical)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 22))
                    }
                }
                
            }
            .navigationTitle("Adicionar Frase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button("OK"){
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        FrasesModel().AddFrase(frase: text)
                        dimiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FraseAddView()
}
