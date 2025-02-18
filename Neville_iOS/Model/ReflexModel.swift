//
//  RefexModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//
//Maneja las operaciones en la tabla Reflex

import Foundation
import CoreData

//Representa una reflexion
struct RefType      : Identifiable{
    let id          : String = UUID().uuidString
    let title       : String
    let content     : String
    let autor       : String
    let isInbuilt   : Bool
    let isfav       : Bool
}


@MainActor
final class ReflexModel : ObservableObject{
    private let context = CoreDataController.shared.context
 
    @Published var list : [RefType] = []
    
    
    static let shared = ReflexModel()
    
    private init(){
        getArrayReflexOfTxtFile()
    }
    

    
    
    
    //Nuevas funciones Yorj:
    

    //Actualiza la variable observable self.list : RefType
    //Crea un arreglo de objetos de tipo RefType que representa las reflexiones en el fichero Reflexiones.txt más las creadas por el usuario.
    func getArrayReflexOfTxtFile(){
        let arrayOFLines = UtilFuncs.FileReadToArray("reflexiones")
        
        self.list.removeAll()
        
        for line in arrayOFLines {
            let component = line.components(separatedBy: "##")
            if component.count == 3 {
                self.list.append(RefType(title: component[0], content: component[1], autor: component[2], isInbuilt: true, isfav: getFavState(title: component[0])))
            }
        }
        //Adicionando también las reflexiones no inbuilt creadas
        self.list.append(contentsOf: getAllReflexNoInbuiltGet())
    }
    
    //Funcion auxiliar: Devuelve un arreglo con las refleciones en el fichero Reflexiones.txt más las que ha creado el usuario
    //componentes de la tupla devuelta: 0:title, 1:contenido, 2:autor
    func getArrayReflexOfTxtFileGET()->[RefType]{
        let arrayOFLines = UtilFuncs.FileReadToArray("reflexiones")
        
        var listtemp : [RefType] = []
        
        for line in arrayOFLines {
            let component = line.components(separatedBy: "##")
            if component.count == 3 {
                listtemp.append(RefType(title: component[0], content: component[1], autor: component[2], isInbuilt: true, isfav: getFavState(title: component[0])))
            }
        }
        //Adicionando también las reflexiones no inbuilt creadas
        listtemp.append(contentsOf: getAllReflexNoInbuiltGet())
        
        return listtemp
    }
    
    
    //Devuelve las reflexiones favoritas
    func getReflexFavoritasGet()->[RefType]{
        
        let listado  =  getArrayReflexOfTxtFileGET()
        var result : [RefType] = []
        
        for item in listado {
            if item.isfav{
                result.append(item)
            }
        }
        
        return result
  
    }
    
    
    //Obtiene las reflexiones no inbuilt (Creadas por el usuario)
    func getAllReflexNoInbuiltGet()->[RefType]{
        let fetchRequest : NSFetchRequest<Reflex> = NSFetchRequest(entityName:  "Reflex")
        fetchRequest.predicate = NSPredicate(format: "isInbuilt == %@", NSNumber(value: false))
        
        do{
            let elements = try context.fetch(fetchRequest)
            return elements.map{ item in
                return RefType(title: item.title ?? "", content: item.texto ?? "", autor: item.autor ?? "", isInbuilt: item.isInbuilt, isfav: item.isfav)
            }
            
        }catch{
            return []
        }
    }
    
    
    //Determina si una reflexion es favorita
    func getFavState(title : String)->Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        fetchRequest.fetchLimit = 1
        do{
            if let item = try context.fetch(fetchRequest).first{
                return item.isfav
            }else{
                return false
            }
            
        }catch{
            return false
        }
    }
    
    //Fija el estado de favorito de una reflexión
    func setFavState(title : String, state : Bool) -> Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        let predicate : NSPredicate = NSPredicate(format: "title == %@", title)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            if let item = try context.fetch(fetchRequest).first{
                item.isfav = state
                try context.save()
                return true
            }else{ //No esta el elemento en la tabla, crearlo con el nuevo estado
                let reflexNew = Reflex(context: context)
                reflexNew.id = UUID().uuidString
                reflexNew.title = title
                reflexNew.isfav = state
                reflexNew.isInbuilt = true
                reflexNew.texto = "" //El texto no es necesario ponerlo en la tabla
                try context.save()
                
                return true
            }
        }catch{
            return false
        }
    }
    
    //Elimina una reflexión de la tabla Reflex. Esta acción solo debe hacerse sobre las reflexiones creadas por el usuario.
    func deleteReflex(title : String)->Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        let predicate : NSPredicate = NSPredicate(format: "title == %@", title)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            if let item = try context.fetch(fetchRequest).first{
                 context.delete(item)
                try context.save()
                return true
            }
        }catch{
            return false
        }
        return false
    }
    
    //Buscar en el contenido de la reflexión
    func searchInContent(text : String)-> [RefType]{
        let listado = getArrayReflexOfTxtFileGET()
        var result : [RefType] = []
        for item in listado{
            if item.content.lowercased().contains(text.lowercased()){
                result.append(item)
            }
        }
        return result
    }
    
    
    //Guardar una reflexión personal
    func savePersonalReflex(title : String, autor : String, texto : String, isfav : Bool)->Bool{
        let newEntity = Reflex(context: self.context)
        
        newEntity.id = UUID().uuidString
        newEntity.autor = autor
        newEntity.title = title
        newEntity.texto = texto
        newEntity.isInbuilt = false
        newEntity.isfav = isfav
        
        do {
            try context.save()
            return true
        }catch{
            context.rollback()
            return false
        }

    }
    
    
    
    //Aux: Elimina los elementos duplicados en Reflex
    //Yor: este método debe ejecutar se solo una vez cuando desde que se instala la App.
    func eliminarDuplicados(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Reflex> = Reflex.fetchRequest()
        
        do {
            let reflexes = try context.fetch(fetchRequest)  // Obtener todos los Reflex
            
            var seenTitles = Set<String>()  // Set para rastrear títulos únicos
            
            for reflex in reflexes {
                if let title = reflex.title {
                    if seenTitles.contains(title) {
                        // Si el título ya está en el conjunto, eliminar duplicado
                        context.delete(reflex)
                    } else {
                        // Agregar título al conjunto
                        seenTitles.insert(title)
                    }
                }
            }
            
            // Guardar cambios en Core Data
            try context.save()
            print("Duplicados eliminados correctamente.")
            
        } catch {
            print("Error al eliminar duplicados: \(error)")
        }
    }
    
    
}


