//
//  ReminderStoreModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

//maneja la persistencia de las notificaciones creadas

/*
 Logica:
 🔹 Detener (STOP)
     •    ❌ Cancela la notificación
     •    ❌ Elimina el recordatorio del store
     •    ❌ No se puede reanudar
 🔹 Pausar (PAUSE)
     •    ❌ Cancela la notificación del sistema
     •    ✅ Mantiene el recordatorio en el store
     •    ✅ Guarda cuánto tiempo ya ha transcurrido
     •    ❌ No avanza el progreso mientras está pausado
 🔹 Reanudar (RESUME)
     •    ✅ Reprograma la notificación
     •    ✅ Continúa el progreso desde donde se pausó
     •    ❌ No reinicia el contador
 
 Resultado esperado:
 Acción:    Notificación:       Progreso:       ModelStore:
 Crear      Activa              Empieza en 0    Guardado
 Pausar     Cancelada           Se congela      Se mantiene
 Reanudar   Reprogramada        Continúa        Se mantiene
 Detener    Eliminada           Desaparece      Eliminado

 */

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
        var reminders = load()
        reminders.append(reminder)
        save(reminders)

    }
    
 

    //Remueve un recordatorio de UserDefault
    func remove(id: String) {
        //Salva el listado de recordatorios obtenidos, exceptuando el recordatorio que queremos eliminar.
        save(load().filter { $0.id != id })
    }
    
    // NUEVO: actualizar un reminder existente por id
    func update(_ reminder: StoredReminder) {
        var reminders = load()
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
            save(reminders)
        }
    }

    // NUEVO: marcar un reminder como no iniciado (pausado)
    func markPaused(id: String) {
        var reminders = load()
        if let idx = reminders.firstIndex(where: { $0.id == id }) {
            var r = reminders[idx]
            r.isStarted = false
            r.startedAt = nil // ⬅️ limpia el progreso
            reminders[idx] = r
            save(reminders)
        }
    }
    
    // NUEVO: marcar un reminder como iniciado (reanudar)
    func markStarted(id: String) {
        var reminders = load()
        if let idx = reminders.firstIndex(where: { $0.id == id }) {
            var r = reminders[idx]
            r.isStarted = true
            reminders[idx] = r
            save(reminders)
        }
    }
    
    //Notificando cambios:
    private func notifyChange() {
        NotificationCenter.default.post(name: .reminderStoreDidChange, object: nil)
    }
    
}


