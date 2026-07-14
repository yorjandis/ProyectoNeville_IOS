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

    var contentKind: ContentKind? {
        switch self {
        case .conf: .conference
        case .citas: .quote
        case .preg: .question
        case .ayud: .help
        case .NA: nil
        }
    }
}

@MainActor
final class TxtContentModel : ObservableObject {
    
    @Published var textList: [String] = [] //Listado de elementos txt
    
    @Published var lastFiveConferences: [String] = [] //Vector que contiene las últimas 5 conferencias vistas

    private var recentConferenceIDs: [ContentID] = []
    private var storesObserver: NSObjectProtocol?
    private let repository = ContentRepository.shared

    private let context = CoreDataController.shared.context

    static let shared = TxtContentModel() //Singleton
    
    private init(){
        //Cargando el vector de conferencias
        loadLastFiveConferences()

        storesObserver = NotificationCenter.default.addObserver(
            forName: .coreDataStoresDidLoad,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.migrateLegacyContentState()
            }
        }

        if !(context.persistentStoreCoordinator?.persistentStores.isEmpty ?? true) {
            migrateLegacyContentState()
        }
    }
    

}


//Vector de conferencias
extension TxtContentModel {
    
   // Trabajo con el vector de conferencias vistas: ---------------------------------------------------------------------------
    
    func handleLast3Conferences(nombreTxt : String){
        let cleanName = nombreTxt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty,
              let descriptor = repository.descriptor(named: cleanName, kind: .conference) else { return }

        recentConferenceIDs.removeAll { $0 == descriptor.id }
        recentConferenceIDs.insert(descriptor.id, at: 0)

        if recentConferenceIDs.count > 3 {
            recentConferenceIDs = Array(recentConferenceIDs.prefix(3))
        }
        refreshRecentConferenceTitles()
    }
    
    //Salva la lista del vector. Debe ser llamada al salir de la vista de Lista de Conferencias
    func saveLastFiveConferences(){
        UserDefaults.standard.set(
            recentConferenceIDs.map(\.rawValue),
            forKey: "recentContentIDs.conferences.v2"
        )
        // Se mantiene temporalmente para poder volver a una versión anterior de la app.
        UserDefaults.standard.set(lastFiveConferences, forKey: "lastFiveConferences")
    }
    //Recupera el vector de conferencias vistas. Llamado en el init(){}
    func loadLastFiveConferences(){
        if let storedIDs = UserDefaults.standard.stringArray(forKey: "recentContentIDs.conferences.v2") {
            recentConferenceIDs = storedIDs.map(ContentID.init(rawValue:))
            refreshRecentConferenceTitles()
            return
        }

        let legacyNames = UserDefaults.standard.stringArray(forKey: "lastFiveConferences") ?? []
        recentConferenceIDs = legacyNames.compactMap {
            repository.descriptor(named: $0, kind: .conference, language: .spanish)?.id
        }
        refreshRecentConferenceTitles()
        saveLastFiveConferences()
    }

    private func refreshRecentConferenceTitles() {
        lastFiveConferences = recentConferenceIDs.compactMap {
            repository.descriptor(id: $0, kind: .conference)?.title
        }
    }
    //----------------------------------------------------------------------------------------------------------------------------
    
    
    ///Actualiza la un arreglo de String con los nombres de ficheros txt dentro del bundle según un prefijo (el prefijo se extrae de parametro de entrada)
    /// - Parameter type : Tipo de contenido a indexar. Se toma de un enum
    func getAllFileTxtOfType(type: TipoDeContenido){
        guard let kind = type.contentKind else {
            textList = []
            return
        }
        textList = repository.descriptors(of: kind).map(\.title)
    }
    
    ///Devuelve un arreglo de String con los nombres de ficheros txt dentro del bundle según un prefijo (el prefijo se extrae de parametro de entrada)
    /// - Parameter type : Tipo de contenido a indexar. Se toma de un enum
    func getArrayOfAllFileTxtOfType(type: TipoDeContenido)->[String]{
        guard let kind = type.contentKind else { return [] }
        return repository.descriptors(of: kind).map(\.title)
    }
    

    //devuelve el contenido de un elemento Txt
    func getContentTxt(nombreTxt : String, type : TipoDeContenido)-> String{
        guard let kind = type.contentKind,
              let descriptor = repository.descriptor(named: nombreTxt, kind: kind) else {
            return UtilFuncs.FileRead("\(type.rawValue)\(nombreTxt)")
        }
        return repository.content(for: descriptor)
    }
    
    //Devuelve una conferencia Aleatoria
    func getRandomConferencia()-> String?{
        let array = getArrayOfAllFileTxtOfType(type: .conf)
        return array.randomElement()
    }

    private func stableContentID(nombreTxt: String, type: TipoDeContenido) -> ContentID? {
        guard let kind = type.contentKind else { return nil }
        return repository.descriptor(named: nombreTxt, kind: kind)?.id
            ?? repository.stableID(forLegacyName: nombreTxt, kind: kind)
    }

    private func fetchState(nombreTxt: String, type: TipoDeContenido) throws -> TxtCont? {
        guard let contentID = stableContentID(nombreTxt: nombreTxt, type: type) else { return nil }
        let fetchRequest: NSFetchRequest<TxtCont> = TxtCont.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "contentID == %@ OR (namefile =[cd] %@ AND (type == %@ OR type == nil))",
            contentID.rawValue,
            nombreTxt,
            type.rawValue
        )
        fetchRequest.fetchLimit = 1

        guard let item = try context.fetch(fetchRequest).first else { return nil }
        if item.contentID == nil || item.type == nil {
            item.contentID = contentID.rawValue
            item.type = type.rawValue
        }
        return item
    }

    private func makeState(nombreTxt: String, type: TipoDeContenido) -> TxtCont {
        let item = TxtCont(context: context)
        item.id = UUID()
        item.contentID = stableContentID(nombreTxt: nombreTxt, type: type)?.rawValue
        item.namefile = nombreTxt
        item.type = type.rawValue
        return item
    }

    private func localizedName(for item: TxtCont, type: TipoDeContenido) -> String? {
        guard let kind = type.contentKind else { return item.namefile }
        if let rawID = item.contentID,
           let descriptor = repository.descriptor(id: ContentID(rawValue: rawID), kind: kind) {
            return descriptor.title
        }
        return item.namefile
    }

    private func migrateLegacyContentState() {
        guard !(context.persistentStoreCoordinator?.persistentStores.isEmpty ?? true) else { return }

        let request: NSFetchRequest<TxtCont> = TxtCont.fetchRequest()
        request.predicate = NSPredicate(format: "contentID == nil")

        guard let legacyItems = try? context.fetch(request), !legacyItems.isEmpty else { return }

        for item in legacyItems {
            guard let name = item.namefile?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { continue }

            if let rawType = item.type,
               let type = TipoDeContenido(rawValue: rawType),
               let id = stableContentID(nombreTxt: name, type: type) {
                item.contentID = id.rawValue
                continue
            }

            let matches = TipoDeContenido.allCases.compactMap { type -> (TipoDeContenido, ContentID)? in
                guard let kind = type.contentKind,
                      let descriptor = repository.descriptor(named: name, kind: kind, language: .spanish) else {
                    return nil
                }
                return (type, descriptor.id)
            }
            if matches.count == 1, let match = matches.first {
                item.type = match.0.rawValue
                item.contentID = match.1.rawValue
            }
        }

        if context.hasChanges {
            try? context.save()
        }
    }
    
    //Verifica si un elemento tiene una nota
    func isNotaOfTxt(nombreTxt: String, type: TipoDeContenido) -> Bool {
        do {
            return !(try fetchState(nombreTxt: nombreTxt, type: type)?.nota?.isEmpty ?? true)
        } catch {
            msg("Error al buscar la nota: \(error.localizedDescription)")
            return false
        }
    }
    
    //Obtiene la nota de un elemento
    func getNotaOfTXT(nombreTxt: String, type: TipoDeContenido) -> String {
        do{
            return try fetchState(nombreTxt: nombreTxt, type: type)?.nota ?? ""
        }catch{
            msg("Error al obtener la nota de un elemento: \(error.localizedDescription)")
            return ""
        }
    }
    
    //Fija la nota de un elemento:
    func setNotaOfTXT(nombreTxt: String, type: TipoDeContenido, nota: String) -> Bool{
        do{
            let element = try fetchState(nombreTxt: nombreTxt, type: type)
                ?? makeState(nombreTxt: nombreTxt, type: type)
            element.nota = nota
            try context.save()
            return true
        }catch{
            msg("Error al fija la nota del elemento: \(error.localizedDescription)")
            return false
        }
    }
    
    
    //Verifica si un elemento es favorito
    func getIsFavOfTxt(nombreTxt: String, type: TipoDeContenido) -> Bool {
        do {
            return try fetchState(nombreTxt: nombreTxt, type: type)?.isfav ?? false
        } catch {
            msg("Error al buscar el estado de favorito: \(error.localizedDescription)")
            return false
        }
    }
    
    
    //Actualiza el estado de favorito de un elemento
    func setIsFavOfTxt(nombreTxt: String, type: TipoDeContenido, isFav: Bool) -> Bool {
        do{
            if let element = try fetchState(nombreTxt: nombreTxt, type: type) {
                element.isfav = isFav
                try context.save()
            }else if isFav{ //Si no se encuentra un elemento en la tabla y el isfav a fijar es true, se crea el elemento
                let itemnew = makeState(nombreTxt: nombreTxt, type: type)
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
                    if let name = localizedName(for: item, type: type) {
                        result.append(name)
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
                    if let name = localizedName(for: item, type: type) {
                        result.append(name)
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
                .compactMap { localizedName(for: $0, type: type) }
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
                    guard let itemNameFileOK = localizedName(for: item, type: type),
                            let content = item.nota?.lowercased() else { return nil }
                    
                    return content.contains(str.lowercased()) ? itemNameFileOK : nil
                }
        } catch {
            msg("Error al obtener los elementos para la búsqueda: \(error.localizedDescription)")
            return []
        }
    }
    
}
