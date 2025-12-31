//
//  ProgressHome.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//

//Crea una instancia de la barra de progreso para ser colocada em el home

import SwiftUI

struct ReminderProgressWidget: View {
    
    let reminder: StoredReminder
    let subtitle: String
    
    
    @AppStorage("hideTextInProgressReminder") private var hideTextInProgressReminder: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            
            progressView
                .opacity(reminder.isStarted ? 1.0 : 0.5)         // Atenúa si está pausado
                .grayscale(reminder.isStarted ? 0 : 0.7)        // Aplica gris si está pausado
                .animation(.default, value: reminder.isStarted) // Animación suave
            
            Text(subtitle.truncated(maxLength: 12))
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(reminder.isStarted ? 1.0 : 0.6) // Atenúa texto cuando pausado
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        switch reminder.frequency {
        case .interval:
            if let startedAt = reminder.startedAt, let interval = reminder.frequency.timeInterval {
                IntervalProgressView(totalInterval: interval, startedAt: startedAt, size: 60)
            } else {
                fallbackPauseView
            }
        case .daily, .date, .monthly, .yearly:
            if let startedAt = reminder.startedAt,
               let progress = reminder.frequency.progressSince(startedAt: startedAt) {
                IntervalProgressView(totalInterval: progress.total,
                                     startedAt: Date().addingTimeInterval(-progress.elapsed),
                                     size: 60)
            } else {
                fallbackPauseView
            }
        }
    }
    
    @ViewBuilder
    private var fallbackPauseView: some View {
        Image(systemName: "pause.circle.fill")
            .font(.system(size: 40))
            .foregroundStyle(.gray.opacity(0.6))
    }
}

extension String {
    func truncated(maxLength: Int) -> String {
        guard self.count > maxLength else {
            return self
        }

        let truncatedText = self.prefix(maxLength)
        return "\(truncatedText)..."
    }
}
