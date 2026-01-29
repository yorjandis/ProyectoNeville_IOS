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


//FiltroPorAutores
enum CriterioPorAutor : String{
    case nev
    case joeD
    case bruceL
    case greggB
    case personal
    case otros
}

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

    //Nuevas Funciones
    
    /*
     //Procesa todas las frases
     func ProcessFrasesTemp() -> String {
         let all = getAllFrasesGet()
         return all.map{$0 + "|nev"}.joined(separator: "\n")
     }
     */
    
    
    
    
    /// Elimina TODAS las frases almacenadas en Core Data
    /// - Returns: true si la operación fue exitosa, false en caso contrario
    /*
    frase personal (noinbuilt == true)
    frase inbuilt (noinbuilt == false)
    */
    func deleteAllFrases(omitirPersonales : Bool = true) -> Bool {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            NSFetchRequest(entityName: "Frases")
        
        // 🔹 Solo elimina las frases donde noinbuilt == false: omite las frases personales
        if omitirPersonales == true{
            fetchRequest.predicate = NSPredicate(format: "noinbuilt == %@", false as NSNumber)
        }
        
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: objectIDs
                ]
                
                // Sincroniza el contexto y la UI
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [context]
                )
            }
            
            // Limpia el estado en memoria
            self.listfrases.removeAll()
            self.fraseActual = nil
            
            return true
            
        } catch {
            msg("❌ Error al eliminar todas las frases: \(error.localizedDescription)")
            context.rollback()
            return false
        }
    }
    
    //Resuelve las entradas Duplicadas
    //Se consideran frases duplicadas aquellas que tiene un texto igual
    func resolverDuplicadosFrases(context: NSManagedObjectContext) async {
        
        let fetchRequest: NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        
        let todasLasFrases: [Frases]
        
        do {
            todasLasFrases = try context.fetch(fetchRequest)
        } catch {
            msg("❌ Error al obtener frases para deduplicar: \(error)")
            return
        }
        
        // Agrupar por texto de frase
        let frasesAgrupadas = Dictionary(grouping: todasLasFrases) {
            $0.frase?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        
        var totalEliminadas = 0
        
        for (_, grupo) in frasesAgrupadas {
            
            // Si solo hay una, no hay duplicado
            guard grupo.count > 1 else { continue }
            
            // Elegimos la frase a conservar
            let fraseAConservar = grupo.sorted { f1, f2 in
                // Prioridad: noinbuilt
                if f1.noinbuilt != f2.noinbuilt {
                    return f1.noinbuilt && !f2.noinbuilt
                }
                // Si empatan, dejamos la primera
                return true
            }.first!
            
            // Eliminamos el resto
            for frase in grupo where frase != fraseAConservar {
                context.delete(frase)
                totalEliminadas += 1
            }
        }
        
        // Guardar cambios
        if context.hasChanges {
            do {
                try context.save()
                await MainActor.run {
                    msg("🧹 Duplicados resueltos. Eliminadas: \(totalEliminadas)")
                }
            } catch {
                msg("❌ Error al guardar tras deduplicar: \(error)")
            }
        }else{
            msg("No se modificó el contexto para Frases Duplicadas")
        }
    }
    
    //Volca el contenido de los ficheros de Frases, en el nuevo formato, a la tabla Frases de CoreData:
    func PopularFrases() async {

 //Caculando el hash Global y determinando si se debe proseguir:
 let  newHash = HashFileModel().VerificarHashGlobal(NameArchivosTXT:
                                                     [AppCons.FileListFrases,
                                                      AppCons.FileListFrasesJD,
                                                      AppCons.FileListFrasesBruceL,
                                                      AppCons.FileListFrasesGregg
                                                     ])
 guard newHash != nil else {
     print("No se ha modificado ninguno de los ficheros de Frases")
     return
 }

        
        

        msg("Se ha modificado los archivos de Frases. El importador comenzará ahora")

        // Resolver duplicados previos
        await resolverDuplicadosFrases(context: self.context)

        // Flag temporal (UI / progreso)
        UserDefaults.standard.set(true, forKey: AppCons.UD_PopulandoFrases)

        // 1️⃣ Obtener todas las frases existentes en CoreData
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        let frasesExistentes: [Frases]

        do {
            frasesExistentes = try context.fetch(fetchRequest)
        } catch {
            msg("❌ Error al obtener frases existentes: \(error)")
            UserDefaults.standard.set(false, forKey: AppCons.UD_PopulandoFrases)
            return
        }

        // 2️⃣.1️⃣ Diccionario: texto → Frase (para evitar duplicados por contenido)
            var frasesPorTexto: [String: Frases] = [:]
            for frase in frasesExistentes {
                if let texto = frase.frase?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                    frasesPorTexto[texto] = frase
                }
            }
        
        // 2️⃣.2️⃣ Genera un Diccionario: nombreContexto → Contexto (para evitar duplicados)
        // Diccionario: nombre de contexto (lowercased) → Contexto
        //El diccionario generado se utiliza más abajo en: (7️⃣ Fase 3)
        var contextosPorNombre: [String: Contexto] = [:]

        let fetchRequestContexto: NSFetchRequest<Contexto> = Contexto.fetchRequest()
        if let contextosExistentes = try? context.fetch(fetchRequestContexto) {
            for contexto in contextosExistentes {
                if let nombre = contexto.nombre?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    contextosPorNombre[nombre.lowercased()] = contexto
                }
            }
        }
        
            
            // 3️⃣ Leer ficheros TXT (nuevo formato)
            let contenidoTotal = [
                UtilFuncs.FileRead(AppCons.FileListFrases),
                UtilFuncs.FileRead(AppCons.FileListFrasesJD),
                UtilFuncs.FileRead(AppCons.FileListFrasesGregg),
                UtilFuncs.FileRead(AppCons.FileListFrasesBruceL)
            ].joined(separator: "\n\n")
        

        // 4️⃣ Parsear al modelo intermedio:Conviertiendo los bloques de las frases en un tipo Swift personalizado
            let frasesDTO = parsearFrasesNuevoFormato(contenidoTotal)

            var frasesInsertadas = 0 //feedBack
            var frasesActualizadasAutor = 0 //feedBack
            
            // 5️⃣ FASE 1: Crear / actualizar frases (SIN relaciones)
            for dto in frasesDTO {
                let textoClave = dto.texto.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                
                if let fraseExistente = frasesPorTexto[textoClave] {
                    
                  
                    msg("Frases Repetidas: \(dto.id)\n\(dto.texto)\n\n")

                    // Frase ya existe, entonces👇:
                    
                    //🟠 actualizar autor si su valor esta vacío (en las versiones antiguas de la app este campo podia estar vacío, ahora es requerido)
                    if  let autor = fraseExistente.autor {
                        if autor.isEmpty{
                            fraseExistente.autor = dto.autor //poniendo el valor desde el TXT
                            frasesActualizadasAutor += 1
                        }
                    }
                    
                    

  
                } else {
                    // La Frase No existe - Crear nueva frase en CoreData
                    let nuevaFrase = Frases(context: context)
                    nuevaFrase.id           = dto.id  //Ponemos el campo id desde el TXT para que las relaciones funcionen
                    nuevaFrase.frase        = dto.texto
                    nuevaFrase.autor        = dto.autor
                    nuevaFrase.nota         = dto.nota
                    nuevaFrase.fuente       = dto.fuente
                    nuevaFrase.isfav        = false
                    nuevaFrase.noinbuilt    = false
                    nuevaFrase.isnew        = false
                    
                    frasesPorTexto[textoClave] = nuevaFrase
                    frasesInsertadas += 1
                }
            }

        // Guardar tras FASE 1
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            msg("❌ Error guardando frases (fase 1): \(error)")
        }

        /*
         👉 Ahora Que las Frases existen en CoreData podemos crear las relaciones
         */
        
        // 6️⃣ FASE 2: Actualizar relaciones entre frases según el DTO
        // Esta fase se ejecuta después de que todas las frases han sido creadas/actualizadas en FASE 1
        /*
         Objetivo: actualizar las relaciones en CoreData de acuerdo a las expresadas en el fichero 
         */

        // 🔹 Paso 1: Construir un diccionario ID → Frase para acceder rápido
        var frasesPorID: [String: Frases] = [:]
        for frase in frasesPorTexto.values {
            if let id = frase.id {
                frasesPorID[id] = frase
            }
        }

        // 🔹 Paso 2: Recorrer cada DTO y sincronizar relaciones
        for dto in frasesDTO {
            
            // Obtener la frase correspondiente en CoreData
            guard let frase = frasesPorID[dto.id] else { continue }
            
            // 🔹 Obtener las relaciones actuales en CoreData (IDs de frases relacionadas)
            let relacionesCoreData = Set(frase.relacionadasArray.compactMap { $0.id })
            
            // 🔹 Obtener las relaciones indicadas en el TXT (DTO)
            let relacionesDTO = Set(dto.relacionadas)
            
            // 🔹 Paso 2a: Agregar nuevas relaciones que no existían
            let relacionesNuevas = relacionesDTO.subtracting(relacionesCoreData)
            for idRelacionada in relacionesNuevas {
                if let relacionada = frasesPorID[idRelacionada] {
                    // Vincular simétricamente la frase con la relacionada
                    frase.vincularCon(relacionada)
                } else {
                    msg("⚠️ Relación no encontrada (no existe la frase con id: \(idRelacionada))")
                }
            }
            
        }
            // Guardar relaciones creadas/actualizadas en (6️⃣ FASE 2:)
            do {
                if context.hasChanges {
                    try context.save()
                }
                await MainActor.run {
                    msg("Insertadas: \(frasesInsertadas) | Actualizadas(Autor): \(frasesActualizadasAutor) | Actualizadas(Contexto): \(frasesActualizadasAutor)")
                }
            } catch {
                msg("❌ Error guardando relaciones: \(error)")
            }
        
        
        // 7️⃣ Fase 3: Insertar y  vincular los contextos entre frases
        for dto in frasesDTO {
            guard let frase = frasesPorID[dto.id] else { continue }

            // 🔹 Este es el código que vincula contextos a la frase
            for nombre in dto.contexto {   // ya es [String]
                let key = nombre.lowercased()
                let contexto: Contexto
                
                if let existente = contextosPorNombre[key] {
                    contexto = existente
                } else {
                    contexto = Contexto(context: context)
                    contexto.nombre = nombre
                    contextosPorNombre[key] = contexto
                }

                frase.vincularConContexto(contexto)
            }
        }

        // Guardar contextos
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            msg("❌ Error guardando contextos: \(error)")
        }
        
        
        

        // Flags finales
        UserDefaults.standard.set(false, forKey: AppCons.UD_PopulandoFrases) //Terminando...
        
        UserDefaults(suiteName: "group.com.ypg.nev.group")?.set(newHash, forKey: HashFileModel.UD_HashFrasesTXT) //Importante!!! Almacenando el nuevo flag
   
    }
    
    
    // Fin de nuevas funciones
    

    

    func getAllFrases(){
        self.listfrases.removeAll()

        //Agregando las frases noInbuit, de la Tabla Frases
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        do{
            let elements = try self.context.fetch(fetchRequest)
            
            self.listfrases = elements
        }catch{
            msg("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
        }
    }
    
    

    func getAllFrasesGet() -> [Frases]{
        
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")

        do{
            let elements = try self.context.fetch(fetchRequest)
            return elements
        }catch{
            msg("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
            return []
        }
    }
    

    //Filtro del listado de frases:
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
                    msg("")
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
                    msg("")
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
    
    
    //Genera un listado dinámico con todos los autores disponibles en las Frases en CoreData
    func getAllAutoresList() -> [String:String] {
        var list = Set<String>()
        var result : [String:String] = [:]
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        
        do {
            let elements = try context.fetch(fetchRequest)
            for element in elements {
                list.insert(element.autor ?? "")
            }
            let arrayListAutor = Array(list)
            if !arrayListAutor.isEmpty {
                for item in arrayListAutor {
                    switch item {
                    case "nev": result["nev"] = "Neville"
                    case "jd": result["jd"] = "Dr. Joe Dispenza"
                    case "gregg": result["gregg"] = "Gregg Braden"
                    case "bruceL": result["bruceL"] = "Dr. Bruce H. Lipton"
                    default:
                        result["OtrosAutores"] = "Otros Autores"
                    }
                }
            }
            
            
            return result
        }catch{
            msg("Error al obtener las frases favoritas: \(error.localizedDescription)")
            return result
        }
        
    }
    
    //Obtiene todas las Frases de un Autor Determinado:
    func getListFrasesByAutor(autor: String) -> [Frases] {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "autor == %@", autor)
        
        do {
            let elements = try context.fetch(fetchRequest)
            return elements
        }catch{
            msg("Error al obtener las frases favoritas: \(error.localizedDescription)")
        }
        return []
        
    }
    

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

        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isfav == %@", NSNumber(value: true))
        
        do {
            let elements = try context.fetch(fetchRequest)
            return elements
        }catch{
            msg("Error al obtener las frases favoritas: \(error.localizedDescription)")
        }
        return []
    }
    
    //Chequear si una frase es favorita
    func isFavFrase(fraseID: String) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", fraseID)
        fetchRequest.fetchLimit = 1 // Solo necesitamos verificar si existe al menos una
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            msg("Error al verificar la frase favorita: \(error.localizedDescription)")
            return false
        }
    }
    
    //fija el estado de favorito a una frase
    //Nota: esta función busca si la frase esta en la tabla Frases. Si esta, le asigna el nuevo estado isfav.
    func setFavFrase(fraseID: String, _ isFav: Bool) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", fraseID)
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do {
            if let fraseEntity = try context.fetch(fetchRequest).first {
                // La frase ya existe en la tabla, solo actualizamos el estado de favorito si es necesario
                    fraseEntity.isfav = isFav
                    try context.save()
            }
            return true
        } catch {
            msg("Error al fijar el estado de favorito: \(error.localizedDescription)")
            return false
        }
    }
    
    
    
    
    ///Adiciona una frase Personal (NO inBuilt) a la tabla Frases.
    /// - Parameter frase : El texto de la frase a añadir
    func AddFrase(frase : String, autor: String, nota: String = "", isfav: Bool = false) -> Bool{
        let entidad = Frases(context: context)
        entidad.id = UUID().uuidString
        entidad.frase = frase
        entidad.isfav = isfav
        entidad.noinbuilt = true //Se marca como una frase NO inbuilt
        entidad.nota = nota
        entidad.autor = autor
        
        if context.hasChanges {
            do{
                try context.save()
                return true
            }catch{
                msg(error.localizedDescription)
                return false
            }
        }
        return false
    }
    
//----------------------------------------------------------------
    //Obtiene un objeto de Frase a partir de su id:
    func getFraseCoreData(FraseID : String) -> Frases?{
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "id == %@", FraseID)
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
                msg("Error al actualizar la Frase: \(error.localizedDescription)")
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
            msg(error.localizedDescription)
            return []
        }
    }
    
    //Chequea si una frase es no inbuilt:
    func isNoInbuilt(fraseID:String)->Bool?{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", fraseID)
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
            msg("Error al eliminar una frase personal : \(error.localizedDescription)")
            return false
        }
        
    }
    
    

    func getFrasesConNotas()->[Frases]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate = NSPredicate(format: "nota != nil AND nota != ''")
        fetchRequest.predicate = predicate
        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            return elements
        }catch{
            msg("Error al devolver todas las frases con notas : \(error.localizedDescription)")
        }
        return []
    }
    
    ///Obtiene la nota de una frase
    ///
    func GetNotaAsociadaFrase(fraseID : String)->String{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "id == %@", fraseID)
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
        fetchRequest.predicate = NSPredicate(format: "id == %@", fraseID)
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
            msg(error.localizedDescription)
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
            msg(error.localizedDescription)
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


