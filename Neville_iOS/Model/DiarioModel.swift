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

enum Emociones{
    case feliz, enfado,desanimado,sorpresa,distraido,neutral
}

struct DiarioModel{
    private let context = CoreDataController.dC.context
    
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
    func addItem(title : String, emocion : String, content : String, isTijeras : Bool ){
        let diario : Diario = Diario(context: context)
        diario.id = UUID()
        diario.title = title
        diario.emotion = emocion
        diario.content = content
        diario.istijeras = isTijeras
        
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
    func UpdateEmoticono(emoticono : String, diario : Diario){
        diario.emotion = emoticono
        if context.hasChanges {
            try? context.save()
        }
    }
    
    
    
}

