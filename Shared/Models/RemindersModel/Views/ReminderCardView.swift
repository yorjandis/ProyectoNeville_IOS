//
//  ReminderCardView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 26/12/25.
//

import SwiftUI

struct ReminderCardView: View {
    
    let reminder: StoredReminder
    let onEdit:     () -> Void
    let onDelete:   () -> Void
    let onPause:    () -> Void
    
    @State private var ocultarTexto: Bool = true
    
    @StateObject private var selectedReminderModel: SelectedReminderModel = .shared
    
    @AppStorage(AppCons.UD_setting_fontReminder) var fontReminder         : Int = 18
    
    @AppStorage("hideTextInProgressReminder") private var hideTextInProgressReminder: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            //Contenido principal
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10){
                    //Adiciona/quita un reminder al listado de widget:
                    Button{
                        if self.selectedReminderModel.existingRemindersId(reminder) {
                            self.selectedReminderModel.deselect(reminder)
                        }else{
                            self.selectedReminderModel.select(reminder)
                        }
                        
                    }label: {
                        Image(systemName: self.selectedReminderModel.existingRemindersId(reminder) ? "pin.fill" : "pin")
                    }
                    Text(reminder.title)
                        .font(.title2)
                        .bold()
                }
                
                
                Text(reminder.message)
                    .font(.system(size: CGFloat(self.fontReminder)))
                    .lineLimit(self.ocultarTexto ? 1 : nil)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation{
                            self.ocultarTexto.toggle()
                        }
                       
                    }
                    
                
                Text("Frecuencia: \(reminder.frequency.description)")
                    .font(.caption)
                    .bold()
                    .padding(.top, 4)
            }
            .foregroundStyle(.black)
            
            Divider()

            // Acciones inferiores
            HStack(spacing: 5) {
                //Pausar o Iniciar de nuevo la notificación
                
                Button{
                    onPause()
                }label:{
                    Image(systemName: reminder.isStarted ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.plain)
                
                
                IntervalProgress()
                    .contextMenu{
                        Button(hideTextInProgressReminder ? "Mostrar Texto" : "Ocultar Texto"){
                            if hideTextInProgressReminder {
                                hideTextInProgressReminder = false
                            }else{
                                hideTextInProgressReminder = true
                            }
                            
                        }
                    }
                
                Spacer()
                
                if reminder.isStarted {
                    Button{
                        onEdit()
                    }label:{
                        Image(systemName: "pencil")
                        //Label("Editar", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    
                    Button{
                        onDelete()
                    }label:{
                        Image(systemName: "trash")
                        //Label("Quitar", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                
                
            }
            .foregroundStyle(.black)
        }
        .padding()
        .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    reminder.isStarted ? Color(red: 222/255, green: 184/255, blue: 135/255) : .black.opacity(0.4), // beige claro
                                    reminder.isStarted ? Color(red: 222/255, green: 184/255, blue: 135/255)  : .gray// marrón claro
                                    ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
                )
    }
    
    @ViewBuilder
    func IntervalProgress() -> some View {

        if reminder.isStarted, let startedAt = reminder.startedAt {
            switch reminder.frequency {
                
                // ✅ INTERVALO (lógica original)
            case .interval:
                if let interval = reminder.frequency.timeInterval {
                    HStack {
                        Spacer()
                        IntervalProgressView(
                            totalInterval: interval,
                            startedAt: startedAt,
                            size: 50
                        )
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                
                // ✅ DAILY y DATE (cuenta atrás)
            case .daily, .date, .monthly, .yearly:
                if let progress = reminder.frequency.progressSince(startedAt: startedAt) {
                    HStack {
                        Spacer()
                        IntervalProgressView(
                            totalInterval: progress.total,
                            startedAt: Date().addingTimeInterval(-progress.elapsed),
                            size: 50
                        )
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
}


extension Color {
    static let beige = Color(red: 245/255, green: 245/255, blue: 220/255)
    static let peach = Color(red: 255/255, green: 218/255, blue: 185/255)
    static let yellowGreen = Color(red: 154/255, green: 205/255, blue: 50/255)
}
