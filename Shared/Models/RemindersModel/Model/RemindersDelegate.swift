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

/*
 •    Este método se llama:
 •    cuando el usuario toca la notificación
 •    cuando pulsa un botón
 •    cuando iOS entrega la notificación
 •    Es el único punto garantizado donde:
 •    sabes que la notificación ocurrió
 •    tienes acceso al reminderId
 •    puedes programar el siguiente intervalo
 */

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

        if response.actionIdentifier == ReminderNotificationConstants.stopActionId,
           let reminderId {
            ReminderNotificationManager.shared.stop(id: reminderId)
        }

        completionHandler()
    }
}


