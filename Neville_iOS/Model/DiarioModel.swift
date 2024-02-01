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



struct DiarioModel{
    private let context = CoreDataController.shared.context
    
    //Obtiene el valor enum de Emociones a partir de una cadena de texto
    func getEmocionesFromStr(value : String)->Emociones{
        switch value{
        case "feliz":       Emociones.feliz
        case "enfadado":    Emociones.enfado
        case "desanimado":  Emociones.desanimado
        case "sorpresa":    Emociones.sorpresa
        case "distraido":   Emociones.distraido
        case "neutral":     Emociones.neutral
        default:            Emociones.neutral  //By default
        }
    }
    
    
    
    ///Obtiene todos los item de la tabla Diario. Devuelve un arreglo
    func getAllItem()->[Diario]{    
        let fechtRequest : NSFetchRequest<Diario> = Diario.fetchRequest()
        
        do{
           let temp =  try context.fetch(fechtRequest)
            return temp.reversed()
            
        }catch{
            return []
        }
        
    }
    
    
    ///Adiciona un item a la tabla Diario
    func addItem(title : String, emocion : Emociones, content : String, isFav : Bool = false ){
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
        }
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
         let listDiarios = self.getAllItem()
        
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
         let listDiarios = self.getAllItem()
        
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
         let listDiarios = self.getAllItem()
        
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
         let listDiarios = self.getAllItem()
        
        for diario in listDiarios {
            
            if diario.isFav {
                result.append(diario)
            }
        }

        return result
    }
    

    
    
    
}

