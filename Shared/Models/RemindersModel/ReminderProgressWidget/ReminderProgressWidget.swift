//
//  ProgressHome.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//

//Crea una instancia de la barra de progreso para ser colocada em el home

import SwiftUI

struct ReminderProgressWidget: View {
    
    let reminder: StoredReminder //Recordatorio
    let subtitle: String        //Subtitulo para mostrar
    
    @State private var showSheet: Bool = false
    
    @AppStorage("hideTextInProgressReminder") private var hideTextInProgressReminder: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            
            progressView
            
            Text(subtitle.truncated(maxLength: 12))
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onTapGesture {
            self.showSheet = true
        }
        .contextMenu{
            
            Button{
                ReminderNotificationManager.shared.pause(id: reminder.id)
            }label:{
                Label("Detener", systemImage: "pause.fill")
            }
            
            Button{
                SelectedReminderModel.shared.deselect(self.reminder)
            }label:{
                Label("Remover", systemImage: "trash")
            }
            #if os(macOS)
            
            Button(){
                showWindow(for: ReminderEditorView(reminderAEditar: self.reminder, titleAImportar: nil, textoAImportar: nil, onSave: {}),
                           environmentObjects: [],
                           title: "Recordatorios",
                           size: AppCons.windows_size_content,
                           isModal: false)
            }label: {
                Label("Editar", systemImage: "pencil")
            }
            
            #else
            
            NavigationLink{
                ReminderEditorView(reminderAEditar: self.reminder, titleAImportar: nil, textoAImportar: nil, onSave: {})
            }
            label:{
                Label("Editar", systemImage: "pencil")
            }
            
            #endif
            
            Button{
                if hideTextInProgressReminder {
                    hideTextInProgressReminder = false
                }else{
                    hideTextInProgressReminder = true
                }
            }label:{
                Label(hideTextInProgressReminder ? "Mostrar Texto" : "Ocultar Texto", systemImage: "eye")
            }
            
            
        }
        .sheet(isPresented: self.$showSheet) {
            ReminderListView()
        }
        
    }
    
    // Progreso
    
    @ViewBuilder
    private var progressView: some View {
        
        if reminder.isStarted,
           
           let startedAt = reminder.startedAt {
            
            switch reminder.frequency {
                
            case .interval:
                if let interval = reminder.frequency.timeInterval {
                    IntervalProgressView(
                        totalInterval: interval,
                        startedAt: startedAt,
                        size: 60
                    )
                }
                
            case .daily, .date, .monthly, .yearly:
                if let progress = reminder.frequency.progressSince(startedAt: startedAt) {
                    IntervalProgressView(
                        totalInterval: progress.total,
                        startedAt: Date().addingTimeInterval(-progress.elapsed),
                        size: 60
                    )
                }
            }
            
        } else {
            // Estado vacío (por ejemplo cuando está pausado)
            Image(systemName: "pause.circle")
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.6))
        }
    }
}

extension String {
    func truncated(maxLength: Int) -> String {
        guard self.count > maxLength else {
            return self
        }

        let truncatedText = self.prefix(maxLength)
        return "\(truncatedText)..."
    }
}
