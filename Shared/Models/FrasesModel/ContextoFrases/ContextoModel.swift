//
//  ContextoModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/1/26.
//

//Maneja la infromación del contexto de las frases: El campo contexto de Frases
//Nota: El contexto define el tema general al que pertenece una frase

import Foundation
import CoreData
import Combine

@MainActor
final class ContextoModel : ObservableObject{
    
    private let context = CoreDataController.shared.context
    
    @Published var listContextos : [Contexto] = []
    
    //Singleton
    static let shared : ContextoModel = .init()
    
    
    //Get All List Contextos from CoreData
    func getAllContextos(){
        self.listContextos.removeAll()

        //Agregando las frases noInbuit, de la Tabla Frases
        let fetchRequest : NSFetchRequest<Contexto> = NSFetchRequest(entityName: "Contexto")
        do{
            let elements = try self.context.fetch(fetchRequest)
            self.listContextos = elements
            
        }catch{
            
            self.listContextos = []
            msg("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
        }
    }
    
    //Add new Contexto
    func addContexto(newContextoName: String)->Bool{
        let nombre = newContextoName
               .trimmingCharacters(in: .whitespacesAndNewlines)
               .lowercased()

           guard !nombre.isEmpty else { return false }

           // 1️⃣ Verificar si ya existe
           let request: NSFetchRequest<Contexto> = Contexto.fetchRequest()
           request.predicate = NSPredicate(
               format: "nombre =[c] %@",
               nombre
           )
           request.fetchLimit = 1

           do {
               let existe = try context.count(for: request) > 0
               if existe {
                   return false
               }

               // 2️⃣ Crear solo si no existe
               let newContexto = Contexto(context: context)
               newContexto.id = UUID().uuidString
               newContexto.nombre = nombre

               try context.save()
               return true

           } catch {
               print("Error creando Contexto:", error)
               return false
           }
    }
    
    
    //Delete Contexto
    func deleteContexto(contextoDelete: Contexto)->Bool{
        
        do{
            self.context.delete(contextoDelete)
            try self.context.save()
            return true
        }catch{
            return false
        }
    }
    
    //Delete All Contexto
    func DeleteAllContextos()->Bool{
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
                NSFetchRequest(entityName: "Contexto")

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []

                // Sincronizar el contexto en memoria
                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: objectIDs
                ]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [context]
                )

                listContextos.removeAll()
                return true
            } catch {
                print("Error borrando todos los Contextos:", error)
                return false
            }
    }
    
    //Modificar COntexto
    func updateContexto(contextoUpdate: Contexto, newContextoName: String)->Bool{
        contextoUpdate.nombre = newContextoName
        
        do{
            contextoUpdate.nombre = newContextoName
            try self.context.save()
            return true
           
        }catch{
            return false
        }
    }
    
   private init() {
       getAllContextos()
    }
    
    
    
}
