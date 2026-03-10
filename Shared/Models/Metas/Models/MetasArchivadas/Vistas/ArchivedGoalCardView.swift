//
//  ArchivedGoalCardView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

/*
 Copiamos la estructura visual de GoalCardView, pero:
     •    ❌ Quitamos reloj
     •    ❌ Quitamos botón iniciar
     •    ❌ Quitamos lógica temporal
     •    ❌ Quitamos lógica de fichaje
     •    ✅ Mostramos estado final
     •    ✅ Permitimos ver notas
     •    ✅ Permitimos eliminar
 */

import SwiftUI
import CoreData

struct ArchivedGoalCardView: View {

    @ObservedObject var goal: ArchivedGoalEntity
    @Environment(\.managedObjectContext) var context

    @State private var expandirUnidades: Bool = false
    @State private var expandirNotas: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var NotasGenerales : String = ""

    var body: some View {

        VStack(alignment: .leading, spacing: 22) {

            // Título
            VStack(alignment: .leading, spacing: 8) {

                Text(goal.wrappedTitle)
                    .font(.title2)
                    .bold()
                #if os(macOS)
                    .foregroundStyle(.white)
                #else
                    .foregroundStyle(.black)
                #endif
                   

                HStack(spacing: 10) {
                    Spacer()
                    
                    Text("Cumplimiento: \(String(format: "%.2f", goal.completionRate)) %")
                        .font(.title2)
                        .bold()
                    /*
                     Image(systemName: "checkmark.circle.fill")
                     .foregroundStyle(
                     .green.opacity(0.7)
                     )
                     .font(.system(size: 32))
                     */
                    
                }
            }

            // Barra de progreso
            HStack {
                Text("\(Int(goal.progressRatio * 100))%")
                LabeledGradientProgressBar(progress: goal.progressRatio, lostUnits: goal.lostUnitIndexes, totalUnits: Int(goal.totalUnits))
                    .padding(1)
            }

            // Barra acciones
            HStack {

                Text("Completado: \(goal.completedUnitsText)")
                    .font(.body)
                    .bold()

                Spacer()

                Button {
                    withAnimation {
                        expandirUnidades = false
                        expandirNotas.toggle()
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.black)
                        .font(.system(size: 28))
                }
                .padding(.trailing, 15)

                Button {
                    withAnimation {
                            expandirNotas = false
                            expandirUnidades.toggle()
                    }
                } label: {
                    Image("celdasLogo")
                        .resizable()
                        .overlay {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(goal.hasLostUnits ? .orange : .green)
                                .offset(y: 8)
                        }
                        .frame(width: 35, height: 30)
                        .offset(y: -2)
                }

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.circle")
                        .foregroundStyle(.black)
                        .font(.system(size: 28))
                }
                .padding(.horizontal, 15)
            }

            // Detalle unidades
            if expandirUnidades {
                ArchivedGoalDetailView(goal: goal)
                    .frame(height: 300)
            }

            // Notas generales
            if expandirNotas {
                VStack(alignment: .leading) {
                    //Contenido de la nota
                    Text("Notas Generales:")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                        .padding(.bottom, 5)
                    
                    ScrollView{
                        TextEditor(text: self.$NotasGenerales)
                            .font(.platFormSize(iOS: 22, mac: 24))
                            .padding(3)
                            .frame(minHeight: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    
                    Button("Guardar"){
                        goal.descriptionText = self.NotasGenerales
                        
                        do{
                            try self.context.save()
                        }catch{
                            msg("Error al actualizar la descripción de la Meta")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(1)
                .onAppear{
                    self.NotasGenerales = self.goal.descriptionText ?? ""
                }
            }
        }
        .padding(5)
        #if os(macOS)
        .background{
            LinearGradient.AzulTecnologico()
        }
        #else
        .background(.thinMaterial)
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Eliminar meta archivada",
               isPresented: $showDeleteConfirmation) {

            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                withAnimation {
                    context.delete(goal)
                    try? context.save()
                }
                
            }

        } message: {
            Text("¿Eliminar permanentemente esta meta del historial?")
        }
    }
}
