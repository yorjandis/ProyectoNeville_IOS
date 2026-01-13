//
//  CrearFrasesIntent_mac.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//

import SwiftUI
import AppIntents

//Crea una frase de manera silenciosa, sin abrir la app.
struct CrearFraseIntentMac : AppIntent, ProvidesDialog{
    var value: Never?

    static let title: LocalizedStringResource = "Crear Frase"
    static let description = IntentDescription("Crear una nueva frase")
    //static let openAppWhenRun: Bool = true //Activar esto si deseas que se abra la App
    
    @Parameter(title: "frase",description: "El contenido de la frase")
    var frase : String
    
    @Parameter(title: "autor",description: "El autor de la frase")
    var autor : String


    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog{
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard hasPremium else {
            throw PremiumError.noSubscription
        }
        
        // Guarda la nota:
        if await FrasesModel.shared.AddFrase(frase: frase, autor: autor){
            return .result(
                value: frase,
                dialog: IntentDialog("La frase ha sido creada correctamente.")
            )
        }else{
            return .result(value: frase, dialog: IntentDialog("Ha habido un problema al guadar la frase. Inténtelo más tarde."))
                
        }
    }

}
