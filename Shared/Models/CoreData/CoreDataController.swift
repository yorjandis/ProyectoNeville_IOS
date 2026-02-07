//
//  CoreDataController.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/9/23.
//

import Foundation
import CoreData


final class CoreDataController: Sendable {

    // MARK: - Propiedades
    let persistentContainer: NSPersistentCloudKitContainer

    static let shared = CoreDataController()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Init
    private init() {
        // Inicializa el contenedor con el nombre del modelo
        persistentContainer = NSPersistentCloudKitContainer(name: "ModelData")

        // Configurar la ubicación de la BD
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("ModelData.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)

        // Habilitar historial de cambios y notificaciones remotas
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Configurar CloudKit
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.ypg.nev.app.icloud"
        )

        persistentContainer.persistentStoreDescriptions = [description]

        // Configuraciones del contexto (merge policy)
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }

    // MARK: - Cargar Persistent Stores Async
    func cargarStores() async throws {
        // Cargar persistent stores de forma síncrona
            persistentContainer.loadPersistentStores { description, error in
                if let error = error {
                    fatalError("❌ Error cargando Core Data: \(error)")
                } else {
                    msg("✅ Core Data cargado correctamente")
                }
            }
    }

    // MARK: - Guardar Contexto
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ Error al guardar en Core Data: \(error.localizedDescription)")
            }
        }
    }
}
