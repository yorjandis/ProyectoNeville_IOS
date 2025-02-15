//
//  CoreDataController.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/9/23.
//

import Foundation
import CoreData

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
