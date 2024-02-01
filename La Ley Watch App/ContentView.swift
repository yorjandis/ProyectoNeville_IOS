//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @EnvironmentObject  var WatchVM : WatchConectivityModel
    @State private var selectedTab = 0
    
    var body: some View {
      TabView(selection: $selectedTab) {
          NavigationStack{
              Frases()
          }.tag(0)
                    
      }
      .tabViewStyle(.page)
                
                
    }
    
   //Vista de
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
}

#Preview {
    ContentView()
        .environmentObject(WatchConectivityModel.shared)
}
