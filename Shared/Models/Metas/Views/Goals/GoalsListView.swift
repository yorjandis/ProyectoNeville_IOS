//
//  GioalsListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//LISTA DE TARJETAS DE OBJETIVOS

import SwiftUI
import CoreData

struct GoalsListView: View {

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    @State private var showCreateGoal = false

    var body: some View {
        NavigationStack {
            ZStack{
                LinearGradient(colors: [.orange, .blue], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(goals.sorted {
                            //Ordena la lista poniendo primero objetivos de: Horas -> Dias -> Meses -> Años
                            guard let firstUnit = TimeUnit(rawValue: $0.unitType ?? ""),
                                  let secondUnit = TimeUnit(rawValue: $1.unitType ?? "")
                            else { return false }
                            return firstUnit.priority < secondUnit.priority
                        }) { goal in
                            GoalCardView(goal: goal)
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.top, 15)
                
            }
            .navigationTitle("Objetivos")
            .toolbar {
                Button {
                    showCreateGoal = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalView()
                    .environment(\.managedObjectContext, context)
            }
        }
    }
}
