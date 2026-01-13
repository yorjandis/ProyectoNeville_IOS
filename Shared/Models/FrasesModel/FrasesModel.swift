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
    
    @Published var listfrases : [Frases] = [] //Listado de Frases
    
    @Published var listfrasesPrueba : [FraseItem] = [] //Listado de Frases a cargar
    
    @Published var favStateOfCurrentFrase : Bool = false //Almacena el estado del favorito de la frase actualmente en la pantalla Home.
    
    @Published var fraseAnteriores : [Frases] = [] //Arreglo que almacena la frase anterior para poder acceder a ella.
    
    @Published  var buscarEn : DondeBuscar = .TodasFrases //Almacena el tipo de listado que hay actualmente
    
    @Published  var criterioFiltroActual : CriterioFiltro = .ListadoFull //Almacena el tipo de Criterio de filtro  que hay actualmente
    
    
    var fraseActual : Frases? = nil //Almacena la frase actualmente cargada en el home. Esto permite ajustar el estado del favorito en el home, si lo modificamos en el listado de frases.
   
    ///Almacena el Id de la frase actualmente cargada. Se actualiza en: getRandomFrase()
    static var idFraseActual : String = ""
    
    static let shared = FrasesModel() //Singleton

    private let context = CoreDataController.shared.context

    
    private init(){
       getAllFrases()

    }

    //Nuevas Funciones - Prueba
    
    /*
     //Procesa todas las frases
     func ProcessFrasesTemp() -> String {
         let all = getAllFrasesGet()
         return all.map{$0 + "|nev"}.joined(separator: "\n")
     }
     */
    
    //Popula la Tabla Frases con las Frases tomadas de los ficheros de Frases de varios autores
    //nota: Se debe chequear primero si la frase ya existe en la tabla Frases
    func PopularFrases() async {
        
        //Chequeando un flag permanente para ver si continuamos con la lógica, si es false continua:
        if UserDefaults.standard.bool(forKey: AppCons.UD_TablaFrasesPopulada){
            print("No se procederá a popular la Tabla Frases")
            return //Sale
        }
        
        print("Se procederá a popular la Tabla Frases")
        
        
        //Activando un flag que indica que se esta procesando la tabla Frases...
        //Nota: este flag se debe consultar al mostrar la tabla de Frases y si es true, mostrar alguna barra de progreso o mensaje
        UserDefaults.standard.set(true, forKey: AppCons.UD_PopulandoFrases)
        
        // 1. Obtener todas las frases actuales
        let fetchRequest: NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        let allFrasesInCoreData: [Frases]
        
        do {
            allFrasesInCoreData = try context.fetch(fetchRequest)
        } catch {
            print("Error al obtener frases existentes: \(error)")
            //Desactivando el flag que indica que se esta populando la tabla Frases:
            UserDefaults.standard.set(false, forKey: AppCons.UD_PopulandoFrases)
            return
        }
        
        // 2. Diccionario: texto de la frase -> objeto Frases
        let frasesPorTexto: [String: Frases] = Dictionary(
            uniqueKeysWithValues:
                allFrasesInCoreData.compactMap {
                    guard let texto = $0.frase else { return nil }
                    return (texto, $0)
                }
        )
        
        // 3. Leer frases desde fichero: Si existiera más ficheros txt de frases (joe dispenza, greeg, bruce Lipton, otros Autores)
        //hay que concatenarlos a la variable: listTemp
        let listTemp: [String] = UtilFuncs.FileReadToArray(AppCons.FileListFrases)
        
        var frasesInsertadas = 0
        var frasesActualizadas = 0
        
        // 4. Procesar cada línea
        for linea in listTemp {
            
            let partes = linea.split(separator: "|", maxSplits: 1)
            if partes.count != 2 { continue }
            
            let textoFrase = String(partes[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let autorFrase = String(partes[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 5. Si la frase existe → actualizar autor
            if let fraseExistente = frasesPorTexto[textoFrase] {
                
                // Solo actualizamos si realmente cambia
                if fraseExistente.autor != autorFrase {
                    fraseExistente.autor = autorFrase
                    frasesActualizadas += 1 //feedBack
                }
                
            } else {
                // 6. Si no existe → insertar
                let nuevaFrase = Frases(context: context)
                nuevaFrase.frase = textoFrase
                nuevaFrase.autor = autorFrase
                frasesInsertadas += 1 //FeedBack
            }
        }
        
        // 7. Guardar cambios
        if context.hasChanges {
            do {
                try context.save()
                await MainActor.run {
                    print("Insertadas: \(frasesInsertadas) | Actualizadas: \(frasesActualizadas)")
                }
                
            } catch {
                print("Error al guardar cambios: \(error)")
                
            }
        }
        
        
        //Desactivando el flag temporal que indica que se esta populando la tabla Frases:
        UserDefaults.standard.set(false, forKey: AppCons.UD_PopulandoFrases)
        
        //Dejando activo un flag permanente para que en cada actualización de la app No se ejecute este código
        UserDefaults.standard.set(true, forKey: AppCons.UD_TablaFrasesPopulada)
        
    }
    
    
    // Fin de nuevas funciones
    

    
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

        //Agregando las frases noInbuit, de la Tabla Frases
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        do{
            let elements = try self.context.fetch(fetchRequest)
            
            self.listfrases = elements
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
    func getAllFrasesGet() -> [Frases]{
        
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")

        do{
            let elements = try self.context.fetch(fetchRequest)
            return elements
        }catch{
            print("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
            return []
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
                    self.listfrases = temp.filter{$0.frase?.localizedCaseInsensitiveContains(textAbuscar) ?? false}
                case .FrasesFavoritas:
                    let temp = getAllFavFrases()
                    self.listfrases =  temp.filter{$0.frase?.localizedCaseInsensitiveContains(textAbuscar) ?? false}
                case .FrasesConNotas:
                    let temp = getFrasesConNotas()
                    self.listfrases =  temp.filter{$0.frase?.localizedCaseInsensitiveContains(textAbuscar) ?? false}
                case .TodasFrases:
                    getAllFrases()
                    let temp = self.listfrases
                    self.listfrases =  temp.filter{$0.frase?.localizedCaseInsensitiveContains(textAbuscar) ?? false}
                    
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
    func getRandomFrase()->Frases? {
        let listTemp = getAllFrasesGet()
        if listTemp.isEmpty {
           return nil
        }else{
            return listTemp.randomElement()!
        }
        
    }

    
    
    //Devuelve todas las frases favoritas
    func getAllFavFrases() -> [Frases] {
        let frasesFavoritas: [Frases] = []
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isfav == %@", NSNumber(value: true))
        
        do {
            let elements = try context.fetch(fetchRequest)
            return elements
        }catch{
            print("Error al obtener las frases favoritas: \(error.localizedDescription)")
        }
        return frasesFavoritas
    }
    
    //Chequear si una frase es favorita
    func isFavFrase(fraseID: String) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: true))
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
    func setFavFrase(fraseID: String, _ isFav: Bool) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: true))
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do {
            if let fraseEntity = try context.fetch(fetchRequest).first {
                // La frase ya existe en la tabla, solo actualizamos el estado de favorito si es necesario
                    fraseEntity.isfav = isFav
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
    func AddFrase(frase : String, autor: String) -> Bool{
        let entidad = Frases(context: context)
        entidad.id = UUID().uuidString
        entidad.frase = frase
        entidad.isfav = false
        entidad.noinbuilt = true //Se marca como una frase NO inbuilt
        entidad.nota = ""
        entidad.autor = autor
        
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
    
//----------------------------------------------------------------
    //Obtiene un objeto de Frase a partir de su id:
    func getFraseCoreData(FraseID : String) -> Frases?{
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: true))
        fetchRequest.fetchLimit = 1
        
        do{
            let element : Frases? = try context.fetch(fetchRequest).first
            return element
        }catch {
            return nil
        }
    }
    
    //Obtiene un objeto de Frase a partir de su texto:
    //Misma Versión anterio, pero con el texto de la frase como parámetro: Solo usado para obtener la frase que viene del Widget de Frase
    func getFraseCoreDataFromTextFrase(fraseText : String) -> Frases?{
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "frase == %@", fraseText)
        fetchRequest.fetchLimit = 1
        
        do{
            let element : Frases? = try context.fetch(fetchRequest).first
            return element
        }catch {
            return nil
        }
    }
  
    //----------------------------------------------------------------
    
    ///Actualizar una Frase Personal
    func updateFrasePersonal(frase : Frases, newText : String, newNota : String, newIsfav : Bool, newAutor : String = "") -> Bool{
        if (frase.noinbuilt == true){
            let element = frase
            do{
                element.frase = newText
                element.isfav = newIsfav
                element.nota = newNota
                element.autor = newAutor
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
    
    ///Devuelve un arreglo con todas las frases NO inBuilt (Personales). Útil para funciones de filtrado
    func getFrasesNoInbuilt()->[Frases]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate : NSPredicate = NSPredicate(format: "noinbuilt == true")
        fetchRequest.predicate = predicate

        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            return elements
        }catch{
            print(error.localizedDescription)
            return []
        }
    }
    
    //Chequea si una frase es no inbuilt:
    func isNoInbuilt(fraseID:String)->Bool?{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: true))
        fetchRequest.fetchLimit = 1
        
        do{
            if let element = try context.fetch(fetchRequest).first {
                return element.noinbuilt
            }else{
               return nil
            }
            
        }catch{
            return nil
        }
    }
    
    //Elimina una frase personal de la Tabla Frases
    func DeleteFraseInbuilt(fraseID : String)->Bool{
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND noinbuilt == %@", fraseID, NSNumber(value: true))
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
    func getFrasesConNotas()->[Frases]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate = NSPredicate(format: "nota != nil AND nota != ''")
        fetchRequest.predicate = predicate
        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            return elements
        }catch{
            print("Error al devolver todas las frases con notas : \(error.localizedDescription)")
        }
        return []
    }
    
    ///Obtiene la nota de una frase
    ///
    func GetNotaAsociadaFrase(fraseID : String)->String{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: true))
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
    func UpdateNotaAsociada(fraseID : String, notaAsociada : String = "")->Bool{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: true))
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do{
            let element = try context.fetch(fetchRequest).first
            
            element?.nota = notaAsociada
            
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
    func searchTextInFrases(text : String)->[Frases]{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        do{
            let elements = try context.fetch(fetchRequest)
            
            return elements.filter{$0.frase?.contains(text) == true}
            
        }catch{
            return []
        }
    }
    
    
    ///Buscar texto en el campo nota de una frase
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de entity Frases que contienen el texto a buscar
    func searchTextInNotaFrases(textNota : String)->[Frases]{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        do{
            let elements = try context.fetch(fetchRequest)
            
            return elements.filter{$0.nota?.contains(textNota) == true}

        }catch{
            print(error.localizedDescription)
        }
        return []
        
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


