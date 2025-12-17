//
//  SecurityModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/11/25.
//

//Modelo Obervable que almacena claves del usuario

import SwiftUI
import Combine

@MainActor
final class SecurityModel: ObservableObject {
    
    @Published var canOpenDiario : Bool //Acceso al diario
    @Published var canOpenNotas : Bool //Acceso a las notas
    @Published var canOpenToggleButtonNotas : Bool //Acceso a las áreas protegidas dentro de Ajustes
    @Published var canOpenToggleButtonDiario : Bool //Acceso a las áreas protegidas dentro de Ajustes para el Diario
    
    static let shared = SecurityModel()
    
    private init() {
        self.canOpenNotas = false
        self.canOpenDiario = false
        self.canOpenToggleButtonNotas = false
        self.canOpenToggleButtonDiario = false
    }
   
}
