//
//  GradientProgressBar.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//Barra de progreso personalizada
import SwiftUI

struct LabeledGradientProgressBar: View {

    var progress: Double
    var lostUnits: [Int]? = nil
    var totalUnits: Int? = nil

    var body: some View {

        GeometryReader { geo in

            ZStack(alignment: .leading) {

                Capsule()
                    .fill(Color.gray.opacity(0.15))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.fitnessMint, .fitnessAqua, .fitnessBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.6), value: progress)

                // 🔶 Marcadores de unidades perdidas (solo si existen)
                if let lostUnits, let totalUnits, totalUnits > 0 {

                    ForEach(lostUnits, id: \.self) { index in

                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                            .position(
                                x: geo.size.width * (CGFloat(index) + 0.5) / CGFloat(totalUnits),
                                y: (geo.size.height / 2) + 8
                            )
                    }
                }

                // Textos de porcentaje
                HStack {

                    Spacer(minLength: 0)

                    percentageText(0.25, active: progress >= 0.25)

                    Spacer()

                    percentageText(0.50, active: progress >= 0.50)

                    Spacer()

                    percentageText(0.75, active: progress >= 0.75)

                    Spacer()

                    percentageText(1.0, active: progress >= 1.0)
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 24)
    }

    @ViewBuilder
    private func percentageText(_ value: Double, active: Bool) -> some View {
        Text(value, format: .percent.precision(.fractionLength(0)))
            .font(.caption.weight(.heavy))
            .monospacedDigit()
            .foregroundStyle(active ? Color.black : Color.white.opacity(0.6))
            .padding(.horizontal, active ? 0 : 3)
            .padding(.vertical, active ? 0 : 1)
            .opacity(active ? 1.0 : 0.96)
            .animation(.easeInOut(duration: 0.4), value: active)
    }
}




extension Color {
    static let fitnessMint   = Color(red: 0.40, green: 0.85, blue: 0.65)
    static let fitnessAqua   = Color(red: 0.35, green: 0.75, blue: 0.80)
    static let fitnessBlue   = Color(red: 0.25, green: 0.55, blue: 0.85)
}
