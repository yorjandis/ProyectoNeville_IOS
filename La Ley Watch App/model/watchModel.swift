//
//  watchModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 15/2/25.
//

import SwiftUI
import CoreData
import Combine

struct WatchAgendaItem: Identifiable {
    let id: UUID
    let titulo: String
    let fechaCreacion: Date
    let fechaModificacion: Date
    let nota: String
    let fechaActividad: Date
    let hora: Date
    let lugar: String
    let contenido: String
    let prioridad: String
    let colorHex: String
    let completada: Bool?
    let recordatorioActivo: Bool
    let reminderID: String?
    let seriesID: UUID?
}

struct WatchPresenceMood: Identifiable, Hashable {
    let id: String
    let title: String
    let symbolName: String
    let countsAsInconsciente: Bool

    static let common: [WatchPresenceMood] = [
        WatchPresenceMood(id: "pilotoAutomatico", title: "Piloto automático", symbolName: "moon.zzz.fill", countsAsInconsciente: true),
        WatchPresenceMood(id: "distraido", title: "Distraído", symbolName: "sparkle.magnifyingglass", countsAsInconsciente: true),
        WatchPresenceMood(id: "sereno", title: "Sereno", symbolName: "leaf.fill", countsAsInconsciente: false),
        WatchPresenceMood(id: "alegre", title: "Alegre", symbolName: "sun.max.fill", countsAsInconsciente: false),
        WatchPresenceMood(id: "ansioso", title: "Ansioso", symbolName: "waveform.path.ecg", countsAsInconsciente: false),
        WatchPresenceMood(id: "triste", title: "Triste", symbolName: "cloud.rain.fill", countsAsInconsciente: false),
        WatchPresenceMood(id: "enfadado", title: "Enfadado", symbolName: "flame.fill", countsAsInconsciente: false),
        WatchPresenceMood(id: "cansado", title: "Cansado", symbolName: "battery.25percent", countsAsInconsciente: false),
        WatchPresenceMood(id: "agradecido", title: "Agradecido", symbolName: "heart.fill", countsAsInconsciente: false)
    ]
}

@MainActor
final class watchModel: ObservableObject {
    
    let context  : NSManagedObjectContext = CoreDataController.shared.context
    
    static let shared : watchModel = watchModel() //Singleton
    
    
    @Published var listfrases : [String] = []
    
    @Published var listNotas : [Notas] = []
    
    @Published var listDiario : [Diario] = []
    @Published var listAgenda: [WatchAgendaItem] = []
    @Published var hasAgendaPremiumAccessValue: Bool = false
    @Published var yorjPremiumAccessValue: Bool = false
    @Published var todayPresenceReturnCount: Int = 0
    private var observers = Set<AnyCancellable>()

    private var homeFrasesCache: [Frases] = []
    private var homeFrasesCacheKey: String = ""

    private init() {
        setupObservers()
        refreshPremiumAccessState()
        self.getNotas()
        self.getDiarioEntradas()
        self.getAgendaEntradas()
        self.refreshTodayPresenceReturnCount()
        self.syncPresenceEventsToPhone()
    }

    private func setupObservers() {
        let center = NotificationCenter.default

        center.publisher(for: .coreDataStoresDidLoad)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getNotas()
                self?.getDiarioEntradas()
                self?.getAgendaEntradas()
                self?.refreshTodayPresenceReturnCount()
                self?.syncPresenceEventsToPhone()
            }
            .store(in: &observers)

        center.publisher(for: .NSPersistentStoreRemoteChange,
                         object: CoreDataController.shared.persistentContainer.persistentStoreCoordinator)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.context.refreshAllObjects()
                self?.getNotas()
                self?.getDiarioEntradas()
                self?.getAgendaEntradas()
                self?.refreshTodayPresenceReturnCount()
            }
            .store(in: &observers)

        center.publisher(for: .NSManagedObjectContextDidSave,
                         object: context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getNotas()
                self?.getDiarioEntradas()
                self?.getAgendaEntradas()
                self?.refreshTodayPresenceReturnCount()
            }
            .store(in: &observers)

        center.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPremiumAccessState()
            }
            .store(in: &observers)
    }

    //------FRASES-----
    /// Devuelve el texto de una frase aleatoria para Home con el autor al final.
    func getRandomFraseDisplayForHome() -> String {
        
        refreshHomeFrasesIfNeeded()

        if let item = homeFrasesCache.randomElement(),
           let frase = item.frase?.trimmingCharacters(in: .whitespacesAndNewlines),
           !frase.isEmpty {
            let autor = displayNameForAutor(item.autor)
            return autor.isEmpty ? frase : "\(frase)\n\n— \(autor)"
        }

        // Fallback seguro si Core Data aún no está poblado en watch.
        // Se aplican los mismos filtros de Ajustes para no quedarse solo en AppCons.FileListFrases.
        if let item = fallbackFrasesForHome().randomElement() {
            let autor = displayNameForAutor(item.autorCode)
            return autor.isEmpty ? item.texto : "\(item.texto)\n\n— \(autor)"
        }

        return ""
    }

    private func displayNameForAutor(_ code: String?) -> String {
        switch code {
        case "nev": return "Neville"
        case "jd": return "Joe Dispenza"
        case "bruceL": return "Bruce Lipton"
        case "gregg": return "Gregg Braden"
        case "salud": return "Salud"
        case let value? where !value.isEmpty: return value
        default: return ""
        }
    }

    /// Mantiene compatibilidad con el flujo antiguo del watch.
    func getfrasesArrayFromTxtFile() {
        self.listfrases.removeAll()
        self.listfrases = UtilFuncs.FileReadToArray(AppCons.FileListFrases)

        let fetchRequest: NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        fetchRequest.predicate = NSPredicate(format: "noinbuilt == %@", NSNumber(value: true))

        do {
            let elements = try self.context.fetch(fetchRequest)
            for item in elements {
                if let frase = item.frase {
                    self.listfrases.append(frase)
                }
            }
        } catch {
            msg("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
        }
    }

    private var hasPremiumAccess: Bool {
        NSUbiquitousKeyValueStore.default.synchronize()
        let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        let purchaseStatusStandard = UserDefaults.standard.bool(forKey: "purchaseStatus")
        let purchaseStatusShared = sharedDefaults?.bool(forKey: "purchaseStatus") ?? false
        let purchaseStatusCloud = NSUbiquitousKeyValueStore.default.bool(forKey: "purchaseStatus")
        return purchaseStatusStandard || purchaseStatusShared || purchaseStatusCloud
    }

    private var hasYorjPremiumAccess: Bool {
        NSUbiquitousKeyValueStore.default.synchronize()
        let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        let yorjPremiumStandard = UserDefaults.standard.bool(forKey: "yorjPremium")
        let yorjPremiumShared = sharedDefaults?.bool(forKey: "yorjPremium") ?? false
        let yorjPremiumCloud = NSUbiquitousKeyValueStore.default.bool(forKey: "yorjPremium")
        return yorjPremiumStandard || yorjPremiumShared || yorjPremiumCloud
    }

    var hasAgendaPremiumAccess: Bool {
        hasAgendaPremiumAccessValue
    }

    func refreshPremiumAccessState() {
        let yorj = hasYorjPremiumAccess
        yorjPremiumAccessValue = yorj
        hasAgendaPremiumAccessValue = hasPremiumAccess || yorj
    }

    var hasPresencePremiumAccess: Bool {
        hasAgendaPremiumAccess
    }

    func recordPresenceReturn() -> Bool {
        recordPresenceReturn(mood: nil)
    }

    func recordPresenceReturn(mood: WatchPresenceMood?) -> Bool {
        let saved = createPresenceEvent(type: "presente", moodID: mood?.id)
        if saved {
            refreshTodayPresenceReturnCount()
        }
        return saved
    }

    func recordPresenceMood(_ mood: WatchPresenceMood) -> Bool {
        let saved = createPresenceEvent(
            type: mood.countsAsInconsciente ? "inconsciente" : "estadoAnimo",
            moodID: mood.id
        )
        if saved {
            refreshTodayPresenceReturnCount()
        }
        return saved
    }

    func refreshTodayPresenceReturnCount() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            todayPresenceReturnCount = 0
            return
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.predicate = NSPredicate(
            format: "eventType == %@ AND createdAt >= %@ AND createdAt < %@",
            "presente",
            start as NSDate,
            end as NSDate
        )

        todayPresenceReturnCount = (try? context.count(for: request)) ?? 0
    }

    func syncPresenceEventsToPhone(limit: Int = 200) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        guard let rows = try? context.fetch(request) else { return }

        rows.compactMap { presencePayload(from: $0) }
            .forEach { WatchPresenceTransferSender.shared.sendCreatedPresence($0) }
    }

    private func createPresenceEvent(type: String, moodID: String?) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "PresenciaEventEntity", in: context) else {
            return false
        }

        let now = Date()
        let eventID = UUID()
        let dayStart = Calendar.current.startOfDay(for: now)
        let row = NSManagedObject(entity: entity, insertInto: context)
        row.setValue(eventID, forKey: "id")
        row.setValue(now, forKey: "createdAt")
        row.setValue(dayStart, forKey: "dayStart")
        row.setValue(type, forKey: "eventType")
        row.setValue(moodID, forKey: "mood")
        row.setValue("", forKey: "note")
        row.setValue("watchOS", forKey: "source")

        do {
            try context.save()
            WatchPresenceTransferSender.shared.sendCreatedPresence(
                WatchPresenceTransferPayload(
                    id: eventID.uuidString,
                    createdAt: now,
                    dayStart: dayStart,
                    eventType: type,
                    mood: moodID,
                    note: "",
                    source: "watchOS"
                )
            )
            return true
        } catch {
            context.rollback()
            msg("Error al guardar presencia desde watchOS: \(error.localizedDescription)")
            return false
        }
    }

    private func presencePayload(from row: NSManagedObject) -> WatchPresenceTransferPayload? {
        guard
            let id = row.value(forKey: "id") as? UUID,
            let createdAt = row.value(forKey: "createdAt") as? Date,
            let dayStart = row.value(forKey: "dayStart") as? Date,
            let eventType = row.value(forKey: "eventType") as? String
        else {
            return nil
        }

        return WatchPresenceTransferPayload(
            id: id.uuidString,
            createdAt: createdAt,
            dayStart: dayStart,
            eventType: eventType,
            mood: row.value(forKey: "mood") as? String,
            note: row.value(forKey: "note") as? String ?? "",
            source: row.value(forKey: "source") as? String ?? "watchOS"
        )
    }

    private var canUseExtendedHomeFilters: Bool {
        hasAgendaPremiumAccess
    }

    private let supportedHomeFilterValues: Set<String> = [
        "todasFrases",
        "frasesPersonales",
        "frasesFavoritas",
        "frasesConNotas",
        "frasesSalud",
        "neville",
        "jd",
        "bruce",
        "gregg",
        "otrosAutores"
    ]

    private func effectiveHomeFilters() -> [String] {
        NSUbiquitousKeyValueStore.default.synchronize()
        let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        let cloudFilters = NSUbiquitousKeyValueStore.default.array(forKey: AppCons.UD_FiltroFrasesHome) as? [String] ?? []
        let sharedFilters = sharedDefaults?.stringArray(forKey: AppCons.UD_FiltroFrasesHome) ?? []
        let standardFilters = UserDefaults.standard.stringArray(forKey: AppCons.UD_FiltroFrasesHome) ?? []

        let sourceFilters = !cloudFilters.isEmpty ? cloudFilters : (!sharedFilters.isEmpty ? sharedFilters : standardFilters)
        let filters = sourceFilters.filter { supportedHomeFilterValues.contains($0) }
        let resolvedFilters = filters.isEmpty ? ["neville"] : filters

        if canUseExtendedHomeFilters {
            return resolvedFilters
        }

        let freeFilters = resolvedFilters.filter { $0 == "neville" }
        return freeFilters.isEmpty ? ["neville"] : freeFilters
    }

    
    private func refreshHomeFrasesIfNeeded() {
        let key = "\(canUseExtendedHomeFilters)|\(effectiveHomeFilters().sorted().joined(separator: ","))"

        guard homeFrasesCache.isEmpty || homeFrasesCacheKey != key else {
            return
        }

        homeFrasesCacheKey = key

        var deduped: [NSManagedObjectID: Frases] = [:]
        for filter in effectiveHomeFilters() {
            for frase in fetchFrasesForHome(filterRawValue: filter) {
                deduped[frase.objectID] = frase
            }
        }

        homeFrasesCache = Array(deduped.values)
    }

    private func fallbackFrasesForHome() -> [(texto: String, autorCode: String)] {
        let filters = effectiveHomeFilters()
        var items: [(texto: String, autorCode: String)] = []
        var seenTexts = Set<String>()

        for filter in filters {
            for fileName in fileNamesForFallback(filterRawValue: filter) {
                for frase in parseFrasesFromFile(fileName: fileName) {
                    guard !frase.texto.isEmpty else { continue }
                    if seenTexts.insert(frase.texto).inserted {
                        items.append(frase)
                    }
                }
            }
        }

        return items
    }

    private func fileNamesForFallback(filterRawValue: String) -> [String] {
        switch filterRawValue {
        case "todasFrases":
            return [
                AppCons.FileListFrases,
                AppCons.FileListFrasesJD,
                AppCons.FileListFrasesBruceL,
                AppCons.FileListFrasesGregg,
                AppCons.FileListFrasesOtros,
                AppCons.FileListFrasesSalud
            ]
        case "neville":
            return [AppCons.FileListFrases]
        case "jd":
            return [AppCons.FileListFrasesJD]
        case "bruce":
            return [AppCons.FileListFrasesBruceL]
        case "gregg":
            return [AppCons.FileListFrasesGregg]
        case "otrosAutores":
            return [AppCons.FileListFrasesOtros]
        case "frasesSalud":
            return [AppCons.FileListFrasesSalud]
        default:
            // filtros de Core Data (favoritas, con notas, personales) no tienen equivalente directo en txt.
            return []
        }
    }

    private func parseFrasesFromFile(fileName: String) -> [(texto: String, autorCode: String)] {
        let rawContent = UtilFuncs.FileRead(fileName)
        guard !rawContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let blocks = rawContent
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var result: [(texto: String, autorCode: String)] = []

        for block in blocks {
            var texto = ""
            var autor = ""

            for line in block.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("texto=") {
                    texto = String(trimmed.dropFirst("texto=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if trimmed.hasPrefix("autor=") {
                    autor = String(trimmed.dropFirst("autor=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            if !texto.isEmpty {
                result.append((texto: texto, autorCode: autor))
            }
        }

        return result
    }

    private func fetchFrasesForHome(filterRawValue: String) -> [Frases] {
        let request: NSFetchRequest<Frases> = Frases.fetchRequest()

        switch filterRawValue {
        case "todasFrases":
            break
        case "frasesPersonales":
            request.predicate = NSPredicate(format: "noinbuilt == YES")
        case "frasesFavoritas":
            request.predicate = NSPredicate(format: "isfav == YES")
        case "frasesConNotas":
            request.predicate = NSPredicate(format: "nota != nil AND nota != ''")
        case "frasesSalud":
            request.predicate = NSPredicate(format: "autor == %@", "salud")
        case "neville":
            request.predicate = NSPredicate(format: "autor == %@", "nev")
        case "jd":
            request.predicate = NSPredicate(format: "autor == %@", "jd")
        case "bruce":
            request.predicate = NSPredicate(format: "autor == %@", "bruceL")
        case "gregg":
            request.predicate = NSPredicate(format: "autor == %@", "gregg")
        case "otrosAutores":
            request.predicate = NSPredicate(format: "NOT (autor IN %@)", ["nev", "jd", "bruceL", "gregg", "salud"])
        default:
            request.predicate = NSPredicate(format: "autor == %@", "nev")
        }

        do {
            return try context.fetch(request)
        } catch {
            msg("Error al obtener frases para Home en watch: \(error)")
            return []
        }
    }
    
    
    //------NOTAS-----
    //Obtiene todas las notas de la BD
    func getNotas(){
        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "fechaModificacion", ascending: false),
            NSSortDescriptor(key: "fechaCreacion", ascending: false)
        ]
        fetchRequest.fetchBatchSize = 25
        fetchRequest.returnsObjectsAsFaults = false

        do {
            self.listNotas = try context.fetch(fetchRequest)

        } catch {
            msg("Failed to fetch notes: \(error)")
        }
    }
    
    //Obtiene todas las notas de la BD
    func getNotasGet() -> [Notas]{
        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()
        do {
            return  try context.fetch(fetchRequest)
            
        } catch {
            msg("Failed to fetch notes: \(error)")
            return []
        }
    }
    
    //Obtiene las notas favoritas:
    func getNotasFavoritas()->[Notas]{
        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isfav == %@", NSNumber(value: true))
        
        do {
            return  try context.fetch(fetchRequest)
            
        }catch{
            msg("Failed to fetch notes: \(error)")
            return []
        }
        
        
    }
    
    //Eliminar una nota
    func deleteNota(nota : NSManagedObject)->Bool{
            let noteID = ((nota as? Notas)?.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            self.context.delete(nota)
            do{
                try self.context.save()
                WatchNotesTransferSender.shared.sendDeletedNote(id: noteID)
                return true
            }catch{
                self.context.rollback()
                return false
            }
    }

    //Crear una nueva nota usando dirección de mapa
    func addNota(title: String, nota: String = "", direccionMapa: String) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNota = nota.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return false }

        let newNota = Notas(context: self.context)
        let now = Date()
        let noteID = UUID().uuidString
        newNota.id = noteID
        newNota.title = trimmedTitle
        newNota.nota = resolvedNoteText(nota: trimmedNota, direccionMapa: trimmedAddress)
        newNota.isfav = false
        newNota.setValue(trimmedAddress, forKey: "direccionMapa")
        newNota.setValue(now, forKey: "fechaCreacion")
        newNota.setValue(now, forKey: "fechaModificacion")

        return persistAndSyncNota(newNota, fallbackCreationDate: now)
    }

    func updateNota(noteID: String, title: String, nota: String) -> Bool {
        let trimmedID = noteID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNota = nota.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, !trimmedTitle.isEmpty else { return false }

        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id == %@", trimmedID)

        guard let existing = try? context.fetch(fetchRequest).first else { return false }

        let direccionMapa = (existing.value(forKey: "direccionMapa") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        existing.title = trimmedTitle
        existing.nota = resolvedNoteText(nota: trimmedNota, direccionMapa: direccionMapa)

        return persistAndSyncNota(existing)
    }

    private func resolvedNoteText(nota: String, direccionMapa: String) -> String {
        if !nota.isEmpty { return nota }
        if !direccionMapa.isEmpty { return direccionMapa }
        return "Nota creada desde watchOS"
    }

    private func persistAndSyncNota(_ note: Notas, fallbackCreationDate: Date = Date()) -> Bool {
        let now = Date()
        let noteID = note.id ?? UUID().uuidString
        note.id = noteID

        let title = (note.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let direccionMapa = (note.value(forKey: "direccionMapa") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = resolvedNoteText(
            nota: (note.nota ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            direccionMapa: direccionMapa
        )
        note.nota = noteText

        let creationDate = (note.value(forKey: "fechaCreacion") as? Date) ?? fallbackCreationDate
        note.setValue(creationDate, forKey: "fechaCreacion")
        note.setValue(now, forKey: "fechaModificacion")

        do {
            try self.context.save()
            self.getNotas()
            WatchNotesTransferSender.shared.sendCreatedNote(
                WatchNoteTransferPayload(
                    id: noteID,
                    title: title,
                    nota: noteText,
                    direccionMapa: direccionMapa,
                    isfav: note.isfav,
                    fechaCreacion: creationDate,
                    fechaModificacion: now
                )
            )
            return true
        } catch {
            self.context.rollback()
            msg("Error al guardar nota desde watchOS: \(error.localizedDescription)")
            return false
        }
    }
    
    //Buscar en los textos de los títulos de las notas
    func searchTextInNotas(text: String, donde buscar: TipoBusqueda)->[Notas]{
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return getNotasGet()
        }

        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()

        switch buscar {
        case .contenido:
            fetchRequest.predicate = NSPredicate(format: "nota CONTAINS[cd] %@", trimmedText)
        case .titulo:
            fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", trimmedText)
        }

        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Failed to search notes: \(error)")
            return []
        }
    }
    
    
    
    //------AGENDA-----
    enum AgendaFiltroTemporal {
        case hoy
        case semanaActual
        case mesActual
    }

    func getAgendaEntradas(filtro: AgendaFiltroTemporal = .hoy) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "fechaActividad", ascending: true),
            NSSortDescriptor(key: "hora", ascending: true)
        ]

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        switch filtro {
        case .hoy:
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { break }
            request.predicate = NSPredicate(format: "fechaActividad >= %@ AND fechaActividad < %@", startOfToday as NSDate, endOfDay as NSDate)
        case .semanaActual:
            guard
                let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
            else { break }
            request.predicate = NSPredicate(format: "fechaActividad >= %@ AND fechaActividad < %@", weekInterval.start as NSDate, weekInterval.end as NSDate)
        case .mesActual:
            guard
                let monthInterval = calendar.dateInterval(of: .month, for: now)
            else { break }
            request.predicate = NSPredicate(format: "fechaActividad >= %@ AND fechaActividad < %@", monthInterval.start as NSDate, monthInterval.end as NSDate)
        }

        do {
            let rows = try context.fetch(request)
            self.listAgenda = deduplicateAgendaRows(rows).compactMap(mapAgendaEntity)
        } catch {
            self.listAgenda = []
            msg("Failed to fetch agenda: \(error)")
        }
    }

    func addAgendaEntry(title: String, contenido: String = "", lugar: String = "", fechaActividad: Date = .now, hora: Date = .now) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return false }

        guard let entity = NSEntityDescription.entity(forEntityName: "AgendaItemEntity", in: context) else { return false }

        let now = Date()
        let uuid = UUID()
        let row = NSManagedObject(entity: entity, insertInto: context)
        row.setValue(uuid, forKey: "id")
        row.setValue(trimmedTitle, forKey: "titulo")
        row.setValue(now, forKey: "fechaCreacion")
        row.setValue(now, forKey: "fechaModificacion")
        row.setValue("", forKey: "nota")
        row.setValue(Calendar.current.startOfDay(for: fechaActividad), forKey: "fechaActividad")
        row.setValue(hora, forKey: "hora")
        row.setValue(lugar.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "lugar")
        row.setValue(contenido.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "contenido")
        row.setValue("neutral", forKey: "prioridad")
        row.setValue("#A9D7A4", forKey: "colorHex")
        row.setValue(nil, forKey: "completada")
        row.setValue(false, forKey: "recordatorioActivo")
        row.setValue(nil, forKey: "reminderID")
        row.setValue(nil, forKey: "seriesID")

        do {
            try context.save()
            getAgendaEntradas()

            WatchAgendaTransferSender.shared.sendCreatedAgenda(
                WatchAgendaTransferPayload(
                    id: uuid.uuidString,
                    titulo: trimmedTitle,
                    fechaCreacion: now,
                    fechaModificacion: now,
                    nota: "",
                    fechaActividad: Calendar.current.startOfDay(for: fechaActividad),
                    hora: hora,
                    lugar: lugar.trimmingCharacters(in: .whitespacesAndNewlines),
                    contenido: contenido.trimmingCharacters(in: .whitespacesAndNewlines),
                    prioridad: "neutral",
                    colorHex: "#A9D7A4",
                    completada: nil,
                    recordatorioActivo: false,
                    reminderID: nil,
                    seriesID: nil
                )
            )
            return true
        } catch {
            context.rollback()
            msg("Error al guardar agenda desde watchOS: \(error.localizedDescription)")
            return false
        }
    }

    private func mapAgendaEntity(_ object: NSManagedObject) -> WatchAgendaItem? {
        guard let id = object.value(forKey: "id") as? UUID else { return nil }

        let fechaCreacion = object.value(forKey: "fechaCreacion") as? Date ?? Date()
        let fechaModificacion = object.value(forKey: "fechaModificacion") as? Date ?? fechaCreacion
        let prioridadRaw = (object.value(forKey: "prioridad") as? String) ?? "neutral"

        return WatchAgendaItem(
            id: id,
            titulo: (object.value(forKey: "titulo") as? String) ?? "",
            fechaCreacion: fechaCreacion,
            fechaModificacion: fechaModificacion,
            nota: (object.value(forKey: "nota") as? String) ?? "",
            fechaActividad: (object.value(forKey: "fechaActividad") as? Date) ?? Date(),
            hora: (object.value(forKey: "hora") as? Date) ?? Date(),
            lugar: (object.value(forKey: "lugar") as? String) ?? "",
            contenido: (object.value(forKey: "contenido") as? String) ?? "",
            prioridad: prioridadRaw,
            colorHex: (object.value(forKey: "colorHex") as? String) ?? "#A9D7A4",
            completada: object.value(forKey: "completada") as? Bool,
            recordatorioActivo: (object.value(forKey: "recordatorioActivo") as? Bool) ?? false,
            reminderID: object.value(forKey: "reminderID") as? String,
            seriesID: object.value(forKey: "seriesID") as? UUID
        )
    }

    func deleteAgendaEntry(id: UUID) -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let rows = try context.fetch(request)
            guard !rows.isEmpty else { return false }

            rows.forEach(context.delete)
            try context.save()
            getAgendaEntradas()
            WatchAgendaTransferSender.shared.sendDeletedAgenda(id: id.uuidString)
            return true
        } catch {
            context.rollback()
            msg("Error al eliminar agenda desde watchOS: \(error.localizedDescription)")
            return false
        }
    }

    //------DIARIO-----
    //Obtiene las entradas del Diario
    func getDiarioEntradas() {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
        // Ordenar por fecha descendente (del más reciente al más antiguo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        
        do {
            self.listDiario = deduplicateDiarioRows(try context.fetch(fetchRequest))
        } catch {
            msg("Failed to fetch notes: \(error)")
        }
    }

    func addDiarioEntry(title: String, content: String, emotion: String, isFav: Bool = false, direccionMapa: String = "") -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmotion = emotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedContent.isEmpty else { return false }

        let diario = Diario(context: context)
        let now = Date.now
        let dayStart = Calendar.current.startOfDay(for: now)
        let uuid = UUID()
        diario.id = uuid
        diario.title = trimmedTitle
        diario.content = trimmedContent
        diario.emotion = trimmedEmotion.isEmpty ? Emoticono2.neutral.txt : trimmedEmotion
        diario.isFav = isFav
        diario.setValue(trimmedAddress, forKey: "direccionMapa")
        diario.fecha = dayStart
        diario.fechaM = now

        do {
            try context.save()
            self.getDiarioEntradas()
            WatchDiarioTransferSender.shared.sendCreatedDiario(
                WatchDiarioTransferPayload(
                    id: uuid.uuidString,
                    title: trimmedTitle,
                    content: trimmedContent,
                    emotion: diario.emotion ?? Emoticono2.neutral.txt,
                    isFav: isFav,
                    direccionMapa: trimmedAddress,
                    fecha: dayStart,
                    fechaM: now
                )
            )
            return true
        } catch {
            context.rollback()
            msg("Error al guardar diario desde watchOS: \(error.localizedDescription)")
            return false
        }
    }

    func deleteDiarioEntry(_ diario: Diario) -> Bool {
        guard let id = diario.id else { return false }

        context.delete(diario)

        do {
            try context.save()
            getDiarioEntradas()
            WatchDiarioTransferSender.shared.sendDeletedDiario(id: id.uuidString)
            return true
        } catch {
            context.rollback()
            msg("Error al eliminar diario desde watchOS: \(error.localizedDescription)")
            return false
        }
    }
    
    //Obtiene las entradas del Diario
    func getDiarioEntradasGet()->[Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
        // Ordenar por fecha descendente (del más reciente al más antiguo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Failed to fetch notes: \(error)")
            return []
        }
    }
    
    //Obtiene las entradas del diario favoritas
    func getDiarioEntradasFavoritas()->[Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isfav == %@", NSNumber(value: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        do {
            return try context.fetch(fetchRequest)
            
        }catch{
            return []
        }
    }
    
    //Obtiene las entradas del Diario según la emotion dada
    func getDiarioEntradasPorEmotion(emotion : String)->[Diario]{
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "emotion == %@", emotion)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        do {
            return try context.fetch(fetchRequest)
            
        }catch{
            return []
        }
    }
    
    //Busca en los títulos o el contenido
    //Buscar en los textos de los títulos de las notas
    func searchTextInDiario(text: String, donde buscar: TipoBusqueda)->[Diario]{
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return getDiarioEntradasGet()
        }

        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]

        switch buscar {
        case .contenido:
            fetchRequest.predicate = NSPredicate(format: "content CONTAINS[cd] %@", trimmedText)
        case .titulo:
            fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", trimmedText)
        }

        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Failed to search diario: \(error)")
            return []
        }
    }
    
    //Busca entradas por emociones
    func searchPorEmotion(emotion: String)->[Diario]{
        let arrayDiario = getDiarioEntradasGet()
        return arrayDiario.filter{$0.emotion?.lowercased() == emotion.lowercased()}
    }
    
    //Buscar por fecha de creación
    func searchPorFecha(for date: Date) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        
        // Obtener el rango de la fecha (00:00 - 23:59)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Configurar el predicado para buscar en ese rango
        fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    //Buscar en un rango de fechas
    func searchPorRangoFecha(from startDate: Date, to endDate: Date) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        
        // Obtener el comienzo del día de startDate y el final del día de endDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        // Configurar el predicado para buscar en el rango
        fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    
    //Buscar según antiguedad:
    func searchPorAntiguedad(for antiguedad: Antiguedad) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // Inicio del día actual
        var startDate: Date
        
        // Determinar la fecha de inicio según la antigüedad
        switch antiguedad {
        case .tresDias:
            startDate = calendar.date(byAdding: .day, value: -3, to: today)!
        case .semana:
            startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        case .quincena:
            startDate = calendar.date(byAdding: .day, value: -15, to: today)!
        case .mes:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)!
        case .dosMeses:
            startDate = calendar.date(byAdding: .month, value: -2, to: today)!
        case .tresMeses:
            startDate = calendar.date(byAdding: .month, value: -3, to: today)!
        case .seisMeses:
            startDate = calendar.date(byAdding: .month, value: -6, to: today)!
        case .unAno:
            startDate = calendar.date(byAdding: .year, value: -1, to: today)!
        case .dosAnos:
            startDate = calendar.date(byAdding: .year, value: -2, to: today)!
        case .tresAnos:
            startDate = calendar.date(byAdding: .year, value: -3, to: today)!
        case .cincoAnos:
            startDate = calendar.date(byAdding: .year, value: -5, to: today)!
        case .diezAnos:
            startDate = calendar.date(byAdding: .year, value: -10, to: today)!
        }
        
        // Configurar el predicado para obtener entradas desde startDate hasta hoy
        fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha <= %@", startDate as NSDate, today as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    
    
    //Opciones para los filtros de busqueda
    enum TipoBusqueda {
        case titulo
        case contenido
    }
    

    
    enum Antiguedad : String{
        case tresDias, semana, quincena, mes, dosMeses, tresMeses, seisMeses, unAno, dosAnos, tresAnos, cincoAnos, diezAnos
    }

    private func deduplicateDiarioRows(_ fetched: [Diario]) -> [Diario] {
        let groupedByID = Dictionary(grouping: fetched) { item in
            item.id?.uuidString ?? ""
        }

        var idsToDelete = Set<NSManagedObjectID>()

        for (id, items) in groupedByID where !id.isEmpty && items.count > 1 {
            let keeper = items.max { lhs, rhs in
                (lhs.fechaM ?? lhs.fecha ?? .distantPast) < (rhs.fechaM ?? rhs.fecha ?? .distantPast)
            }

            for item in items where item.objectID != keeper?.objectID {
                idsToDelete.insert(item.objectID)
                context.delete(item)
            }
        }

        guard !idsToDelete.isEmpty else { return fetched }
        try? context.save()
        return fetched.filter { !idsToDelete.contains($0.objectID) }
    }

    private func deduplicateAgendaRows(_ fetched: [NSManagedObject]) -> [NSManagedObject] {
        let groupedByID = Dictionary(grouping: fetched) { item in
            (item.value(forKey: "id") as? UUID)?.uuidString ?? ""
        }

        var idsToDelete = Set<NSManagedObjectID>()

        for (id, items) in groupedByID where !id.isEmpty && items.count > 1 {
            let keeper = items.max { lhs, rhs in
                agendaComparableDate(lhs) < agendaComparableDate(rhs)
            }

            for item in items where item.objectID != keeper?.objectID {
                idsToDelete.insert(item.objectID)
                context.delete(item)
            }
        }

        guard !idsToDelete.isEmpty else { return fetched }
        try? context.save()
        return fetched.filter { !idsToDelete.contains($0.objectID) }
    }

    private func agendaComparableDate(_ object: NSManagedObject) -> Date {
        if let modified = object.value(forKey: "fechaModificacion") as? Date {
            return modified
        }
        if let created = object.value(forKey: "fechaCreacion") as? Date {
            return created
        }
        return .distantPast
    }
}

enum Emoticono2:String, CaseIterable{
    case feliz = "😃", neutral = "🙂", enfadado = "😤", sorpresa = "😲", distraido = "🙄",desanimado = "😔"
    var txt : String{
        switch self{
        case .desanimado   : "desanimado"
        case .distraido    : "distraido"
        case .enfadado     : "enfadado"
        case .feliz        : "feliz"
        case .neutral      : "neutral"
        case .sorpresa     : "sorpresa"
        }
    }
    }
