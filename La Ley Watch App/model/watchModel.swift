//
//  watchModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 15/2/25.
//

import SwiftUI
import CoreData

@MainActor
final class watchModel: ObservableObject {
    
    let context  : NSManagedObjectContext = CoreDataController.shared.context
    
    static let shared : watchModel = watchModel() //Singleton
    
    
    @Published var listfrases : [String] = []
    
    @Published var listNotas : [Notas] = []
    
    @Published var listDiario : [Diario] = []

    private var homeFrasesCache: [Frases] = []
    private var homeFrasesCacheKey: String = ""

    private init() {
        self.getNotas()
        self.getDiarioEntradas()
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

    var yorjPremiumAccessValue: Bool {
        hasYorjPremiumAccess
    }

    private var canUseExtendedHomeFilters: Bool {
        hasPremiumAccess || hasYorjPremiumAccess
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
            self.context.delete(nota)
            do{
                try self.context.save()
                return true
            }catch{
                self.context.rollback()
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
    
    
    
    //------DIARIO-----
    //Obtiene las entradas del Diario
    func getDiarioEntradas() {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
        // Ordenar por fecha descendente (del más reciente al más antiguo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        
        do {
            self.listDiario = try context.fetch(fetchRequest)
        } catch {
            msg("Failed to fetch notes: \(error)")
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
