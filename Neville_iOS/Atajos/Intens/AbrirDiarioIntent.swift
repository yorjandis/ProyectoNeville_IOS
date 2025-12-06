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
    
    @AppStorage("abrirDiario" ) var abrirDiario: String = ""
    
    func perform() async throws -> some IntentResult {
        abrirDiario = "abrir"
        return .result()
    }
}

//El parámetro openAppWhenRun puede ser reemplazado por esta versión moderna, la pega es que es para iOS 26.0+
/*
@available(iOS 26.0, *)
static let modosAdmitidos: IntentModes  = .foreground
*/

