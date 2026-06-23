//
//  CrearNotaIntent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 1/12/25.
//

import SwiftUI
import AppIntents

/// `CrearNotaIntent` es un `AppIntent` que permite crear una nueva nota dentro de la aplicación. De menera silenciosa, sin abrir la app.
///
/// Esta estructura implementa `ProvidesDialog` para mostrar un diálogo de confirmación al usuario
/// una vez que la nota ha sido creada exitosamente.
///
/// - Propiedades:
///   - `titulo`: El título de la nota a crear. Debe ser un texto descriptivo y único.
///   - `nota`: El contenido de la nota.
///
/// - Funcionalidad:
///   - Al ejecutar `perform()`, intenta guardar la nota usando `NotasModel().addNote`.
///   - Si la nota se guarda correctamente, muestra un diálogo confirmando la creación.
///   - En caso de fallo, retorna el título de la nota sin mensaje adicional.
///
/// - Ejemplo de uso:
/// ```swift
/// let crearNota = CrearNotaIntent(titulo: "Compra", nota: "Comprar leche y pan")
/// try await crearNota.perform()
/// ```
///
/// - Nota:
///   - Puedes activar la apertura automática de la app cuando se ejecute el intent
///     descomentando `static let openAppWhenRun = true`.
///
struct CrearNotaIntent : AppIntent, ProvidesDialog{
    var value: Never?

    static let title: LocalizedStringResource = "Crear Nota"
    static let description = IntentDescription("Crear una nueva nota")
    //static let openAppWhenRun: Bool = true //Activar esto si deseas que se abra la App
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    @Parameter(title: "Título",description: "El título de la nota")
    var titulo : String
    
    @Parameter(title: "Nota",description: "El contenido de la nota")
    var nota : String

    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        
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

            let entity = Notas(context: context)
            let now = Date()
            entity.id = UUID().uuidString
            entity.title = titulo
            entity.nota = nota
            entity.isfav = false
            entity.setValue("", forKey: "categoria")
            entity.setValue(now, forKey: "fechaCreacion")
            entity.setValue(now, forKey: "fechaModificacion")

            try context.save()
            
           await  CoreDataController.shared.context.refreshAllObjects()

            return .result(
                dialog: IntentDialog("La nota «\(titulo)» ha sido creada correctamente.")
            )

        } catch {

            return .result(
                dialog: IntentDialog("No se pudo guardar la nota.")
            )

        }
        
        
    }

}
