//
//  StoreReminder.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

//Modelo para almacenar en UserDefault las notificaciones

import Foundation

struct StoredReminder: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let message: String
    let frequency: ReminderFrequency
    var isStarted: Bool // NUEVO
    var startedAt: Date? //NUEVO -> cuándo empezó el ciclo actual
    // 🔥 NUEVO
       var elapsedBeforePause: TimeInterval //segundos acumulados antes de pausar
}
