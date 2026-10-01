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

enum NotaChecklistItemKind: String, Codable, Equatable, Hashable {
    case task
    case leadingNote
    case trailingNote
}

struct NotaChecklistItem: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var isChecked: Bool
    var kind: NotaChecklistItemKind

    init(
        id: String = UUID().uuidString,
        text: String,
        isChecked: Bool = false,
        kind: NotaChecklistItemKind = .task
    ) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case isChecked
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isChecked = try container.decode(Bool.self, forKey: .isChecked)
        // Los checklists guardados antes de introducir bloques de nota solo
        // contienen tareas, por lo que siguen decodificando sin migración.
        kind = try container.decodeIfPresent(NotaChecklistItemKind.self, forKey: .kind) ?? .task
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isChecked, forKey: .isChecked)
        try container.encode(kind, forKey: .kind)
    }

    var isTask: Bool {
        kind == .task
    }

    static func fromText(_ text: String) -> [NotaChecklistItem] {
        var tasks: [NotaChecklistItem] = []
        var leadingNoteParts: [String] = []
        var trailingNoteParts: [String] = []
        var activeNoteKind: NotaChecklistItemKind?
        var noteLines: [String] = []

        func finishNoteBlock() {
            guard let activeNoteKind else { return }
            let note = noteLines
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty {
                switch activeNoteKind {
                case .leadingNote: leadingNoteParts.append(note)
                case .trailingNote: trailingNoteParts.append(note)
                case .task: break
                }
            }
            noteLines.removeAll()
        }

        for line in text.components(separatedBy: .newlines) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            switch trimmedLine {
            case leadingNoteStartMarker:
                finishNoteBlock()
                activeNoteKind = .leadingNote
            case trailingNoteStartMarker:
                finishNoteBlock()
                activeNoteKind = .trailingNote
            case leadingNoteEndMarker, trailingNoteEndMarker:
                finishNoteBlock()
                activeNoteKind = nil
            default:
                if activeNoteKind != nil {
                    noteLines.append(line)
                } else if !trimmedLine.isEmpty {
                    tasks.append(NotaChecklistItem(text: trimmedLine))
                }
            }
        }
        finishNoteBlock()

        var items: [NotaChecklistItem] = []
        if !leadingNoteParts.isEmpty {
            items.append(
                NotaChecklistItem(
                    text: leadingNoteParts.joined(separator: "\n\n"),
                    kind: .leadingNote
                )
            )
        }
        items.append(contentsOf: tasks)
        if !trailingNoteParts.isEmpty {
            items.append(
                NotaChecklistItem(
                    text: trailingNoteParts.joined(separator: "\n\n"),
                    kind: .trailingNote
                )
            )
        }
        return items
    }

    static func renderPlainText(_ items: [NotaChecklistItem]) -> String {
        items.map(\.text).joined(separator: "\n")
    }

    /// Mantiene los nodos internos al editar su proyección como texto plano.
    /// En la edición habitual SwiftUI entrega cambios incrementales, por lo que
    /// podemos aplicar la modificación al nodo afectado sin exponer marcadores.
    static func updatingTexts(
        in items: [NotaChecklistItem],
        toMatchPlainText plainText: String
    ) -> [NotaChecklistItem] {
        guard !items.isEmpty else { return fromText(plainText) }

        let renderedText = renderPlainText(items)
        guard renderedText != plainText else { return items }

        let oldCharacters = Array(renderedText)
        let newCharacters = Array(plainText)
        let sharedLimit = min(oldCharacters.count, newCharacters.count)
        var prefixCount = 0
        while prefixCount < sharedLimit,
              oldCharacters[prefixCount] == newCharacters[prefixCount] {
            prefixCount += 1
        }

        var suffixCount = 0
        while suffixCount < oldCharacters.count - prefixCount,
              suffixCount < newCharacters.count - prefixCount,
              oldCharacters[oldCharacters.count - suffixCount - 1]
                == newCharacters[newCharacters.count - suffixCount - 1] {
            suffixCount += 1
        }

        let oldEditEnd = oldCharacters.count - suffixCount
        let replacementEnd = newCharacters.count - suffixCount
        let replacement = Array(newCharacters[prefixCount..<replacementEnd])

        var itemStart = 0
        for index in items.indices {
            let itemCharacters = Array(items[index].text)
            let itemEnd = itemStart + itemCharacters.count
            if prefixCount >= itemStart,
               prefixCount <= itemEnd,
               oldEditEnd >= itemStart,
               oldEditEnd <= itemEnd {
                var updatedCharacters = itemCharacters
                updatedCharacters.replaceSubrange(
                    (prefixCount - itemStart)..<(oldEditEnd - itemStart),
                    with: replacement
                )
                var updatedItems = items
                updatedItems[index].text = String(updatedCharacters)
                return updatedItems
            }
            itemStart = itemEnd + 1
        }

        // Un pegado masivo puede afectar varios nodos. Si conserva el mismo
        // número de líneas, mantenemos la distribución y los tipos existentes.
        let newLines = plainText.components(separatedBy: .newlines)
        let lineCounts = items.map { $0.text.components(separatedBy: .newlines).count }
        guard lineCounts.reduce(0, +) == newLines.count else {
            return fromText(plainText)
        }

        var updatedItems = items
        var lineIndex = 0
        for index in updatedItems.indices {
            let lineCount = lineCounts[index]
            updatedItems[index].text = newLines[lineIndex..<(lineIndex + lineCount)]
                .joined(separator: "\n")
            lineIndex += lineCount
        }
        return updatedItems
    }

    /// Reconoce el formato heredado para migrar notas que ya contienen
    /// marcadores. Las conversiones nuevas nunca generan estas etiquetas.
    static func containsConvertibleNoteBlocks(in text: String) -> Bool {
        let lines = Set(
            text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
        let hasLeadingNote = lines.contains(leadingNoteStartMarker)
            && lines.contains(leadingNoteEndMarker)
        let hasTrailingNote = lines.contains(trailingNoteStartMarker)
            && lines.contains(trailingNoteEndMarker)
        return hasLeadingNote || hasTrailingNote
    }

    private static let leadingNoteStartMarker = "[[NOTA-INICIAL]]"
    private static let leadingNoteEndMarker = "[[/NOTA-INICIAL]]"
    private static let trailingNoteStartMarker = "[[NOTA-FINAL]]"
    private static let trailingNoteEndMarker = "[[/NOTA-FINAL]]"
}

struct NotaCreationDraft: Sendable {
    let title: String
    let content: String
    let category: String

    init(title: String, content: String, category: String = "") {
        self.title = title
        self.content = content
        self.category = category
    }
}

private enum NotaKindMarkers {
    static let voiceNote = "\u{200B}[[VOICE-NOTE]]"
}

extension Notas {
    var isVoiceNote: Bool {
        (nota ?? "").hasPrefix(NotaKindMarkers.voiceNote)
    }

    var voiceNoteAssociatedText: String {
        guard isVoiceNote else { return nota ?? "" }
        return String((nota ?? "").dropFirst(NotaKindMarkers.voiceNote.count))
    }

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

    /// Estructura asociada tanto a un checklist activo como a su proyección en
    /// texto plano. También migra en memoria el antiguo formato con etiquetas.
    var structuredChecklistItems: [NotaChecklistItem] {
        let storedItems = checklistItems
        if !storedItems.isEmpty {
            return storedItems
        }

        let rawText = nota ?? ""
        guard NotaChecklistItem.containsConvertibleNoteBlocks(in: rawText) else {
            return []
        }
        return NotaChecklistItem.fromText(rawText)
    }

    var noteDisplayText: String {
        if isVoiceNote {
            return voiceNoteAssociatedText
        }

        if isChecklistNote {
            let renderedItems = structuredChecklistItems
                .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .renderedAsChecklistText()
            return renderedItems.isEmpty ? (nota ?? "") : renderedItems
        }

        let rawText = nota ?? ""
        if checklistItems.isEmpty,
           NotaChecklistItem.containsConvertibleNoteBlocks(in: rawText) {
            return NotaChecklistItem.renderPlainText(structuredChecklistItems)
        }
        return rawText
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

    #if os(iOS)
    func convertPlainTextNoteToVoice(
        noteID: String,
        title: String,
        text: String,
        category: String,
        isFavorite: Bool
    ) -> Bool {
        let row = getEntityRow(value: noteID)
        row.title = title
        row.nota = NotaKindMarkers.voiceNote + text
        row.isfav = isFavorite
        row.isChecklistNote = false
        row.checklistItems = []
        row.setValue(category.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "categoria")
        row.setValue("", forKey: "direccionMapa")
        row.setValue(Date(), forKey: "fechaModificacion")

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    func addVoiceNote(
        id: String,
        title: String,
        note: String,
        category: String = ""
    ) -> Bool {
        let entity = Notas(context: context)
        let now = Date()
        entity.id = id
        entity.title = title
        entity.nota = NotaKindMarkers.voiceNote + note
        entity.isfav = false
        entity.isChecklistNote = false
        entity.checklistItems = []
        entity.setValue(category.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "categoria")
        entity.setValue("", forKey: "direccionMapa")
        entity.setValue(now, forKey: "fechaCreacion")
        entity.setValue(now, forKey: "fechaModificacion")

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    #endif

    /// Añade varias notas en una sola transacción. Si alguna escritura falla,
    /// no se conserva ninguna nota parcial.
    func addNotes(_ drafts: [NotaCreationDraft]) -> Bool {
        guard !drafts.isEmpty else { return true }
        let now = Date()

        for draft in drafts {
            let entity = Notas(context: context)
            entity.id = UUID().uuidString
            entity.title = draft.title
            entity.nota = draft.content
            entity.isfav = false
            entity.isChecklistNote = false
            entity.checklistItems = []
            entity.setValue(
                draft.category.trimmingCharacters(in: .whitespacesAndNewlines),
                forKey: "categoria"
            )
            entity.setValue("", forKey: "direccionMapa")
            entity.setValue(now, forKey: "fechaCreacion")
            entity.setValue(now, forKey: "fechaModificacion")
        }

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    
    
    
    
    ///Elimina una nota
    /// - Parameter nota : El objeto Nota a eliminar
    func deleteNota(nota : Notas){
        let noteID = (nota.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        #if os(iOS)
        if nota.isVoiceNote, !noteID.isEmpty {
            VoiceNoteAudioStore.removeFiles(for: noteID)
        }
        #endif
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
    func updateNota(NotaID : String, newTitle : String, newNota : String, isfav : Bool? = nil, direccionMapa: String = "", categoria: String = "", isChecklist: Bool? = nil, checklistItems: [NotaChecklistItem]? = nil, preserveVoiceType: Bool = true )->Bool{
        let row = getEntityRow(value: NotaID)
        let shouldRemainVoiceNote = row.isVoiceNote && preserveVoiceType && isChecklist != true
        if row.value(forKey: "fechaCreacion") as? Date == nil {
            row.setValue(Date(), forKey: "fechaCreacion")
        }
        row.title = newTitle
        row.nota = shouldRemainVoiceNote ? NotaKindMarkers.voiceNote + newNota : newNota
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
