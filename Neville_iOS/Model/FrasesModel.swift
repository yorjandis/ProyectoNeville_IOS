//
//  FrasesModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 8/11/23.
//
//Operaciones sobre Frases

import Foundation
import CoreData
import SwiftUI

//Manejo de la tabla frases
struct FrasesModel {
    
    ///Obtiene el contexto de Objetos administrados
    private var context = CoreDataController.dC.context
 
    ///Almacena el Id de la frase actualmente cargada. Se actualiza en: getRandomFrase()
    static var idFraseActual : String = ""
    
    ///Variable que indica si se ha populado la tabla frase (consulta a UserDefault)
   private  var isFrasesPopulated : Bool {
        return UserDefaults.standard.bool(forKey: AppCons.UD_isfrasesLoaded)
    }
    
    
    
    //Conjuntos de predicados comunes
    struct PredicatesTypes{
        var getAllFavorites: NSPredicate{
            NSPredicate(format: "%K == %@", #keyPath(Frases.isfav), NSNumber(value: true))
        }
        var getAllNotas: NSPredicate{
            NSPredicate(format: "%K != %@", #keyPath(Frases.nota), "")
        }
        var getAllNews: NSPredicate{
            NSPredicate(format: "%K != %@", #keyPath(Frases.isnew), NSNumber(value: true))
        }
        var getAllPersonalFrases: NSPredicate{
            NSPredicate(format: "%K == %@", #keyPath(Frases.noinbuilt), NSNumber(value: true))
        }
        
        
    }
    
    
    ///Realiza consultas a la BD
    /// - Parameter - type: define el tipo de contenido a consultar
    /// - Parameter - predicate: define el predicado a utilizar para filtrar la consulta. Si es nil devuelve todos los elementos
    ///  - Returns - Devuelve un arreglo de elementos de cierto tipo. Si falla la cosulta se devuelve un arreglo vacio
    func GetRequest(predicate : NSPredicate?)->[Frases]{
        
        let fecthRequest = NSFetchRequest<Frases>(entityName: "Frases")
        
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

  
    
    ///Obtiene la lista de frases del fichero txt in-built:
    /// - Returns: Devuelve un  arreglo de cadenas con las frases cargadas del txt en Staff
     func getfrasesArrayFromTxtFile() ->[String] {
        var array = [String]()
        
        array = UtilFuncs.FileReadToArray(AppCons.FileListFrases)
        
        return array
        
    }
    
    ///Adiciona una frase Personal NO inBuilt a la tabla Frases.
    /// - Parameter frase : El texto de la frase a añadir
    func AddFrase(frase : String){
        let entidad = Frases(context: context)
        entidad.id = UUID().uuidString
        entidad.frase = frase
        entidad.isfav = false
        entidad.noinbuilt = true
        entidad.nota = ""
        
        if context.hasChanges {
            do{
                try context.save()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    ///Devuelve un arreglo con todas las frases NO inBuilt. Útil para funciones de filtrado
    func getFrasesNoInbuilt()->[Frases]{
        return GetRequest(predicate: PredicatesTypes().getAllPersonalFrases)
    }


    
    ///Obtiene una frase aleatoria
    ///Aqui se actualiza el ID de la frase actualmente cargada para fines de búsqueda dentro de la tabla Frases. Al inicio,  se intenta popular la tabla Frases si esta marcada como NO populada(false).
    /// - Returns Devuelve el texto de la frase. Actualiza la static var idFraseActual con el id de la frase devuelta. Si falla devuelve una frase vacia
    func getRandomFrase()->String {
        let arrayFrases = GetRequest(predicate: nil)
        if arrayFrases.count > 0 {
            return arrayFrases.randomElement()?.frase ?? ""
        }else{
            return ""
        }
        
    }

    
    ///Obtiene una entity aleatoria de Frase
    ///Aqui se actualiza el ID de la frase actualmente cargada para fines de búsqueda dentro de la tabla Frases. Al inicio,  se intenta popular la tabla Frases si esta marcada como NO populada(false).
    /// - Returns Devuelve la entity frase.
    func getRandomFraseEntity()->Frases?{
        let arrayFrases = GetRequest(predicate: nil)
        if arrayFrases.count > 0 {
            return arrayFrases.randomElement()!
        }else{
            return nil
        }
 
    }
    
    ///Popula la tabla Frases al inicio de la app (ojo: esto borrará todas las notas y marcas de fav en la tabla)
    ///Es llamado solo una vez al iniciar la app por primera vez. Carga todos los datos de la tabla Frases y actualiza el el estado de la carga de la tabla Frases
    func populateTableFrases(){

        if isFrasesPopulated {return} //Sale si la tabla frases ya esta populada
            
            let arrayFrases = getfrasesArrayFromTxtFile() //Obtiene el arreglo de frases del txt
 
            //Populando la tabla frases
            for item in arrayFrases {
                let row = Frases(context: context) //carga entidad Frases desde el contexto
                row.id    = UUID().uuidString
                row.frase = item
                row.isfav = false
                row.nota  = ""
                row.noinbuilt = false
            }
        
        if context.hasChanges {
            try? context.save()
        }
                
                //almacena una marca que indica que la tabla frase ha sido populada
                UserDefaults.standard.setValue(true, forKey: AppCons.UD_isfrasesLoaded)
     
    }
    
   
    ///Elimina todas las filas de la tabla Frases
    /// - Returns : Devuelve true si la operación ha sido un éxito o false si ha habido un error o la tabla no esta populada. Por defecto es true (éxito)
    func cleanFrases()->Bool{
       var result = true
        
        if isFrasesPopulated == false { return false}
        
            let content = GetRequest(predicate: nil)
            
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
 
    
    ///Obtiene el estado de favorito de una frase
    /// - returns : deuelve el valor del capo fav de la frase actual:  `true` | `false` . Por defecto devuelve `false`
    func getFavState(frase : Frases)->Bool {
        return  frase.isfav
    }
    
    //Hace un toggle al estado de favorito de una frase
    func handleFavState(frase : Frases?){
        if let tt = frase {
            var yy = tt.isfav
            yy.toggle()
            tt.isfav = yy
            try? frase?.managedObjectContext?.save()
        }
        
    }
    
    ///Chequea si una frase tiene Nota asociada
    /// - returns : deuelve el valor del capo fav de la frase actual:  `true` | `false` . Por defecto devuelve `false`
    func getNoteState(fraseID : String)->Bool {
        let array = GetRequest(predicate: nil)

        for item in array{
            if item.id == fraseID {
                let nota = item.nota ?? ""
                if nota.isEmpty {
                    return true
                }else{
                    return false
                }
            }
        }

        return false

    }
    
    
    ///Establece el estado de favorito
    /// - parameter fraseID : ID de la frase que será usado como id de búsqueda
    /// - parameter statusFav : `true` para marca como favorito, `false` para des-marcarlo
    func updateFavState(fraseID : String, statusFav : Bool)-> Bool{
        let array = GetRequest(predicate: nil)
        
        for item in array{
            if item.id == fraseID {
                item.isfav = statusFav
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
    
    ///Actualizar nota asociada
    /// - Returns : Devuelve true si éxito; false de otro modo
    func UpdateNotaAsociada(fraseID : String, notaAsociada : String = "")->Bool{
        
        let array = GetRequest(predicate: nil)
        for frase in array{
            if frase.id == fraseID {
                frase.nota = notaAsociada
                if context.hasChanges {
                    do{
                        try context.save()
                        return true
                    }catch{
                        return false
                    }
                    
                }
            }
        }

        return false
    }

    ///Buscar texto en frases.
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de entity Frases que contienen el texto a buscar
    func searchTextInFrases(text : String)->[Frases]{
        var arrayResult = [Frases]()
        
        let arrayFrases = GetRequest(predicate: nil)
        
        for item in arrayFrases {
            let temp = item.frase?.lowercased() ?? ""
            if (temp.contains(text.lowercased())){
                arrayResult.append(item)
            }
        }
        
        return arrayResult
 
    }
    
    
    ///Buscar texto en el campo nota de una frase
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de entity Frases que contienen el texto a buscar
    func searchTextInNotaFrases(textNota : String)->[Frases]{
        var arrayResult = [Frases]()
        
        let arrayFrases = GetRequest(predicate: nil)
        
        for item in arrayFrases {
            let temp = item.nota?.lowercased() ?? ""
            if (temp.contains(textNota.lowercased())){
                arrayResult.append(item)
            }
        }
        
        return arrayResult
 
    }
    
    
    
    ///Obtiene todas las frases favoritas
    ///Obtener todas las notas favoritas
    ///  - Returns : Devuelve un arreglo con todas las entity Frases favoritas
    func getAllFavFrases()->[Frases]{
        
        let array = GetRequest(predicate: nil)
        var arrayResult = [Frases]()
        
        for item in array {
            if item.isfav {
                arrayResult.append(item)
            }
        }
        
        return arrayResult
        
    }
    
    ///Devuelve un registro en base a un predicado (semajante a utilizar Where en SQL):
    /// - Parameter value : Valor del campo que será tomado como condición
    /// - Parameter fieldId : Campo de la entity que será chequeado (por defecto es `id`)
    /// - Returns Devuelve una instancia de la fila filtrada dentro de la entity
     func getEntityRow( value : String, fieldId: String = "id")-> Frases{
         
        let predicate = NSPredicate(format: "\(fieldId) = %@", value)
        let fetcRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Frases")
        fetcRequest.predicate = predicate
        do{
            let fetchedResults = try context.fetch(fetcRequest) as! [NSManagedObject]
            
            if  let entity = fetchedResults.first as? Frases{
                return  entity
            }
        }catch{
            print(error.localizedDescription)
              
        }
        
         return Frases()
    }
    
    
    ///Devuelve un arreglo de entity Frases con las frases que contienen notas
    ///
    /// - Returns - Devuelve un arreglo de tipo [Frases]
    ///
    //Lista todas las frases que tienen notas
     func getAllNotasFrases()->[Frases]{
        var result : [Frases] = []
        
        let array = FrasesModel().GetRequest(predicate: nil)
        
        for frase in array {
            if frase.nota ?? "" != "" {
                result.append(frase)
            }
        }
 
        return result
    }
    
    
    ///Delete frase: Solo las frases personales se pueden eliminar
    func Delete(frase : Frases){
        if frase.noinbuilt {
            context.delete(frase)
            try? context.save()
        }
    }
    
    ///Delete frase: Solo las frases personales se pueden eliminar
    func Update(frase : Frases, fraseStr : String, nota : String){
        if frase.noinbuilt {
            frase.frase  = fraseStr
            frase.nota = nota
            try? context.save()
        }
    }
    
    ///Devuelve una entity Frase de  acuerdo al texto de la frase
    /// - Parameter -  frase : el texto de la frase a filtrar
    ///  - Return - Devuelve una entity Frase? que corresponde con la frase filtrada, de lo contrario devuelve una frase aleatoria
    func GetFraseFromTextFrase(frase : String)->Frases?{
        let array = GetRequest(predicate: nil)
        
        for i in array{
            
            if i.frase == frase {
                return i
            }
        }
        return getRandomFraseEntity()
    }
    
    
    
    ///Actualiza la BD cuando se adiciona nuevas frases al bundle en una nueva actualización
    /// - Returns : Devuelve una tupla de dos enteros: el primero es el # de elementos que se han añadido, el segundo el # de elementos que han fallado al insertarse
    func UpdateContenAfterAppUpdate()->(Int, Int){
        
        var set : Set<String> = Set()
        var errorCount = 0 //cuanta los elementos fallidos que no se han podido adicionar a la BD
        var exitoCount = 0 //cuanta los elementos exitosos que no se han podido adicionar a la BD
        
        //Volcar todos los nombres de conferencias de la BD a un set.
        let arrayBdFrases = self.GetRequest(predicate: nil)
        
        if arrayBdFrases.isEmpty { return  (0,0) } //Manejo de errores
        
        //Insertando todas las frases de la BD a un conjunto
        for i in arrayBdFrases {
            set.insert(i.frase ?? "")
        }
        
       // print("Cantidad antes de actualizar: \(set.count)")
        
        
        //Obtengo todas los nombres de conferencias del bundle e intento actualizar el set, los que se inserten representan los nuevos elementos
        //Luego inserto esos nuevos elementos a la BD.
        let frases = UtilFuncs.FileReadToArray("listfrases")
        
        if frases.isEmpty { return (0,0) } //Manejo de errores
        
        
        for i in frases {
            let result = set.insert(i)
            if result.0 {
               //Actualizando la BD
                do {
                    let item = Frases(context: self.context)
                    item.id = UUID().uuidString
                    item.frase = i
                    item.nota = ""
                    item.isfav = false
                    item.noinbuilt = false
                    item.isnew = true //Marca el elemento como nuevo
                   try context.save()
                    exitoCount += 1
                }catch{
                    errorCount += 1 //Cuenta los elementos que no se han actualizado
                }
                
                
            }
            
        }
        
       // print("Cantidad después de actualizar: \(set.count)")
    
            return (exitoCount, errorCount)
        
        
    }
    
 
    ///Pone el campo isnew a false. La modificación se hace inline, sobre el parámetro pasado
    /// - Parameter - entity : el registro a modificar
    func RemoveNewFlag( entity : inout Frases){
            entity.isnew = false
            try?  entity.managedObjectContext?.save()
    }
    
    ///Pone el campo isnew a false de todas las frases nuevas
    func RemoveAllNewFlag(){
        let predicate = NSPredicate(format: "%K==%@", #keyPath(Frases.isnew), NSNumber(value: true))
        let fetcRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        fetcRequest.predicate = predicate
        do {
           let  temp =  try context.fetch(fetcRequest)
            
            for i in temp {
                i.isnew = false
               try?  i.managedObjectContext?.save()
            }
            
        }catch{
           
        }
    }
    
    

    ///Lista todos los elementos recientemente adicionado: isnew:true
    /// - Returns - Devuelve un arreglo con todos los campos Frases añadidas recientemente
    func getAllNewsElements()->[Frases]{
        let result : [Frases] = []
        let predicate = NSPredicate(format: "%K==%@", #keyPath(Frases.isnew), NSNumber(value: true))
        let fetcRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        fetcRequest.predicate = predicate
        do {
            return try context.fetch(fetcRequest)
        }catch{
            return result
        }
    }

}//struct

