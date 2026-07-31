//
//  IntervalProgressView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 28/12/25.
//

import SwiftUI

struct IntervalProgressView: View {

    let totalInterval: TimeInterval
    let startedAt: Date
    let size: CGFloat

    @ObservedObject private var clock = GlobalClock.shared
    @AppStorage("hideTextInProgressReminder")
    private var hideTextInProgressReminder: Bool = false

    // ⏱ Elapsed SIEMPRE desde 0
    private var elapsed: TimeInterval {
        max(clock.now.timeIntervalSince(startedAt), 0)
    }

    private var remaining: TimeInterval {
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: totalInterval)
        return max(totalInterval - cycleElapsed, 0)
    }

    private var progress: Double {
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: totalInterval)
        return cycleElapsed / totalInterval
    }

    var body: some View {
        ZStack {
            let lineWidth = size * 0.12

            RoundedRectangle(cornerRadius: size * 0.35)
                .stroke(.black.opacity(0.15), lineWidth: lineWidth)

            RoundedRectangle(cornerRadius: size * 0.35)
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        stops: [
                            .init(
                                color: Color(red: 0.42, green: 0.88, blue: 0.78),
                                location: 0
                            ),
                            .init(
                                color: Color(red: 0.08, green: 0.48, blue: 0.68),
                                location: 0.55
                            ),
                            .init(
                                color: Color(red: 0.03, green: 0.14, blue: 0.38),
                                location: 1
                            )
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .animation(.linear(duration: 0.4), value: progress)

            if !hideTextInProgressReminder {
                Text(timeText)
                    .font(.system(
                        size: size * 0.28,
                        weight: .bold,
                        design: .monospaced
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, size * 0.2)
            }
        }
        .frame(maxWidth: 125)
        .frame(height: size * 0.65)
    }

    private var timeText: String {
        let total = Int(remaining)

        let secondsInMinute = 60
        let secondsInHour = 3_600
        let secondsInDay = 86_400
        let secondsInMonth = 2_592_000

        let months = total / secondsInMonth
        let days = (total % secondsInMonth) / secondsInDay
        let hours = (total % secondsInDay) / secondsInHour
        let minutes = (total % secondsInHour) / secondsInMinute
        let seconds = total % secondsInMinute

        if months > 0 {
            return String(format: "%dM:%02dd:%02dh", months, days, hours)
        } else if days > 0 {
            return String(format: "%dd:%02dh:%02dm", days, hours, minutes)
        } else if hours > 0 {
            return String(format: "%02dh:%02dm:%02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm:%02ds", minutes, seconds)
        }
    }
}
