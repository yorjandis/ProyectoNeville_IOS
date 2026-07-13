//
//  CoreDataController.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/9/23.
//

import Foundation
import CoreData

extension Notification.Name {
    static let coreDataStoresDidLoad = Notification.Name("coreDataStoresDidLoad")
}

@MainActor
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
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        // Habilitar historial de cambios y notificaciones remotas
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        #if os(iOS) || os(macOS)
        // iOS/macOS usan CloudKit como fuente de verdad. watchOS sincroniza a través de iOS.
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.ypg.nev.app.icloud"
        )
        #endif

        persistentContainer.persistentStoreDescriptions = [description]
        
        #if os(macOS)
        //Solo en macOS, carga la BD en el init
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Error cargando Core Data: \(error)")
            }
            NotificationCenter.default.post(name: .coreDataStoresDidLoad, object: nil)
        }

        #endif
        
        

        // Configuraciones del contexto (merge policy)
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
         persistentContainer.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
         
        //Esto evita crashes cuando el contexto intenta acceder a objetos que aún están sincronizándose.
        persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
        
        
    }

    // MARK: - Cargar Persistent Stores Async
    func cargarStores() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            persistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                NotificationCenter.default.post(name: .coreDataStoresDidLoad, object: nil)
                continuation.resume(returning: ())
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
