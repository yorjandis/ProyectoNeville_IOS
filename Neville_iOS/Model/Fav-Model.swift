//
//  Fav-Model.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//
//Manejo de la tabla FavTxt
//Para los favoritos de las frases se utiliza `ManageFrases` en CoreDataCRUD.swift

import Foundation
import CoreData

struct FavModel{

        private var context = CoreDataController.dC.context
        
    ///Obtiene la lista de txt favoritas. Si no hay devuelve un []
    /// - Returns - Devuelve un areglo de entity FavTxt
        func getAllFavTxt()->[FavTxt]{
            let defaultResult : [FavTxt] = []
            
            let fetcRequest : NSFetchRequest<FavTxt> = FavTxt.fetchRequest()
            
            do{
                return try context.fetch(fetcRequest)
                
            }
            catch{
                return defaultResult
            }
            
        }
        

    ///Adiciona un nuevo elemento a la BD
    /// - Returns - true si OK, false si error
    func Add(title : String, prefix : String, idvideo : String = "")-> Bool{
            let entity : FavTxt = FavTxt(context: self.context)
            entity.id = UUID().uuidString
            entity.title = title.lowercased()
            entity.prefix = prefix
            entity.idvideo = idvideo
            
            if self.context.hasChanges {
                do{
                    try self.context.save()
                    return true
                }catch{
                    return false
                }
            }
            return false
        }
        
        
    ///Delete Item (quita una referencia de la tabla conferencia) PARA TXT
    /// - Returns -  true ai OK, false si error
    func DeleteTXT(title : String, prefix : String)-> Bool{
            let array : [FavTxt] = getAllFavTxt()
            if array.count == 0 {return false}
            
            for it in array {
                if (it.title == title.lowercased() && it.prefix == prefix){
                    self.context.delete(it)
                    if self.context.hasChanges{
                        try? self.context.save()
                    }
                    
                    return true
                }
            }
            
            return false
        }
    
   
    ///Delete Item (quita una referencia de la tabla conferencia) PARA VIDEOS
    /// - Returns -  true ai OK, false si error
    func DeleteVideos(title : String, idVideo : String)-> Bool{
            let array : [FavTxt] = getAllFavTxt()
            if array.count == 0 {return false}
            
            for it in array {
                if (it.title == title.lowercased() && it.idvideo == idVideo){
                    self.context.delete(it)
                    if self.context.hasChanges{
                        try? self.context.save()
                    }
                    
                    return true
                }
            }
            
            return false
        }
    
    
    
    
    ///Chequea si esta en la tabla FavTxt  (true si esta en la BD) PARA TXT (conf, citas conf, preguntas, ayudas, etc)
    ///
    /// - Parameters - nameFile La propiedad prefix se refiere a la función "getPrefix" de TypeOfContent
    /// - Parameters - prefix  se refiere a la función "getPrefix" de TypeOfContent
    ///
    /// - Returns - true si esta en la BD, false si no esta
    func isFavTxt(title : String, prefix : String)-> Bool{
        let array = getAllFavTxt()
        for item in array{
            if (item.title == title.lowercased() && item.prefix == prefix) {
                return true
            }
        }
        return false
    }
    
    
    ///Chequea si esta en la tabla FavTxt  (true si esta en la BD) PARA VIDEOS ()
    ///
    /// - Parameters - nameFile La propiedad prefix se refiere a la función "getPrefix" de TypeOfContent
    /// - Parameters - prefix  se refiere a la función "getPrefix" de TypeOfContent
    ///
    /// - Returns - true si esta en la BD, false si no esta
    func isFavVideos(title : String, idVideo : String)-> Bool{
        let array = getAllFavTxt()
        for item in array{
            if (item.title == title.lowercased() && item.idvideo == idVideo) {
                return true
            }
        }
        return false
    }
   
}




