//
//  RefexModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//
//Maneja las operaciones en la tabla Reflex

import Foundation
import CoreData
import Combine

/// Representa una reflexión mostrada en la app.
///
/// - Properties:
///   - id: Identificador único generado automáticamente.
///   - title: Título de la reflexión.
///   - content: Contenido o cuerpo de la reflexión.
///   - autor: Autor de la reflexión.
///   - isInbuilt: Indica si la reflexión viene incluida en la app (archivo de recursos) o fue creada por el usuario.
///   - isfav: Indica si la reflexión está marcada como favorita por el usuario.
struct RefType      : Identifiable, Equatable {
    let id          : String // = UUID().uuidString
    let title       : String
    let content     : String
    let autor       : String
    let isInbuilt   : Bool
    let isfav       : Bool
    
    static func == (lhs: RefType, rhs: RefType) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.content == rhs.content &&
               lhs.autor == rhs.autor &&
               lhs.isInbuilt == rhs.isInbuilt &&
               lhs.isfav == rhs.isfav
    }
}

//Información que será extraida de los ficheros json txt que contienen las reflexiones.
struct RefJSON: Codable {
    let titulo: String
    let autor: String
    let contenido: [String]
}

/// Modelo principal para gestionar reflexiones.
///
/// Se encarga de:
/// - Cargar reflexiones incluidas en la app desde el archivo de recursos.
/// - Consultar, crear, actualizar y eliminar reflexiones del usuario usando Core Data.
/// - Exponer un listado observable (`list`) para que la UI se actualice automáticamente.
@MainActor
final class ReflexModel : ObservableObject{
    private let context = CoreDataController.shared.context
 
    /// Listado observable de reflexiones combinadas (integradas y personales).
    @Published var list : [RefType] = []
    
    
    /// Instancia compartida (singleton) del modelo de reflexiones.
    static let shared = ReflexModel() //Singleton
    
    /// Inicializa el modelo y carga el listado inicial desde el archivo y Core Data.
    private init(){
        getArrayReflexOfTxtFile()
    }
    

    
    
    
    //Nuevas funciones Yorj:
    

    /// Actualiza `list` con las reflexiones disponibles.
    ///
    /// Lee el archivo de recursos `reflexiones` y construye un arreglo de `RefType` con los elementos integrados,
    /// marcando el estado de favorito según Core Data. Luego agrega las reflexiones creadas por el usuario.
    ///
    /// - Note: Este método modifica el estado publicado `list`.
    func getArrayReflexOfTxtFile(){

        // Limpiar el listado primero
        self.list.removeAll()

        // Cargar reflexiones integradas desde la localización activa
        let inbuilt = loadInbuiltReflexes()
        self.list.append(contentsOf: inbuilt)

        // Adicionar las reflexiones personales al listado
        self.list.append(contentsOf: getAllReflexNoInbuiltGet())
    }
    
    /// Obtiene todas las reflexiones sin modificar el estado publicado.
    ///
    /// Combina las reflexiones integradas (archivo `reflexiones`) con las reflexiones personales almacenadas en Core Data.
    ///
    /// - Returns: Un arreglo con todas las reflexiones disponibles.
    func getArrayReflexOfTxtFileGET()->[RefType]{
  
        var result : [RefType] = []

        // Cargar reflexiones integradas desde la localización activa
        result.append(contentsOf: loadInbuiltReflexes())
        
        // Adicionar las reflexiones personales al listado
        result.append(contentsOf: getAllReflexNoInbuiltGet())
        
        return result
        
    }
    
    /// Carga las reflexiones integradas desde el bundle.
    ///
    /// Intenta primero cargar un único recurso localizado "reflex.txt" (el sistema elegirá la variante del idioma).
    /// Ese archivo puede contener una única reflexión (RefJSON) o un arreglo de reflexiones ([RefJSON]).
    /// Si no existe o falla la decodificación, hace fallback a buscar archivos "reflex_*.txt" únicamente
    /// dentro de la carpeta de la localización activa (o Base), evitando mezclar idiomas.
    private func loadInbuiltReflexes() -> [RefType] {
        var result: [RefType] = []

        // 1) Intentar con un único archivo localizado: reflex.txt
        if let url = Bundle.main.url(forResource: "reflex", withExtension: "txt") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()

                // Intentar decodificar como arreglo de reflexiones
                if let array = try? decoder.decode([RefJSON].self, from: data) {
                    for item in array {
                        let isFav = self.getFavState(title: item.titulo)
                        let refType = RefType(
                            id: UUID().uuidString,
                            title: item.titulo,
                            content: item.contenido.joined(separator: "\n\n"),
                            autor: item.autor,
                            isInbuilt: true,
                            isfav: isFav
                        )
                        result.append(refType)
                    }
                    return result
                }

                // Si no es arreglo, decodificar como una sola reflexión
                let item = try decoder.decode(RefJSON.self, from: data)
                let isFav = self.getFavState(title: item.titulo)
                let single = RefType(
                    id: UUID().uuidString,
                    title: item.titulo,
                    content: item.contenido.joined(separator: "\n\n"),
                    autor: item.autor,
                    isInbuilt: true,
                    isfav: isFav
                )
                result.append(single)
                return result
            } catch {
                msg("Error cargando reflex.txt: \(error)")
            }
        }

        // 2) Fallback: buscar archivos por prefijo en la localización activa para no mezclar idiomas
        let bundle = Bundle.main
        var directoryCandidates: [URL] = []

        if let loc = bundle.preferredLocalizations.first,
           let locDir = bundle.url(forResource: loc, withExtension: "lproj") {
            directoryCandidates.append(locDir)
        }
        if let baseDir = bundle.url(forResource: "Base", withExtension: "lproj") {
            directoryCandidates.append(baseDir)
        }
        if let resURL = bundle.resourceURL {
            directoryCandidates.append(resURL)
        }

        let fm = FileManager.default
        var reflexURLs: [URL] = []

        for dir in directoryCandidates {
            if let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                let matches = urls.filter { $0.pathExtension == "txt" && $0.lastPathComponent.hasPrefix("reflex_") }
                if !matches.isEmpty {
                    reflexURLs = matches
                    break
                }
            }
        }

        for url in reflexURLs {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let refJSON = try decoder.decode(RefJSON.self, from: data)

                let isFav = self.getFavState(title: refJSON.titulo)

                let refType = RefType(
                    id: UUID().uuidString,
                    title: refJSON.titulo,
                    content: refJSON.contenido.joined(separator: "\n\n"),
                    autor: refJSON.autor,
                    isInbuilt: true,
                    isfav: isFav
                )

                result.append(refType)
            } catch {
                msg("Error cargando \(url.lastPathComponent): \(error)")
            }
        }

        return result
    }
    
    /// Obtiene las reflexiones marcadas como favoritas.
    ///
    /// - Returns: Un arreglo de `RefType` donde `isfav == true`.
    func getReflexFavoritasGet()->[RefType]{
        
        let listado  =  getArrayReflexOfTxtFileGET()
        var result : [RefType] = []
        
        for item in listado {
            if item.isfav{
                result.append(item)
            }
        }
        
        return result
  
    }
    
    
    
    
    /// Recupera las reflexiones creadas por el usuario (no integradas).
    ///
    /// - Returns: Un arreglo con las reflexiones almacenadas en Core Data con `isInbuilt == false`.
    func getAllReflexNoInbuiltGet()->[RefType]{
        let fetchRequest : NSFetchRequest<Reflex> = NSFetchRequest(entityName:  "Reflex")
        fetchRequest.predicate = NSPredicate(format: "isInbuilt == %@", NSNumber(value: false))
        
        do{
            let elements = try context.fetch(fetchRequest)
            return elements.map{ item in
                return RefType(id: item.id ?? "123", title: item.title ?? "", content: item.texto ?? "", autor: item.autor ?? "", isInbuilt: item.isInbuilt, isfav: item.isfav)
            }
            
        }catch{
            return []
        }
    }
    
    
    /// Consulta si una reflexión (por título) está marcada como favorita en Core Data.
    ///
    /// - Parameter title: Título de la reflexión a consultar.
    /// - Returns: `true` si existe un registro en Core Data con `isfav == true`; de lo contrario `false`.
    func getFavState(title : String)->Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        fetchRequest.fetchLimit = 1
        do{
            if let item = try context.fetch(fetchRequest).first{
                return item.isfav
            }else{
                return false
            }
            
        }catch{
            return false
        }
    }
    
    /// Establece el estado de favorito de una reflexión.
    ///
    /// Si la reflexión ya existe en Core Data, actualiza su campo `isfav`.
    /// Si no existe, crea un registro nuevo marcándolo como integrado y con el estado solicitado.
    ///
    /// - Parameters:
    ///   - title: Título de la reflexión.
    ///   - state: Nuevo estado de favorito.
    /// - Returns: `true` si la operación se guardó correctamente; `false` en caso de error.
    func setFavState(title : String, state : Bool) -> Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        let predicate : NSPredicate = NSPredicate(format: "title == %@", title)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            if let item = try context.fetch(fetchRequest).first{
                item.isfav = state
                try context.save()
                return true
            }else{ //No esta el elemento en la tabla, crearlo con el nuevo estado
                let reflexNew = Reflex(context: context)
                reflexNew.id = UUID().uuidString
                reflexNew.title = title
                reflexNew.isfav = state
                reflexNew.isInbuilt = true
                reflexNew.texto = "" //El texto no es necesario ponerlo en la tabla
                try context.save()
                
                return true
            }
        }catch{
            return false
        }
    }
    
    /// Elimina una reflexión de Core Data por título.
    ///
    /// - Important: Esta operación debe aplicarse únicamente a reflexiones creadas por el usuario.
    /// - Parameter title: Título de la reflexión a eliminar.
    /// - Returns: `true` si se eliminó y guardó correctamente; `false` si no se encontró o hubo un error.
    func deleteReflex(title : String)->Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        let predicate : NSPredicate = NSPredicate(format: "title == %@", title)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            if let item = try context.fetch(fetchRequest).first{
                 context.delete(item)
                try context.save()
                return true
            }
        }catch{
            return false
        }
        return false
    }
    
    /// Busca coincidencias en el contenido de las reflexiones (no sensible a mayúsculas/minúsculas).
    ///
    /// - Parameter text: Texto a buscar dentro del contenido de cada reflexión.
    /// - Returns: Arreglo de reflexiones cuyo `content` contiene el texto indicado.
    func searchInContent(text : String)-> [RefType]{
        let listado = getArrayReflexOfTxtFileGET()
        var result : [RefType] = []
        for item in listado{
            if item.content.lowercased().contains(text.lowercased()){
                result.append(item)
            }
        }
        return result
    }
    
    /// Guarda una reflexión personal en Core Data.
    ///
    /// Crea una nueva entidad `Reflex` marcada como no integrada (`isInbuilt = false`).
    /// En caso de error, revierte los cambios con `rollback()`.
    ///
    /// - Parameters:
    ///   - title: Título de la reflexión.
    ///   - autor: Autor de la reflexión.
    ///   - texto: Contenido de la reflexión.
    ///   - isfav: Estado de favorito inicial.
    /// - Returns: `true` si la operación se guardó correctamente; `false` si ocurrió un error.
    func savePersonalReflex(title : String, autor : String, texto : String, isfav : Bool)->Bool{
        let newEntity = Reflex(context: self.context)
        
        newEntity.id = UUID().uuidString
        newEntity.autor = autor
        newEntity.title = title
        newEntity.texto = texto
        newEntity.isInbuilt = false
        newEntity.isfav = isfav
        
        do {
            try context.save()
            return true
        }catch{
            context.rollback()
            return false
        }

    }
    
    func updatePersonalReflex(id: String, title: String, autor: String, texto: String, isfav: Bool)->Bool{
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        let predicate : NSPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
       
        do {
            if let item = try context.fetch(fetchRequest).first{
                item.id = id
                item.title = title
                item.autor = autor
                item.texto = texto
                item.isfav = isfav
                item.isInbuilt = false
                item.isnew = false
                try context.save()
                return true
            }else{
                return false
            }
        }catch{
            return false
        }
    }
    
    /// Elimina entradas duplicadas en la entidad `Reflex` basándose en el título.
    ///
    /// Recorre todas las entradas y conserva solo la primera aparición de cada título, eliminando duplicados.
    ///
    /// - Parameter context: Contexto de Core Data donde se ejecutará la limpieza.
    func eliminarDuplicados(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Reflex> = Reflex.fetchRequest()
        
        do {
            let reflexes = try context.fetch(fetchRequest)  // Obtener todos los Reflex
            
            var seenTitles = Set<String>()  // Set para rastrear títulos únicos
            
            for reflex in reflexes {
                if let title = reflex.title {
                    if seenTitles.contains(title) {
                        // Si el título ya está en el conjunto, eliminar duplicado
                        context.delete(reflex)
                    } else {
                        // Agregar título al conjunto
                        seenTitles.insert(title)
                    }
                }
            }
            
            // Guardar cambios en Core Data
            try context.save()
           // msg("Duplicados eliminados correctamente.")
            
        } catch {
            msg("Error al eliminar duplicados: \(error)")
        }
    }
    
    
    
    //Devuelve una entity Reflex por su ID
    //Esta función se utiliza para actualizar el contenido de una entidad una vez que cambia (usando en la ventana ReflexShowTextView en macOS)
    func getEntityById(id: String) -> Reflex? {
        let fetchRequest = NSFetchRequest<Reflex>(entityName: "Reflex")
        let predicate : NSPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            if let item = try context.fetch(fetchRequest).first{
                return item
            }else{
                return nil
            }
        }catch{
           return nil
        }
    }
    
}

