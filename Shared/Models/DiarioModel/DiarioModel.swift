//
//  DiarioModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//
//Controla las funciones de diario

/*
El diario se basa en un arreglo de entradas. 
Cada entrada contiene un registro de la tabla Diario

 Para el usuario se mostrará dos Views:
 ->Una que contiene un arreglo de entradas
 ->y la otra que muestra detalles de una entrada seleccionada

*/

import Foundation
import CoreData
import Combine

extension Notification.Name {
    static let diarioDeletedForWatchSync = Notification.Name("diarioDeletedForWatchSync")
}

enum Emociones : String, CaseIterable{
    case feliz      = "feliz",
         triste     = "triste",
         enfado     = "enfadado",
         desanimado = "desanimado",
         sorpresa   = "sorpresa",
         distraido  = "distraido",
         neutral    = "neutral",
         enamorado  = "enamorado",
         enfermo    = "enfermo",
         pensativo  = "pensativo",
         festivo    = "Festivo"

    var emoji: String {
        switch self {
        case .neutral: "🙂"
        case .feliz: "😊"
        case .triste: "🥺"
        case .enfado: "😤"
        case .desanimado: "😔"
        case .distraido: "🙄"
        case .sorpresa: "😮"
        case .enamorado: "🥰"
        case .enfermo: "🤒"
        case .pensativo: "🤔"
        case .festivo: "🥳"
        }
    }

    /// Nombre visible de la emoción. El `rawValue` sigue siendo el valor
    /// canónico guardado en Core Data y usado por los filtros.
    var localizedTitle: String {
        switch self {
        case .feliz: L10n.exact("Feliz")
        case .triste: L10n.exact("Triste")
        case .enfado: L10n.exact("Enfadado")
        case .desanimado: L10n.exact("Desanimado")
        case .sorpresa: L10n.exact("Sorprendido")
        case .distraido: L10n.exact("Distraído")
        case .neutral: L10n.exact("Neutral")
        case .enamorado: L10n.exact("Enamorado")
        case .enfermo: L10n.exact("Enfermo")
        case .pensativo: L10n.exact("Pensativo")
        case .festivo: L10n.exact("Festivo")
        }
    }

    static func localizedTitle(from rawValue: String?) -> String {
        Emociones(rawValue: rawValue ?? "")?.localizedTitle
            ?? (rawValue?.capitalized ?? L10n.exact("Neutral"))
    }

    static func emoji(from rawValue: String?) -> String {
        Emociones(rawValue: rawValue ?? "")?.emoji ?? Emociones.neutral.emoji
    }
}


@MainActor
final class DiarioModel : ObservableObject{

    @Published var list : [Diario] = []
    
    @Published var expandirEntrada : String = ""
    
    @Published var intentTestYor : Bool = false
    
    
    //Obtiene el valor de una variable de UserDefault
    private var getUserDefaultOrdenarEntradasDiario : Bool {
        if UserDefaults.standard.object(forKey: AppCons.UD_setting_OrdenarEntradaDiario) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppCons.UD_setting_OrdenarEntradaDiario)
    }
    
    
    
    static let shared = DiarioModel() //Singleton
    
    
    private let context = CoreDataController.shared.context
    private var observers = Set<AnyCancellable>()
    
    
    private init(){
        setupObservers()
        getAllItem()
    }

    private func setupObservers() {
        let center = NotificationCenter.default

        center.publisher(for: .coreDataStoresDidLoad)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getAllItem()
            }
            .store(in: &observers)

        center.publisher(for: .NSPersistentStoreRemoteChange,
                         object: CoreDataController.shared.persistentContainer.persistentStoreCoordinator)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.context.refreshAllObjects()
                self?.getAllItem()
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
            self?.getAllItem()
        }
        .store(in: &observers)
        #endif

        center.publisher(for: .NSManagedObjectContextDidSave,
                         object: context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getAllItem()
            }
            .store(in: &observers)
    }

    private func defaultSortDescriptors(ascending: Bool = false) -> [NSSortDescriptor] {
        let keyPath: KeyPath<Diario, Date?> = getUserDefaultOrdenarEntradasDiario ? \Diario.fecha : \Diario.fechaM
        return [NSSortDescriptor(keyPath: keyPath, ascending: ascending)]
    }
    
    //Obtiene el valor enum de Emociones a partir de una cadena de texto
    func getEmocionesFromStr(value : String)->Emociones{
        Emociones(rawValue: value) ?? .neutral
    }
    
    
    
    ///Obtiene todos los item de la tabla Diario. Devuelve un arreglo
    func getAllItem(){
        let fechtRequest : NSFetchRequest<Diario> = Diario.fetchRequest()
        fechtRequest.fetchBatchSize = 100
        fechtRequest.sortDescriptors = defaultSortDescriptors()
        
        
        do{
            self.list = deduplicateDiarioByID(try context.fetch(fechtRequest))
        }catch{
            self.list = []
        }
    }

    private func deduplicateDiarioByID(_ fetched: [Diario]) -> [Diario] {
        let groupedByID = Dictionary(grouping: fetched) { diario in
            diario.id?.uuidString ?? ""
        }

        var idsToDelete = Set<NSManagedObjectID>()

        for (id, diarios) in groupedByID where !id.isEmpty && diarios.count > 1 {
            let keeper = diarios.max { lhs, rhs in
                comparableDate(for: lhs) < comparableDate(for: rhs)
            }

            for diario in diarios where diario.objectID != keeper?.objectID {
                idsToDelete.insert(diario.objectID)
                context.delete(diario)
            }
        }

        guard !idsToDelete.isEmpty else { return fetched }

        do {
            try context.save()
        } catch {
            context.rollback()
            msg("❌ Error eliminando entradas duplicadas de Diario: \(error.localizedDescription)")
            return fetched
        }

        return fetched.filter { !idsToDelete.contains($0.objectID) }
    }

    private func comparableDate(for diario: Diario) -> Date {
        if let modified = diario.fechaM {
            return modified
        }
        if let created = diario.fecha {
            return created
        }
        return .distantPast
    }
    
    ///Obtiene todos los item de la tabla Diario. Devuelve un arreglo
    func getAllItemGET() -> [Diario]{
        let fechtRequest : NSFetchRequest<Diario> = Diario.fetchRequest()
        fechtRequest.fetchBatchSize = 100
        // Retorna en orden ascendente para preservar el resultado actual de reversed().
        fechtRequest.sortDescriptors = defaultSortDescriptors(ascending: true)

        do{
            return try context.fetch(fechtRequest)
        }catch{
            return []
        }
    }
    
    //Obtiene todas las entradas registradas en un mes dado
    //Usado en las funciones del Calendario
    func getEntriesByMonth(forDate date: Date) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        
        fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@", startDate as NSDate, endDate as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al obtener las entradas: \(error.localizedDescription)")
            return []
        }
    }

    //Devuelve el número de entradas por día para el mes de la fecha indicada.
    func getEntryCountByCreationDay(forMonth date: Date) -> [Date: Int] {
        let calendar = Calendar.current
        let monthEntries = getEntriesByMonth(forDate: date)
        let normalized = monthEntries.compactMap { $0.fecha }.map { calendar.startOfDay(for: $0) }
        return Dictionary(grouping: normalized, by: { $0 }).mapValues(\.count)
    }
    
    //Determinar si una fecha dada corresponde a la fecha actua:
    func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    
    //Para las funciones de calendario del diario. Utilizado en el archivo DiarioCalendarView.
    //Devuelve un set de las fechas de las entradas, normalizadas al dia y en orden ascendente.
    func fetchEntradasForCalendar() -> Set<Date> {
            let request: NSFetchRequest<Diario> = Diario.fetchRequest()
            request.fetchBatchSize = 200
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fecha, ascending: true)]

            do {
                let resultados = try context.fetch(request)
                let fechas = resultados.compactMap { $0.fecha?.startOfDay() }
                        return Set(fechas)
            } catch {
                //print("Error al obtener las entradas: \(error)")
                return []
            }
        }
    
    ///Adiciona un item a la tabla Diario
    func addItem(title : String, emocion : Emociones, content : String, isFav : Bool = false, direccionMapa: String = "", capitulo: String = "" )->Bool{
        return addItem(title: title, emocion: emocion, content: content, fechaCreacion: Date.now, isFav: isFav, direccionMapa: direccionMapa, capitulo: capitulo)
    }

    ///Adiciona un item a la tabla Diario con fecha de creación personalizada.
    func addItem(title : String, emocion : Emociones, content : String, fechaCreacion: Date, isFav : Bool = false, direccionMapa: String = "", capitulo: String = "" )->Bool{
        let diario : Diario = Diario(context: context)
        diario.id = UUID()
        diario.title = title
        diario.emotion = emocion.rawValue
        diario.isFav = isFav
        diario.content = content
        diario.setValue(capitulo.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "capitulo")
        diario.setValue(direccionMapa, forKey: "direccionMapa")
        diario.fecha = Calendar.current.startOfDay(for: fechaCreacion)
        diario.fechaM = Date.now

        if context.hasChanges {
            try? context.save()
            return true
        }
        return false
    }
    
    //Actualiza una entrada: La fecha se actualiza automáticamente.
    func UpdateItem(diario : Diario, title : String,  content : String, emoticono : Emociones, isFav : Bool = false, direccionMapa: String = "", capitulo: String = "" ){
        diario.title = title
        diario.emotion = emoticono.rawValue
        diario.isFav = isFav
        diario.content = content
        diario.setValue(capitulo.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "capitulo")
        diario.setValue(direccionMapa, forKey: "direccionMapa")
        diario.fechaM = Date.now
        if context.hasChanges {
            try? context.save()
        }
    }

    ///Actualiza el capítulo de varias entradas del diario en una sola operación.
    func UpdateCapitulo(capitulo: String, ids: Set<UUID>) {
        guard !ids.isEmpty else { return }

        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", Array(ids))

        do {
            let entries = try context.fetch(fetchRequest)
            let now = Date.now
            let trimmedCapitulo = capitulo.trimmingCharacters(in: .whitespacesAndNewlines)
            entries.forEach { diario in
                diario.setValue(trimmedCapitulo, forKey: "capitulo")
                diario.fechaM = now
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
            msg(error.localizedDescription)
        }
    }
    
    
    ///Elimina un item de la tabla diario
    func DeleteItem(diario : Diario){
         let diarioID = diario.id?.uuidString ?? ""
         context.delete(diario)
        if context.hasChanges {
            do{
                try context.save()
                postDeletedDiarioForWatchSync(id: diarioID)
            }catch{
                context.rollback()
                msg(error.localizedDescription)
            }
        }
    }

    ///Elimina varias entradas del diario en una sola operación.
    func DeleteItems(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }

        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", Array(ids))

        do {
            let entries = try context.fetch(fetchRequest)
            let deletedIDs = entries.compactMap { $0.id?.uuidString }
            entries.forEach { context.delete($0) }

            if context.hasChanges {
                try context.save()
                deletedIDs.forEach(postDeletedDiarioForWatchSync)
            }
        } catch {
            context.rollback()
            msg(error.localizedDescription)
        }
    }

    private func postDeletedDiarioForWatchSync(id: String) {
        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return }

        NotificationCenter.default.post(
            name: .diarioDeletedForWatchSync,
            object: nil,
            userInfo: ["id": trimmedID]
        )
    }
    
    //Actualizar el emoticono
    func UpdateEmoticono(emoticono : Emociones, diario : Diario){
        diario.emotion = emoticono.rawValue
        diario.fechaM = Date.now
        if context.hasChanges {
            try? context.save()
        }
    }

    ///Actualiza el emoticono de varias entradas del diario en una sola operación.
    func UpdateEmoticono(emoticono: Emociones, ids: Set<UUID>) {
        guard !ids.isEmpty else { return }

        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", Array(ids))

        do {
            let entries = try context.fetch(fetchRequest)
            let now = Date.now
            entries.forEach { diario in
                diario.emotion = emoticono.rawValue
                diario.fechaM = now
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
            msg(error.localizedDescription)
        }
    }
    
    //Actualizar el título
    func UpdateTitle(title : String, diario : Diario){
        diario.title    = title
        diario.fechaM   = Date.now
        if context.hasChanges {
            try? context.save()
        }
    }
    
    //Actualizar el título
    func UpdateContent(content : String, diario : Diario){
        diario.content = content
        diario.fechaM = Date.now
        if context.hasChanges {
            try? context.save()
        }
    }
    
    //Actualizar el estado de favorito
    func UpdateFav(isFav : Bool, diario : Diario){
        diario.isFav = isFav
        diario.fechaM = Date.now
        if context.hasChanges {
            try? context.save()
        }
    }
    
    //MARK Operaciones de filtrado
    
    //Filtrar por título: Case Insentitive
    func filterByTitle(criterio : String)->[Diario]{
        if criterio.isEmpty {
            return getAllItemGET()
        }
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        fetchRequest.sortDescriptors = defaultSortDescriptors(ascending: true)
        fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", criterio)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    //Filtrar por contenido: Case Insentitive
    func filterByContent(criterio : String)->[Diario]{
        if criterio.isEmpty {
            return getAllItemGET()
        }
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        fetchRequest.sortDescriptors = defaultSortDescriptors(ascending: true)
        fetchRequest.predicate = NSPredicate(format: "content CONTAINS[cd] %@", criterio)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    //Filtrar por emoticono: Case Insentitive
    func filterByEmoticono(criterio : String)->[Diario]{
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        fetchRequest.sortDescriptors = defaultSortDescriptors(ascending: true)
        fetchRequest.predicate = NSPredicate(format: "emotion == %@", criterio)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    //Filtrar por Favorito: Devuelve todas las entradas favoritas
    func filterByFav()->[Diario]{
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        fetchRequest.sortDescriptors = defaultSortDescriptors(ascending: true)
        fetchRequest.predicate = NSPredicate(format: "isFav == YES")
        do {
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    //Buscar por fecha de creación
    func searchPorFecha(for date: Date, typeFecha : TypeFecha = .FechaCreacion ) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        
        // Obtener el rango de la fecha (00:00 - 23:59)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Configurar el predicado para buscar en ese rango sefún el tipo de fecha:
        switch typeFecha {
        case .FechaCreacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fecha, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@", startOfDay as NSDate, endOfDay as NSDate)
        case .FechaModificacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fechaM >= %@ AND fechaM < %@", startOfDay as NSDate, endOfDay as NSDate)
        }
       
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    //Buscar en un rango de fechas
    func searchPorRangoFecha(from startDate: Date, to endDate: Date, typeFecha : TypeFecha = .FechaCreacion ) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        
        
        // Obtener el comienzo del día de startDate y el final del día de endDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        // Configurar el predicado para buscar en el rango según el tipo de fecha:
        switch typeFecha {
        case .FechaCreacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fecha, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@", startOfDay as NSDate, endOfDay as NSDate)
        case .FechaModificacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fechaM >= %@ AND fechaM < %@", startOfDay as NSDate, endOfDay as NSDate)
        }
        
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    
    //Buscar según antiguedad:
    func searchPorAntiguedad(for antiguedad: Antiguedad, typeFecha : TypeFecha = .FechaCreacion ) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        fetchRequest.fetchBatchSize = 100
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // Inicio del día actual
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: today)!
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
        switch typeFecha {
        case .FechaCreacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fecha, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@", startDate as NSDate, endOfToday as NSDate)
        case .FechaModificacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fechaM >= %@ AND fechaM < %@", startDate as NSDate, endOfToday as NSDate)
        }
        
        
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            msg("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    
    
    
    enum Antiguedad{
        case tresDias, semana, quincena, mes, dosMeses, tresMeses, seisMeses, unAno, dosAnos, tresAnos, cincoAnos, diezAnos
    }
    
   
}

enum TypeFecha{
    case FechaCreacion, FechaModificacion
    }
