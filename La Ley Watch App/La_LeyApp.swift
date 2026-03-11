//
//  La_LeyApp.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI

@main
struct La_Ley_Watch_AppApp: App {
    
    //@StateObject private var WatchConectivityMV = WatchConectivityModel.shared
    private let persistentStore: CoreDataController = CoreDataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentStore.context)
                .task {
                    do {
                        if persistentStore.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                            try await persistentStore.cargarStores()
                        }
                        
                        await MainActor.run {
                            watchModel.shared.getNotas()
                            watchModel.shared.getDiarioEntradas()
                        }
                    } catch {
                        msg("❌ Error al cargar Core Data en watchOS: \(error.localizedDescription)")
                    }
                }
                //.environmentObject(WatchConectivityMV)
        }
    }
}
