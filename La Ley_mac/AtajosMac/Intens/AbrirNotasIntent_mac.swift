//
//  AbrirNotasIntent_mac.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//

import AppIntents
import SwiftUI

//Abrir Notas
struct AbrirNotasItentMac : AppIntent {
    static let title: LocalizedStringResource = "Abrir Notas"
    static let description = IntentDescription("Abre el listado de las notas")
    
    static let openAppWhenRun: Bool = true
    
   
    func perform() async throws -> some IntentResult {
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard hasPremium else {
            throw PremiumError.noSubscription
        }
        
        UserDefaults.standard.set("abrirNotas", forKey: "AtajosMac")
        return .result()
    }
    
}
