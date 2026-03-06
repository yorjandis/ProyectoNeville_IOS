//
//  CrearEntradaDiario.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/12/25.
//

import SwiftUI
import AppIntents

//Permite crear una entrada segura al Diario, Se le pedirá la contraseña del sistema.
struct CrearEntradaDiarioIntent : AppIntent, ProvidesDialog{
    var value: Never?

    static let title: LocalizedStringResource = "Crear Entrada Diario"
    static let description = IntentDescription("Crea una nueva entrada en el Diario")
    //static let openAppWhenRun: Bool = true //Activar esto si deseas que se abra la App
    
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    @Parameter(title: "Contraseña", description: "La palabra clave para el diario")
    var password: String
    
    @Parameter(title: "Título",description: "El título de la entrada del Diario")
    var titulo : String
    
    @Parameter(title: "Contenido",description: "El contenido de la entrada del Diario")
    var contenido : String

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog{
        //Validar estado de premium
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        
        
         
           guard (hasPremium || self.yorjPremium) else {
               throw PremiumError.noSubscription
           }

        
        //Comprobando que no se haya ya la BD... Porque si la App esta abierta la BD ya se ha cargado y da problemas
        let coordinator = await CoreDataController.shared
            .persistentContainer
            .persistentStoreCoordinator

        if coordinator.persistentStores.isEmpty {
            try await CoreDataController.shared.cargarStores()
        }
        
        let context = await CoreDataController.shared.persistentContainer.newBackgroundContext()
        
        
            //Validar la palabra clave
        if let pass = await KeychainHelper.shared.getPassword(){
            if pass.lowercased() == password.lowercased(){
                
                let diario : Diario = Diario(context: context)
                diario.id = UUID()
                diario.title = titulo
                diario.emotion = "neutral"
                diario.isFav = false
                diario.content = contenido
                diario.fecha = Date.now
                diario.fechaM = Date.now
                
                try context.save()
                
                return .result(value: titulo, dialog: IntentDialog("Se ha creado la entrada en el diario."))
                
            }else{
                return .result(value: titulo, dialog: IntentDialog("La contraseña no es correcta."))
            }
        }else{
            return .result(value: titulo, dialog: IntentDialog("No se ha podido obtener la contraseña."))
        }
    }

}
