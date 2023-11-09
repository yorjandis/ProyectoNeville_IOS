//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Lista todas las frases que tienen notas

import SwiftUI
import CoreData

struct FrasesListView: View {
    @Environment(\.colorScheme) var theme
    
    @State  var list : [Frases] = FrasesModel().getAllFrases()
    @State  private var showAddFrase = false
    @State private var subtitle = "Todas las Frases"
    
    
    var body: some View {
        NavigationStack{
            VStack {
                Text(subtitle)
                List(list, id: \.id){ frase in
                    Text(frase.frase ?? "")
                        .swipeActions(edge: .trailing, allowsFullSwipe: true){
                            //Solo se pueden borrar las frases personalas: NoInbuilt
                            if FrasesModel().CheckIfNotInbuiltFrase(frase: frase){
                                Button{
                                    FrasesModel().Delete(frase: frase)
                                    withAnimation {
                                        list.removeAll()
                                        list = FrasesModel().getAllFrases()
                                    }
                                }label: {
                                    Image(systemName: "trash")
                                        .tint(.red)
                                }
                                
                                NavigationLink{
                                    FrasesUpdateView(frase: frase, list: list)
                                }label: {
                                    Image(systemName: "pencil.and.scribble")
                                        .tint(.green)
                                }
                                
                                
                                
                            }
                            
                        }
                        
                }
                .onAppear{
                    list.removeAll()
                    list = FrasesModel().getAllFrases()
                }
                .navigationTitle("Listado de Frases")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
      
                    Menu{
                        Button("Todas las Frases"){withAnimation {
                            list.removeAll(); list = FrasesModel().getAllFrases()}
                            subtitle = "Todas las Frases"
                        }
                        Button("Frases Personales"){withAnimation {
                            list.removeAll(); list = FrasesModel().getFrasesNoInbuilt()}
                            subtitle = "Frases Personales"
                        }
                        Button("Frases Favoritas"){withAnimation {
                            list.removeAll(); list = FrasesModel().getAllFavFrases()}
                            subtitle = "Frases Favoritas"
                        }
                        Button("Frases con notas"){withAnimation {
                            list.removeAll(); list = FrasesModel().getAllNotasFrases()}
                            subtitle = "Frases con notas"
                        }
                        
                    }label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                    
                    Button{
                        showAddFrase = true
                    }label: {
                        Image(systemName: "plus")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                }
                .sheet(isPresented: $showAddFrase){
                    FraseAddView()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.hidden)
            }
            }
            
        }
        
    }
    
    
    
    
    
}

#Preview {
    ContentView()
}
