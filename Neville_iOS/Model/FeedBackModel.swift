//
//  FeedBackModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 15/2/25.
//

import SwiftUI
import StoreKit
import UIKit

//Yorj: es importante que este fichero solo se ejecute en el target iOS (NO watchOS)


///Muestra una ventana de review
///
//Permite escribir una reseña de la App
@MainActor func requestReview() {
#if os(macOS)
    SKStoreReviewController.requestReview()
#else
    guard let scene = UIApplication.shared.foregroundActiveScene else { return }
    SKStoreReviewController.requestReview(in: scene)
#endif
}

struct FeedBackModel {

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
    @MainActor static func checkReviewRequest()->Bool{
        
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
