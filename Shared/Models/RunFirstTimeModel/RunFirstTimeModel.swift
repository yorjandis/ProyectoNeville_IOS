//
//  NovedadesModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/12/25.
//

//Permite ejecutar lógica la primera vez que inicia la app.

//Este código debe ser llamado una sola vez, preferiblemente al inicio de la App. Ejemplo:
/*
 en el onApper de WindowsGroup(iOS) o en el inicio de la App en macOS:
 .onAppear {
     switch RunFirstTimeModel.LanzarVentanaNovedades(){
     case "primeraVez":
         //Actualiza las variables iniciales del Lienzo:
         UserDefaults.standard.set(true,forKey: LienzoModel.key_visibilidadTextoSecundario) //Visibilidad de Imagen
         
     case "actualizacion":
         
     default:
         print("No hacer nada")
     }
     
 }
 */
import SwiftUI

enum FirstTimeLaunch {
    case firstLaunchApp
    case updateApp
    case NA
}


@MainActor
struct RunFirstTimeModel{
    static let key_isFirstLaunch = "isFirstLaunch"
    
    static func CheckStatusAppRun() -> FirstTimeLaunch {
        
        let lastVersion = UserDefaults.standard.string(forKey: Self.key_isFirstLaunch)
        
        if lastVersion == nil {
            // Primera vez que se instala
            UserDefaults.standard.set(AppCons.appVersion!, forKey: Self.key_isFirstLaunch) //Almacena la Versión Actual
            return .firstLaunchApp
            
        } else if lastVersion != AppCons.appVersion! {
            // La app se actualizó
            UserDefaults.standard.set(AppCons.appVersion!, forKey: Self.key_isFirstLaunch) //Almacena la Versión Actual
            
            return .updateApp
        }else{
            //Estado indeterminado
            return .NA
        }
        
    }
}
