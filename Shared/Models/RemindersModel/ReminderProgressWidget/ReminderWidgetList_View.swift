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
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    
    @State private var showSheet: Bool = false
    
    var body: some View {
        if purchaseStatus {
            VStack{
                
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(modelRecordatorios.selectedReminders) { reminder in
                            if reminder.isStarted {
                                ReminderProgressWidget(
                                   reminder: reminder,
                                   subtitle: reminder.title
                                )
                                .foregroundStyle(settingModel.colorFondo_b.adaptiveTextColor()) //Adapta el color del texto al fondo donde esta.
                                .padding(5)
                                .frame(width: 130)
                                .contextMenu{
                                    Button{
                                        ReminderNotificationManager.shared.stop(id: reminder.id)
                                    } label:{
                                        Label("Detener",systemImage: "stop.fill" )
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
                                              systemImage: hideTextInProgressReminder ? "eye" : "eye.slash")
                                    }
                                }
                                .onTapGesture{
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
      
                            }else{
                                VStack{
                                    
                                    
                                    ModBarraProgreso(progress: 0 , size: 60, text: "Detenido")
                                    Text(reminder.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(5)
                                .contextMenu(menuItems: {
                                    
                                    Button{
                                        ReminderNotificationManager.shared.resume(id: reminder.id)
                                    }label:{
                                        Label("Iniciar", systemImage: "play.fill")
                                    }
                                    
                                    Button{
                                        SelectedReminderModel.shared.deselect(reminder)
                                    } label:{
                                        Label("Remover Widget", systemImage: "trash")
                                    }
                                })
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
                    .task {
                        //msg("Recordatorios selectos: \(modelRecordatorios.selectedReminders.count)")
                        for reminder in modelRecordatorios.selectedReminders {
                            msg("\(reminder)")
                        }
                    }
                }
            }
            .padding(3)
            .sheet(isPresented: self.$showSheet) {
                ReminderListView()
            }
        }else{
            EmptyView()
                .padding(0)
        }
        
    }
    
    //Solo la imagen de la barra de progreso para mostrarla cuando los widget esten detenidos:
    @ViewBuilder
    func ModBarraProgreso(
        progress: Double,
        size: CGFloat,
        text: String? = nil
    ) -> some View {
        
        let lineWidth = size * 0.12
        let cornerRadius = size * 0.35

        ZStack {
            // Fondo (track)
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(.black.opacity(0.15), lineWidth: lineWidth)

            // Progreso
            RoundedRectangle(cornerRadius: cornerRadius)
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.black.opacity(0.5), .black.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .animation(.linear(duration: 0.4), value: progress)

            // Texto centrado
            if let text {
                Text(text)
                    .font(.system(
                        size: size * 0.28,
                        weight: .bold,
                        design: .monospaced
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, size * 0.2)
            }
        }
        .frame(maxWidth: 125)
        .frame(height: size * 0.65)
    }
    
}


