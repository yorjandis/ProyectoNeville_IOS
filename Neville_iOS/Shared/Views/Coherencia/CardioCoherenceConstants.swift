import SwiftUI

enum CardioCoherenceConstants {
    enum BreathingPattern {
        /// Pausa en milisegundos al final de inhalación y exhalación.
        static let topPauseMillis: UInt64 = 1100
        /// Intervalo de refresco de animación y textos respiratorios.
        static let frameRefreshNanos: UInt64 = 16_000_000
    }

    enum BreathingRhythm {
        /// Ritmo 5s inhalar / 5s exhalar.
        static let fiveFive = (inhaleMillis: 5000, exhaleMillis: 5000)
        /// Ritmo 5.5s inhalar / 5.5s exhalar.
        static let fiveHalfFiveHalf = (inhaleMillis: 5500, exhaleMillis: 5500)
        /// Ritmo 6s inhalar / 6s exhalar.
        static let sixSix = (inhaleMillis: 6000, exhaleMillis: 6000)
        /// Ritmo 4.5s inhalar / 5.5s exhalar.
        static let fourHalfFiveHalf = (inhaleMillis: 4500, exhaleMillis: 5500)
    }

    enum Haptics {
        /// Pulsos hápticos por segundo durante la rampa.
        static let pulsesPerSecond: Double = 12
        /// Mínimo de pulsos por tramo para evitar patrón demasiado corto.
        static let minPulses = 32
        /// Máximo de pulsos por tramo para evitar saturación.
        static let maxPulses = 96
        /// Intensidad mínima aplicada al pulso háptico.
        static let minIntensity: CGFloat = 0.08
    }

    enum Orb {
        /// Factor base del radio del orbe respecto al canvas.
        static let baseRadiusFactor: CGFloat = 0.34
        /// Escala mínima del orbe (cerrado).
        static let minScale: CGFloat = 0.78
        /// Delta de escala máxima (abierto = minScale + scaleRange).
        static let scaleRange: CGFloat = 0.22
        /// Factor del radio usado para dibujar la roseta dentro del orbe.
        static let rosetteRadiusFactor: CGFloat = 0.98
        /// Expansión del anillo exterior del orbe.
        static let ringInsetFactor: CGFloat = 0.12
        /// Grosor del anillo exterior.
        static let ringLineWidth: CGFloat = 3

        /// Color central del gradiente radial del orbe.
        static let coreColor = Color(red: 0.13, green: 0.03, blue: 0.13, opacity: 1.0)
        /// Color medio del gradiente radial del orbe.
        static let middleColor = Color(red: 0.13, green: 0.12, blue: 0.16, opacity: 0.22)
        /// Color exterior del gradiente radial del orbe.
        static let outerColor = Color(red: 0.07, green: 0.04, blue: 0.20, opacity: 0.10)
        /// Color del anillo exterior del orbe.
        static let ringColor = Color(red: 0.36, green: 0.39, blue: 0.84)
    }

    enum Rosette {
        /// Radio mínimo de la roseta cuando está cerrada.
        static let minRadiusFactor: CGFloat = 0.08
        /// Radio máximo de la roseta cuando está abierta.
        static let maxRadiusFactor: CGFloat = 1.5
        /// Grados totales de rotación dinámica de la roseta.
        static let rotationDegrees: CGFloat = 90.0
        /// Número de pétalos.
        static let petalCount = 12
        /// Distancia del centro de cada pétalo respecto al centro de roseta.
        static let petalOrbitFactor: CGFloat = 0.34
        /// Escala mínima del ancho de pétalo.
        static let widthScaleMin: CGFloat = 0.62
        /// Escala máxima del ancho de pétalo.
        static let widthScaleMax: CGFloat = 1.04
        /// Escala mínima del largo de pétalo.
        static let lengthScaleMin: CGFloat = 0.72
        /// Escala máxima del largo de pétalo.
        static let lengthScaleMax: CGFloat = 1.0
        /// Factor base del radio largo del pétalo.
        static let petalLengthBaseFactor: CGFloat = 0.33
        /// Factor base del radio ancho del pétalo.
        static let petalWidthBaseFactor: CGFloat = 0.33
        /// Color de relleno del pétalo.
        static let petalFillColor = Color(red: 0.29, green: 0.78, blue: 0.66, opacity: 0.66)
        /// Color de trazo del pétalo.
        static let petalStrokeColor = Color(red: 0.19, green: 0.51, blue: 0.44, opacity: 0.72)
        /// Grosor de trazo del pétalo.
        static let petalStrokeWidth: CGFloat = 0.9
    }
}
