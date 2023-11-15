//
//  ConfeModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//Maneja la tabla TxtCont que muestra los elementos txt que contienen prefijo



import Foundation
import CoreData

struct TxtContentModel{

    private let context = CoreDataController.dC.context
    
    //Typo de contenido a manejar: Nota: Si en un futuro se adiciona más contenido se maneja aqui
    enum TipoDeContenido: String{
        case conf="conf_", citas="cita_", preg="preg_", ayud="ayud_", NA = ""
    }

    
   
    ///Obtiene un arreglo de entitys segun el tipo (Hace un filtrado según el tipo)
    /// - Parameter type : indica el tipo de contenido a filtrar
    /// - Returns : Devuelve un arreglo de entitys segun el tipo
    func getAllItems(type : TipoDeContenido )-> [TxtCont]{
        var result = [TxtCont]()
            do{
                let fetchRequest : NSFetchRequest<TxtCont> = TxtCont.fetchRequest()
                let array =  try context.fetch(fetchRequest)
                for item in array {
                    if item.type == type.rawValue {
                        result.append(item)
                    }
                }
            }
            catch{
               
            }
        return result

    }
    
    
    
    ///Devuelve una entity aleatoria, segun el tipo
    ////// - Parameter type : indica el tipo de contenido a filtrar
    /// - Returns - Devuelve un objeto de tipo Confe. Si falla devuelve un objeto vacio
    func getRandomConfe(type : TipoDeContenido)->TxtCont{
        let temp = self.getAllItems(type: type)
        if temp.count > 0 {
            return temp.randomElement() ?? TxtCont(context: context)
        }
        return TxtCont(context: context)
    }
    
    
    ///Actualiza el estado de favorito (Alterna entre el estado actual)
    func setFavState(entity : TxtCont, state : Bool){
        do{
            entity.isfav = state
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    

    ///Devuelve el valor del campo nota
    func getNota(entity : TxtCont)->String{
        return entity.nota ?? ""
    }
    
    ///Establece el valor del campo nota
    func setNota(entity : TxtCont, nota : String){
        do{
            entity.nota = nota
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    ///Devuelve un arreglo con todas las entity de cierto tipo que son favoritas
    func getAllFavorite(type : TipoDeContenido)->[TxtCont]{
        var result : [TxtCont] = []
        let array = self.getAllItems(type: type)
        
        for item in array{
            if item.isfav{
                result.append(item)
            }
        }
        
        return result
    }
    
    ///Devuelve todas las entity que tiene una nota, segun el tipo
    func getAllNota(type : TipoDeContenido)->[TxtCont]{
        var result : [TxtCont] = []
        let array = self.getAllItems(type: type)
        
        for item in array{
            let temp = item.nota ?? ""
            if !temp.isEmpty {
                result.append(item)
            }
        }

        return result
    }
 
    
    ///Búsqueda en texto
    func searchInText(list : [TxtCont],  texto : String)->[TxtCont]{
        var result : [TxtCont] = []

        for item in list {
            let temp = UtilFuncs.ReadFileToArray("\(item.type?.lowercased() ?? "")" + "\(item.namefile?.lowercased() ?? "")")
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
    
 
    
    
    // ---------------------------------------------------- FUNCIONES INTERNAS --------------------------------------------------------------
    
    ///Popula la Tabla Conf. Esto se hace la primera vez que se instala la app
    func populateTable(){
        
       if UserDefaults.standard.bool(forKey: Constant.UD_isTxtFilesPupulate) {return} //Sale si la tabla TxtFiles ya esta populada
        
        var array : [String] = [] //Almacena los name files leidos del bundle para el contenido txt

       // let arrayOfPrefix = ["conf_","cita_","preg_","ayud_"] //Yor en un futuro esto debe poder escalarse autom. con nuevo contenido
        
 
       // for prefix in arrayOfPrefix{
            
            
            
            array = self.FilesListToArray(prefix : "conf_") //Obteniendo el arreglo de nombre de ficheros...
            
            //Populando... segun el tipo de elemento (prefijo)
            for item in array {
                let entidad = TxtCont(context: context)
                entidad.id = UUID()
                entidad.isfav = false
                entidad.nota = ""
                entidad.type = "conf_" //!!!determina el tipo de contenido. es el prefijo del txt!!!
                entidad.namefile = item
            }
        //}
        
        if context.hasChanges {
            try? context.save()
        }
        
        
        //almacena en UserDefault un flag que indica que la tabla se ha populado
        if self.getAllItems(type: .conf).count > 0 { //Significa que se populó la tabla con al menos las conferencias
            UserDefaults.standard.setValue(true, forKey: Constant.UD_isTxtFilesPupulate)
        }
            
           
    }
    


    
    ///Devuelve un arreglo de String con los nombres de ficheros txt dentro del bundle según un prefijo (el prefijo se extrae de parametro de entrada)
    /// - Parameter type : Tipo de contenido a indexar. Se toma de un enum
    private  func  FilesListToArray(prefix : String)-> [String] {
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
    
    
    
}
