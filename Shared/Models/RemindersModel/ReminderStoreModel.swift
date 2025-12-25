//
//  ReminderStoreModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

//maneja la persistencia de las notificaciones creadas

import Foundation

@MainActor
final class ReminderStore {

    static let shared = ReminderStore()
    private let key = "stored_reminders"

    private init() {}

    func load() -> [StoredReminder] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let reminders = try? JSONDecoder().decode([StoredReminder].self, from: data)
        else {
            return []
        }
        return reminders
    }

    func save(_ reminders: [StoredReminder]) {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func add(_ reminder: StoredReminder) {
        var current = load()
        current.append(reminder)
        save(current)
    }

    func remove(id: String) {
        save(load().filter { $0.id != id })
    }
}
