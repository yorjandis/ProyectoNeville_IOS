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

    
    private let persistentStore : CoreDataController =  CoreDataController.shared
    
    
    var body: some Scene {
        WindowGroup {
                ContentViewMac()
                    .environmentObject(settingModel)
                    .environmentObject(frasesModel)
                    .environmentObject(txtcontentModel)
                    .environmentObject(securityModel) //acceso seguro a las notas protegisas y al diario
                    .environment(\.managedObjectContext, persistentStore.context)
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
