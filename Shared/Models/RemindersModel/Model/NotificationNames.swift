//
//  NotificationNames.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

import Foundation

extension Notification.Name {
    static let showReminderMessage = Notification.Name("showReminderMessage") //Para mostrar la notificaciones en la app
    static let didReceiveReminderMessage = Notification.Name("didReceiveReminderMessage") //
    static let didReceiveForegroundNotification = Notification.Name("didReceiveForegroundNotification") //Para mostrar las notificaciones con la App Abierta
}

