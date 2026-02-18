//
//  ArchivedGoalsListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

import SwiftUI
import CoreData

struct ArchivedGoalsListView: View {
    
    

    #if os(macOS)
    let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
        
        // Crear el FetchRequest manual
        let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArchivedGoalEntity.completionDate, ascending: false)]
        
        do {
            self.archivedGoals = try context.fetch(request)
        } catch {
            print("Error fetching archived goals: \(error)")
            self.archivedGoals = []
        }
    }

    // Propiedad para almacenar los resultados en macOS
    private var archivedGoals: [ArchivedGoalEntity]

    
    
    #else
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ArchivedGoalEntity.completionDate, ascending: false)
        ]
    )
    private var archivedGoals: FetchedResults<ArchivedGoalEntity>
    #endif
    

    

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.AtardecerVioleta()
                .ignoresSafeArea()

                VStack{
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(archivedGoals) { goal in
                                ArchivedGoalCardView(goal: goal)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    .padding(.top, 15)
                    
                    #if os(macOS)
                    Button("Cerrar"){
                        if let window = NSApp.keyWindow {
                            closeWindow(window)
                            }
                    }
                    .padding()
                    #endif
                    
                }
                
            }
            .navigationTitle("Historial de Metas")
        }
    }
}


