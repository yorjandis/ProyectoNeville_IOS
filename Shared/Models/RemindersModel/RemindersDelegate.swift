//
//  RemindersDelegate.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//
import SwiftUI
import UserNotifications

@MainActor
final class ReminderNotificationDelegate: NSObject, @MainActor UNUserNotificationCenterDelegate {

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
                //Almacena el mensaje en UserDefault, para que la app pueda leerlo cuando se abra:
                UserDefaults.standard.set(message, forKey: "pendingReminderMessage")
            }

        default:
            break
        }

        completionHandler()
    }
}
