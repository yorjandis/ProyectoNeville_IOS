//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI




@main
struct Neville_iOSApp: App {
    
 @StateObject private var networkMonitor        = NetworkMonitor() //Helper Para conexiones de red
 @StateObject private var modelTxt              = TxtContentModel()
 @StateObject private var modelFrases           = FrasesModel.shared

    
    
  private let persistentStore : CoreDataController =  CoreDataController.shared
    
    
    
    


    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
                .environmentObject(modelTxt)
                .environmentObject(modelFrases)
                .environment(\.managedObjectContext, persistentStore.context)
                .task {
                    modelTxt.getAllFileTxtOfType(type: .conf) // Carga el listado de conferencias
                    modelFrases.getAllFrases()
                }
                
        }
    }
}
