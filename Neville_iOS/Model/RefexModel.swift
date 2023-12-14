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
    
    
    
    //Conjuntos de predicados comunes
    struct PredicatesTypes{
        let  getAllFavorites: NSPredicate       = NSPredicate(format: "%K == %@", #keyPath(Reflex.isfav), NSNumber(value: true))
        let  getAllNews: NSPredicate            = NSPredicate(format: "%K != %@", #keyPath(Reflex.isnew), NSNumber(value: true))
    }
    
    ///Realiza consultas a la BD
    /// - Parameter - type: define el tipo de contenido a consultar
    /// - Parameter - predicate: define el predicado a utilizar para filtrar la consulta. Si es nil devuelve todos los elementos
    ///  - Returns - Devuelve un arreglo de elementos de cierto tipo. Si falla la cosulta se devuelve un arreglo vacio
    func GetRequest(predicate : NSPredicate?)->[Reflex]{
        
        let fecthRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        
        if let tt = predicate {
            fecthRequest.predicate = tt
        }
  
        do {
            return try context.fetch(fecthRequest)
        }catch{
            print(error.localizedDescription)
            return []
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
                row.isInbuilt = true
               
            }
        if context.hasChanges {
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
        entidad.isInbuilt = false
        
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
    
    
    ///Modificar una reflexión
    func EditReflex(reflex : Reflex, title: String, autor: String, texto: String)->Bool{
        var result = false
        reflex.title = title
        reflex.autor = autor
        reflex.texto = texto
        
        if context.hasChanges {
            do{
                try context.save()
                result = true
            }catch{
                result = false
            }
            
        }
        return result
        
    }
    
    
    ///Delete un entity for you ID
    func deleteEntity(reflex : Reflex)->Bool{
        do {
            context.delete(reflex)
            try context.save()
            return true
        }catch{
            return false
        }
    }
    
    
    ///Elimina todas las filas de la tabla Reflex
    /// - Returns : Devuelve true si la operación ha sido un éxito o false si ha habido un error o la tabla no esta populada. Por defecto es true (éxito)
    func cleanReflex()->Bool{
       var result = true
        
        if isReflexPopulated == false { return false}
        
            let arrayReflex = GetRequest(predicate: nil)
            
            for row in arrayReflex{
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
        return GetRequest(predicate: PredicatesTypes().getAllFavorites)
    }
    
    
    ///Obtiene el estado de favorito de una Reflexion
    /// - returns : deuelve el valor del capo fav de la reflex actual:  `true` | `false` . Por defecto devuelve `false`
    func getFavState(reflex : Reflex?)->Bool {
        if let tt = reflex {
            return tt.isfav
        }else{
            return false
        }
        
    }
    
    ///Establece el estado de favorito
    /// - parameter reflex : la instancia de reflex a modificar
    /// - Returns -  Devuelve true si exito, false si se ha pasado una instancia nil
    func handleFavState(reflex : Reflex?)-> Bool{
        if let tt = reflex {
            var temp = tt.isfav
            temp.toggle()
            tt.isfav = temp
            try? context.save()
            return true
        }
        
        return false
    }
    
    
    ///Buscar texto en texto de reflex.
    /// - Parameter text : Texto a buscar dentro de la reflex
    /// - Returns : Devuelve un arreglo de entity Reflex que contienen el texto a buscar
    func searchTextInTextoReflex(text : String)->[Reflex]{
        var arrayResult = [Reflex]()
        
        let arrayReflex = GetRequest(predicate: nil)
        
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
        
        let arrayReflex = GetRequest(predicate: nil)
        
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
    
    
    
    //-----------------------------------------  FUNCIONES PARA LOS NUEVOS ITEMS AÑADIDOS ---------------------------------
    
    
    ///Funcion que actualiza la info cuando se adiciona nuevas reflexiones  al bundle en una nueva actualización
    /// - Returns : Devuelve una tupla de dos enteros: el primero es el # de elementos que se han añadido, el segundo el # de elementos que han fallado al insertarse
    func UpdateContenAfterAppUpdate()->(Int,Int){
        
        var set : Set<String> = Set()
        var errorCount = 0 //cuanta los elementos fallidos que no se han podido adicionar a la BD
        var exitoCount = 0 //cuanta los elementos exitosos que no se han podido adicionar a la BD
        
        //Volcar todos los nombres de conferencias de la BD a un set.
        let arrayBdReflex = self.GetRequest(predicate: nil)
        
        if arrayBdReflex.isEmpty { return (0,0) } //Manejo de errores
        
        for i in arrayBdReflex {
            set.insert(i.title ?? "" )
        }
        
       // print("Cantidad antes de actualizar: \(set.count)")
        
        
        //Obtengo todas los nombres de conferencias del bundle e intento actualizar el set, los que se inserten representan los nuevos elementos
        //Luego inserto esos nuevos elementos a la BD.
        let reflex = self.getArrayReflexOfTxtFile()
        
        if reflex.isEmpty { return (0,0) } //Manejo de errores
        
        
        for i in reflex {
            let result = set.insert(i.0)
            if result.0 {
               //Actualizando la BD
                do {
                    let item = Reflex(context: self.context)
                    item.id = UUID().uuidString
                    item.title = i.0
                    item.texto = i.1
                    item.autor = i.2
                    item.isInbuilt = true
                    item.isfav = false
                    item.isnew = true
                    try context.save()
                    exitoCount += 1
                }catch{
                    errorCount += 1 //Cuenta los elementos que no se han actualziado
                }
                
                
            }
            
        }
        
       // print("Cantidad después de actualizar: \(set.count)")
        
  
        return (exitoCount, errorCount)
        
    }
    
    
    
    ///Pone el campo isnew a false. La modificación se hace inline, sobre el parámetro pasado
    /// - Parameter - entity : el registro a modificar
    func RemoveNewFlag( entity : inout Reflex){
            entity.isnew = false
            try?  entity.managedObjectContext?.save()
    }
    
    
    ///Pone el campo isnew a false de todas las reflexiones nuevas
    func RemoveAllNewFlag(){
        let array = GetRequest(predicate: nil)
        for i in array{
            i.isnew = false
            try? i.managedObjectContext?.save()
        }
    }
    
    
    ///Lista todos los elementos recientemente adicionado: isnew:true
    /// - Returns - Devuelve un arreglo con todos las reflexiones  añadidas recientemente
    func getAllNewsElements()->[Reflex]{
        var result : [Reflex] = []
        let array = GetRequest(predicate: nil)
        for i in array{
            if i.isnew {
                result.append(i)
            }
        }
        return result
    }
    
    
}

