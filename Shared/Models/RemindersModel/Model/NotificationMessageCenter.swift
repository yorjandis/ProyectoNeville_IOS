//
//  NotificationMessageCenter.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 27/12/25.
//

//Observable para manejar el contenido de una notificación y mostrarla en la app

import SwiftUI
import Combine

@MainActor
final class NotificationMessageCenter: ObservableObject {

    @Published var message: String?
    @Published var showMessage: Bool = false
    
    static let shared = NotificationMessageCenter()
    
    private init() {}
    
    @objc private func handlePendingMessage() {
        loadPendingMessage()
    }

    func loadPendingMessage() {
        if let msg = UserDefaults.standard.string(forKey: "pendingReminderMessage") {
            message = msg
            showMessage = true
            UserDefaults.standard.removeObject(forKey: "pendingReminderMessage") //eliminas el objeto para evitar que se repita
        }
    }
    
    func showMessageSet(state : Bool){
        self.showMessage = state
    }
    
    
}
