//
//  CoreDataCRUD.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 24/9/23.
//
//Funciones relacionadas con BD

import SwiftUI
import CoreData


//Manejo de la tabla frases
struct manageFrases {
    
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
                manageFrases.idFraseActual = res.first?.id ?? ""
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
                manageFrases.idFraseActual = res.first?.id ?? ""
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
            
            let arrayFrases = UtilFuncs.getfrasesArrayFromTxtFile() //Obtiene el arreglo de frases del txt
 
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
            if ((item.frase?.contains(text)) != nil){
                arrayResult.append(item)
            }
        }
        
        return arrayResult
 
    }
    
    
    ///Obtiene todas las frases favoritas
    ///Obtener todas las notas favoritas
    ///  - Returns : Devuelve un arreglo con todas las entity Notas favoritas
    func getFavFrases()->[Frases]{
        
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
     func getFrasesWithNotes()->[Frases]{
        var result : [Frases] = []
        
        let array = manageFrases().getAllFrases()
        
        for frase in array {
            if frase.nota ?? "" != "" {
                result.append(frase)
            }
        }
 
        return result
    }
    
    
}//struct


//Manejo de la tabla Notas
struct manageNotas{
    
    /// Establece los campos para búsqueda contenido dentro de las notas
    enum campo{
        case titulo, nota
    }
    
    private var context = CoreDataController.dC.context
    
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
    /// - Returns : devuelve una tupla: $0: true si éxito, false si error; $1: descripción del error, si $0 es false
    func addNote(nota : String, title : String = "", isFav : Bool = false)->(Bool, String){
        let entity = Notas(context: self.context)
        entity.id = UUID().uuidString
        entity.title = title
        entity.nota = nota
        entity.isfav = isFav
   
        if self.context.hasChanges {
            do {
                try context.save()
                return (true, "")
            }catch{
                context.rollback()
                return (false, error.localizedDescription)
            }
        }
        return (true, "")
    }
    
    ///Elimina una nota
    /// - Parameter NotaID : Id de la nota a eliminar
    func deleteNota(NotaID : String){
         let row = getEntityRow(value: NotaID)
            context.delete(row)
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
    
    ///Buscar texto en notas
    /// - Parameter text : texto a buscar
    /// - Parameter buscarEn: search target: en el campo de nota o en el campo de titulo
    func searchTextInNotas(_ text : String, buscarEn : campo = .nota)->[Notas]{
      
        let arrayNotas = getAllNotas()
        var result = [Notas]()
        
        for item in arrayNotas {
            
            switch buscarEn{
            case .nota:
                if item.nota?.contains(text) != nil{
                    result.append(item)
                }
            case .titulo:
                if item.title?.contains(text) != nil{
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








