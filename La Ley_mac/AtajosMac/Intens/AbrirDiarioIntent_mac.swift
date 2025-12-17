//
//  AbrirDiarioIntent_mac.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//

import AppIntents
import SwiftUI

//Abrir el diario:
struct AbrirDiarioIntentMac: AppIntent {
    static let title: LocalizedStringResource = "Abrir el Diario"
    static  let description =  IntentDescription ( "Abre la vista del Diario" )
    
    static let  openAppWhenRun: Bool = true //Abre la App cuando se invoca el Intent
    
    
    func perform() async throws -> some IntentResult {
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard hasPremium else {
            throw PremiumError.noSubscription
        }

            UserDefaults.standard.set("abrirDiario", forKey: "AtajosMac")
            return .result()
    }
}
