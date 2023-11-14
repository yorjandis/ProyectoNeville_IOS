//
//  GameModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 13/11/23.
//

import Foundation



struct GameModel{
    
    private let nameFile = "cuestionario" //Nombre del fichero que contiene las preguntas
  
    
    
    //Obtiene el listado de preguntas de la fuente: cuestionario.txt
    func getList()->[Pregunta]{
        var result : [Pregunta] = []
        
        let array = UtilFuncs.ReadFileToArray(nameFile)

        for item in array{
            let temp2 = item.components(separatedBy: "-")
            let pregunta = Pregunta(pregunta: temp2[0], isCorrect: temp2[1] == "v" ? true : false)
            result.append(pregunta)
        }

        return result
    }
    
    
  
    
    
    
    
    
}


//Representa una pregunta
struct Pregunta : Equatable{
    let pregunta : String
    let isCorrect : Bool
}
