//
//  CrearEntradaDiarioIntent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//


import SwiftUI
import AppIntents

//Permite crear una entrada segura al Diario, Se le pedirá la contraseña del sistema.
struct CrearEntradaDiarioIntentMac
: AppIntent, ProvidesDialog{
    var value: Never?

    static let title: LocalizedStringResource = "Crear Entrada Diario"
    static let description = IntentDescription("Crea una nueva entrada en el Diario")
    //static let openAppWhenRun: Bool = true //Activar esto si deseas que se abra la App
    
    static let requiresAuthentication: Bool = true
    
    @Parameter(title: "Contraseña", description: "La palabra clave para el diario")
    var password: String
    
    @Parameter(title: "Título",description: "El título de la entrada del Diario")
    var titulo : String
    
    @Parameter(title: "Contenido",description: "El contenido de la entrada del Diario")
    var contenido : String

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog{
        
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        guard hasPremium else {
            throw PremiumError.noSubscription
        }
        
            //Validar la palabra clave
        if let pass = await KeychainHelper.shared.getPassword(){
            if pass.lowercased() == password.lowercased(){
                if  await DiarioModel.shared.addItem(title: titulo, emocion: .neutral, content: contenido) {
                    return .result(value: titulo, dialog: IntentDialog("La entrada ha sido añadida al Diario."))
                }else{
                    return .result(value: titulo, dialog: IntentDialog("Ha habido un problema al guadar la entrada del Diario. Inténtelo más tarde."))
                }
            }else{
                return .result(value: titulo, dialog: IntentDialog("La contraseña no es correcta"))
            }
        }else{
            return .result(value: titulo, dialog: IntentDialog("No se ha podido obtener la contraseña."))
        }
    }

}
