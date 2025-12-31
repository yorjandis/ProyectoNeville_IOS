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

    /// Programa una notificación local con el contenido especificado y conserva sus metadatos en el almacén de recordatorios.
    ///
    /// Este método:
    /// - Crea un identificador único para el recordatorio y crea una UNNotificationRequest con:
    /// - El título y el mensaje proporcionados.
    /// - El sonido de notificación seleccionado (`NotificationSound.selected.unSound`).
    /// - Una categoría de notificación para acciones personalizadas (`ReminderNotificationConstants.categoryId`).
    /// - Carga útil de información del usuario que contiene el ID y el mensaje del recordatorio.
    /// - Crea un UNNotificationTrigger adecuado según la frecuencia especificada:
    /// - `.interval(h, m)`: Se repite cada h horas y m minutos.
    /// - `.daily(hour, minute)`: Se repite diariamente a la hora especificada.
    /// - `.date(date)`: Se activa una vez en la fecha y hora especificadas.
    /// - `.monthly(day, hour, minute)`: Se repite mensualmente en el día y hora especificados.
    /// - `.yearly(month, day, hour, minute)`: Se repite anualmente en la fecha y hora especificadas.
    /// - Registra la notificación en UNUserNotificationCenter.
    /// - Crea y almacena el `StoredReminder` correspondiente con:
    /// - `isStarted = true`
    /// - `startedAt = Date()`
    /// - `elapsedBeforePause = 0`
    ///
    /// Notas:
    /// - Para la frecuencia mensual, seleccionar el día 31 significa que los meses sin 31 no se activarán; seleccionar el día 30 significa que febrero no se activará.
    /// - Asegúrese de que se haya solicitado la autorización de notificación antes de llamar a este método (consulte `requestPermission()`).
    ///
    /// - Parámetros:
    /// - title: El título de la notificación que se mostrará.
    /// - message: El mensaje del cuerpo de la notificación que se mostrará. /// - frecuencia: La regla de programación que determina cuándo y cómo se repite la notificación.
    /// - Devuelve: El `StoredReminder` recién creado y persistente que representa esta notificación programada.
    func scheduleAndStore(title: String,message: String,frequency: ReminderFrequency) -> StoredReminder {

        let identifier = UUID().uuidString //Agrega una identificación a la notificación

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = NotificationSound.selected.unSound //Carga el tono seleccionado, si algo falla carga el tono por defecto

            // 👇 Agregar Botones a la notificación
            content.categoryIdentifier = ReminderNotificationConstants.categoryId
            // 👇 Almacenar la info del recordatorio
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

        //Registrando la notificación en el Sistema
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
            isStarted: true,
            startedAt:  Date(),
            elapsedBeforePause: 0 // reiniciar el contador de tiempo transcurrido antes de pausarse
        )
        ReminderStore.shared.add(reminder)
        
        return reminder
    }
    
    //Botones que aparecen en la notificación.
    //Hay que llamar a esta función al inicio de la App
    /// Configura las categorías de notificación y las acciones utilizadas para las notificaciones de recordatorio.
    ///
    /// Este método registra una `UNNotificationCategory` personalizada en el sistema, lo que habilita las notificaciones accionables para recordatorios.
    /// La categoría incluye las siguientes acciones:
    /// - "Ver mensaje": Abre la aplicación en primer plano para mostrar el contenido del recordatorio.
    /// - "Pausar": Pausa el recordatorio programado sin eliminarlo.
    /// - "Eliminar notificación": Elimina la notificación programada (destructiva).
    ///
    /// Comportamiento:
    /// - La categoría se identifica mediante `ReminderNotificationConstants.categoryId`.
    /// - Las acciones se registran en el orden: Ver, Pausar, Eliminar.
    /// - Esta configuración debe ejecutarse al principio del ciclo de vida de la aplicación (por ejemplo, al iniciarse) antes de programar las notificaciones,
    /// para que el sistema sepa qué acciones mostrar al recibir una notificación. ///
    /// Requisitos:
    /// - Asegurarse de que los permisos de notificación se soliciten previamente mediante `requestPermission()`.
    ///
    /// Efectos secundarios:
    /// - Llamar a `UNUserNotificationCenter.setNotificationCategories(_:)` para reemplazar el conjunto actual de categorías por uno que incluya la categoría de recordatorio.
    ///
    /// - Ver también: `UNNotificationCategory`, `UNNotificationAction`, `UNUserNotificationCenter.setNotificationCategories(_:)`
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
            title: "Pausar",
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

   
    /// Pausa un recordatorio programado y conserva su tiempo transcurrido.
    ///
    /// Este método realiza lo siguiente:
    /// - Cancela la notificación pendiente con el identificador proporcionado, lo que garantiza que no se active mientras esté en pausa.
    /// - Calcula el tiempo transcurrido desde la última vez que se inició el recordatorio (`startedAt`) y lo acumula en `elapsedBeforePause`.
    /// - Actualiza el estado del recordatorio a pausado estableciendo `isStarted` en `false` y borrando `startedAt`.
    /// - Conserva el recordatorio actualizado en `ReminderStore`.
    ///
    /// Requisitos:
    /// - El recordatorio con el `id` proporcionado debe existir en `ReminderStore`.
    /// - El recordatorio debe estar ejecutándose (`isStarted == true`) y tener un `startedAt` distinto de nulo.
    ///
    /// - Parámetro id: El identificador único del recordatorio que se pausará.
    func pause(id: String) {
        //intenta obtener el recordatorio almacenado, queque si esta iniciado,
        //y le actualiza su propiedad startedAt
        guard var reminder = ReminderStore.shared.load().first(where: { $0.id == id }),
              reminder.isStarted,
              let startedAt = reminder.startedAt
        else { return }

        // 1️⃣ Cancelar notificación
        removePendingNotification(id: id)

        // 2️⃣ Calcular tiempo transcurrido
        let elapsed = Date().timeIntervalSince(startedAt)

        // 3️⃣ Guardar estado
        reminder.elapsedBeforePause += elapsed
        reminder.isStarted = false
        reminder.startedAt = nil

        ReminderStore.shared.update(reminder)
    }
    

    /// Reanuda un recordatorio previamente pausado reprogramando su notificación y restableciéndolo a su estado de ejecución.
    ///
    /// Este método:
    /// - Reconstruye el UNNotificationTrigger apropiado según la frecuencia almacenada del recordatorio.
    /// - Recrea y programa la notificación utilizando el identificador, el título, el mensaje, el sonido y la categoría originales.
    /// - Establece `isStarted` en `true`.
    /// - Establece `startedAt` en la hora actual menos el `elapsedBeforePause` acumulado previamente, lo que garantiza que cualquier interfaz de usuario que muestre el tiempo transcurrido continúe desde donde se detuvo.
    ///
    /// Requisitos:
    /// - Debe existir un recordatorio con el `id` proporcionado en `ReminderStore`.
    ///
    /// Notas:
    /// - Si no se encuentra ningún recordatorio para el `id` especificado, el método regresa sin realizar cambios.
    /// - Para recordatorios basados ​​en intervalos, la notificación se programa para repetirse utilizando el intervalo original. /// - Para recordatorios basados ​​en calendario (diarios, mensuales, anuales, de fecha específica), la notificación se programa utilizando los componentes de fecha originales y la configuración de repetición.
    ///
    /// - ID del parámetro: El identificador único del recordatorio que se reanudará.
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
        updated.startedAt = Date().addingTimeInterval(-reminder.elapsedBeforePause) // 🔥 REANUDAR DESDE DONDE SE DEJÓ
        ReminderStore.shared.update(updated)
        
        
    
    }

    
    /// Detener: cancelar y eliminar definitivamente
    /// Cancela y elimina permanentemente un recordatorio programado.
    ///
    /// Este método realiza una desinstalación completa del recordatorio especificado:
    /// - Elimina la solicitud de notificación pendiente del sistema (ya no se activará).
    /// - Elimina el recordatorio del almacén persistente (`ReminderStore`), incluyendo cualquier estado asociado, como el progreso, el tiempo transcurrido y las marcas de tiempo de inicio.
    ///
    /// Úselo cuando el recordatorio ya no sea necesario. Si solo desea detener temporalmente las notificaciones conservando el estado, utilice `pause(id:)`.
    ///
    /// - Parámetro id: El identificador único del recordatorio que se cancelará y eliminará permanentemente.
    func cancel(id: String) {
    center.removePendingNotificationRequests(withIdentifiers: [id])
        ReminderStore.shared.remove(id: id)
    }
    
    //Notificando cambios:
    /// Publica una notificación para todo el sistema que indica que el almacén de recordatorios ha cambiado.
    ///
    /// Este método transmite una notificación `.reminderStoreDidChange` a través de `NotificationCenter.default`.
    /// Los observadores en otras partes de la aplicación pueden suscribirse a esta notificación para actualizar la interfaz de usuario, recargar datos o realizar cualquier acción secundaria que dependa del estado actual del almacén de recordatorios.
    ///
    /// La publicación se realiza en el actor principal (la clase se anota con `@MainActor`), lo que garantiza que los observadores controlados por la interfaz de usuario reciban la notificación en el hilo principal.
    ///
    /// - Nota: La notificación se publica con `object: nil`. Los consumidores deben filtrar por el nombre de `Notification.Name.reminderStoreDidChange` en lugar de basarse en el remitente.
    /// - Véase también: `Notification.Name.reminderStoreDidChange`
    private func notifyChange() {
        NotificationCenter.default.post(name: .reminderStoreDidChange, object: nil)
    }
}
