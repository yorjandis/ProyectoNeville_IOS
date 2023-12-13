//
//  Pruebas.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/12/23.
//

import Foundation
import CoreData


struct testYor {
    
   private  let context = CoreDataController.dC.context
    
    
    
    func test(){
        var dic  = [String:Frases]()
        let frase = Frases(context: context)
        frase.id = UUID().uuidString
        frase.frase = "Esto es una frase"
        frase.isfav = false
        frase.nota = "esto es una nota"
        
        dic["Ejemplo"] = frase
        dic["Ejemplo"] = frase
        dic["Ejemplo3"] = frase
        
        print(dic)
    }

    
}




