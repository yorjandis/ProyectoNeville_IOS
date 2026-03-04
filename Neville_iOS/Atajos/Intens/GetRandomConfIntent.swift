//
//  GetRandomConfIntent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//

import AppIntents
import SwiftUI

//Abrir el diario:
struct GetRandomConfIntent: AppIntent {
    static let title: LocalizedStringResource = "Abrir Conferencia Aleatoria"
    static  let description =  IntentDescription ( "Abre la app en una conferencia aleatoria" )
    
    static let  openAppWhenRun: Bool = true //Abre la App cuando se invoca el Intent
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    func perform() async throws -> some IntentResult {
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard (hasPremium || self.yorjPremium) else {
            throw PremiumError.noSubscription
        }
        
        
        UserDefaults.standard.set("abrirRamdonConf", forKey: "AtajosiOS")
        return .result()
    }
}

