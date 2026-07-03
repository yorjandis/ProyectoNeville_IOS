//
//  NotasModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 8/11/23.
//

import Foundation
import CoreData
import Combine

extension Notification.Name {
    static let noteDeletedForWatchSync = Notification.Name("noteDeletedForWatchSync")
}

struct NotaChecklistItem: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var isChecked: Bool

    init(id: String = UUID().uuidString, text: String, isChecked: Bool = false) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
    }

    static func fromText(_ text: String) -> [NotaChecklistItem] {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { NotaChecklistItem(text: $0, isChecked: false) }
    }

    static func renderPlainText(_ items: [NotaChecklistItem]) -> String {
        items.map(\.text).joined(separator: "\n")
    }
}

extension Notas {
    var isChecklistNote: Bool {
        get {
            value(forKey: "isChecklist") as? Bool ?? false
        }
        set {
            setValue(newValue, forKey: "isChecklist")
        }
    }

    var checklistItems: [NotaChecklistItem] {
        get {
            guard let rawValue = value(forKey: "checklistItemsData") as? String,
                  let data = rawValue.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([NotaChecklistItem].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let encoded = String(data: data, encoding: .utf8) else {
                setValue("[]", forKey: "checklistItemsData")
                return
            }
            setValue(encoded, forKey: "checklistItemsData")
        }
    }

    var noteDisplayText: String {
        if isChecklistNote {
            let renderedItems = checklistItems
                .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .renderedAsChecklistText()
            return renderedItems.isEmpty ? (nota ?? "") : renderedItems
        }
        return nota ?? ""
    }
}

private extension Array where Element == NotaChecklistItem {
    func renderedAsChecklistText() -> String {
        NotaChecklistItem.renderPlainText(self)
    }
}

//Manejo de la tabla Notas
@MainActor
final class NotasModel : ObservableObject  {
    
    @Published var notas : [Notas] = [] //Listado de Notas
    private var observers = Set<AnyCancellable>()
    
    
    
    init(){
        setupObservers()
        getAllNotasToModel()
    }
    
    /// Establece los campos para búsqueda contenido dentro de las notas
    enum CampoBusqueda{
        case titulo, nota, categoria
    }
    
    private var context = CoreDataController.shared.context

    private func setupObservers() {
        let center = NotificationCenter.default

        center.publisher(for: .coreDataStoresDidLoad)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getAllNotasToModel()
            }
            .store(in: &observers)

        center.publisher(for: .NSPersistentStoreRemoteChange,
                         object: CoreDataController.shared.persistentContainer.persistentStoreCoordinator)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.context.refreshAllObjects()
                self?.getAllNotasToModel()
            }
            .store(in: &observers)

        #if !os(watchOS)
        center.publisher(
            for: NSPersistentCloudKitContainer.eventChangedNotification,
            object: CoreDataController.shared.persistentContainer
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.context.refreshAllObjects()
            self?.getAllNotasToModel()
        }
        .store(in: &observers)
        #endif

        center.publisher(for: .NSManagedObjectContextDidSave,
                         object: context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getAllNotasToModel()
            }
            .store(in: &observers)
    }
    
    
    ///Obtener la lista de notas
    /// - Returns : Devuelve un arreglo de entity Notas. De lo contrario devuelve un arreglo vacio
    func getAllNotasToModel(){
        self.notas.removeAll()
        
        let fetcRequest : NSFetchRequest<Notas> = Notas.fetchRequest()
        
        do{
            let fetched = try self.context.fetch(fetcRequest)
            self.notas = deduplicateNotasByID(fetched)
           
        }
        catch{
            self.notas = []
        }
        
    }

    private func deduplicateNotasByID(_ fetched: [Notas]) -> [Notas] {
        let groupedByID = Dictionary(grouping: fetched) { nota in
            (nota.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var idsToDelete = Set<NSManagedObjectID>()

        for (id, notas) in groupedByID where !id.isEmpty && notas.count > 1 {
            let keeper = notas.max { lhs, rhs in
                comparableDate(for: lhs) < comparableDate(for: rhs)
            }

            for nota in notas where nota.objectID != keeper?.objectID {
                idsToDelete.insert(nota.objectID)
                context.delete(nota)
            }
        }

        guard !idsToDelete.isEmpty else { return fetched }

        do {
            try context.save()
        } catch {
            context.rollback()
            msg("❌ Error eliminando notas duplicadas: \(error.localizedDescription)")
            return fetched
        }

        return fetched.filter { !idsToDelete.contains($0.objectID) }
    }

    private func comparableDate(for nota: Notas) -> Date {
        if let modified = nota.value(forKey: "fechaModificacion") as? Date {
            return modified
        }
        if let created = nota.value(forKey: "fechaCreacion") as? Date {
            return created
        }
        return .distantPast
    }
    
    
    ///Adicionar una nueva nota:
    /// - Parameter nota : Texto de la nota
    /// - Parameter title : Título  de la nota , por defecto es " "
    /// - Parameter isfav : Campo favorito <true|false>, por defecto `false`
    /// - Returns : devuelve  true si éxito, false si error
    func addNote(nota : String, title : String = "", isFav : Bool = false, direccionMapa: String = "", categoria: String = "", isChecklist: Bool = false, checklistItems: [NotaChecklistItem] = [] )->Bool {
        let entity = Notas(context: self.context)
        let now = Date()
        entity.id = UUID().uuidString
        entity.title = title
        entity.nota = nota
        entity.isfav = isFav
        entity.isChecklistNote = isChecklist
        entity.checklistItems = checklistItems
        entity.setValue(categoria.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "categoria")
        entity.setValue(direccionMapa, forKey: "direccionMapa")
        entity.setValue(now, forKey: "fechaCreacion")
        entity.setValue(now, forKey: "fechaModificacion")
   
        if self.context.hasChanges {
            do {
                try context.save()
                return true
            }catch{
                context.rollback()
                return false
            }
        }
        return true
    }
    
    
    
    
    
    ///Elimina una nota
    /// - Parameter nota : El objeto Nota a eliminar
    func deleteNota(nota : Notas){
        let noteID = (nota.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        context.delete(nota)
        do {
            try context.save()
            if !noteID.isEmpty {
                NotificationCenter.default.post(
                    name: .noteDeletedForWatchSync,
                    object: nil,
                    userInfo: ["id": noteID]
                )
            }
        } catch {
            context.rollback()
            msg(error.localizedDescription)
        }
    }
    
    ///Modifica una nota
    ///  - Parameter NotaID : Id de la nota a actualizar
    ///  - Parameter newTitle : Nuevo título de la nota
    ///  - Parameter newNota : Nuevo texto de la nota
    ///  - Parameter isfav : Estado del campo favorito, por defecto false
    ///  - Returns : true si éxito, false otherwise
    func updateNota(NotaID : String, newTitle : String, newNota : String, isfav : Bool? = nil, direccionMapa: String = "", categoria: String = "", isChecklist: Bool? = nil, checklistItems: [NotaChecklistItem]? = nil )->Bool{
        let row = getEntityRow(value: NotaID)
        if row.value(forKey: "fechaCreacion") as? Date == nil {
            row.setValue(Date(), forKey: "fechaCreacion")
        }
        row.title = newTitle
        row.nota = newNota
        if let isfav {
            row.isfav = isfav
        }
        if let isChecklist {
            row.isChecklistNote = isChecklist
        }
        if let checklistItems {
            row.checklistItems = checklistItems
        }
        row.setValue(categoria.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "categoria")
        row.setValue(direccionMapa, forKey: "direccionMapa")
        row.setValue(Date(), forKey: "fechaModificacion")
        do {
            try  self.context.save()
            return true
        }catch{
            return false
        }
        
    }
    
    ///Buscar texto en titulo y en el texto de las notas
    /// - Parameter text : texto a buscar
    /// - Parameter buscarEn: search target: en el campo de nota o en el campo de titulo
    /// - Returns - Devuelve un arreglo de entity Notas
    func searchTextInNotas(text: String, donde buscar: CampoBusqueda)->[Notas]{
      
        let arrayNotas = self.notas
        var result : [Notas] = []
        
        for item in arrayNotas {
            
            switch buscar{
            case .nota:
                let temp = item.noteDisplayText.lowercased()
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            case .titulo:
                let temp = item.title?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            case .categoria:
                let temp = (item.value(forKey: "categoria") as? String ?? "").lowercased()
                if temp.contains(text.lowercased()){
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

    func updateChecklistItems(NotaID: String, checklistItems: [NotaChecklistItem]) -> Bool {
        let row = getEntityRow(value: NotaID)
        row.isChecklistNote = true
        row.checklistItems = checklistItems
        row.nota = NotaChecklistItem.renderPlainText(checklistItems)
        row.setValue(Date(), forKey: "fechaModificacion")
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    ///Obtener todas las notas favoritas
    ///  - Returns : Devuelve un arreglo con todas las entity Notas favoritas
    func getFavNotas()->[Notas]{
        let array = self.notas
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
            msg(error.localizedDescription)
            
        }
        
        return Notas()
    }
    
}
