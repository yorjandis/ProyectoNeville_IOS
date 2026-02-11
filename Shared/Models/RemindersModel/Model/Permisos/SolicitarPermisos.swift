//
//  SolicitarPermisos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//
import SwiftUI
import UserNotifications

//Solicita permisos para notificaciones al usuario.
//Se debe colocar al inicio de la app:
/*
Ejemplo:
 .onAppear {
     NotificationPermissionManager.requestPermission()
 }
 */
final class NotificationPermissionManager {

    static func requestPermission() {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Task{ @MainActor in
                    msg("Error solicitando permisos: \(error)")
                }
                
            }
            Task{ @MainActor in
                msg("Permiso concedido: \(granted)")
            }
            
        }
    }
}
