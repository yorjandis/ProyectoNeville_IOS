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
    @Published var canOpenToggleButton : Bool //Acceso a las áreas protegidas dentro de Ajustes
    
    static let shared = SecurityModel()
    
    private init() {
        self.canOpenNotas = false
        self.canOpenDiario = false
        self.canOpenToggleButton = false
    }
   
}
