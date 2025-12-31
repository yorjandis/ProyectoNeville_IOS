//
//  ReminderStoreModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

//maneja la persistencia de las notificaciones creadas

import Foundation

@MainActor
final class ReminderStore{

    static let shared = ReminderStore() //Singleton
    
    private let key = "stored_reminders"
    
    
    

    private init() {}

    //Devuelve el listado de recordatorios almacenados en UserDefalt
    func load() -> [StoredReminder] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let reminders = try? JSONDecoder().decode([StoredReminder].self, from: data)
        else {
            return []
        }
        return reminders
    }

    //Salva un nuevo recordatorio
    func save(_ reminders: [StoredReminder]) {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: key)
        notifyChange() //Notificando cambios. estos cambios son captados por ReminderProgressWidgetModel.observeStoreChanges
    }

    //Adiciona un nuevo recordatorio
    func add(_ reminder: StoredReminder) {
        var current = load()
        current.append(reminder)
        save(current)

    }
    
    //Adiciona un nuevo recordatorio por su ID
    func addPorId(_ id: String) {
        
    }

    //Remueve un recordatorio de UserDefault
    func remove(id: String) {
        //Salva el listado de recordatorios obtenidos, exceptuando el recordatorio que queremos eliminar.
        save(load().filter { $0.id != id })
    }
    
    // NUEVO: actualizar un reminder existente por id
    func update(_ reminder: StoredReminder) {
        var current = load()
        if let idx = current.firstIndex(where: { $0.id == reminder.id }) {
            current[idx] = reminder
            save(current)
        }
    }

    // NUEVO: marcar un reminder como no iniciado (pausado)
    func markPaused(id: String) {
        var current = load()
        if let idx = current.firstIndex(where: { $0.id == id }) {
            var r = current[idx]
            r.isStarted = false
            r.startedAt = nil // ⬅️ limpia el progreso
            current[idx] = r
            save(current)
        }
    }
    
    // NUEVO: marcar un reminder como iniciado (reanudar)
    func markStarted(id: String) {
        var current = load()
        if let idx = current.firstIndex(where: { $0.id == id }) {
            var r = current[idx]
            r.isStarted = true
            current[idx] = r
            save(current)
        }
    }
    
    //Notificando cambios:
    private func notifyChange() {
        NotificationCenter.default.post(name: .reminderStoreDidChange, object: nil)
    }
    
}
