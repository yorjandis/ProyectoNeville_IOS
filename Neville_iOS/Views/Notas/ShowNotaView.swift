//
//  ShowNotaView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

struct ShowNotaView: View {
    @Environment(\.dismiss) var dimiss
    let nota : Notas //La nota que se desea visualizar
    @Binding var notass : [Notas]
    @State var showUpdateNotaView = false
    
    var body: some View {
        VStack{
            Form{
                Section(nota.title ?? ""){
                    Text(nota.nota ?? "")
                }
            }
            Spacer()
            Divider()
            HStack(spacing: 30){
                Spacer()
                Button{
                    showUpdateNotaView = true
                }label: {
                    Image(systemName: "pencil.and.scribble").tint(.green)
                }
                Button("Volver"){
                    dimiss()
                }
                .padding(.trailing, 30)
            }
            .padding(20)
        }
        .sheet(isPresented: $showUpdateNotaView){
            UpdateNotasView(NotaId: nota.id ?? "", title: nota.title ?? "", nota: nota.nota ?? "", notas: $notass)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        
        
    }
}

