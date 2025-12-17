//
//  NovedadesModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/12/25.
//

//Comprueba si es la primera vez que se ejecuta la app
import SwiftUI



@MainActor
struct NovedadesModel{
    static let key_isFirstLaunch = "isFirstLaunch"
    
    static func LanzarVentanaNovedades() -> String {
        
        let lastVersion = UserDefaults.standard.string(forKey: Self.key_isFirstLaunch)
        
        if lastVersion == nil {
            // Primera vez que se instala
            UserDefaults.standard.set(AppCons.appVersion!, forKey: Self.key_isFirstLaunch) //Almacena la Versión Actual
            return "primeraVez"
        } else if lastVersion != AppCons.appVersion! {
            // La app se actualizó
            UserDefaults.standard.set(AppCons.appVersion!, forKey: Self.key_isFirstLaunch)
            return "actualizacion"
        } else {
            // No es primera instalación ni actualización
            return "NA"
        }
        
    }
}
