//
//  RemindersDelegate.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//
import SwiftUI
import UserNotifications

//maneja los botones de la notificación cuando aparece,
//además también tiene la lógica para que los recordatorios aparezcan cuando la app esta en foreground

@MainActor
final class AppNotificationDelegate: NSObject, @MainActor UNUserNotificationCenterDelegate {

    static let shared = AppNotificationDelegate()

    // 🔹 APP EN PRIMER PLANO
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        let content = notification.request.content

        NotificationCenter.default.post(
            name: .didReceiveForegroundNotification,
            object: nil,
            userInfo: [
                "title": content.title,
                "message": content.body
            ]
        )

        // No mostrar banner del sistema
        completionHandler([])
    }

    // 🔹 ACCIONES DE BOTONES / TAP EN NOTIFICACIÓN
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {

        let userInfo = response.notification.request.content.userInfo
        let reminderId = userInfo["reminderId"] as? String
        let message = userInfo["message"] as? String

        switch response.actionIdentifier {

        case ReminderNotificationConstants.cancelActionId:
            if let reminderId {
                ReminderNotificationManager.shared.cancel(id: reminderId)
            }

        case ReminderNotificationConstants.viewActionId:
            if let message {
                UserDefaults.standard.set(
                    message,
                    forKey: "pendingReminderMessage"
                )

                NotificationCenter.default.post(
                    name: .didReceiveReminderMessage,
                    object: nil,
                    userInfo: ["message": message]
                )
            }

        case ReminderNotificationConstants.pauseActionId:
            if let reminderId {
                ReminderNotificationManager.shared.pause(id: reminderId)
            }

        default:
            break
        }

        completionHandler()
    }
}


