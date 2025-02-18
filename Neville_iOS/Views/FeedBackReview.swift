//
//  FeedBackReview.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/2/25.
//

import SwiftUI
import StoreKit
import UIKit

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    let showTextBotton : Bool
    @State private var feedbackText: String = ""
    @State private var isSatisfied: Bool = false
    
    @State private var isReviewComplete : Bool = false
    
    var body: some View {
        VStack{
            Image("Logo")
                .resizable()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .shadow(color: .orange ,radius: 10)
                

                Text("Las enseñansas de neville rebozan de Amor y Verdad!")
                    .padding()
                    .multilineTextAlignment(.center)

            Text("¿Te gusta la app?")
                .font(.headline)
                .padding()
            
          
            Button("Sí, me encanta! 💖") {
                withAnimation {
                    isSatisfied = true
                    
                }
            }
            .buttonStyle(BorderedButtonStyle())
            .padding()

            
            if isSatisfied {
                    Button{
                        requestReview()
                    }label:{
                        Text("Dejar una reseña en la App Store")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 350)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20) // Borde redondeado
                            .shadow(radius: 5) // Sombra opcional
                    }
                    .padding()
                
                Text("Al escribir una reseña ayudas a que más personas puedan disfrutar de estas enseñanzas, gracias por tu apoyo!")
                    .multilineTextAlignment(.center)
                Text("😊")
                    .font(.system(size: 30))
                    .multilineTextAlignment(.center)
                    
                    
            }
            Spacer()
            if self.showTextBotton{
                Button("Ya he escrito una reseña") {
                    UserDefaults.standard.setValue(2, forKey: AppCons.UD_setting_showReview)
                    self.isReviewComplete = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
                .buttonStyle(BorderedButtonStyle())
                .padding()
            }
            

           
        }
        .padding()
        .preferredColorScheme(.dark)
        .alert(isPresented: self.$isReviewComplete){
            Alert(title: Text("La Ley"),
                  message: Text("No se volverá a mostrar esta ventana"),
                  dismissButton: .default(Text("Aceptar")))
        }
    }
}










#Preview {
    FeedbackView(showTextBotton: true)
}
