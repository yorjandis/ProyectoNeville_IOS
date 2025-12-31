//
//  ReminderWidgetList_View.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//

import SwiftUI

struct ReminderWidgetList_View : View {
    
    @EnvironmentObject private var settingModel : SettingModel
    
    @StateObject private var modelRecordatorios: SelectedReminderModel = .shared
    
    @AppStorage("hideTextInProgressReminder") private var hideTextInProgressReminder: Bool = false
    
    
    @State private var showSheet: Bool = false
    
    var body: some View {
        VStack{
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(modelRecordatorios.selectedReminders) { reminder in
                        ReminderProgressWidget(
                           reminder: reminder,
                           subtitle: reminder.title
                        )
                        .foregroundStyle(settingModel.colorFondo_b.adaptiveTextColor()) //Adapta el color del texto al fondo donde esta.
                        .padding(5)
                        .frame(width: 130)
                        .contextMenu{
                            Button{
                                ReminderNotificationManager.shared.pause(id: reminder.id)
                            } label:{
                                Label(reminder.isStarted ? "Pausar" : "Reanudar",
                                      systemImage: reminder.isStarted ? "pause.fill" : "play.fill")
                            }

                            Button{
                                SelectedReminderModel.shared.deselect(reminder)
                            } label:{
                                Label("Remover Widget", systemImage: "trash")
                            }
                            
                            #if os(macOS)
                            Button(){
                                showWindow(for: ReminderEditorView(reminderAEditar: reminder, titleAImportar: nil, textoAImportar: nil, onSave: {}),
                                           environmentObjects: [],
                                           title: "Recordatorios",
                                           size: AppCons.windows_size_content,
                                           isModal: false)
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            #else
                            NavigationLink{
                                ReminderEditorView(reminderAEditar: reminder, titleAImportar: nil, textoAImportar: nil, onSave: {})
                            } label:{
                                Label("Editar", systemImage: "pencil")
                            }
                            #endif
                            
                            Button{
                                hideTextInProgressReminder.toggle()
                            } label:{
                                Label(hideTextInProgressReminder ? "Mostrar Texto" : "Ocultar Texto",
                                      systemImage: "eye")
                            }
                        }
                        .onTapGesture {
                            #if os(macOS)
                            showWindow(for: ReminderListView(),
                                       environmentObjects: [],
                                       title: "Recordatorios",
                                       size: AppCons.windows_size_content,
                                       isModal: false)
                            #else
                            self.showSheet = true
                            #endif
                            
                        }
                    }
                }
            }
        }
        .padding(3)
        .sheet(isPresented: self.$showSheet) {
            ReminderListView()
        }
    }
    
}


