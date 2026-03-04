//
//  CrearEntradaDiarioIntent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/11/25.
//

import AppIntents
import SwiftUI

//Abrir el diario:
struct AbrirDiarioIntent: AppIntent {
    static let title: LocalizedStringResource = "Abrir el Diario"
    static  let description =  IntentDescription ( "Abre la vista del Diario" )
    static let  openAppWhenRun: Bool = true
    
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    func perform() async throws -> some IntentResult {
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard (hasPremium || yorjPremium) else {
            throw PremiumError.noSubscription
        }
        
        UserDefaults.standard.set("abrirDiario", forKey: "AtajosiOS")
        return .result()
    }
}
