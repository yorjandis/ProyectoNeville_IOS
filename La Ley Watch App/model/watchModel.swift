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
    
    
    
    private init() {
        self.getNotas()
        self.getDiarioEntradas()
    }

    //------FRASES-----
    ///Obtiene la lista de frases del fichero txt in-built(De momento no muestra las frases personales, deben ser solicitadas desde iOS):
    /// - Returns: Devuelve un  arreglo de cadenas con las frases cargadas del txt en Staff
    func getfrasesArrayFromTxtFile(){
        self.listfrases.removeAll()
        //Extrayendo las frases inbuilt, almacenadas dentro del bundle de la App
        self.listfrases = UtilFuncs.FileReadToArray(AppCons.FileListFrases)
        
        //Agregando las frases noInbuit, de la Tabla Frases
        let fetchRequest : NSFetchRequest<Frases> = NSFetchRequest(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "noinbuilt == %@", NSNumber(value: true))
        fetchRequest.predicate = predicate
        do{
            let elements = try self.context.fetch(fetchRequest)
            for item in elements{
                if let frase = item.frase{
                    self.listfrases.append(frase)
                }
            }
        }catch{
            print("Error al recuperar las frases desde Core Data: \(error.localizedDescription)")
        }
    }
    
    
    //------NOTAS-----
    //Obtiene todas las notas de la BD
    func getNotas(){
        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()
        do {
            self.listNotas = try context.fetch(fetchRequest)

        } catch {
            print("Failed to fetch notes: \(error)")
        }
    }
    
    //Obtiene todas las notas de la BD
    func getNotasGet() -> [Notas]{
        let fetchRequest: NSFetchRequest<Notas> = Notas.fetchRequest()
        do {
            return  try context.fetch(fetchRequest)
            
        } catch {
            print("Failed to fetch notes: \(error)")
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
            print("Failed to fetch notes: \(error)")
            return []
        }
        
        
    }
    
    //Eliminar una nota
    func deleteNota(nota : NSManagedObject)->Bool{
        self.context.performAndWait {
            self.context.delete(nota)
            do{
                try self.context.save()
                return true
            }catch{
                self.context.rollback()
                return false
            }
        }
    }
    
    //Buscar en los textos de los títulos de las notas
    func searchTextInNotas(text: String, donde buscar: TipoBusqueda)->[Notas]{
        
        let arrayNotas = getNotasGet()
        var result : [Notas] = []
        
        for item in arrayNotas {
            
            switch buscar{
            case .contenido:
                let temp = item.nota?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            case .titulo:
                let temp = item.title?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            }
        }
        
        return result
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
            print("Failed to fetch notes: \(error)")
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
            print("Failed to fetch notes: \(error)")
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
        
        let arrayDiario = getDiarioEntradasGet()
        
        var result : [Diario] = []
        
        for item in arrayDiario {
            
            switch buscar{
            case .contenido:
                let temp = item.content?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            case .titulo:
                let temp = item.title?.lowercased() ?? ""
                if temp.contains(text.lowercased()){
                    result.append(item)
                }
            }
        }
        
        return result
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
            print("Error al recuperar entradas: \(error)")
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
            print("Error al recuperar entradas: \(error)")
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
            print("Error al recuperar entradas: \(error)")
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
