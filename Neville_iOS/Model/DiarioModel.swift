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

enum Emociones : String{
    case feliz      = "feliz",
         enfado     = "enfadado",
         desanimado = "desanimado",
         sorpresa   = "sorpresa",
         distraido  = "distraido",
         neutral    = "neutral"
}


@MainActor
final class DiarioModel : ObservableObject{

    @Published var list : [Diario] = []
    
    
    
    static let shared = DiarioModel() //Singleton
    
    
    private let context = CoreDataController.shared.context
    
    
    private init(){
        getAllItem()
    }
    
    //Obtiene el valor enum de Emociones a partir de una cadena de texto
    func getEmocionesFromStr(value : String)->Emociones{
        switch value{
        case "feliz"        : Emociones.feliz
        case "enfadado"     : Emociones.enfado
        case "desanimado"   : Emociones.desanimado
        case "sorpresa"     : Emociones.sorpresa
        case "distraido"    : Emociones.distraido
        case "neutral"      : Emociones.neutral
        default             : Emociones.neutral  //By default
        }
    }
    
    
    
    ///Obtiene todos los item de la tabla Diario. Devuelve un arreglo
    func getAllItem(){
        let fechtRequest : NSFetchRequest<Diario> = Diario.fetchRequest()
        // Ordenar por fecha descendente (del más reciente al más antiguo)
        fechtRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
        
        do{
            self.list =  try context.fetch(fechtRequest)
        }catch{
            self.list = []
        }
    }
    
    ///Obtiene todos los item de la tabla Diario. Devuelve un arreglo
    func getAllItemGET() -> [Diario]{
        let fechtRequest : NSFetchRequest<Diario> = Diario.fetchRequest()
        
        do{
            let temp =  try context.fetch(fechtRequest)
            return temp.reversed()
        }catch{
            return []
        }
    }
    
    //Obtiene todas las entradas registradas en un mes dado
    //Usado en las funciones del Calendario
    func getEntriesByMonth(forDate date: Date) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
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
            print("Error al obtener las entradas: \(error.localizedDescription)")
            return []
        }
    }
    
    //Determinar si una fecha dada corresponde a la fecha actua:
    func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    
    ///Adiciona un item a la tabla Diario
    func addItem(title : String, emocion : Emociones, content : String, isFav : Bool = false )->Bool{
        let diario : Diario = Diario(context: context)
        diario.id = UUID()
        diario.title = title
        diario.emotion = emocion.rawValue
        diario.isFav = isFav
        diario.content = content
        diario.fecha = Date.now
        diario.fechaM = Date.now
        
        if context.hasChanges {
            try? context.save()
            return true
        }
        return false
    }
    
    //Actualiza una entrada: La fecha se actualiza automáticamente.
    func UpdateItem(diario : Diario, title : String,  content : String, emoticono : Emociones, isFav : Bool = false ){
        diario.title = title
        diario.emotion = emoticono.rawValue
        diario.isFav = isFav
        diario.content = content
        diario.fechaM = Date.now
        if context.hasChanges {
            try? context.save()
        }
    }
    
    
    ///Elimina un item de la tabla diario
    func DeleteItem(diario : Diario){
         context.delete(diario)
        if context.hasChanges {
            do{
                try context.save()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    //Actualizar el emoticono
    func UpdateEmoticono(emoticono : Emociones, diario : Diario){
        diario.emotion = emoticono.rawValue
        diario.fechaM = Date.now
        if context.hasChanges {
            try? context.save()
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
        if context.hasChanges {
            try? context.save()
        }
    }
    
    //Actualizar el estado de favorito
    func UpdateFav(isFav : Bool, diario : Diario){
        diario.isFav = isFav
        if context.hasChanges {
            try? context.save()
        }
    }
    
    //MARK Operaciones de filtrado
    
    //Filtrar por título: Case Insentitive
    func filterByTitle(criterio : String)->[Diario]{
         var result : [Diario] = []
         let listDiarios = self.getAllItemGET()
        
        for diario in listDiarios {
            let temp = diario.title?.lowercased() ?? ""
            if temp.contains(criterio.lowercased()){
                result.append(diario)
            }
        }

        return result
    }
    
    //Filtrar por contenido: Case Insentitive
    func filterByContent(criterio : String)->[Diario]{
         var result : [Diario] = []
         let listDiarios = self.getAllItemGET()
        
        for diario in listDiarios {
            let temp = diario.content?.lowercased() ?? ""
            if temp.contains(criterio.lowercased()){
                result.append(diario)
            }
        }

        return result
    }
    
    //Filtrar por emoticono: Case Insentitive
    func filterByEmoticono(criterio : String)->[Diario]{
         var result : [Diario] = []
         let listDiarios = self.getAllItemGET()
        
        for diario in listDiarios {
            if diario.emotion == criterio {
                result.append(diario)
            }
        }

        return result
    }
    
    //Filtrar por Favorito: Devuelve todas las entradas favoritas
    func filterByFav()->[Diario]{
         var result : [Diario] = []
         let listDiarios = self.getAllItemGET()
        
        for diario in listDiarios {
            
            if diario.isFav {
                result.append(diario)
            }
        }

        return result
    }
    
    //Buscar por fecha de creación
    func searchPorFecha(for date: Date, typeFecha : TypeFecha = .FechaCreacion ) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
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
            fetchRequest.predicate = NSPredicate(format: "fechaM >= %@ AND fecha < %@", startOfDay as NSDate, endOfDay as NSDate)
        }
       
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    //Buscar en un rango de fechas
    func searchPorRangoFecha(from startDate: Date, to endDate: Date, typeFecha : TypeFecha = .FechaCreacion ) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
        
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
            print("Error al recuperar entradas: \(error)")
            return []
        }
    }
    
    
    //Buscar según antiguedad:
    func searchPorAntiguedad(for antiguedad: Antiguedad, typeFecha : TypeFecha = .FechaCreacion ) -> [Diario] {
        let fetchRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        
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
        switch typeFecha {
        case .FechaCreacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fecha, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fecha >= %@ AND fecha <= %@", startDate as NSDate, today as NSDate)
        case .FechaModificacion:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fechaM, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "fechaM >= %@ AND fechaM <= %@", startDate as NSDate, today as NSDate)
        }
        
        
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error al recuperar entradas: \(error)")
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
