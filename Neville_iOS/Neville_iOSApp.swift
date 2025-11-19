//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI




@main
struct Neville_iOSApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
 @StateObject private var networkMonitor        = NetworkMonitor() //Helper Para conexiones de red
 @StateObject private var modelTxt              = TxtContentModel()
 @StateObject private var modelFrases           = FrasesModel.shared
 @StateObject private var settingModel = SettingModel() //Inicializo el modelo para cargar valores de Setting y lo inyecto en el árbol de vistas
 @StateObject private var securityModel = SecurityModel.shared //Almacena variables observables para
@StateObject private var reflexModel = ReflexModel.shared //Modelo Observable para Reflexiones
    
    
  private let persistentStore : CoreDataController =  CoreDataController.shared
    
    


    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingModel)
                .environmentObject(networkMonitor)
                .environmentObject(modelTxt)
                .environmentObject(modelFrases)
                .environmentObject(securityModel) //Almacena variables observables para acceso seguro: Notas protegidas y Diario
                .environmentObject(reflexModel) 
                .environment(\.managedObjectContext, persistentStore.context)
                .task {
                    modelTxt.getAllFileTxtOfType(type: .conf) // Carga el listado de conferencias
                    modelFrases.getAllFrases()
                    self.securityModel.canOpenDiario = false //Al iniciar la ventana se reinicia la variabe que da acceso al diario.
                }
                
        }
  
    }
}
