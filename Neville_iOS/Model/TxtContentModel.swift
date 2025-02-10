//
//  ConfeModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//Maneja la tabla TxtCont que muestra los elementos txt que contienen prefijo(conferencias, citas, ayudas, preguntas y respuestas ect)



import Foundation
import CoreData
import SwiftUI

@MainActor
final class TxtContentModel : ObservableObject {
    
    @Published var txtContent: [TxtCont] = []
    
    
  //  private let context = CoreDataController.shared.context
    
    //Typo de contenido a manejar: Nota: Si en un futuro se adiciona más contenido se maneja aqui
    enum TipoDeContenido: String, CaseIterable{
        case conf="conf_", citas="cita_", preg="preg_", ayud="ayud_", NA = ""
    }

    //Conjuntos de predicados comunes
    struct PredicatesTypes{
        let type : TipoDeContenido

        var getAllFavorites: NSPredicate{
            NSPredicate(format: "%K == %@ AND %K == %@", #keyPath(TxtCont.type), type.rawValue, #keyPath(TxtCont.isfav), NSNumber(value: true))
        }
        var getAllNotas: NSPredicate{
            NSPredicate(format: "%K == %@ AND %K != %@", #keyPath(TxtCont.type), type.rawValue, #keyPath(TxtCont.nota), "")
        }
        
    }
    
    
    ///Realiza consultas a la BD
    /// - Parameter - type: define el tipo de contenido .txt a consultar (conf, citas, preguntas, reflexiones)
    /// - Parameter - predicate: define el predicado a utilizar para filtrar la consulta. Si es nil devuelve todos los elementos
    /// - Returns - Devuelve un arreglo de elementos de cierto tipo. Si falla la cosulta se devuelve un arreglo vacio
    func GetRequest( context : NSManagedObjectContext, type: TipoDeContenido, predicate : NSPredicate?)->[TxtCont]{
        
        let fecthRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        
        if let pred = predicate {
            fecthRequest.predicate = pred
        }else { //Si no se da predicado entonces devuelve todos los elementos de un mismo tipo
            fecthRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(TxtCont.type), type.rawValue)
        }
           
        do {
            return try context.fetch(fecthRequest)
        }catch{
            print(error.localizedDescription)
            return []
        }
 
    }
    

    
    
    
    ///Devuelve una entity aleatoria, segun el tipo
    ////// - Parameter type : indica el tipo de contenido a filtrar
    /// - Returns - Devuelve un objeto de tipo Confe. Si falla devuelve un objeto vacio
    func getRandomItem(context : NSManagedObjectContext, type : TipoDeContenido)->TxtCont?{
        
        let temp = GetRequest(context: context, type: type, predicate: nil) //Obtiene todas las conferencias
        if temp.count > 0 {
            return temp.randomElement() ?? TxtCont(context: context)
        }
        return nil
    }
    
    
    ///Actualiza el estado de favorito (Alterna entre el estado actual)
    func setFavState(context : NSManagedObjectContext, entity : TxtCont?, state : Bool){
        do{
            if let tt = entity {
                tt.isfav = state
                try context.save()
            }
        }catch{
            print(error.localizedDescription)
        }
    }
    

    ///Devuelve el valor del campo nota
    func getNota(entity : TxtCont?)->String{
        if let tt = entity {
            return tt.nota ?? ""
        }else{
            return ""
        }
        
    }
    
    ///Establece el valor del campo nota
    func setNota(context : NSManagedObjectContext, entity : TxtCont?, nota : String){
        do{
            if let tt = entity {
                tt.nota = nota
                try context.save()
            }
        }catch{
            print(error.localizedDescription)
        }
    }
    
    ///Devuelve un arreglo con todas las entity de cierto tipo que son favoritas
    func getAllFavorite(context : NSManagedObjectContext, type : TipoDeContenido)->[TxtCont]{
        return GetRequest(context: context, type: type, predicate: PredicatesTypes(type: type).getAllFavorites)
    }
    
    ///Devuelve todas las entity que tiene una nota, segun el tipo
    func getAllNota(context : NSManagedObjectContext,  type : TipoDeContenido)->[TxtCont]{
        return GetRequest(context: context, type: type, predicate: PredicatesTypes(type: type).getAllNotas)
    }
 
    
    ///Búsqueda en texto
    func searchInText(list : [TxtCont],  texto : String)->[TxtCont]{
        var result : [TxtCont] = []

        for item in list {
            let temp = UtilFuncs.FileReadToArray("\(item.type?.lowercased() ?? "")" + "\(item.namefile?.lowercased() ?? "")")
            for item2 in temp {
                if item2.contains(texto){
                    result.append(item)
                    break
                }
            }
        }

        return result
    }
    
    ///Búsqueda en Títulos
    func searchInTitle(list : [TxtCont],  texto : String)->[TxtCont]{
        var result : [TxtCont] = []

        for item in list {
            let temp = item.namefile?.lowercased() ?? ""
            if temp.contains(texto.lowercased()){
                result.append(item)
            }
        }

        return result

    }
    
    
    //Clean DataBase: Elimina todos los registros de la tabla TXT: conf, citas, ayudas, pregunt
    func cleanTxtCont(context : NSManagedObjectContext)->Bool{

      if UserDefaults.standard.bool(forKey: AppCons.UD_isTxtFilesPupulate) {return false} //Sale si la tabla TxtFiles ya esta populada
        
        //Obteniendo todos los registros de la tabla TXTCont:
        
        let fecthRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
            fecthRequest.predicate = nil
        
        
        do {
            let array =  try context.fetch(fecthRequest)
            
            for row in array {
                context.delete(row)
            }
            
            try context.save()
            
            return true
            
        }catch{
            print(error.localizedDescription)
            return false
        }
        
    }
    
    
 
    
    
    // ---------------------------------------------------- FUNCIONES INTERNAS --------------------------------------------------------------
    
    ///Popula la Tabla Conf. Esto se hace la primera vez que se instala la app en un dispositivo
    func populateTable(context : NSManagedObjectContext) async {
        
       if UserDefaults.standard.bool(forKey: AppCons.UD_isTxtFilesPupulate) {return} //Sale si la tabla TxtFiles ya esta populada
        
        //Chequea si iCloud esta habilitado.
        if FileManager.default.ubiquityIdentityToken != nil {
            //icloud disponible:
            
            //Chequeando si existe registros en iCloud
            let resultTemp = await iCloudKitModel(of: .BDPrivada).getRecords(tableName: .CD_Frases)
            if !resultTemp.isEmpty {
                //Significa que tiene registros en iCloud: NO popula
                return
            }
            
        }
        
        
       // print("populando la tabla TxtContent")
        
        var array : [String] = [] //Almacena los name files leidos del bundle para el contenido txt

        let arrayOfPrefix = ["conf_","cita_","preg_","ayud_"] //Yor en un futuro esto debe poder escalarse autom. con nuevo contenido
        
 
        for prefix in arrayOfPrefix{
            array = self.FilesListToArray(prefix : prefix) //Obteniendo el arreglo de nombre de ficheros...
            
            //Populando... segun el tipo de elemento (prefijo)
            for item in array {
                let entidad = TxtCont(context: context)
                entidad.id = UUID()
                entidad.isfav = false
                entidad.nota = ""
                entidad.type = prefix //!!!determina el tipo de contenido. es el prefijo del txt!!!
                entidad.namefile = item
            }
        }
        
        if context.hasChanges {
            try? context.save()
        }
        
        
        //almacena en UserDefault un flag que indica que la tabla se ha populado
        if self.GetRequest(context: context, type: .conf, predicate: nil).count > 0 { //Significa que se populó la tabla con al menos las conferencias
            UserDefaults.standard.setValue(true, forKey: AppCons.UD_isTxtFilesPupulate)
        }
            
           
    }
    


    
    ///Devuelve un arreglo de String con los nombres de ficheros txt dentro del bundle según un prefijo (el prefijo se extrae de parametro de entrada)
    /// - Parameter type : Tipo de contenido a indexar. Se toma de un enum
      func  FilesListToArray(prefix : String)-> [String] {
        var result = [String]()
        var temp : String = ""
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!

        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix(prefix) {
                    temp = String(item.trimmingPrefix(prefix)) //Remueve el prefijo
                        .replacingOccurrences(of: ".txt", with: "") //Remueve la extension de fichero
                        .capitalized(with: .autoupdatingCurrent)    //Capitaliza el resultado
                    
                    result.append(temp)
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        
        return result
        
    }
    
    // ------------------------- FUNCIONES PARA PROCESAR LOS NUEVOS ELEMENTOS AÑADIDOS ------------------------------
    
    ///Funcion que actualiza la info cuando se adiciona nuevo contenido al bundle en una nueva actualización
    ///Por ejemplo cuando adicionamos nuevas conferencias, o ayudas, citas o preguntas
    /// - Parameter - type : Tipo de contenido a actualizar
    /// - Returns : Devuelve una tupla de dos enteros: el primero es el # de elementos que se han añadido, el segundo el # de elementos que han fallado al insertarse
    func UpdateContenAfterAppUpdate(context : NSManagedObjectContext, type : TipoDeContenido)->(Int,Int){
        
        var set : Set<String> = Set()
        var errorCount = 0 //cuanta los elementos fallidos que no se han podido adicionar a la BD
        var exitoCount = 0 //cuanta los elementos exitosos que no se han podido adicionar a la BD
        var totalNews = 0 //cuanta elementos nuevos han sido detectados
        
        //Volcar todos los nombres de conferencias de la BD a un set.
        let arrayBdConfe = self.GetRequest(context: context, type: type, predicate: nil)
        
        if arrayBdConfe.isEmpty { return (0,0) } //Manejo de errores
        
        for i in arrayBdConfe {
           set.insert(i.namefile ?? "")
        }
        
        //print("Cantidad antes de actualizar: \(set.count)")
        
        
        //Obtengo todas los nombres de conferencias del bundle e intento actualizar el set, los que se inserten representan los nuevos elementos
        //Luego inserto esos nuevos elementos a la BD.
        let files = self.FilesListToArray(prefix: type.rawValue)
        if files.isEmpty {  return (0,0)} //Manejo de errores
        
        
        for i in files {
            let result = set.insert(i) //Intenta insertar al set un elemento del bundle, si el elemento se logra insertar es porque es Nuevo contenido
            if result.0 {
                totalNews += 1
               //Actualizando la BD
                do {
                    let item = TxtCont(context: context)
                    item.id = UUID()
                    item.namefile = result.1
                    item.type = type.rawValue
                    item.isfav = false
                    item.nota = ""
                    item.isnew = true //Marcando como nuevo
                    try context.save()
                    exitoCount += 1
                }catch{
                    errorCount += 1 //Cuenta los elementos que no se han actualziado
                }
                
                
            }
            
        }
        
       // print("Cantidad después de actualizar: \(set.count)")
        
            return (exitoCount, totalNews)
        
        
        
    }
    
    
    ///Pone el campo isnew a false. La modificación se hace inline, sobre el parámetro pasado
    /// - Parameter - entity : el registro a modificar
    func RemoveNewFlag( entity : TxtCont){
            entity.isnew = false
            try?  entity.managedObjectContext?.save()
    }
    
    ///Pone el campo isnew a false de todos los registros de un tipo determinado
    func RemoveAllNewFlag(context : NSManagedObjectContext, type : TipoDeContenido){
        let array = GetRequest(context: context, type: type, predicate: nil)
        for i in array {
            i.isnew = false
           try?  i.managedObjectContext?.save()
        }

    }
    
    ///Lista todos los elementos recientemente adicionado: isnew:true
    /// - Returns - Devuelve un arreglo con todos los campos del tipo dado,   añadidos recientemente
    func getAllNewsElements(context : NSManagedObjectContext,  type : TipoDeContenido)->[TxtCont]{
        var result : [TxtCont] = []

        let array = GetRequest(context: context, type: type, predicate: nil)
        for i in array{
            if i.isnew {
                result.append(i)
            }
        }
        return result
    }
    
    
    
    
    ///OKOKOK Mantenimiento de la BD: Elimina registros duplicados en Core Data. Se asegura que se eliminan solos aquellos registros que tengan el campo fav a false y nota a vacio:
    /// Yor: esto repara la BD de frases de elementos duplicados. Solo conserva aquellos que tiene  nota o están marcados como favoritos.
    /// - Returns - devuelve el número de registros duplicados:
    func Fix_DeleteDuplicatesRowsInBDCoreDataForConf(context : NSManagedObjectContext){
        var arrayForDelete : [TxtCont] = [] //Arreglo de elementos duplicados para eliminar
        
        
        var totalDuplicadosTemp = 0 //Para control de elementos duplicados
        
        
        let tipoDeElemento = [TipoDeContenido.conf, TipoDeContenido.citas, TipoDeContenido.ayud, TipoDeContenido.preg]
        
        for type in tipoDeElemento {
            let ArrayItems = TxtContentModel().GetRequest(context: context, type: type, predicate: nil) //Total de elementos en BD
            for i in ArrayItems {
                let duplicadosTemp = ArrayItems.filter{ $0.namefile == i.namefile } //Filtrando los elementos duplicados
                totalDuplicadosTemp = duplicadosTemp.count //almacena la cantidad de elementos duplicados
                
                for ii in duplicadosTemp{//Recorre los elementos duplicados para filtrar todos lo que no son favoritos ni tienen notas
                    if ii.isfav == false && ii.nota == ""{
                        arrayForDelete.append(ii)
                        if ii.namefile == "" { continue } //Para eliminar las frases que estan vacias (Actualmente se ha ido una yor)
                        totalDuplicadosTemp -= 1 //va descontando el contador cada vez que se adiciona un elemento para eliminar
                    }
                }
                
                //dejando un elemento vivo en la BD en caso de que se hayan filtrados todos los duplicados para borrar:
                if totalDuplicadosTemp == 0 { //Significa que se ha tomado todos los registros para borrar, hay que dejar uno yorj
                    _ = arrayForDelete.popLast() //Quita el último registro del arreglo de elementos para eliminar
                }
            }
        }
        
        
        
        // print("despues de borrar:\(arrayForDelete)")
        
        //Eliminando los elementos
        for d in arrayForDelete {
            context.delete(d)
            do {
                try context.save()
            }catch{
                print("Yorjandis error eliminando: \(d.namefile ?? "")")
            }
        }
        
        
    }
    
    
    
    
}



