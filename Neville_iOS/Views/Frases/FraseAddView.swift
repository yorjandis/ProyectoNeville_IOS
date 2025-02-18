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
    
    //Mostrar la ventana de FeedBackReview
    @State private var sheetShowFeedBackReview: Bool = false
    
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
                        FrasesModel.shared.AddFrase(frase: text)
                        //Lanza la ventana de FeedBackreview si se alcanza el humbral de hitos
                        if  FeedBackModel.checkReviewRequest() {
                            self.sheetShowFeedBackReview = true
                        }
                        dimiss()
                    }
                }
            }
            .sheet(isPresented: self.$sheetShowFeedBackReview) {
                FeedbackView(showTextBotton: true)
            }
        }
    }
}

#Preview {
    FraseAddView()
}
