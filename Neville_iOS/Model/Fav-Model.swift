//
//  Fav-Model.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//
//Manejo de la tabla FavTxt para facvoritos de las conferencias
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
    func Add(nameFile : String, prefix : String)-> Bool{
            let entity : FavTxt = FavTxt(context: self.context)
            entity.id = UUID().uuidString
        entity.namefile = nameFile.lowercased()
            entity.prefix = prefix
            
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
        
        
    ///Delete Item (quita una referencia de la tabla conferencia)
    /// - Returns -  true ai OK, false si error
    func Delete(nameFile : String, prefix : String)-> Bool{
            let array : [FavTxt] = getAllFavTxt()
            if array.count == 0 {return false}
            
            for it in array {
                if (it.namefile == nameFile.lowercased() && it.prefix == prefix){
                    self.context.delete(it)
                    if self.context.hasChanges{
                        try? self.context.save()
                    }
                    
                    return true
                }
            }
            
            return false
        }
    
    
    ///Check if is Favorite (true si esta en la BD)
    /// - Returns - true si esta en la BD, false si no esta
    func isFav(nameFile : String, prefix : String)-> Bool{
        let array = getAllFavTxt()
        for item in array{
            if (item.namefile == nameFile.lowercased() && item.prefix == prefix) {
                return true
            }
        }
        return false
    }
   
}




