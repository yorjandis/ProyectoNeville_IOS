//
//  NotificationBannerView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//
import SwiftUI

//Vista que aparece por encima de cualquier otra
struct NotificationBannerOverlay: View {

    @ObservedObject var manager = ForegroundNotificationManager.shared

    var body: some View {
        if manager.showBanner, let notification = manager.notification {
            VStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.title)
                        .font(.headline)
                    Text(notification.message)
                        .font(.subheadline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 10)
                .padding()
                
                Spacer()
            }
            .padding(.top, 10)
            .transition(.move(edge: .top))
            .zIndex(999)
        }
    }
}



