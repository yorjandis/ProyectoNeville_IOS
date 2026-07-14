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
    @State private var isStoreReady = false
    
    init() {
        _ = WatchIncomingDataReceiver.shared
        _ = WatchGoalUnitsStore.shared
        WatchGoalNotificationRouter.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isStoreReady {
                    ContentView()
                } else {
                    ProgressView("Cargando datos...")
                }
            }
            .environment(\.managedObjectContext, persistentStore.context)
            .task {
                do {
                    if persistentStore.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                        try await persistentStore.cargarStores()
                    }
                    
                    await MainActor.run {
                        watchModel.shared.getNotas()
                        watchModel.shared.getDiarioEntradas()
                        WatchGoalUnitsStore.shared.requestSnapshot()
                        isStoreReady = true
                    }
                } catch {
                    msg("❌ Error al cargar Core Data en watchOS: \(error.localizedDescription)")
                }
            }
            //.environmentObject(WatchConectivityMV)
        }
    }
}
