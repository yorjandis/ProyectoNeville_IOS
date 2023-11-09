//
//  FrasesModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 8/11/23.
//
//Operaciones sobre Frases

import Foundation
import CoreData

//Manejo de la tabla frases
struct FrasesModel {
    
    ///Obtiene el contexto de Objetos administrados
    private var context = CoreDataController.dC.context
 
    ///Almacena el Id de la frase actualmente cargada. Se actualiza en: getRandomFrase()
    static var idFraseActual : String = ""
    
    ///Variable que indica si se ha populado la tabla frase (consulta a UserDefault)
   private  var isFrasesPopulated : Bool {
        return UserDefaults.standard.bool(forKey: Constant.UD_isfrasesLoaded)
    }
    
    
    ///Obtiene todas las frases
    /// - Returns : Devuelve un arreglo de objetos Frases, si falla devuelve un arreglo vacio
    func getAllFrases()-> [Frases]{
        let defaultResult = [Frases]()
        
        if isFrasesPopulated == false {return defaultResult}
        
            let fetcRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
            
            do{
                return try context.fetch(fetcRequest)
            }
            catch{
                return defaultResult
            }

    }
  
    
    ///Obtiene la lista de frases del fichero txt in-built:
    /// - Returns: Devuelve un  arreglo de cadenas con las frases cargadas del txt en Staff
     func getfrasesArrayFromTxtFile() ->[String] {
        var array = [String]()
        
        array = UtilFuncs.ReadFileToArray(Constant.FileListFrases)
        
        return array
        
    }
    
    ///Adiciona una frase NO inBuilt a la tabla Frases.
    /// - Parameter frase : El texto de la frase a añadir
    func AddFrase(frase : String){
        var entity = Frases(context: context)
        entity.id = UUID().uuidString
        entity.frase = frase
        entity.isfav = false
        entity.noinbuilt = true
        entity.nota = ""
        
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
        var result : [Frases] = []
        let lista = getAllFrases()
        
        for item in lista {
            if item.noinbuilt {
                result.append(item)
            }
        }
        
        return result
    }
    

    ///Devuelve una frase aleatoria
    /// - Returns : Devuelve una frase aleatoria a partir del arreglo generado por `getfrasesArrayFromTxtFile()`
     func getRandonFrase()->String{
        return getfrasesArrayFromTxtFile().randomElement() ?? ""
    }

    
    ///Obtiene una frase aleatoria
    ///
    ///Aqui se actualiza el ID de la frase actualmente cargada para fines de búsqueda dentro de la tabla Frases. Al inicio,  se intenta popular la tabla Frases si esta marcada como NO populada(false).
    ///
    /// - Returns Devuelve el texto de la frase. Actualiza la static var idFraseActual con el id de la frase devuelta. Si falla devuelve una frase vacia
    ///
    ///
    func getRandomFrase()->String {
        
        if isFrasesPopulated == false {populateTableFrases(); return ""}
        
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Frases")
        
        // find out how many items are there
        let totalresults = try! context.count(for: req)
        if totalresults > 0 {
            // randomlize offset
            req.fetchOffset = Int.random(in: 0..<totalresults)
            req.fetchLimit = 1
            
            do{
                let res = try context.fetch(req) as! [Frases]
                FrasesModel.idFraseActual = res.first?.id ?? ""
                return res.first?.frase ?? ""
            }catch{
                
            }
        }
        
        return ""
 
    }

    
    ///Obtiene una entity aleatoria de Frase
    ///
    ///Aqui se actualiza el ID de la frase actualmente cargada para fines de búsqueda dentro de la tabla Frases. Al inicio,  se intenta popular la tabla Frases si esta marcada como NO populada(false).
    ///
    /// - Returns Devuelve la entity frase.
    ///
    ///
    func getRandomFraseEntity()->Frases {
        
        if isFrasesPopulated == false {populateTableFrases(); return Frases()}
        
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Frases")
        
        // find out how many items are there
        let totalresults = try! context.count(for: req)
        if totalresults > 0 {
            // randomlize offset
            req.fetchOffset = Int.random(in: 0..<totalresults)
            req.fetchLimit = 1
            
            do{
                let res = try context.fetch(req) as! [Frases]
                FrasesModel.idFraseActual = res.first?.id ?? ""
                return res.first ?? Frases()
            }catch{
                
            }
            
  
           
        }
        
        return Frases()
 
    }
    
    ///Popula la tabla Frases al inicio de la app (ojo: esto borrará todas las notas y marcas de fav en la tabla)
    ///
    ///Es llamado solo una vez al iniciar la app por primera vez. Carga todos los datos de la tabla Frases y actualiza el el estado de la carga de la tabla Frases
    ///
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
                    try? context.save()
            }
                
                //almacena una marca que indica que la tabla frase ha sido populada
                UserDefaults.standard.setValue(true, forKey: Constant.UD_isfrasesLoaded)
     
    }
    
   
    ///Elimina todas las filas de la tabla Frases
    /// - Returns : Devuelve true si la operación ha sido un éxito o false si ha habido un error o la tabla no esta populada. Por defecto es true (éxito)
    func cleanFrases()->Bool{
       var result = true
        
        if isFrasesPopulated == false { return false}
        
            let content = getAllFrases()
            
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
    func getFavState(fraseID : String)->Bool {
        
        let array = getAllFrases()
        
        
        for item in array{
            if item.id == fraseID {
                return item.isfav
            }
        }
        return false

    }
    
    ///Chequea si una frase tiene Nota asociada
    /// - returns : deuelve el valor del capo fav de la frase actual:  `true` | `false` . Por defecto devuelve `false`
    func getNoteState(fraseID : String)->Bool {
        let array = getAllFrases()

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
        let array = getAllFrases()
        
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
        
        let array = getAllFrases()
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
        
        let arrayFrases = getAllFrases()
        
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
        
        let arrayFrases = getAllFrases()
        
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
        
        let array = getAllFrases()
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
        
        let array = FrasesModel().getAllFrases()
        
        for frase in array {
            if frase.nota ?? "" != "" {
                result.append(frase)
            }
        }
 
        return result
    }
    
    
    ///Chequear si una frase es NoInbuilt (personal)
    func CheckIfNotInbuiltFrase(frase : Frases)->Bool{
        if frase.noinbuilt {
            return true
        }else{
            return false
        }
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
    
    
    
    
}//struct

