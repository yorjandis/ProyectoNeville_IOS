//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData
import CloudKit

struct ContentView: View {
    
    
    @EnvironmentObject  var WatchVM : WatchConectivityModel
    @State private var selectedTab = 4
    
    var body: some View {
      TabView(selection: $selectedTab) {
          
          NavigationStack{
              Notas()
          }.tag(1)
          
          NavigationStack{
              Frases()
          }.tag(2)
          
          NavigationStack{
              Diario()
          }.tag(3)
          
          NavigationStack{
              pruebas()
          }.tag(4)
          
          
                    
      }
      .tabViewStyle(.page)
                
                
    }
    
   //Vista de
    
    struct Notas: View {
        
        @State var list = [[String:String]]()
        @State var runTask = true

        var body: some View {
            
            VStack {
                    Label("Sync", systemImage: "arrow.counterclockwise.icloud")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding([.top, .trailing], 25)
                        .onTapGesture {
                            Task{
                                self.list.removeAll()
                                let model = iCloudKitModel(of: .BDPrivada)
                                list = await model.getRecords(tableName: "CD_Notas", listFields: ["CD_title","CD_nota"])
                                runTask = false
                            }
                        }
                        .opacity(runTask ? 0 : 1)
 
                
                List(self.list, id: \.self){ idx in
                    NavigationLink(idx["CD_title"] ?? ""){
                        ScrollView {
                            Text(idx["CD_nota"] ?? "")
                        }
                    }
                    .swipeActions(edge: .trailing){
                        Button{
                            
                        }label: {
                            Image(systemName: "trash")
                                .tint(.orange)
                        }
                    }
                    
                }
                .overlay(content: {
                    if list.isEmpty {
                        ProgressView()
                    }
                })
                .task{
                    if runTask {
                        self.list.removeAll()
                        let model = iCloudKitModel(of: .BDPrivada)
                        
                        list = await model.getRecords(tableName:"CD_Notas" ,listFields: ["CD_title","CD_nota"])
                        runTask = false
                    }
                    
                    
            }
            }
            .ignoresSafeArea(edges: .top)
        }
        
        
    }
    
    struct Frases : View {
        @State private var frase : String = UtilFuncs.FileReadToArray("listfrases").randomElement() ?? ""
        var body: some View {
            ScrollView
            {
                VStack(alignment: .center){
                    Text(frase)
                        .onTapGesture {
                            frase = UtilFuncs.FileReadToArray("listfrases").randomElement() ?? ""
                        }
                        
                }
                .navigationTitle("Frases")
            .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    struct Diario: View {
        
        @State var list = [[String:String]]()
        @State var runTask = true
        
        var body: some View {
            
            VStack {
                Label("Sync", systemImage: "arrow.counterclockwise.icloud")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding([.top, .trailing], 25)
                    .onTapGesture {
                        Task{
                            self.list.removeAll()
                            let model = iCloudKitModel(of: .BDPrivada)
                            list = await model.getRecords(tableName: "CD_Diario", listFields: ["CD_title","CD_content"])
                            runTask = false
                        }
                    }
                    .opacity(runTask ? 0 : 1)
                
                
                List(self.list, id: \.self){ idx in
                    NavigationLink(idx["CD_title"] ?? "error"){
                        ScrollView {
                            Text(idx["CD_content"] ?? "error")
                        }
                    }
                    .swipeActions(edge: .trailing){
                        Button{
                            
                        }label: {
                            Image(systemName: "trash")
                                .tint(.orange)
                        }
                    }
                    
                }
                .overlay(content: {
                    if list.isEmpty {
                        ProgressView()
                    }
                })
                .task{
                    if runTask {
                        self.list.removeAll()
                        let model = iCloudKitModel(of: .BDPrivada)
                        
                        list = await model.getRecords(tableName:"CD_Diario" , listFields: ["CD_title","CD_content"])
                        runTask = false
                    }
                    
                    
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        
        
    }
    
    struct pruebas : View {
        var body: some View {
            Button("OK09"){
                Task{
                    await  iCloudKitModel(of: .BDPrivada).saveRecordNota(title:"titulo OKOKOK", nota:"Nota OKOKOK", isfav:0)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    
}

#Preview {
    ContentView()
        .environmentObject(WatchConectivityModel.shared)
}
