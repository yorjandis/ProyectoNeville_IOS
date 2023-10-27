//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Lista todas las frases que tienen notas

import SwiftUI
import CoreData

struct FrasesNotasListView: View {
    
    private let context : NSManagedObjectContext = CoreDataController.dC.context
    
    @State private var listNotas : [Frases] = manageFrases().getFrasesWithNotes()
    
    
    var body: some View {
        NavigationStack{
            List(listNotas){ idx in
                HStack{
                    Image(systemName: "heart")
                        .foregroundColor(idx.isfav ? .orange : .gray)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            idx.isfav.toggle()
                            if context.hasChanges {
                                try? context.save()
                            }
                            listNotas.removeAll()
                            listNotas = manageFrases().getFrasesWithNotes()
                        }
                    NavigationLink{
                        NotaFraseAddView(idFrase: idx.id ?? "" , nota: idx.nota ?? "" )
                            .onDisappear { //Al salir actualiza el listado
                                listNotas.removeAll()
                                listNotas = manageFrases().getFrasesWithNotes()
                            }
                    }label: {
                        Text(idx.frase ?? "")
                            .padding(.top, 3)
                        
                    }
                }
                    
            }
            .navigationTitle("Notas en Frases")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        
    }
    
    
    
    
    
}

#Preview {
    FrasesNotasListView()
}
