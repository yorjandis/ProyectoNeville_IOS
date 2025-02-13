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
  private let persistentStore : CoreDataController =  CoreDataController.shared
    //Codigo a cargar al inicio:
    init(){

        
        //Carga los valores de Setting para Userdefault si es la primera vez
        if UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize) == 0 {
            SettingModel().setValuesByDefault()
        }

        
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
                .environmentObject(WatchConectivityMV) //Conectividad con el reloj
                .environment(\.managedObjectContext, persistentStore.context)
                .task {
                    await FrasesModel().populateTableFrases() //Popular la tabla Frases SI se reinstala la app por primera vez
                    await TxtContentModel().populateTable(context: self.persistentStore.context)   //Popular la tabla TxtFiles SI se reinstala la app por primera vez
                }
                
        }
    }
}
