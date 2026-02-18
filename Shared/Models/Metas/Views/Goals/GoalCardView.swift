//
//  GoalCardView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//Tarjeta de Objetivo

import SwiftUI








struct GoalCardView: View {

    @ObservedObject var goal: GoalEntity
    
    @Environment(\.managedObjectContext) var context
    
    @ObservedObject var clock = GlobalClock.shared
    
    @State private var showSheetProgress = false
    
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var showModifyGoalView = false
    
    
    @State private var expandirUnidades: Bool = false
    
    @State private var expandirNotas: Bool = false
    
    @State private var NotasGenerales: String = ""
    
    
 
    
    
    
    //Calcula el tiempo que resta para que caduque una unidad que esta lista para chequearse:
    //Toma la hora actual y calcula cuanto tiempo falta para completarse la hora actual, el día actual, el mes actual y el año actual
    private func timeRemainingUntil(until date: Date) -> String {
            let interval = Int(date.timeIntervalSince(clock.now))
            let hours = interval / 3600
            let minutes = (interval % 3600) / 60
            let seconds = interval % 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        }
    

    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 22) {
            //Título con subtitulo del objetivo
            VStack(alignment: .leading, spacing: 8){
                Text(goal.wrappedTitle)
                    .font(.platFormSize(iOS: 20, mac: 24))
                    .font(.headline).bold()
                    .foregroundStyle(.black)
                    .onTapGesture(count: 2) {
                        self.showModifyGoalView = true
                    }
                
                //Mostrar El tiempo que falta para la próxima unidad:
                HStack{
                    //🔥 Mostrar un botón para archivar/Actualizar la unidad
                    if let id = goal.id {
                        if goal.isCompleted && goal.isStarted {
                            Button("Archivar"){
                                if GoalEntity.isArchived(id: id, context: self.context){
                                    //Actualizar:
                                    do{
                                        try goal.updateArchivedVersion(context: self.context)
                                    }catch{
                                        msg("Error en la función actualizar (archivar)")
                                    }
                                }else{
                                    //Archivar:
                                    do{
                                        try goal.archive(context: self.context)
                                    }catch{
                                        msg("Error en la función archivar")
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .padding(.horizontal)
                        }
                        
                        
                    }
                    
                    
                    Spacer()
                    if goal.isCompleted && goal.isStarted {
                        //Mostrar un indicador de que se ha completado el objetivo:
                        HStack(spacing: 10){
                            Text("Completado!").font(.title2).bold()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(
                                    .green.opacity(0.7)
                                ).bold()
                                .font(.system(size: 44))
                        }
                        
                    }else{
                        if let timeRemaining = goal.timeUntilNextUnit(now: clock.now) {
                            
                            if timeRemaining == "Listo",
                               let unit = goal.nextPendingUnit,
                               let expiration = goal.nextExpirationDate(from: clock.now) {

                                HStack {
                                    Text("Esta unidad vence en : \(timeRemainingUntil(until: expiration))")

                                    //Botón para fichar la unidad actual disponible
                                    Button {
                                        unit.markCompleted(context: context)
                                    } label: {
                                        Image(systemName: "checkmark.circle.dotted")
                                            .foregroundStyle(.green)
                                            .font(.system(size: 44))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }else{
                                //Muestra un contador hasta la próxima unidad disponible
                                Text(timeRemaining)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut, value: timeRemaining)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    
                }
                
            }
            
            //Barra de Progreso:
            HStack{
                Text("\(Int(goal.progressRatio * 100))%")
                LabeledGradientProgressBar(progress: goal.progressRatio)
                    .padding(1)
            }
            .onReceive(clock.$now) { _ in
                // Esto fuerza que la vista se redibuje cuando el reloj cambia
            }
            
            
            //Barra de acciones:
            HStack {
                Text("Completado: \(progressText)")
                    .font(.body)
                    .foregroundStyle(.primary).bold()
                
                Spacer()
                
                
                //Botón Notas Adjuntas:
                Button{
                    withAnimation{
                        self.expandirUnidades = false
                        self.expandirNotas.toggle()
                    }
                }label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.black)
                        .font(.system(size: 28))
                }
                .padding(.trailing, 15)
                
                
                //Boton Iniciar Objetivo
                if !goal.isStarted{
                    Button{
                        goal.start()
                    }label: {
                        Text("Iniciar")
                        
                    }
                    .tint(.green)
                    .buttonStyle(.bordered)
                }else{
                    //Ya esta iniciado:
                    
                    //Muestra la lista de progreso:
                    Button{
                        withAnimation{
                            self.expandirNotas = false
                            self.expandirUnidades.toggle()
                        }
                    }label:{
                        Image("celdasLogo")
                            .resizable()
                            .overlay(content: {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle( goal.hasLostUnits ? .orange : .green)
                                        .offset(y: 8)
                                
                                
                            })
                            .frame(width: 35, height: 30)
                            .offset(y: -2)
                    }
                }

                //Eliminar el objetivo
                Button{
                    withAnimation {
                        self.showDeleteConfirmation = true
                    }
                    
                }label: {
                    Image(systemName: "trash.circle")
                        .foregroundStyle(.black)
                        .font(.system(size: 28))
                }
                .padding(.horizontal, 15)
            }
            
            
            //Contenido expansible
            if self.expandirUnidades {
                VStack{
                    GoalDetailView(goal: self.goal)
                }
                .frame(height: 300)
            }
            
            if self.expandirNotas{
                VStack(alignment: .leading){
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
                    .onAppear{
                        self.NotasGenerales = self.goal.descriptionText ?? ""
                    }
                }
                .padding(1)
                
            }
            
        }
        .onReceive(clock.$now) { now in
            //Forzar actualización de unidades perdidas globalmente:
            //Así el estado se mantiene siempre consistente.
            goal.unitsArray.forEach {
                $0.updateLostIfNeeded(now: now)
            }
            try? context.save()
        }
        .padding(5)
        #if os(macOS)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    .gray.opacity(0.8),
                    .blue.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
                )
        #else
        .background(.thinMaterial)
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: self.$showSheetProgress) {
            GoalDetailView(goal: self.goal)
        }
        .sheet(isPresented: self.$showModifyGoalView){
            ModifyGoal(goal: self.goal)
                .presentationDetents([.medium])
        }
        .alert("Eliminar objetivo", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                withAnimation {
                    goal.deleteGoal(context: self.context)
                }
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar este objetivo y su progreso?")
        }
    }

    private var progressText: String {
        let completed = goal.unitsArray.filter { $0.unitStatus == .completed }.count
        return "\(completed)/\(goal.totalUnits)"
    }
    
    
    
}
