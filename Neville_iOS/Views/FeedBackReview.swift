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


///Muestra una ventana de review
///
//Permite escribir una reseña de la App
func requestReview() {
#if os(macOS)
    SKStoreReviewController.requestReview()
#else
    guard let scene = UIApplication.shared.foregroundActiveScene else { return }
    SKStoreReviewController.requestReview(in: scene)
#endif
}


//Función que maneja el estado del contador de review e indica si se puede lanzar la ventana
/*de review
Chequea si el contador a llegado al humbral:
Se considera un valor de umbral si el contador llega a 40 hitos
Un hito, se produce cuando:
 abrimos una conferencia
 añadimos una frase
 añadimos una nota
 añadimos una entrada del diario
 */
func checkReviewRequest()->Bool{
    
    let umbral : Int = 40 //El umbral para lanzar la ventana de review al usuario
    
    //Chequea si hay que mostrar la ventana de review, si no hay que mostrarla: termina
    let isReviewActive = UserDefaults.standard.integer(forKey: AppCons.UD_setting_showReview)
    if isReviewActive == 2 {
        return false
    }
    
    
    let count = UserDefaults.standard.integer(forKey: AppCons.UD_setting_ReviewCounter)
    if count == umbral {
        //Resetea el contador
        UserDefaults.standard.set(0, forKey: AppCons.UD_setting_ReviewCounter)
        return true
    }else{
        //Aumenta el contador
        UserDefaults.standard.set(count+1, forKey: AppCons.UD_setting_ReviewCounter)
        //print("Yorj contador en : \(UserDefaults.standard.integer(forKey: AppCons.UD_setting_ReviewCounter))")
        return false
    }

}





#if os(iOS)
//Devuelve la escena activa en runtime
extension UIApplication {
    var foregroundActiveScene: UIWindowScene? {
        connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}
#endif




#Preview {
    FeedbackView(showTextBotton: true)
}
