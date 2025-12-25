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

    var body: some View {
        NavigationStack {
            ZStack{
                
                LinearGradient(colors: [.orange, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                VStack{
                    List {
                        ForEach(reminders) { reminder in
                            VStack(alignment: .leading) {
                                Text(reminder.title).font(.title2).bold()
                                
                                Text(reminder.message).font(.body)
                                
                                Text("Frecuencia: \(reminder.frequency.description)" )
                                    .font(.caption)
                                    .foregroundStyle(.blue).bold()
                                    .padding(.top, 5)
                                
                                Divider()
                                
                                HStack {
                                    
                                    
                                    Spacer()
                                    
                                    
                                    
                                    Button("Editar") {
                                        editing = reminder
                                    }
                                    .tint(.orange)
                                    .buttonStyle(.borderedProminent)
                                    
                                    #if os(macOS)
                                    Button("Quitar", role: .destructive) {
                                        ReminderNotificationManager.shared.cancel(id: reminder.id) //Cancela la notificación
                                        load() //Actualiza la lista de notificaciones
                                        // Asegurarnos de que no se abra la hoja de edición
                                        editing = nil
                                    }
                                    .tint(.red)
                                    .buttonStyle(.borderedProminent)
                                    .padding(.leading, 20)
                                    #endif
                                    
                                }
                            }
                            .padding(.vertical, 8)
                            .swipeActions(edge: .trailing) {
                                Button("Quitar", role: .destructive) {
                                    ReminderNotificationManager.shared.cancel(id: reminder.id) //Cancela la notificación
                                    load() //Actualiza la lista de notificaciones
                                    // Asegurarnos de que no se abra la hoja de edición
                                        editing = nil
                                }
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #endif
                    
                }
                
            }
            .navigationTitle("Recordatorios")
            .toolbar {
                Button {
                    creating = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .onAppear{
                load()
            }
            .sheet(item: $editing) {
                ReminderEditorView(reminder: $0, onSave: load)
            }
            .sheet(isPresented: $creating) {
                ReminderEditorView(reminder: nil, onSave: load)
            }
        }
    }

    private func load() {
        reminders = ReminderStore.shared.load()
    }
}
