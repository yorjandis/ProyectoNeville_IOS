//
//  La_LeyApp.swift
//  La Ley
//
//  Created by Yorjandis PG on 6/11/25.
//

import SwiftUI

@main
struct La_LeyApp: App {
    @StateObject private var settingModel = SettingModel()
    @StateObject private var frasesModel = FrasesModel.shared
    @StateObject private var txtcontentModel = TxtContentModel.shared
    @StateObject private var securityModel = SecurityModel.shared
    @StateObject private var clipBoardObserver : ClipboardObserver = ClipboardObserver() //Inicia la clase que observa cambios en el portapapales

    
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
                ContentViewMac()
                    .environmentObject(settingModel)
                    .environmentObject(frasesModel)
                    .environmentObject(txtcontentModel)
                    .environmentObject(securityModel) //acceso seguro a las notas protegisas y al diario
                    .environmentObject(clipBoardObserver) //Inyectamos la clase que observa cambios en el portapapeles
                    .environment(\.managedObjectContext, persistentStore.context)
                    .applyTheme(setting_theme) //Aplicando la configuración de theme segun los valores en Ajustes
                    .task {
                        self.securityModel.canOpenDiario = false //Al iniciar la ventana se reinicia la variabe que da acceso al diario.
                    }
                    .onDisappear {
                        //Cerrando todas las ventanas hijas abiertas antes de salir
                        WindowManager.shared.closeAllChildren()
                    }
        }
    }
}


