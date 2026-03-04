//
//  AbrirNotasItent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 1/12/25.
//
import AppIntents
import SwiftUI

//Abrir Notas
struct AbrirNotasItent : AppIntent {
    static let title: LocalizedStringResource = "Abrir Notas"
    static let description = IntentDescription("Abre el listado de las notas")
    static let openAppWhenRun: Bool = true
    
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    func perform() async throws -> some IntentResult {
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard (hasPremium || self.yorjPremium) else {
            throw PremiumError.noSubscription
        }
        
        
        UserDefaults.standard.set("abrirNotas", forKey: "AtajosiOS")
        return .result()
    }
    
}

