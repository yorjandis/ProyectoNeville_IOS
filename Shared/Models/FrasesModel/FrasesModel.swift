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
import Combine

//Manejo de la tabla frases


//Tipos de criteros para filtrar el listado
enum CriterioFiltro{
    case Buscar
    case ListadoFull
    case FrasesPersonales
    case FrasesFavoritas
    case FrasesConNotas
    case BuscarEnNotas
}

enum DondeBuscar{
    case TodasFrases
    case FrasesPersonales
    case FrasesFavoritas
    case FrasesConNotas
    case ResultadosDeBusquedaEnNotas
}

//Esto es para pruebas:
struct FraseItem : Identifiable{
    let id = UUID()
    let frase: String
}

@MainActor
final class FrasesModel : ObservableObject {
    
    @Published var listfrases : [String] = [] //Listado de Frases a cargar
    
    @Published var listfrasesPrueba : [FraseItem] = [] //Listado de Frases a cargar
    
    @Published var favStateOfCurrentFrase : Bool = false //Almacena el estado del favorito de la frase actualmente en la pantalla Home.
    
    @Published var fraseAnteriores : [String] = [] //Arreglo que almacena la frase anterior para poder acceder a ella.
    
    @Published  var buscarEn : DondeBuscar = .TodasFrases //Almacena el tipo de listado que hay actualmente
    @Published  var criterioFiltroActual : CriterioFiltro = .ListadoFull //Almacena el tipo de Criterio de filtro  que hay actualmente
    
    
    var fraseActual : String = "" //Almacena la frase actualmente cargada en el home. Esto permite ajustar el estado del favorito en el home, si lo modificamos en el listado de frases.
   
    ///Almacena el Id de la frase actualmente cargada. Se actualiza en: getRandomFrase()
    static var idFraseActual : String = ""
    
    static let shared = FrasesModel() //Singleton

    private let context = CoreDataController.shared.context

    
    private init(){
       getAllFrases()

    }

    

    
    /// Carga todas las frases (in‑built + personales) y actualiza `listfrases`.
    ///
    /// Lee las frases incluidas en el bundle de la app y las combina con las frases personales
    /// almacenadas en Core Data (marcadas como `noinbuilt == true`). El resultado se asigna al
    /// listado observable `listfrases` después de limpiar su contenido previo.
    ///
    /// - Important: Esta función modifica el estado de `listfrases` y realiza lecturas a Core Data.
    ///   No devuelve valor; su efecto es colateral sobre la propiedad publicada.
    func getAllFrases(){
        self.listfrases.removeAll()
        //Extrayendo las frases inbuilt, almacenadas dentro del bundle de la App
       var listTemp : [String] = UtilFuncs.FileReadToArray(AppCons.FileListFrases)
        
        //Agregando las frases noInbuit, de la Tabla Frases
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "noinbuilt == %@", NSNumber(value: true))
        fetchRequest.predicate = predicate
        do{
            let elements = try self.context.fetch(fetchRequest)
            for item in elements{
                if let frase = item.frase{
                    if frase.isEmpty{continue}
                    listTemp.append(frase)
                }
            }
            self.listfrases = listTemp
        }catch{
            print("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
        }
    }
    
    
    /// Devuelve todas las frases (in‑built + personales) sin modificar `listfrases`.
    ///
    /// Obtiene las frases incluidas en el bundle y las concatena con las frases personales presentes
    /// en Core Data (`noinbuilt == true`). A diferencia de `getAllFrases()`, esta función no altera
    /// el estado interno del modelo y únicamente retorna el arreglo resultante.
    ///
    /// - Returns: Un arreglo con todas las frases disponibles. Si ocurre un error de lectura,
    ///   se devuelve el acumulado parcial (que puede incluir solo las in‑built).
    func getAllFrasesGet() -> [String]{
        //Extrayendo las frases inbuilt, almacenadas dentro del bundle de la App
       var listTemp : [String] = UtilFuncs.FileReadToArray(AppCons.FileListFrases)
        
        //Agregando las frases noInbuit, de la Tabla Frases
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "noinbuilt == %@", NSNumber(value: true))
        fetchRequest.predicate = predicate
        do{
            let elements = try self.context.fetch(fetchRequest)
            for item in elements{
                if let frase = item.frase{
                    if frase.isEmpty{continue}
                    listTemp.append(frase)
                }
            }
            return listTemp
        }catch{
            print("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
            return listTemp
        }
    }
    
    
    /// Actualiza `listfrases` aplicando criterios de búsqueda y filtrado.
    ///
    /// Esta función reconstruye el listado observable `listfrases` en función del
    /// `criterioFiltroActual` y del ámbito definido por `buscarEn`. Cuando el
    /// `criterioFiltroActual` es `.Buscar`, el comportamiento depende del contenido
    /// de `textAbuscar` y del origen seleccionado en `buscarEn` (todas, personales,
    /// favoritas o con notas). Para otros criterios (`.ListadoFull`, `.FrasesPersonales`,
    /// `.FrasesFavoritas`, `.FrasesConNotas`, `.BuscarEnNotas`) el listado se carga
    /// directamente desde las fuentes correspondientes.
    ///
    /// - Parameter textAbuscar: Texto a buscar. Cuando está vacío y el criterio es `.Buscar`,
    ///   se restaura el listado según el ámbito `buscarEn`. Cuando contiene valor, se filtra
    ///   el conjunto correspondiente con coincidencia insensible a mayúsculas/minúsculas.
    ///
    /// - Important: Esta operación borra y vuelve a poblar `listfrases`. No modifica otros
    ///   estados como `favStateOfCurrentFrase` o `fraseActual`.
    ///
    /// - Note: Para `.TodasFrases` en modo búsqueda, primero se carga el total con `getAllFrases()`
    ///   y luego se aplica el filtro local sobre `listfrases`. Para `.BuscarEnNotas`, la búsqueda
    ///   se realiza sobre el campo `nota` de las entidades `Frases` mediante `searchTextInNotaFrases(textNota:)`.
    func FiltrarListado(textAbuscar: String = "" ) async {
        
        self.listfrases.removeAll()
        
        switch self.criterioFiltroActual {
            //Devuelve una lista de acuerdo al contenido del cuadro de bisqueda
        case .Buscar:
            if textAbuscar.isEmpty{ //No hay una búsqueda activa
                //Si el cuadro de búsqueda esta vacio se restuara el listado según el filtro seleccionado
                switch buscarEn {
                case .FrasesPersonales:
                    self.listfrases =  getFrasesNoInbuilt()
                case .FrasesFavoritas:
                    self.listfrases =   getAllFavFrases()
                case .FrasesConNotas:
                    self.listfrases =  getFrasesConNotas()
                case .TodasFrases:
                    getAllFrases()
                case .ResultadosDeBusquedaEnNotas:
                    print("")
                }
            }else{
                //Cuando se esté realizado una búsqueda y el cuadro de busqueda tenga un texto:
                switch buscarEn {
                case .FrasesPersonales:
                    let temp = getFrasesNoInbuilt()
                    self.listfrases =  temp.filter{$0.localizedCaseInsensitiveContains(textAbuscar)}
                case .FrasesFavoritas:
                    let temp = getAllFavFrases()
                    self.listfrases =  temp.filter{$0.localizedCaseInsensitiveContains(textAbuscar)}
                case .FrasesConNotas:
                    let temp = getFrasesConNotas()
                    self.listfrases =  temp.filter{$0.localizedCaseInsensitiveContains(textAbuscar)}
                case .TodasFrases:
                    getAllFrases()
                    let temp = self.listfrases
                    self.listfrases =  temp.filter{$0.localizedCaseInsensitiveContains(textAbuscar)}
                    
                case .ResultadosDeBusquedaEnNotas:
                    print("")
                }
            }
        case .ListadoFull: //Obtiene el listado completo de las frases
                getAllFrases()
        case .FrasesPersonales:
            self.listfrases = getFrasesNoInbuilt()
        case .FrasesFavoritas:
            self.listfrases = getAllFavFrases()
        case .FrasesConNotas:
            self.listfrases = getFrasesConNotas()
        case .BuscarEnNotas:
            self.listfrases = searchTextInNotaFrases(textNota: textAbuscar)
            
        }
        
    }
    
    
    /// Devuelve una frase aleatoria del conjunto de frases disponibles.
    ///
    /// La función combina las frases in‑app (in‑built) con las frases personales almacenadas en Core Data
    /// mediante `getAllFrasesGet()` y selecciona un elemento al azar del total. Si por alguna razón
    /// el listado resultara vacío, devuelve el texto por defecto "Imaginar Crea la Realidad".
    ///
    /// - Returns: Un `String` con una frase seleccionada aleatoriamente. Si no hay frases disponibles,
    ///   se retorna una frase por defecto.
    ///
    /// - Note: Esta función no modifica el estado de `listfrases` ni actualiza `idFraseActual`.
    func getRandomFrase()->String {
        let listTemp = getAllFrasesGet()
        return listTemp.randomElement() ?? "Imaginar Crea la Realidad"
    }

    
    
    //Devuelve todas las frases favoritas
    func getAllFavFrases() -> [String] {
        var frasesFavoritas: [String] = []
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isfav == %@", NSNumber(value: true))
        
        do {
            let elements = try context.fetch(fetchRequest)
            for item in elements {
                if let frase = item.frase{
                    frasesFavoritas.append(frase)
                }
            }
        }catch{
            print("Error al obtener las frases favoritas: \(error.localizedDescription)")
        }
        return frasesFavoritas
    }
    
    //Chequear si una frase es favorita
    func isFavFrase(_ frase: String) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "frase == %@ AND isfav == %@", frase, NSNumber(value: true))
        fetchRequest.fetchLimit = 1 // Solo necesitamos verificar si existe al menos una
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error al verificar la frase favorita: \(error.localizedDescription)")
            return false
        }
    }
    
    //fija el estado de favorito a una frase
    //Nota: esta función busca si la frase esta en la tabla Frases. Si esta, le asigna el nuevo estado isfav.
    func setFavFrase(_ frase: String, _ isFav: Bool) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "frase == %@", frase)
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do {
            if let fraseEntity = try context.fetch(fetchRequest).first {
                // La frase ya existe en la tabla, solo actualizamos el estado de favorito si es necesario
                    fraseEntity.isfav = isFav
                    try context.save()
            } else {
                // Si la frase no existe en la tabla Frase,  creamos una nueva entrada en la tabla Frases
                //Esto quiere decir que la frase es inbuilt, porque las frases personales siempre estarán en la tabla
                let newFrase = Frases(context: context)
                newFrase.id = UUID().uuidString
                newFrase.frase = frase
                newFrase.isfav = isFav
                newFrase.noinbuilt = false
                
                try context.save()
                
            }
            return true
        } catch {
            print("Error al fijar el estado de favorito: \(error.localizedDescription)")
            return false
        }
    }
    
    
    ///Adiciona una frase Personal (NO inBuilt) a la tabla Frases.
    /// - Parameter frase : El texto de la frase a añadir
    func AddFrase(frase : String) -> Bool{
        let entidad = Frases(context: context)
        entidad.id = UUID().uuidString
        entidad.frase = frase
        entidad.isfav = false
        entidad.noinbuilt = true //Se marca como una frase NO inbuilt
        entidad.nota = ""
        
        if context.hasChanges {
            do{
                try context.save()
                return true
            }catch{
                print(error.localizedDescription)
                return false
            }
        }
        return false
    }
    

    //Obtiene un objeto de Frase a partir de su id:
    func getFraseCoreData(fraseTexto : String) -> Frases?{
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "frase == %@", fraseTexto)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do{
            let element : Frases? = try context.fetch(fetchRequest).first
            return element
        }catch {
            return nil
        }
    }
    
    
    ///Actualizar una Frase Personal
    func updateFrasePersonal(frase : Frases, newText : String, newNota : String, newIsfav : Bool) -> Bool{
        if (frase.noinbuilt == true){
            let element = frase
            do{
                element.frase = newText
                element.isfav = newIsfav
                element.nota = newNota
                //antes de salvar nos aseguramos que la frase sea personal
                if context.hasChanges {
                    try context.save()
                    return true
                }else{
                    return false
                }
            }catch{
                context.rollback()
                print("Error al actualizar la Frase: \(error.localizedDescription)")
                return false
            }
        }else{
            return false
        }
    }
    
    ///Devuelve un arreglo con todas las frases NO inBuilt. Útil para funciones de filtrado
    func getFrasesNoInbuilt()->[String]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate : NSPredicate = NSPredicate(format: "noinbuilt == true")
        fetchRequest.predicate = predicate
        var result : [String] = []

        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            for item in elements{
                result.append(item.frase ?? "")
            }
            return result
        }catch{
            print(error.localizedDescription)
            return []
        }
    }
    
    //Chequea si una frase es no inbuilt:
    func isNoInbuilt(frase:String)->Bool{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate : NSPredicate = NSPredicate(format: "frase == %@ AND noinbuilt == %@", frase, NSNumber(value: true))
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do{
            let element = try context.fetch(fetchRequest).first
            if element != nil{
                return true
            }else{
                return false
            }
        }catch{
            return false
        }
    }
    
    //Elimina una frase personal de la Tabla Frases
    func DeleteFraseInbuilt(frase : String)->Bool{
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "frase == %@ AND noinbuilt == %@", frase, NSNumber(value: true))
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do{
            let element = try context.fetch(fetchRequest).first
            if let elementToDelete = element { //Se asegura de que exista un elemento a eliminar
                context.delete(elementToDelete)
                try context.save()
                return true
            }else{
                return false
            }
        }catch{
            print("Error al eliminar una frase personal : \(error.localizedDescription)")
            return false
        }
        
    }
    
    
    /// Devuelve todas las frases que tienen una nota asociada.
    ///
    /// Realiza una consulta a Core Data filtrando por `nota != nil` y `nota != ''` y retorna
    /// únicamente el texto de la frase de cada entidad que cumpla dicho criterio.
    ///
    /// - Returns: Un arreglo de `String` con las frases que poseen notas.
    /// - Note: Esta función no modifica `listfrases`; solo consulta Core Data y construye un arreglo.
    func getFrasesConNotas()->[String]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate = NSPredicate(format: "nota != nil AND nota != ''")
        fetchRequest.predicate = predicate
        var result : [String] = []
        
        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            for item in elements{
                //print("[\(item.nota ?? "nil")]")
                result.append(item.frase ?? "")
            }
        }catch{
            print("Error al devolver todas las frases con notas : \(error.localizedDescription)")
        }
        return result
    }
    
    ///Obtiene la nota de una frase
    ///
    func GetNotaAsociadaFrase(frase : String)->String{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "frase == %@", frase)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do{
            let element = try context.fetch(fetchRequest)
            return element.first?.nota ?? ""
        }catch{
            return ""
        }
    }
    

    
    ///Actualizar nota asociada
    /// - Returns : Devuelve true si éxito; false de otro modo
    func UpdateNotaAsociada(frase : String, notaAsociada : String = "")->Bool{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "frase == %@", frase)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            
            if elements.isEmpty{ //Si la frase no esta en la Tabla Frases, crea una nueva entidad y la añade
                
                let frasenew = Frases(context: context)
                frasenew.id = UUID().uuidString
                frasenew.frase = frase
                frasenew.nota = notaAsociada
                frasenew.noinbuilt = false
                
            }else{ //Si la frase esta en la tabla, solo cambia su campo nota
                elements.first?.nota = notaAsociada
            }
            if context.hasChanges{
                try context.save()
                return true
            }else{
                context.rollback()
                return false
            }
            
        }catch{
            print(error.localizedDescription)
            return false
        }
    }

    
    ///Buscar texto en frases.
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de  frases que contienen el texto a buscar
    func searchTextInFrases(text : String)->[String]{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        var result: [String] = []
        do{
            let elements = try context.fetch(fetchRequest)
            for item in elements{
                if let frase = item.frase {
                    if(frase.lowercased().contains(text.lowercased())){
                        result.append(frase)
                    }
                }
            }
            return result
        }catch{
            return result
        }
    }
    
    
    ///Buscar texto en el campo nota de una frase
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de entity Frases que contienen el texto a buscar
    func searchTextInNotaFrases(textNota : String)->[String]{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        var result: [String] = []
        do{
            let elements = try context.fetch(fetchRequest)
            for item in elements{
                if let nota = item.nota {
                    if(nota.localizedCaseInsensitiveContains(textNota)){
                        result.append(item.frase!)
                    }
                }
            }
        }catch{
            print(error.localizedDescription)
        }
        return result
        
    }
    
    
    
    //---------------------------------------------------------------------
    


}//struct

#if os(macOS)
import UniformTypeIdentifiers
//Uso de transferable para poder compartir la frases en macOS y no crashee la app
struct Frase: Transferable {
    var texto: String

    static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .plainText) { frase in
                frase.texto.data(using: .utf8)!
            }
        }
}
#endif


