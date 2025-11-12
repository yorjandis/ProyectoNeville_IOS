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
    
    private let persistentStore : CoreDataController =  CoreDataController.shared
    
    
    var body: some Scene {
        WindowGroup {
                ContentViewMac()
                    .environmentObject(settingModel)
                    .environmentObject(frasesModel)
                    .environmentObject(txtcontentModel)
                    .environment(\.managedObjectContext, persistentStore.context)
                    .preferredColorScheme(.light)
                    .onDisappear {
                        //Cerrando todas las ventanas hijas abiertas antes de salir
                        WindowManager.shared.closeAllChildren()
                    }
          
            

        }
    }
}
