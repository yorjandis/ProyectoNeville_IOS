//
//  CrearFraseIntent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 1/12/25.
//
import SwiftUI
import AppIntents

//Crea una frase de manera silenciosa, sin abrir la app.
struct CrearFraseIntent : AppIntent, ProvidesDialog{
    var value: Never?

    static let title: LocalizedStringResource = "Crear Frase"
    static let description = IntentDescription("Crear una nueva frase")
    //static let openAppWhenRun: Bool = true //Activar esto si deseas que se abra la App
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    @Parameter(title: "frase",description: "El contenido de la frase")
    var frase : String
    
    @Parameter(title: "autor",description: "El autor de la frase")
    var autor : String


    func perform() async throws -> some IntentResult & ProvidesDialog{
        
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


        
        do {

            let entidad = Frases(context: context)
            entidad.id = UUID().uuidString
            entidad.frase = frase
            entidad.isfav = false
            entidad.noinbuilt = true //Se marca como una frase NO inbuilt
            entidad.nota = ""
            entidad.autor = autor

            try context.save()

            return .result(
                dialog: IntentDialog("La frase ha sido creada correctamente.")
            )

        } catch {

            return .result(
                dialog: IntentDialog("No se pudo guardar la frase, intentelo más tarde.")
            )

        }
        
        /*
         // Guarda la nota:
         if await FrasesModel.shared.AddFrase(frase: frase, autor: autor){
             return .result(
                 value: frase,
                 dialog: IntentDialog("La frase ha sido creada correctamente.")
             )
         }else{
             return .result(value: frase, dialog: IntentDialog("Ha habido un problema al guadar la frase. Inténtelo más tarde."))
                 
         }
         */
        
    }

}
