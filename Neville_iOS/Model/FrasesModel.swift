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

//Manejo de la tabla frases

@MainActor
final class FrasesModel : ObservableObject {
    @Published var listfrases : [String] = []
    
    static let shared = FrasesModel() //Singleton

    private let context = CoreDataController.shared.context

 
    ///Almacena el Id de la frase actualmente cargada. Se actualiza en: getRandomFrase()
    static var idFraseActual : String = ""
    
    
  
    //Nuevas funciones Yor
    
    
    ///Obtiene la lista de frases del fichero txt in-built (También agrega las frases personales creadas):
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
    
    ///Obtiene una frase aleatoria
    ///Aqui se actualiza el ID de la frase actualmente cargada para fines de búsqueda dentro de la tabla Frases. Al inicio,  se intenta popular la tabla Frases si esta marcada como NO populada(false).
    /// - Returns Devuelve el texto de la frase. Actualiza la static var idFraseActual con el id de la frase devuelta. Si falla devuelve una frase vacia
    func getRandomFrase()->String {
        return self.listfrases.randomElement() ?? "Malo"
    }

    
    
    //Devuelve todas las frases favoritas
    func getAllFavFrases() -> [String] {
        var frasesFavoritas: [String] = []
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isfav == %@", NSNumber(value: true))
        
        do {
            let elements = try context.fetch(fetchRequest)
            for item in elements {
                if let frase = item.frase{
                    frasesFavoritas.append(frase)
                }
            }
        }catch{
            print("Error al obtener las frases favoritas: \(error.localizedDescription)")
        }
        return frasesFavoritas
    }
    
    //Chequear si una frase es favorita
    func isFavFrase(_ frase: String) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "frase == %@ AND isfav == %@", frase, NSNumber(value: true))
        fetchRequest.fetchLimit = 1 // Solo necesitamos verificar si existe al menos una
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error al verificar la frase favorita: \(error.localizedDescription)")
            return false
        }
    }
    
    //fija el estado de favorito a una frase
    //Nota: esta función busca si la frase esta en la tabla Frases. Si esta, le asigna el nuevo estado isfav.
    func setFavFrase(_ frase: String, _ isFav: Bool) -> Bool {
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "frase == %@", frase)
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do {
            if let fraseEntity = try context.fetch(fetchRequest).first {
                // La frase ya existe en la tabla, solo actualizamos el estado de favorito si es necesario
                if fraseEntity.isfav != isFav { //solo hace el cambio si el estado es distinto al que ya tiene
                    fraseEntity.isfav = isFav
                    try context.save()
                }
            } else {
                // Si la frase no existe,  creamos una nueva entrada en la tabla Frases
                let newFrase = Frases(context: context)
                newFrase.id = UUID().uuidString
                newFrase.frase = frase
                newFrase.isfav = true // Solo creamos si isFav es true
                newFrase.noinbuilt = false
                
                try context.save()
            }
            return true
        } catch {
            print("Error al fijar el estado de favorito: \(error.localizedDescription)")
            return false
        }
    }
    
    
    ///Adiciona una frase Personal (NO inBuilt) a la tabla Frases.
    /// - Parameter frase : El texto de la frase a añadir
    func AddFrase(frase : String){
        let entidad = Frases(context: context)
        entidad.id = UUID().uuidString
        entidad.frase = frase
        entidad.isfav = false
        entidad.noinbuilt = true
        entidad.nota = ""
        
        if context.hasChanges {
            do{
                try context.save()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    

    
    ///Devuelve un arreglo con todas las frases NO inBuilt. Útil para funciones de filtrado
    func getFrasesNoInbuilt()->[String]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate : NSPredicate = NSPredicate(format: "noinbuilt == true")
        fetchRequest.predicate = predicate
        var result : [String] = []

        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            for item in elements{
                result.append(item.frase ?? "")
            }
            return result
        }catch{
            print(error.localizedDescription)
            return []
        }
    }
    
    //Chequea si una frase es no inbuilt:
    func isNoInbuilt(frase:String)->Bool{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate : NSPredicate = NSPredicate(format: "frase == %@ AND noinbuilt == %@", frase, NSNumber(value: true))
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do{
            let element = try context.fetch(fetchRequest).first
            if element != nil{
                return true
            }else{
                return false
            }
        }catch{
            return false
        }
    }
    
    //Elimina una frase personal de la Tabla Frases
    func DeleteFraseInbuilt(frase : String)->Bool{
        let fetchRequest: NSFetchRequest<Frases> = Frases.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "frase == %@ AND noinbuilt == %@", frase, NSNumber(value: true))
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
            print("Error al eliminar una frase personal : \(error.localizedDescription)")
            return false
        }
        
    }
    
    
    
    //Devuelve todas las frases con notas
    func getFrasesConNotas()->[String]{
        
        let fetchRequest : NSFetchRequest<Frases> = Frases.fetchRequest()
        let predicate : NSPredicate = NSPredicate(format: "nota != ''")
        fetchRequest.predicate = predicate
        var result : [String] = []
        
        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            for item in elements{
                result.append(item.frase ?? "")
            }
        }catch{
            print("Error al devolver todas las frases con notas : \(error.localizedDescription)")
        }
        return result
    }
    
    ///Obtiene la nota de una frase
    ///
    func GetNotaAsociadaFrase(frase : String)->String{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "frase == %@", frase)
        fetchRequest.predicate = predicate
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
    func UpdateNotaAsociada(frase : String, notaAsociada : String = "")->Bool{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        let predicate : NSPredicate = NSPredicate(format: "frase == %@", frase)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1 // Optimizamos la búsqueda para traer solo un resultado
        
        do{
            let elements : [Frases] = try context.fetch(fetchRequest)
            
            if elements.isEmpty{ //Si la frase no esta en la Tabla Frases, crea una nueva entidad y la añade
                
                let frasenew = Frases(context: context)
                frasenew.id = UUID().uuidString
                frasenew.frase = frase
                frasenew.nota = notaAsociada
                frasenew.noinbuilt = false
                
            }else{ //Si la frase esta en la tabla, solo cambia su campo nota
                elements.first?.nota = notaAsociada
            }
            if context.hasChanges{
                try context.save()
                return true
            }else{
                context.rollback()
                return false
            }
            
        }catch{
            print(error.localizedDescription)
            return false
        }
    }

    
    ///Buscar texto en frases.
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de  frases que contienen el texto a buscar
    func searchTextInFrases(text : String)->[String]{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        var result: [String] = []
        do{
            let elements = try context.fetch(fetchRequest)
            for item in elements{
                if let frase = item.frase {
                    if(frase.lowercased().contains(text.lowercased())){
                        result.append(frase)
                    }
                }
            }
            return result
        }catch{
            return result
        }
    }
    
    
    ///Buscar texto en el campo nota de una frase
    /// - Parameter text : Texto a buscar dentro de la frase
    /// - Returns : Devuelve un arreglo de entity Frases que contienen el texto a buscar
    func searchTextInNotaFrases(textNota : String)->[String]{
        let fetchRequest : NSFetchRequest = NSFetchRequest<Frases>(entityName: "Frases")
        var result: [String] = []
        do{
            let elements = try context.fetch(fetchRequest)
            for item in elements{
                if let nota = item.nota {
                    if(nota.lowercased().contains(textNota.lowercased())){
                        result.append(nota)
                    }
                }
            }
            return result
        }catch{
            return result
        }
        
    }
    
    
    
    //---------------------------------------------------------------------
    


}//struct

