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
    
}

//Esto es para pruebas:
struct FraseItem : Identifiable{
    let id = UUID()
    let frase: String
}

@MainActor
final class FrasesModel : ObservableObject {
    
    @Published var listfrases : [Frases] = [] //Listado de Frases principal
    
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
     
    }
    
    
    func guardarCambios(){
        if self.context.hasChanges{
            do{
                try self.context.save()
            }catch{
                msg("Fallo al persistir los cambios en Core Data")
            }
        }
    }
    
    
    
    
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
        
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        
        let todasLasFrases: [Frases]
        do {
            todasLasFrases = try context.fetch(fetchRequest)
        } catch {
            msg("❌ Error al obtener frases para deduplicar: \(error)")
            return
        }
        
        var totalEliminadas = 0
        
        // 1️⃣ Paso: eliminar duplicados exactos por ID
        var frasesPorID: [String: Frases] = [:]
        for frase in todasLasFrases {
            guard let id = frase.id else { continue }
            if let existente = frasesPorID[id] {
                // Elegimos cuál conservar según noinbuilt y metadatos
                let conservar = frase.noinbuilt && !existente.noinbuilt ? frase : existente
                let eliminar = (conservar == frase) ? existente : frase
                context.delete(eliminar)
                totalEliminadas += 1
                frasesPorID[id] = conservar
            } else {
                frasesPorID[id] = frase
            }
        }
        
        // 2️⃣ Paso: eliminar duplicados por texto
        // Agrupamos por texto limpio
        let frasesAgrupadasPorTexto = Dictionary(grouping: frasesPorID.values) {
            $0.frase?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        
        for (_, grupo) in frasesAgrupadasPorTexto {
            guard grupo.count > 1 else { continue } // si solo hay una, nada que hacer
            
            // Elegimos la frase a conservar
            let fraseAConservar = grupo.sorted { f1, f2 in
                if f1.noinbuilt != f2.noinbuilt {
                    return f1.noinbuilt && !f2.noinbuilt
                }
                // Si empatan, conservamos la que tenga más metadatos
                let meta1 = [f1.autor, f1.fuente, f1.nota].compactMap { $0 }.count
                let meta2 = [f2.autor, f2.fuente, f2.nota].compactMap { $0 }.count
                return meta1 > meta2
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
                    msg("🧹 Duplicados resueltos (ID + Texto). Eliminadas: \(totalEliminadas)")
                }
            } catch {
                msg("❌ Error al guardar tras deduplicar: \(error)")
            }
        } else {
            msg("No se modificó el contexto para Frases Duplicadas")
        }
    }
    
    
    //Volca el contenido de los ficheros de Frases, en el nuevo formato, a la tabla Frases de CoreData:
    /**
     Importador de frases desde los ficheros TXT a Core Data + CloudKit.

     Funcionalidades principales:

     1️⃣ Sincronización inicial
        - Espera a que CloudKit sincronice los datos existentes antes de realizar cualquier importación
        - Evita duplicados en instalaciones nuevas o reinstalaciones

     2️⃣ Detección de cambios
        - Calcula un hash global de los TXT para determinar si ha habido modificaciones
        - Si los archivos no han cambiado, omite la importación

     3️⃣ Creación y actualización de frases
        - Crea nuevas frases si no existen en Core Data (identificadas por `id`)
        - Actualiza frases existentes con los cambios en el TXT (texto, autor, nota, fuente)
        - No sobrescribe frases creadas por el usuario (UUID sin "_")

     4️⃣ Gestión de relaciones y contextos
        - Actualiza las relaciones entre frases según los datos del TXT
        - Vincula contextos a las frases, creando nuevos contextos si es necesario
        - Evita duplicados de relaciones y contextos

     5️⃣ Eliminación selectiva
        - Elimina frases que ya no aparecen en los TXT
        - Solo elimina frases cuyos IDs contienen exactamente un guion bajo ("_")
        - Frases de usuario (UUID sin "_") nunca se eliminan

     6️⃣ Garantías
        - El proceso es idempotente: múltiples ejecuciones producen el mismo estado final
        - TXT es la fuente de verdad
        - Compatible con CloudKit: cambios se propagan correctamente entre dispositivos
        - Seguridad frente a duplicados y pérdidas accidentales de datos de usuario
    */
    func PopularFrases() async {
        
        //Helper: Verifica si una frase pertenece a los TXT o al usuario
        //nota: las frases en los TXT tiene en su id un solo carcater "_". las frases de los usuarios, en cambio, utilizan UUID() que nunca contienen el caracter "_"
        func esFraseDeTXT(_ frase: Frases) -> Bool {
            guard let id = frase.id else { return false }
            // Contar cuántos "_" hay en el ID
            let guionBajoCount = id.filter { $0 == "_" }.count
            return guionBajoCount == 1
        }
        
        //Helper: Espera a que CloudKit haya sincronizado sus datos:
        func esperarSincronizacionInicial(context: NSManagedObjectContext) async {
            for _ in 0..<10 {
                let request: NSFetchRequest<Frases> = Frases.fetchRequest()
                request.fetchLimit = 1
                let count = (try? context.count(for: request)) ?? 0
                
                if count > 0 {
                    msg("CloudKit parece haber sincronizado datos")
                    return
                }
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            }
        }
        
        //Espera a que Cloud-Kit Termine de sincronizar (sino las frases se duplican):
        await esperarSincronizacionInicial(context: self.context)
        
        
        
        //🔶 Caculando el hash Global y determinando si se debe proseguir:
        
        //Listado de ficheros de frases. El orden en que se colocan en el arreglo es irrelevante porque se ordenan antes de ser procesados
        let ficherosFrases : [String] = [AppCons.FileListFrases,
                                         AppCons.FileListFrasesJD,
                                         AppCons.FileListFrasesBruceL,
                                         AppCons.FileListFrasesGregg,
                                         AppCons.FileListFrasesOtros
        ]
        let  newHash = HashFileModel().VerificarHashGlobal(NameArchivosTXT: ficherosFrases)
        
        let hashGuardado = UserDefaults(suiteName: "group.com.ypg.nev.group")?.string(forKey: HashFileModel.UD_HashFrasesTXT)
        
        if hashGuardado == newHash {
            msg("TXT sin cambios, sincronización omitida")
            return
        }
        
        msg("Se ha modificado los archivos de Frases. El importador comenzará ahora")
        
        // 🔶 Resolver duplicados previos
        await resolverDuplicadosFrases(context: self.context)
        
        // Flag temporal: Para mostrar un progreso (UI / progreso)
        UserDefaults.standard.set(true, forKey: AppCons.UD_ProgresoUI_PopulandoFrases)
        
        // 1️⃣ Obtener todas las frases existentes en CoreData
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        let frasesExistentes: [Frases]
        
        do {
            frasesExistentes = try context.fetch(fetchRequest)
        } catch {
            msg("❌ Error al obtener frases existentes: \(error)")
            UserDefaults.standard.set(false, forKey: AppCons.UD_ProgresoUI_PopulandoFrases)
            return //Termina
        }
        
        // 1️⃣.2️⃣ Creando un Diccionario: textoDeLaFrase → Frase (para evitar duplicados por contenido)
        
        //Diccionario basado en id -> Frases
        var frasesPorID: [String: Frases] = [:]
        
        for frase in frasesExistentes {
            if let id = frase.id {
                frasesPorID[id] = frase
            }
        }
        
        
        
        // 1️⃣.3️⃣ Genera un Diccionario: nombreContexto → Contexto (para evitar duplicados)
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
            UtilFuncs.FileRead(AppCons.FileListFrasesBruceL),
            UtilFuncs.FileRead(AppCons.FileListFrasesOtros),
        ].joined(separator: "\n\n")
        
        
        // 4️⃣ Parsear al modelo intermedio:Conviertiendo los bloques de las frases en un tipo Swift personalizado
        let frasesDTO = parsearFrasesNuevoFormato(contenidoTotal)
        
        // Conjunto de IDs presentes en los TXT
        let idsTXT = Set(frasesDTO.map { $0.id })
        
        var frasesInsertadas = 0 //feedBack
        var frasesActualizadas = 0 //feedBack
        
        // 5️⃣ FASE 1: Crear / actualizar frases (SIN relaciones)
        
        for dto in frasesDTO {
            
            let frase = frasesPorID[dto.id] ?? Frases(context: context)
            
            let esNueva = frase.id == nil
            
            frase.id     = dto.id
            frase.frase  = dto.texto
            frase.autor  = dto.autor
            frase.nota   = dto.nota
            frase.fuente = dto.fuente
            frase.isfav  = frase.isfav
            frase.noinbuilt = false
            frase.isnew  = false
            
            frasesPorID[dto.id] = frase
            
            if esNueva {
                frasesInsertadas += 1
            } else {
                frasesActualizadas += 1
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
        
        
        // 🔹 Paso 2: Recorrer cada DTO y sincronizar relaciones
        for dto in frasesDTO {
            
            // Obtener la frase correspondiente en CoreData
            guard let frase = frasesPorID[dto.id] else { continue }
            
            // 🔹 Obtener las relaciones actuales en CoreData (IDs de frases relacionadas)
            let relacionesCoreData = Set(frase.relacionadasArray.compactMap { $0.id })
            
            // 🔹 Obtener las relaciones indicadas en el TXT (DTO)
            let relacionesDTO = Set(dto.relacionadas)
            
            let relacionesAEliminar = relacionesCoreData.subtracting(relacionesDTO)
            
            for id in relacionesAEliminar {
                if let relacionada = frasesPorID[id] {
                    frase.desvincularDe(relacionada)
                }
            }
            
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
                msg("Insertadas: \(frasesInsertadas) | Actualizadas: \(frasesActualizadas)")
            }
        } catch {
            msg("❌ Error guardando relaciones: \(error)")
        }
        
        
        // 7️⃣ Fase 3: Insertar y  vincular los contextos entre frases
        for dto in frasesDTO {
            guard let frase = frasesPorID[dto.id] else { continue }
            
            // 👉 Eliminando los contextos de la frase y tomándolos de nuevo del TXT, que es la fuente de verdad
            frase.eliminarTodosLosContextos()
            
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
                
                frase.vincularConContexto(contexto) //En la función vincularConContexto también se evita contextos duplicados
            }
        }
        
        // 8️⃣ FASE 4: Eliminar frases de TXT obsoletas (solo IDs con un "_")
        /*
         Este nueva fase permite eliminar una frase en Core Data + CloudKit si hemos eliminados
         ese id de los TXT.
         */
        for frase in frasesExistentes {

            guard esFraseDeTXT(frase) else { continue }
            guard let id = frase.id else { continue }

            // Si el ID de la frase ya no está en el TXT → eliminar
            if !idsTXT.contains(id) {
                context.delete(frase)
                msg("🗑️ Frase eliminada (TXT): \(id)")
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
        UserDefaults.standard.set(false, forKey: AppCons.UD_ProgresoUI_PopulandoFrases) //Terminando...
        
        //🔥 Importante: Almcenando el nuevo VALOR hash creado de los ficheros de frases
        UserDefaults(suiteName: "group.com.ypg.nev.group")?.set(newHash, forKey: HashFileModel.UD_HashFrasesTXT) //Importante!!! Almacenando el nuevo flag
        
    }
    
    
    // Fin de nuevas funciones
    
    
    
    
    func getAllFrases(){
        self.listfrases.removeAll()
        do{
            self.listfrases = try Frases.fetch(.todas, context: context)
        }catch{
            msg("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
        }
    }
    
    
    
    func getAllFrasesGet() -> [Frases]{
        do{
            return try Frases.fetch(.todas, context: context)
            
        }catch{
            msg("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
            return []
        }
    }
    
    
    
    
    //Filtro del listado de frases:
    func FiltrarListado(textAbuscar: String = "" ) async {
        
        let textoNormalizado = textAbuscar.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.listfrases.removeAll()
        
        switch self.criterioFiltroActual {
            //Devuelve una lista de acuerdo al contenido del cuadro de búsqueda
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
                    
                }
            }else{
                //Cuando se esté realizado una búsqueda y el cuadro de busqueda tenga un texto:
                switch buscarEn {
                case .FrasesPersonales:
                    let temp = getFrasesNoInbuilt()
                    self.listfrases = temp.filter{$0.frase?.localizedCaseInsensitiveContains(textoNormalizado) ?? false}
                case .FrasesFavoritas:
                    let temp = getAllFavFrases()
                    self.listfrases =  temp.filter{$0.frase?.localizedCaseInsensitiveContains(textoNormalizado) ?? false}
                case .FrasesConNotas:
                    let temp = getFrasesConNotas()
                    self.listfrases =  temp.filter{$0.frase?.localizedCaseInsensitiveContains(textoNormalizado) ?? false}
                case .TodasFrases:
                    getAllFrases()
                    let temp = self.listfrases
                    self.listfrases =  temp.filter{$0.frase?.localizedCaseInsensitiveContains(textoNormalizado) ?? false}
                    
                    
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
    
    
    
    //Devuelve un listado de todos los Contextos disponibles,  para filtrar las frases
    func getAllContextosList() -> [String] {
        var list = Set<String>() //Un conjunto impide que haya duplicados
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        
        do {
            let frases = try context.fetch(fetchRequest)
            for frase in frases {
                for contexto in frase.contextosArray{
                    list.insert(contexto.nombre ?? "")
                }
            }
            return list.sorted()
        }catch{
            msg("Error al obtener las frases favoritas: \(error.localizedDescription)")
            return []
        }
    }
    
    //Devuelve todas las frases que pertenecen a un contexto determinado:
    func getFrasesByContexto(contexto: String) -> [Frases] {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        
        var result : [Frases] = []
        
        do {
            let frases = try context.fetch(fetchRequest)
            
            for frase in frases {
                for contextoF in frase.contextosArray{
                    if contextoF.nombre == contexto {
                        result.append(frase)
                    }
                }
            }
            return result
        }catch{
            return []
        }
    }
    
    
    //Genera un listado dinámico con todos los autores disponibles en las Frases en CoreData
    //Devuelve un diccionario: key = "jd", value = "Joe Dispenza"
    func getAllAutoresList() -> [String:String] {
        var list = Set<String>() //Un conjunto impide que haya duplicados
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
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest() //Prepara la consulta
        
        let autoresPermitidos = ["nev", "bruceL", "gregg", "jd"] //lista de autores permitidos
        
        if autoresPermitidos.contains(autor) {
            // Caso 1: el autor está en la lista de autores permitidos → se devuelve las Frases de ese autor
            fetchRequest.predicate = NSPredicate(format: "autor == %@", autor)
        } else {
            // Caso 2: el autor NO está en la lista → Se devuelve las frases de todos los autores que no estén en la lista
            fetchRequest.predicate = NSPredicate(format: "NOT (autor IN %@)",autoresPermitidos)
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al obtener las frases: \(error.localizedDescription)")
            return []
        }
        
    }
    
    
    //Obtener una Frase Aleatoria
    func getRandomFrase()->Frases? {
        do{
            return try Frases.fetch(.todas, context: self.context).randomElement()
        }catch{
            msg("No se ha podido obtener una frase aleatoria")
            return nil
        }
    }
    
    
    
    //Devuelve todas las frases favoritas
    func getAllFavFrases() -> [Frases] {
        do{
            return try Frases.fetch(.favoritas, context: self.context)
        }catch{
            msg("No se han podido obtener las frases favoritas")
            return []
        }
    }
    
    
    //Elimina una frase personal de Core Data y actualiza el listado:
    func eliminarFrase(_ frase: Frases) {
        context.delete(frase)
        do {
            try context.save() //Elimina la frase de CoreData
            listfrases.removeAll { $0.id == frase.id } //Actualiza el listado de frases
        } catch {
            msg("Error eliminando frase:", error.localizedDescription)
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
    
    
    ///Actualizar una Frase Personal
    func updateFrasePersonal(frase : Frases, newText : String, newNota : String, newIsfav : Bool, newAutor : String = "") -> Bool{
        guard frase.isPersonal else { return false }
        
        do{
            try frase.actualizarFrasePersonal(texto: newText, nota: newNota, autor: newAutor, isFav: newIsfav, context: self.context)
            return true
        }catch{
            msg(error.localizedDescription)
            return false
        }
        
    }
    
    ///Devuelve un arreglo con todas las frases NO inBuilt (Personales). Útil para funciones de filtrado
    func getFrasesNoInbuilt()->[Frases]{
        do{
            return try Frases.fetch(.personales, context: self.context)
        }catch{
            msg("No se ha podido obtener las frases personales")
            return []
        }
        
    }
    
    
    //Elimina una frase personal de la Tabla Frases
    func DeleteFrasePersonal(frase : Frases)->Bool{
        
        guard frase.isPersonal else { return false } //Sale si NO es una frase Personal
        
        self.context.delete(frase)
        do{
            try self.context.save()
            return true
        }catch{
            msg("No se ha podido eliminar la frase personal")
            return false
        }
        
    }
    
    
    
    func getFrasesConNotas()->[Frases]{
        do{
            return try Frases.fetch(.conNotas, context: self.context)
        }catch{
            msg("No se ha podido devolver las frases con Notas")
            return []
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
        do{
            return try Frases.fetch(.buscarTexto(text), context: self.context)
        }catch{
            msg("No se ha podido buscar el texto en las frases")
            return []
        }
        
    }
    
    
    ///Buscar texto en el campo nota de una frase
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de entity Frases que contienen el texto a buscar
    func searchTextInNotaFrases(textNota : String)->[Frases]{
        do{
            return try Frases.fetch(.buscarEnNotas(textNota), context: self.context)
        }catch{
            msg("No se ha podido buscar en la nota de la frase")
            return []
        }
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



