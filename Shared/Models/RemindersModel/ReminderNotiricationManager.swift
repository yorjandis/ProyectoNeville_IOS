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

    func scheduleAndStore(
        title: String,
        message: String,
        frequency: ReminderFrequency
    ) {

        let identifier = UUID().uuidString

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        // 👇 NUEVO
            content.categoryIdentifier = ReminderNotificationConstants.categoryId
            content.userInfo = [
                "reminderId": identifier,
                "message": message
            ]
        
        let trigger: UNNotificationTrigger

        switch frequency {

        case .interval(let h, let m):
            let seconds = h * 3600 + m * 60
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(seconds),
                repeats: true
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
        }

        center.add(
            UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
        )

        ReminderStore.shared.add(
            StoredReminder(
                id: identifier,
                title: title,
                message: message,
                frequency: frequency
            )
        )
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

        let category = UNNotificationCategory(
            identifier: ReminderNotificationConstants.categoryId,
            actions: [viewAction, cancelAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }
    
    

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        ReminderStore.shared.remove(id: id)
    }
}
