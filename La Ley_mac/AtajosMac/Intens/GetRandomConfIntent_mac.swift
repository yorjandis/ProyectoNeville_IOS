//
//  GetRandomConfIntent_mac.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//

//Abre la App en una conferencia Aleatoria:

import AppIntents
import SwiftUI

//Abrir el diario:
struct GetRandomConfIntentMac: AppIntent {
    static let title: LocalizedStringResource = "Abrir Conferencia Aleatoria"
    static  let description =  IntentDescription ( "Abre la app en una conferencia aleatoria" )
    
    static let  openAppWhenRun: Bool = true //Abre la App cuando se invoca el Intent
    
    
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("abrirRamdonConf", forKey: "AtajosMac")
        return .result()
    }
}

//El parámetro openAppWhenRun puede ser reemplazado por esta versión moderna, la pega es que es para iOS 26.0+
/*
@available(iOS 26.0, *)
static let modosAdmitidos: IntentModes  = .foreground
*/
