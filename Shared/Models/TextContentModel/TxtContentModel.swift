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
import Combine

//Typo de contenido a manejar: Nota: Si en un futuro se adiciona más contenido se maneja aqui
enum TipoDeContenido: String, CaseIterable{
    case conf="conf_", citas="cita_", preg="preg_", ayud="ayud_", NA = ""
}

@MainActor
final class TxtContentModel : ObservableObject {
    
    @Published var textList: [String] = [] //Listado de elementos txt
    
    @Published var lastFiveConferences: [String] = [] //Vector que contiene las últimas 5 conferencias vistas
    

    private let context = CoreDataController.shared.context

    static let shared = TxtContentModel() //Singleton
    
    private init(){
        //Cargando el vector de conferencias
        loadLastFiveConferences()
    }
    

}


//Listado de funciones
extension TxtContentModel {
    
   // Trabajo con el vector de conferencias vistas: ---------------------------------------------------------------------------
    
    func handleLastFiveConferences(nombreTxt : String){
        
        if nombreTxt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{return}
        
        //Sale si la conferencia a manejar ya esta dentro del vector
        guard !lastFiveConferences.contains(nombreTxt) else {return}
        
        //Si el vector tiene espacio se agrega la conferencia, pero solo si la conferencia no esta ya dentro del vector
        if lastFiveConferences.count < 6{
            lastFiveConferences.insert(nombreTxt, at: 0)
        }
        
        //Si el vector esta lleno se quita la primera que se añadió y se añade la actual al final:
        if lastFiveConferences.count == 6{
            lastFiveConferences.removeLast()
            lastFiveConferences.insert(nombreTxt, at: 0)
        }
        
    }
    
    //Salva la lista del vector. Debe ser llamada al salir de la vista de Lista de Conferencias
    func saveLastFiveConferences(){
        UserDefaults.standard.set(lastFiveConferences, forKey: "lastFiveConferences")
    }
    //Recupera el vector de conferencias vistas. Llamado en el init(){}
    func loadLastFiveConferences(){
        if let savedData = UserDefaults.standard.stringArray(forKey: "lastFiveConferences"){
            lastFiveConferences = savedData
        }
    }
    //----------------------------------------------------------------------------------------------------------------------------
    
    
    ///Actualiza la un arreglo de String con los nombres de ficheros txt dentro del bundle según un prefijo (el prefijo se extrae de parametro de entrada)
    /// - Parameter type : Tipo de contenido a indexar. Se toma de un enum
    func getAllFileTxtOfType(type: TipoDeContenido){
        let fm = FileManager.default
        guard let path = Bundle.main.resourcePath else { return}
        
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            let result = items
                .filter { $0.hasPrefix(type.rawValue) && $0.hasSuffix(".txt") }
                .map { $0
                    .replacingOccurrences(of: type.rawValue, with: "")  //Quitando el prefijo
                    .replacingOccurrences(of: ".txt", with: "")         //Quitando la extensión
                    .capitalized(with: .autoupdatingCurrent)            //Capitalizando el texto
                }
            
            self.textList = result.sorted()
        } catch {
            msg("Error al leer el directorio: \(error.localizedDescription)")
            self.textList = []
        }
    }
    
    ///Devuelve un arreglo de String con los nombres de ficheros txt dentro del bundle según un prefijo (el prefijo se extrae de parametro de entrada)
    /// - Parameter type : Tipo de contenido a indexar. Se toma de un enum
    func getArrayOfAllFileTxtOfType(type: TipoDeContenido)->[String]{
        let fm = FileManager.default
        guard let path = Bundle.main.resourcePath else { return []}
        
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            let result = items
                .filter { $0.hasPrefix(type.rawValue) && $0.hasSuffix(".txt") }
                .map { $0
                    .replacingOccurrences(of: type.rawValue, with: "")  //Quitando el prefijo
                    .replacingOccurrences(of: ".txt", with: "")         //Quitando la extensión
                    .capitalized(with: .autoupdatingCurrent)            //Capitalizando el texto
                }
            
            return result.sorted()
        } catch {
            msg("Error al leer el directorio: \(error.localizedDescription)")
            return  []
        }
    }
    

    //devuelve el contenido de un elemento Txt
    func getContentTxt(nombreTxt : String, type : TipoDeContenido)-> String{
        //Obtiene
        return UtilFuncs.FileRead("\(type.rawValue)" + "\(nombreTxt)")
    }
    
    //Devuelve una conferencia Aleatoria
    func getRandomConferencia()-> String?{
        let array = getArrayOfAllFileTxtOfType(type: .conf)
        return array.randomElement()
    }
    
    //Verifica si un elemento tiene una nota
    func isNotaOfTxt(nombreTxt: String, type: TipoDeContenido) -> Bool {
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        
        // Crear el filtro para buscar por nombre y tipo
        fetchRequest.predicate = NSPredicate(format: "namefile == %@ AND type == %@", nombreTxt, type.rawValue )
        fetchRequest.fetchLimit = 1
        
        do {
            // Verificar si hay al menos un elemento que coincida con el criterio
            if let txtCont = try context.fetch(fetchRequest).first {
                if let nota = txtCont.nota {
                    return !nota.isEmpty
                }else{
                    return false
                }
                
            }
            
        } catch {
            msg("Error al buscar la nota: \(error.localizedDescription)")
            return false
        }
        return false
    }
    
    //Obtiene la nota de un elemento
    func getNotaOfTXT(nombreTxt: String, type: TipoDeContenido) -> String {
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        fetchRequest.predicate = NSPredicate(format: "namefile == %@ AND type == %@", nombreTxt, type.rawValue )
        fetchRequest.fetchLimit = 1
        
        do{
            if let element = try context.fetch(fetchRequest).first {
                return element.nota ?? ""
            }
            return ""
        }catch{
            msg("Error al obtener la nota de un elemento: \(error.localizedDescription)")
            return ""
        }
    }
    
    //Fija la nota de un elemento:
    func setNotaOfTXT(nombreTxt: String, type: TipoDeContenido, nota: String) -> Bool{
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        fetchRequest.predicate = NSPredicate(format: "namefile == %@ AND type == %@", nombreTxt, type.rawValue )
        fetchRequest.fetchLimit = 1
        
        do{
            if let element = try context.fetch(fetchRequest).first {
                element.nota = nota //Actualizando la nota
                try context.save()
            }else{ //Si el elemento no esta en la Tabla y hay valor en el parámetro nota se crea el elemento
                let itemnew = TxtCont(context: context)
                itemnew.id = UUID()
                itemnew.namefile = nombreTxt
                itemnew.nota = nota
                
                try context.save()
            }
            return true
        }catch{
            msg("Error al fija la nota del elemento: \(error.localizedDescription)")
            return false
        }
    }
    
    
    //Verifica si un elemento es favorito
    func getIsFavOfTxt(nombreTxt: String, type: TipoDeContenido) -> Bool {
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        // Crear el filtro para buscar por nombre y tipo
        fetchRequest.predicate = NSPredicate(format: "namefile == %@ AND type == %@", nombreTxt, type.rawValue )
        fetchRequest.fetchLimit = 1
        
        do {
            // Verificar si hay al menos un elemento que coincida con el criterio
            if let txtCont = try context.fetch(fetchRequest).first {
                return txtCont.isfav // Se devuelve directamente sin negar
            }
            return false
        } catch {
            msg("Error al buscar el estado de favorito: \(error.localizedDescription)")
            return false
        }
    }
    
    
    //Actualiza el estado de favorito de un elemento
    func setIsFavOfTxt(nombreTxt: String, type: TipoDeContenido, isFav: Bool) -> Bool {
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        // Crear el filtro para buscar por nombre y tipo
        fetchRequest.predicate = NSPredicate(format: "namefile == %@ AND type == %@", nombreTxt, type.rawValue )
            
        do{
            if let element = try context.fetch(fetchRequest).first{
                element.isfav = isFav
                try context.save()
            }else if isFav{ //Si no se encuentra un elemento en la tabla y el isfav a fijar es true, se crea el elemento
                let itemnew = TxtCont(context: context)
                itemnew.id = UUID()
                itemnew.namefile = nombreTxt
                itemnew.type = type.rawValue
                itemnew.isfav = isFav
                try context.save()
            }
            return true
        }catch{
            msg("Error al fijar el estado de favorito: \(error.localizedDescription)")
            return false
        }
        
                                             
    }
    
    
   //Devuelve los elementos favoritos
    func getArrayFavTxt(type: TipoDeContenido)->[String]{
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        // Crear el filtro para buscar por nombre y tipo
        fetchRequest.predicate = NSPredicate(format: "type == %@",type.rawValue )
        var result : [String] = []
        do{
            let elements = try context.fetch(fetchRequest)
            for item in elements{
                if item.isfav {
                    if let namefile = item.namefile {
                        result.append(namefile )
                    }
                }
            }
            
        }catch{
            return []
        }

        return result
    }
    
    //Devuelve los elementos con notas
    func getArrayNoteTxt(type: TipoDeContenido)->[String]{
        let fetchRequest = NSFetchRequest<TxtCont>(entityName: "TxtCont")
        fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue )
        var result : [String] = []
        do{
            let elements = try context.fetch(fetchRequest)
            for item in elements{
                if item.nota != "" {
                    if let namefile = item.namefile {
                        result.append(namefile )
                    }
                }
            }
            
        }catch{
            return []
        }
        
        return result
 
    }
    
    
    //Busca dentro del texto de los elementos.
    //Devuelve un listado de elementos que contienen la cadena buscada
    func searchInTxt(str: String, type: TipoDeContenido) -> [String] {
        let fetchRequest: NSFetchRequest<TxtCont> = TxtCont.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue)
        
        do {
            let elements = try context.fetch(fetchRequest)
            
            return elements
                .compactMap { $0.namefile } // Extraer solo los nombres de archivo no nulos
                .filter { nameFile in
                    let content = getContentTxt(nombreTxt: nameFile, type: type)
                    return content.lowercased().contains(str.lowercased())
                }
        } catch {
            msg("Error al buscar en Core Data: \(error.localizedDescription)")
            return []
        }
    }
    
    //Buscar dentro de las notas de los elementos
    //Debuelve los elementos que contengan la cadena en sus notas
    func searchInNotesTxt(str: String, type: TipoDeContenido) -> [String] {
        let fetchRequest: NSFetchRequest<TxtCont> = TxtCont.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue)
        
        do {
            let elements = try context.fetch(fetchRequest)
            
            return elements
                .compactMap { item -> String? in
                    guard let itemNameFileOK = item.namefile,
                            let content = item.nota?.lowercased() else { return nil }
                    
                    return content.contains(str.lowercased()) ? itemNameFileOK : nil
                }
        } catch {
            msg("Error al obtener los elementos para la búsqueda: \(error.localizedDescription)")
            return []
        }
    }
    
}


