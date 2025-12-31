//
//  ReminderNotiricationManager.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

import UserNotifications

@MainActor
final class ReminderNotificationManager {

    static let shared = ReminderNotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    //Crea una nueva notificación. Devuelve el ID de la nueva notificación
    func scheduleAndStore(title: String,message: String,frequency: ReminderFrequency) -> StoredReminder {

        let identifier = UUID().uuidString //Agrega una identificación a la notificación

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = NotificationSound.selected.unSound //Carga el tono seleccionado, si algo falla carga el tono por defecto

        // 👇 NUEVO: Agregar Botones a la notificación
            content.categoryIdentifier = ReminderNotificationConstants.categoryId
            content.userInfo = [
                "reminderId": identifier,
                "message": message
            ]
        
        //Creando el disparador de la notificación de acuerdo al tipo de frecuencia
        let trigger: UNNotificationTrigger

        //Ajustando el disparador de acuerdo al tipo de frecuencia establecida del recordatorio:
        switch frequency {

        case .interval(let h, let m):
            let seconds = h * 3600 + m * 60
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(seconds),
                repeats: true //Repetitivo
            )

        case .daily(let hour, let minute):
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

        case .date(let date):
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
        
        case .monthly(let day, let hour, let minute):
            //Nota: si el día escogido es el 31, entonces los meses que no tengan día 31 no lanzarán el recordatorio
            //Nota: si el día escogido es el 30, entonces en febrero no se lanzará el recordatorio
            var components = DateComponents()
            components.day = day
            components.hour = hour
            components.minute = minute
            
            trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
            
        case .yearly(let month, let day, let hour, let minute):
                    var components = DateComponents()
                    components.month = month
                    components.day = day
                    components.hour = hour
                    components.minute = minute

                    trigger = UNCalendarNotificationTrigger(
                        dateMatching: components,
                        repeats: true
                    )
            
        }

        //Adicionando la notificación al sistema
        center.add(
            UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
        )

        //Almacenando la notificación en UserDefault
        let reminder = StoredReminder(
            id: identifier,
            title: title,
            message: message,
            frequency: frequency,
            isStarted: true, // NUEVO
            startedAt:  Date()
        )
        ReminderStore.shared.add(reminder)
        
        return reminder
    }
    
    //Botones que aparecen en la notificación.
    //Hay que llamar a esta función al inicio de la App
    func configureCategories() {

        let viewAction = UNNotificationAction(
            identifier: ReminderNotificationConstants.viewActionId,
            title: "Ver mensaje",
            options: [.foreground]
        )

        let cancelAction = UNNotificationAction(
            identifier: ReminderNotificationConstants.cancelActionId,
            title: "Eliminar Notificación",
            options: [.destructive]
        )

        // NUEVO: Acción de Detener
        let pauseAction = UNNotificationAction(
            identifier: ReminderNotificationConstants.pauseActionId,
            title: "Detener",
            options: []
        )

        // MODIFICADO: ahora incluye la acción de Pausar entre Ver y Eliminar
        let category = UNNotificationCategory(
            identifier: ReminderNotificationConstants.categoryId,
            actions: [viewAction, pauseAction, cancelAction], // NUEVO: pauseAction
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }
    
    

    // NUEVO: solo cancelar la notificación, sin tocar el store
    private func removePendingNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // NUEVO: pausar => cancelar notificación + marcar no iniciado
    func pause(id: String) {
        removePendingNotification(id: id)
        ReminderStore.shared.markPaused(id: id)
    }
    
    //Para resumir una notificación pausada: Yorj: Recordar hacer aqui la modificación de la frecuencia mensual igual que esta en scheduleAndStore
    func resume(id: String) {
        guard let reminder = ReminderStore.shared.load().first(where: { $0.id == id }) else {
            return
        }
        
        let trigger: UNNotificationTrigger
        
        switch reminder.frequency {
        case .interval(let h, let m):
            let seconds = h * 3600 + m * 60
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: true)
            
        case .daily(let hour, let minute):
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .date(let date):
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        case .monthly(let day, let hour, let minute):
            var components = DateComponents()
            components.day = day
            components.hour = hour
            components.minute = minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .yearly(let month, let day, let hour, let minute):
            var components = DateComponents()
            components.month = month
            components.day = day
            components.hour = hour
            components.minute = minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = NotificationSound.selected.unSound //selecciona el tono cargado
        content.categoryIdentifier = ReminderNotificationConstants.categoryId
        content.userInfo = [
            "reminderId": reminder.id,
            "message": reminder.message
        ]
        
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
        center.add(request)
        
        //reinicia el contador visual correctamente al reanudar:
        var updated = reminder
        updated.isStarted = true
        updated.startedAt = Date()
        ReminderStore.shared.update(updated)
        
        
        //ReminderStore.shared.markStarted(id: id)
    }

    // Mantener: cancelar y eliminar definitivamente
    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        ReminderStore.shared.remove(id: id)
    }
    
    //Notificando cambios:
    private func notifyChange() {
        NotificationCenter.default.post(name: .reminderStoreDidChange, object: nil)
    }
}
