//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI




@main
struct Neville_iOSApp: App {
    
  @StateObject private var networkMonitor = NetworkMonitor()
  @StateObject private var WatchConectivityMV = WatchConectivityModel.shared
    
    
    //Codigo a cargar al inicio:
    init(){

        //--YTIdModel().populateTable() //Popular la tabla YTVideos si es la primera vez
        //RefexModel().populateTableReflex() //Popula la tabla reflex si es la primera vez
        
        //Carga los valores de Setting para Userdefault si es la primera vez
        if UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize) == 0 {
            SettingModel().setValuesByDefault()
        }
        
        //Temporal: Limpieza de errores
        //--FrasesModel().tempDeleteFrase() //borra frases de pruebas
       
        
        
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
                .environmentObject(WatchConectivityMV) //Conectividad con el reloj
                .task {
                    await FrasesModel().populateTableFrases() //Popular la tabla Frases SI se reinstala la app por primera vez
                    await TxtContentModel().populateTable()   //Popular la tabla TxtFiles SI se reinstala la app por primera vez
                }
                
        }
    }
}
