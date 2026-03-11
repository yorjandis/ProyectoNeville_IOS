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
    //Funciones premium
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.title, ascending: true)]
    ) private var goals: FetchedResults<GoalEntity>

    @State private var showCreateGoal = false
    
    @State private var showHistorial = false
    
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            
            if (self.purchaseStatus || self.yorjPremium){
                ZStack{
                    LinearGradient(colors: [.orange, .blue], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            /*
                             //Habilitar para mostrar las targetas por tipo de unidad: primero minutos, luego, horas, dias...
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

                    ToolbarItem{
                        Button{
                            #if os(macOS)
                            
                            showWindow(for: ArchivedGoalsListView(context: self.context),
                                        environmentObjects: [],
                             title: "Historial de Metas",
                                        size: AppCons.windows_size_content,
                             isModal: true)
                             
                            #else
                            self.showHistorial = true
                            #endif
                            
                        }label:{
                            Image(systemName: "tray.2")
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    ToolbarItem{
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
                .sheet(isPresented: self.$showHistorial){
                    #if os(iOS) || os(ipadOS)
                    ArchivedGoalsListView()
                    #endif
                }
            }else{
                PurchaseView()
            }
            
            
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
