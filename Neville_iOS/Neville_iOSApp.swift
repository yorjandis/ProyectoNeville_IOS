//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI




@main
struct Neville_iOSApp: App {
    
  @StateObject var networkMonitor = NetworkMonitor()
    
    
    //Codigo a cargar al inicio:
    init(){
        //Popular la tabla Frases SI es la primera vez
        manageFrases().populateTableFrases()
        
        //Carga los valores de Setting para Userdefault si es la primera vez
        if UserDefaults.standard.integer(forKey: Constant.setting_fontFrasesSize) == 0 {
            SettingModel().setValuesByDefault()
            print("Es la primera vez")
        }
        
        
        
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
                
        }
    }
}
