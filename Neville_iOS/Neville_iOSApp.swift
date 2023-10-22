//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI




@main
struct Neville_iOSApp: App {
    
  
    
    
    //Codigo a cargar al inicio:
    init(){
        //Popular la tabla Frases SI es la primera vez
        manageFrases().populateTableFrases()
        
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
            //Crear una ambiente de Objeto Administrado y lo expone a SwiftUI
               
                
        }
    }
}
