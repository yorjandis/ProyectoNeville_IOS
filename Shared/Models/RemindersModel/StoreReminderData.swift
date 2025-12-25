//
//  StoreReminder.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

//Modelo para almacenar en UserDefault las notificaciones

import Foundation

struct StoredReminder: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let frequency: ReminderFrequency
}
