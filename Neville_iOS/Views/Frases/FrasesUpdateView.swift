//
//  FrasesUpdateView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//

import SwiftUI
import CoreData

struct FrasesUpdateView: View {
    @Environment(\.dismiss) var dimiss
    
    @State var frase : Frases
    @State var list : [Frases]
    @State private var text = ""
    @State  var nota = ""
    
    var body: some View {
        NavigationStack {
            VStack{
                Form{
                    Section("Frase"){
                        TextField("Texto de la frase", text: $text, axis: .vertical)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 22))
                    }
                    Section("Nota"){
                        TextField("Nota de la frase", text: $nota, axis: .vertical)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 22))
                    }
                }
                .onAppear{
                    text = frase.frase ?? ""
                    nota = frase.nota ?? ""
                }
                
            }
            .navigationTitle("Actualizar Frase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button("OK"){
                    FrasesModel().Update(frase: frase, fraseStr: frase.frase ?? "", nota: frase.nota ?? "")
                    withAnimation {
                        list.removeAll()
                        list = FrasesModel().getAllFrases()
                    }
                }
            }
        }
    }
}

#Preview {
    FraseAddView()
}
