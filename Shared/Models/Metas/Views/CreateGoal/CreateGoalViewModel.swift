//
//  CreateGoalViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI
import Combine

@MainActor
final class CreateGoalViewModel: ObservableObject {

    @Published var title: String            = ""        //Título de la meta
    @Published var description: String      = ""        //Campo Descripción de la meta
    @Published var note: String             = ""        //Campo Nota de la Meta
    @Published var amount: Int              = 21        //Cantidad de Unidades por defecto
    @Published var unit: TimeUnit           = .dias     //Unidad de tiempo por defecto
    @Published var frequency: Int           = 1         //Frecuencia por defecto
    @Published var unidadesInfo : [UnidadesInfo] = []     // Información de unidades de Metas
    

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }
    
    func getTextoForUNidades(number : Int) -> String {
        return number == 1 ? "unidad" : "unidades"
    }
    
    
    static let shared = CreateGoalViewModel()
    
    private init() {}
}

