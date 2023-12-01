//
//  RefexModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

import Foundation
import CoreData


struct RefexModel {
    private let context = CoreDataController.dC.context
    
    ///Variable que indica si se ha populado la tabla frase (consulta a UserDefault)
   private  var isReflexPopulated : Bool {
        return UserDefaults.standard.bool(forKey: AppCons.UD_isReflexPopulate)
    }
    
    ///Obtiene todos las Entitys:
    /// - Returns -  Devuelve un arreglo de entitys
    func getAllReflex()->[Reflex]{
        
        let defaultResult = [Reflex]()
        
        if isReflexPopulated == false {return defaultResult}
        
            let fetcRequest : NSFetchRequest<Reflex> = Reflex.fetchRequest()
            
            do{
                return try context.fetch(fetcRequest)
            }
            catch{
                return defaultResult
            }
    }
    
    
    ///Popula la tabla Reflex. Las reflexiones inbuilt están contenidas en un fichero txt con siguiente formato: Cada linea contiene una reflexión y se compone de un "titulo"##"Contenido"##"autor". El contenido puede tener
    func populateTableReflex(){
        if isReflexPopulated == true {return} //Sale si la tabla reflex ya esta populada
            
        let arrayReflex = getArrayReflexOfTxtFile() //Obtiene la información en forma de una tupla: title,contenido,autor
 
            //Populando la tabla reflex
            for item in arrayReflex {
                
                let row = Reflex(context: context) //carga entidad Reflex desde el contexto
                row.id = UUID().uuidString
                row.isfav = false
                row.title = item.0
                row.texto = item.1
                row.autor = item.2
                
                try? context.save()  
            }
                
                //almacena una marca que indica que la tabla frase ha sido populada
                UserDefaults.standard.setValue(true, forKey: AppCons.UD_isReflexPopulate)
        
    }
    
    
    ///Adiciona una reflexion NO inBuilt a la tabla Reflex.
    /// - Parameter frase : El texto de la frase a añadir
    func AddReflex(title : String, reflex : String, autor : String, isfav : Bool = false)->Bool{
        let entidad = Reflex(context: context)
        entidad.id = UUID().uuidString
        entidad.title = title
        entidad.texto = reflex
        entidad.autor = autor
        entidad.isfav = isfav
        
        if context.hasChanges {
            do{
                try context.save()
                return true
            }catch{
                return false
            }
        }
        
        return false
    }
    
    
    ///Delete un entity for you ID
    func deleteEntity(id : String)->Bool{  
        let items = getAllReflex()
        for i in items {
            if i.id == id {
                do {
                    context.delete(i)
                    try context.save()
                    return true
                }catch{
                    return false
                }
            }
        }
        
        return false
    }
    
    ///Devuelve una reflexion aleatoria
    /// - Returns : Devuelve una entity Reflex aleatoria
     func getRandonFrase()->Reflex{
         let result = getAllReflex().randomElement() ?? Reflex(context: context)
         return result
    }
    
    ///Elimina todas las filas de la tabla Reflex
    /// - Returns : Devuelve true si la operación ha sido un éxito o false si ha habido un error o la tabla no esta populada. Por defecto es true (éxito)
    func cleanReflex()->Bool{
       var result = true
        
        if isReflexPopulated == false { return false}
        
            let content = getAllReflex()
            
            for row in content{
                context.delete(row)
            }
            
            do {
                try context.save()
            }catch{
                result = false //si existe un error se devuelve false
            }
        
        return result
    }
    
    
    ///Devuelve todas las entradas favoritas
    /// - Returns Devuelve un arreglo de entity Frases
    func GetAllFav()->[Reflex]{
        var result : [Reflex] = []
        
        let array = getAllReflex()
        for item in array {
            if (item.isfav){
                result.append(item)
            }
        }
        return result
    }
    
    
    ///Obtiene el estado de favorito de una Reflexion
    /// - returns : deuelve el valor del capo fav de la reflex actual:  `true` | `false` . Por defecto devuelve `false`
    func getFavState(fraseID : String)->Bool {
        
        let array = getAllReflex()

        for item in array{
            if item.id == fraseID {
                return item.isfav
            }
        }
        return false

    }
    
    ///Establece el estado de favorito
    /// - parameter ReflexID : ID de la reflex que será usado como id de búsqueda
    /// - parameter statusFav : `true` para marca como favorito, `false` para des-marcarlo
    func switchFavState(ReflexID : String)-> Bool{
        let array = getAllReflex()
        
        for item in array{
            if item.id == ReflexID {
                item.isfav = !item.isfav
                do{
                    try context.save()
                    return true
                }catch{
                    context.rollback()
                    return false
                }
            }
        }
        
        return false
    }
    
    
    ///Buscar texto en texto de reflex.
    /// - Parameter text : Texto a buscar dentro de la reflex
    /// - Returns : Devuelve un arreglo de entity Reflex que contienen el texto a buscar
    func searchTextInTextoReflex(text : String)->[Reflex]{
        var arrayResult = [Reflex]()
        
        let arrayReflex = getAllReflex()
        
        for item in arrayReflex {
            let temp = item.texto?.lowercased() ?? ""
            if (temp.contains(text.lowercased())){
                arrayResult.append(item)
            }
        }
        
        return arrayResult
 
    }
    
    ///Buscar texto en título  en reflex.
    /// - Parameter text : Texto a buscar dentro de la reflex
    /// - Returns : Devuelve un arreglo de entity Reflex que contienen el texto a buscar
    func searchTextInTitleReflex(text : String)->[Reflex]{
        var arrayResult = [Reflex]()
        
        let arrayReflex = getAllReflex()
        
        for item in arrayReflex {
            let temp = item.title?.lowercased() ?? ""
            if (temp.contains(text.lowercased())){
                arrayResult.append(item)
            }
        }
        
        return arrayResult
 
    }
    
    
    
    
    //Funcion auxiliar: Devuelve un arreglo de tupla con las reflexiones leidas del txt
    //componentes de la tupla devuelta: 0:title, 1:contenido, 2:autor
    private func getArrayReflexOfTxtFile()->[(String, String, String)]{
        
        var result : [(String, String, String)] = []
        
        let arrayOFLines = UtilFuncs.FileReadToArray("reflexiones")
        
        for line in arrayOFLines {
            let component = line.components(separatedBy: "##")
                if component.count == 3 {
                    result.append((component[0],component[1],component[2]))
                }
            }
        return result
    }
    
    
}


