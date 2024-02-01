//
//  CoreDataController.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/9/23.
//

import Foundation
import CoreData

final class CoreDataController : Sendable {
    
    let persistenContainer : NSPersistentContainer
    
    static let shared = CoreDataController() //Singleton
    
    //Acceso al contexto de objeto administrado
    var context : NSManagedObjectContext {
        return persistenContainer.viewContext
    }
    
    //Salva la información. Si falla descarta cualquier cambio realizado
    func save(){
        if context.hasChanges {
            do {
                try context.save()
            }catch{
                context.rollback()
                print(error.localizedDescription)
            }
        }
    }
    
   private init(){

        persistenContainer = NSPersistentContainer(name: "ModelData")
        persistenContainer.loadPersistentStores{(description, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
        }
        
        
    }
    
}
