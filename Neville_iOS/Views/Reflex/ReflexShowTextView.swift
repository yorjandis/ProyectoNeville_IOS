//
//  ReflexShowTextView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

import SwiftUI
import CoreData

struct ReflexShowTextView: View {
    
    @State var entity : Reflex
    
    var body: some View {
        NavigationStack {
            Form{
                Section("Reflexión"){
                    Text(entity.texto ?? "")
                        .multilineTextAlignment(.leading)
                }
                Section("Autor"){
                    Text(entity.autor ?? "")
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle(entity.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ReflexShowTextView( entity: Reflex(context: CoreDataController.dC.context) )
}
