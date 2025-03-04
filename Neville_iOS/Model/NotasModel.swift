//
//  NotasModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 8/11/23.
//

import Foundation
import CoreData

//Manejo de la tabla Notas
struct NotasModel{
    
    /// Establece los campos para búsqueda contenido dentro de las notas
    enum CampoBusqueda{
        case titulo, nota
    }
    
    private var context = CoreDataController.shared.context
    
    ///Obtener la lista de notas
    /// - Returns : Devuelve un arreglo de entity Notas. De lo contrario devuelve un arreglo vacio
    func getAllNotas()->[Notas]{
        let defaultResult = [Notas]()
        
        let fetcRequest : NSFetchRequest<Notas> = Notas.fetchRequest()
        
        do{
            return try  self.context.fetch(fetcRequest)
        }
        catch{
            return defaultResult
        }
        
    }
    
    ///Adicionar una nueva nota:
    /// - Parameter nota : Texto de la nota
    /// - Parameter title : Título  de la nota , por defecto es " "
    /// - Parameter isfav : Campo favorito <true|false>, por defecto `false`
    /// - Returns : devuelve  true si éxito, false si error
    func addNote(nota : String, title : String = "", isFav : Bool = false)->Bool {
        let entity = Notas(context: self.context)
        entity.id = UUID().uuidString
        entity.title = title
        entity.nota = nota
        entity.isfav = isFav
   
        if self.context.hasChanges {
            do {
                try context.save()
                return true
            }catch{
                context.rollback()
                return false
            }
        }
        return true
    }
    
    
    ///Elimina una nota
    /// - Parameter NotaID : Id de la nota a eliminar
    func deleteNota(nota : Notas){
        context.delete(nota)
        try? context.save()
    }
    
    ///Modifica una nota
    ///  - Parameter NotaID : Id de la nota a actualizar
    ///  - Parameter newTitle : Nuevo título de la nota
    ///  - Parameter newNota : Nuevo texto de la nota
    ///  - Parameter isfav : Estado del campo favorito, por defecto false
    ///  - Returns : true si éxito, false otherwise
    func updateNota(NotaID : String, newTitle : String, newNota : String, isfav : Bool = false)->Bool{
        let row = getEntityRow(value: NotaID)
        row.title = newTitle
        row.nota = newNota
        row.isfav = isfav
        do {
            try  self.context.save()
            return true
        }catch{
            return false
        }
        
    }
    
    ///Buscar texto en titulo y en el texto de las notas
    /// - Parameter text : texto a buscar
    /// - Parameter buscarEn: search target: en el campo de nota o en el campo de titulo
    /// - Returns - Devuelve un arreglo de entity Notas
    func searchTextInNotas(text: String, donde buscar: CampoBusqueda)->[Notas]{
      
        let arrayNotas = getAllNotas()
        var result : [Notas] = []
        
        for item in arrayNotas {
            
            switch buscar{
            case .nota:
                let temp = item.nota?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            case .titulo:
                let temp = item.title?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            }
        }
        
        return result
    }
    
    ///Actualizar el estado de favorito
    /// - Parameter NotaID : Id de la nota a actualizar
    /// - Parameter favState : Valor del campo favorito < true | false >
    /// - Returns  : true si éxito, false de otro modo
    func updateFav(NotaID : String, favState : Bool)->Bool{
        let row = getEntityRow(value: NotaID)
        row.isfav = favState
        do{
            try context.save()
            return true
        }catch{
            return false
        }
    
        
        
    }
    
    ///Obtener todas las notas favoritas
    ///  - Returns : Devuelve un arreglo con todas las entity Notas favoritas
    func getFavNotas()->[Notas]{
       let array = getAllNotas()
        var arrayResult = [Notas]()
        
        for item in array {
            if item.isfav == true {
                arrayResult.append(item)
            }
        }
        return arrayResult
        
    }
    
    ///Devuelve un registro en base a un predicado (semajante a utilizar Where en SQL):
    /// - Parameter value : Valor del campo que será tomado como condición
    /// - Parameter fieldId : Campo de la entity que será chequeado (por defecto es `id`)
    /// - Returns Devuelve una instancia de la fila filtrada dentro de la entity
    private func getEntityRow( value : String, fieldId: String = "id")-> Notas{
        
        let predicate = NSPredicate(format: "\(fieldId) = %@", value)
        let fetcRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notas")
        fetcRequest.predicate = predicate
        do{
            let fetchedResults = try context.fetch(fetcRequest) as! [NSManagedObject]
            
            if  let entity = fetchedResults.first as? Notas{
                return  entity
            }
        }catch{
            print(error.localizedDescription)
            
        }
        
        return Notas()
    }
    
}
