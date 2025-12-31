//
//  ReminderListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

//maneja el listado de Recordatorios
import SwiftUI

struct ReminderListView: View {

    @State private var reminders: [StoredReminder] = []
    @State private var editing: StoredReminder?
    @State private var creating = false
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    #if os(iOS)
    @Environment(\.editMode) private var editMode //Para mantener la lista siempre en modo edición (y eliminar el botón editar)
    #endif
    
    var body: some View {
        NavigationStack {
            
            if self.purchaseStatus {
                ZStack{
                    
                    LinearGradient(
                        colors: [
                                Color(red: 255/255, green: 223/255, blue: 186/255), // naranja pastel
                                Color(red: 255/255, green: 250/255, blue: 205/255)  // amarillo suave
                            ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack{
                        
                          Text("Recordatorios")
                            .font(.title).bold()
                            .foregroundStyle(.black)
                        
                        List {
                            ForEach(reminders) { reminder in
                                ReminderCardView(
                                    reminder: reminder,
                                    onEdit: { editing = reminder },
                                    onDelete: {
                                        ReminderNotificationManager.shared.cancel(id: reminder.id)
                                        withAnimation {
                                            load()
                                            editing = nil
                                        }
                                    },
                                    onPause: {
                                        if reminder.isStarted {
                                            ReminderNotificationManager.shared.pause(id: reminder.id)
                                        } else {
                                            ReminderNotificationManager.shared.resume(id: reminder.id)
                                        }
                                        withAnimation {
                                            load()
                                            editing = nil
                                        }
                                    }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .onMove(perform: move)
                        }
                        .listStyle(.plain)
                        
                        
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .scrollContentBackground(.hidden)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 255/255, green: 223/255, blue: 186/255),
                                Color(red: 255/255, green: 250/255, blue: 205/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                }
                .toolbar {
                   
                    #if os(macOS)
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            creating = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    #else
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            creating = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    #endif
                        
                }
                .onAppear{
                    #if os(iOS)
                    editMode?.wrappedValue = .active
                    #endif
                    load()
                }
                .sheet(item: $editing) {
                    ReminderEditorView(reminderAEditar: $0, titleAImportar: nil, textoAImportar: nil , onSave: load)
                }
                .sheet(isPresented: $creating) {
                    ReminderEditorView(reminderAEditar: nil, titleAImportar: nil, textoAImportar: nil, onSave: load)
                }
                
            }else{
                PurchaseView()
            }
            
           
        }
    }

    private func load() {
        reminders = ReminderStore.shared.load()
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        reminders.move(fromOffsets: source, toOffset: destination)
        ReminderStore.shared.save(reminders)
    }
}
