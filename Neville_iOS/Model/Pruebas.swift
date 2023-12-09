//
//  Pruebas.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/12/23.
//

import Foundation
import Vision
import SwiftUI


struct testYor {
    
    //Traduce un texto utilizando el traductor de google:
    func translate(completion: @escaping (String)->()) {
        let selected_language = "es"
                let target_language = "en"
                let YourString = "Esto es solo un ejemplo. de lo que podemos hacer con todo esto"

         let urlGoogle = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=" + selected_language + "&tl=" + target_language + "&dt=t&dt=t&q=" + YourString)
  
        //Iniciamos la tarea de recuperación de datos
        URLSession.shared.dataTask(with: urlGoogle!) { data, response, error in
            if let ddt = data {
                let result = String(decoding: ddt, as: UTF8.self)
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
        .resume()
    }

    
    
}




