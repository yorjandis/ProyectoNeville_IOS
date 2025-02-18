//
//  CoreDataController.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/9/23.
//

import Foundation
import CoreData

//Sin iCloudKit habilitado
/*
final class CoreDataController: Sendable {
    
    let persistentContainer: NSPersistentContainer // Ahora solo con Core Data local
    
    static let shared = CoreDataController() // Singleton
    
    // Acceso al contexto de objeto administrado
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Guarda la información. Si falla, descarta cualquier cambio realizado
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                print("Error al guardar en Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    private init() {
        let description = NSPersistentStoreDescription()
        description.url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("ModelData.sqlite")
        
        //__________________________
        
        // Mantener el historial de cambios aunque iCloud ya no esté activo
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        persistentContainer = NSPersistentContainer(name: "ModelData")
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error al cargar el almacén de datos: \(error.localizedDescription)")
            } else {
               // print("Core Data cargado correctamente sin iCloud, pero con historial de cambios.")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }
}
*/


//Con iCloudKit Habilitado:
/*
 Cambios realizados:
 1.    Se usa NSPersistentCloudKitContainer en lugar de NSPersistentContainer
 •    Este contenedor permite la sincronización con iCloud automáticamente.
 2.    Se configura el almacén con iCloudKit
 •    Se añade NSPersistentStoreUbiquitousContainerIdentifierKey con el identificador de iCloud de la app.
 •    Se habilitan NSPersistentHistoryTrackingKey y NSPersistentStoreRemoteChangeNotificationPostOptionKey para el seguimiento de cambios y sincronización.
 3.    Se mantiene la fusión de cambios automática
 •    Esto ayuda a resolver conflictos entre dispositivos.
 */

final class CoreDataController: Sendable {
    
    let persistentContainer: NSPersistentCloudKitContainer
    
    static let shared = CoreDataController()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                print("Error al guardar en Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    private init() {
        persistentContainer = NSPersistentCloudKitContainer(name: "ModelData")
        
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("ModelData.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        
        // Habilitar el historial de cambios y notificaciones remotas
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Configurar la tienda para usar CloudKit sin claves obsoletas
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.ypg.nev.app.icloud")
        
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error al cargar el almacén de datos con iCloud: \(error.localizedDescription)")
            } else {
                print("Core Data con iCloudKit cargado correctamente.")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }
}
