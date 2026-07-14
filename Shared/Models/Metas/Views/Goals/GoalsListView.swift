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

    let embeddedInNavigationStack: Bool

    @Environment(\.managedObjectContext) private var context

    //Funciones premium
    @AppStorage("purchaseStatus") var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) var yorjPremium: Bool = false
    
    @AppStorage("MostrarMetasEnHome", store: UserDefaults(suiteName: AppCons.AppGroupName)) var MostrarMetasEnHome: Bool = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    @State private var showCreateGoal = false
    @State private var showHistorial = false
    @State private var showStats = false
    @State private var searchText: String = ""

    init(embeddedInNavigationStack: Bool = true) {
        self.embeddedInNavigationStack = embeddedInNavigationStack
    }

    var body: some View {
        if embeddedInNavigationStack {
            NavigationStack {
                content
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
            if purchaseStatus || yorjPremium {
                ZStack {
                    LinearGradient(colors: [.orange, .blue], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            /*
                             GoalsGadgetWidgetListView()
                                 .padding(.horizontal, 8)
                             */
                            

                            //Ordenarmiento de las targetas por urgencia: las que vencen primero se colocan arriba
                            ForEach(filteredGoals) { goal in
                                GoalCardView(goal: goal)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    .padding(.top, 15)
                }
                .navigationTitle("Metas")
                .searchable(text: $searchText, prompt: "Buscar meta por título")
                .toolbar {
                    ToolbarItem {
                        Button {
                            #if os(macOS)
                            showWindow(
                                for: GoalStatsView().environment(\.managedObjectContext, context),
                                environmentObjects: [],
                                title: GoalsL10n.text("goals.ui.statistics_title", fallback: "Estadísticas de Metas"),
                                size: AppCons.windows_size_content,
                                isModal: true
                            )
                            #else
                            showStats = true
                            #endif
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                    }

                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }

                    ToolbarItem {
                        Button {
                            #if os(macOS)
                            showWindow(
                                for: ArchivedGoalsListView(context: context),
                                environmentObjects: [],
                                title: GoalsL10n.text("goals.ui.history_title", fallback: "Historial de Metas"),
                                size: AppCons.windows_size_content,
                                isModal: true
                            )
                            #else
                            showHistorial = true
                            #endif
                        } label: {
                            Image(systemName: "tray.2")
                        }
                    }

                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }

                    ToolbarItem {
                        Button {
                            showCreateGoal = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showCreateGoal) {
                    CreateGoalView()
                        .environment(\.managedObjectContext, context)
                }
                .sheet(isPresented: $showHistorial) {
                    #if os(iOS) || os(ipadOS)
                    ArchivedGoalsListView()
                    #endif
                }
                .sheet(isPresented: $showStats) {
                    GoalStatsView()
                        .environment(\.managedObjectContext, context)
                }
            } else {
                PurchaseView()
            }
    }

    private var filteredGoals: [GoalEntity] {
        let sortedGoals = Array(goals).sorted(by: GoalEntity.urgencySort)

        guard !searchText.isEmpty else { return sortedGoals }

        return sortedGoals.filter { goal in
            goal.wrappedTitle.localizedCaseInsensitiveContains(searchText)
        }
    }
}
