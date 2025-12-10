//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI
import AppIntents



@main
struct Neville_iOSApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var networkMonitor         = NetworkMonitor() //Helper Para conexiones de red
    @StateObject private var modelTxt               = TxtContentModel()
    @StateObject private var modelFrases            = FrasesModel.shared
    @StateObject private var settingModel           = SettingModel() //Inicializo el modelo para cargar valores de Setting y lo inyecto en el árbol de vistas
    @StateObject private var securityModel          = SecurityModel.shared //Almacena variables observables para
    @StateObject private var reflexModel            = ReflexModel.shared //Modelo Observable para Reflexiones
    @StateObject private var clipBoardModel        = ClipboardObserver() //Observa cambios en el portapapales
    
    //Para Las funciones de Atajo:
    @State private var showDiarioView = false //Abrir la ventana del Diario
    @State private var showNotasView = false //Abrir la ventana del Diario
    @AppStorage("abrirDiario" ) var abrirDiario: String = ""
    @AppStorage("abrirNotas" ) var abrirNotas: String = ""
    @AppStorage("notaCreada") var crearNotas : String = ""

    
  private let persistentStore : CoreDataController =  CoreDataController.shared
    
    @AppStorage(AppCons.UD_setting_theme) var setting_theme  : Theme = .auto
   
    
    /*
     init(){
         //Solo para macOS: esto resetea los valores de UserDefault en cada lanzamiento de la app, pero solo dentro del entorno de desarrollo.
         #if DEBUG
         UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
         UserDefaults.standard.synchronize()
         #endif
     }
     */
   
    


    
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                ContentView()
                    .environmentObject(settingModel)
                    .environmentObject(networkMonitor)
                    .environmentObject(modelTxt)
                    .environmentObject(modelFrases)
                    .environmentObject(securityModel) //Almacena variables observables para acceso seguro: Notas protegidas y Diario
                    .environmentObject(reflexModel)
                    .environmentObject(clipBoardModel)
                    .environment(\.managedObjectContext, persistentStore.context)
                    .applyTheme(self.setting_theme) //Aplicando el theme según los valores en Ajustes
                    .task {
                        modelTxt.getAllFileTxtOfType(type: .conf)   // Carga el listado de conferencias
                        modelFrases.getAllFrases() 
                    }
                    //Funciones de Atajo:
                    .onChange(of: abrirDiario) { _ , newValue in
                        if abrirDiario == "abrir" {
                            showDiarioView = true
                            abrirDiario = ""
                        }
                    }
                    .onChange(of: abrirNotas) { _ , newValue in
                        if abrirNotas == "abrir" {
                            showNotasView = true
                            abrirNotas = ""
                        }
                    }
                    .onChange(of: crearNotas) { _ , newValue in
                        let nota = crearNotas.split(separator: "$$$")
                            if nota.count == 2 {
                                //Creando la nota:
                                _ =  NotasModel().addNote(nota: String(nota[1]), title: String(nota[0]))
                               // showNotasView = true
                                crearNotas = ""
                            }
                            
                        
                    }
                    .sheet(isPresented: $showDiarioView) {
                        DiarioListView()
                            .environmentObject(self.settingModel)
                            
                    }
                    .sheet(isPresented: $showNotasView) {
                        ListNotasViews()
                            .environmentObject(self.settingModel)
                            
                    }

                
                
                
                    //Fin de las funciones de Atajo
                
            }
            
            
                
        }
  
    }
}
