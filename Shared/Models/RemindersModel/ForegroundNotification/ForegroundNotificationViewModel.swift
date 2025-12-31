//
//  ForegroundNotificationViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//

import SwiftUI
import UserNotifications
import Combine

struct ForegroundNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class ForegroundNotificationManager: ObservableObject {

    static let shared = ForegroundNotificationManager()

    @Published var notification: ForegroundNotification?
    @Published var showBanner = false

    private init() {
        NotificationCenter.default.addObserver(
            forName: .didReceiveForegroundNotification,
            object: nil,
            queue: .main
        ) { notification in

            guard
                let info = notification.userInfo,
                let title = info["title"] as? String,
                let message = info["message"] as? String
            else { return }
            Task{@MainActor in
                self.notification = ForegroundNotification(
                    title: title,
                    message: message
                )

                withAnimation {
                    self.showBanner = true
                }
            }
            

            // Auto ocultar
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.showBanner = false
                }
            }
        }
    }
}
