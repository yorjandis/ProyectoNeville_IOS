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
    
    @AppStorage("abrirNotas" ) var abrirNotas: String = ""
    
    func perform() async throws -> some IntentResult {
        abrirNotas = "abrir"
        return .result()
    }
    
}

