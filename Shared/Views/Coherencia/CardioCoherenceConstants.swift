import SwiftUI

enum CardioCoherenceConstants {
    
    //Contreol de la pausa en el ciclo
    enum BreathingPattern {
        /// Pausa en milisegundos al final de inhalacion y exhalacion.
        static let topPauseMillis: UInt64 = 1100
        /// Intervalo de refresco de animacion y textos respiratorios.
        static let frameRefreshNanos: UInt64 = 16_000_000
    }

    //Contorl del ritmo respiratorio
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

    //Control del motor háptico de vibraciones
    enum Haptics {
        /// Intensidad fija de cada pulso para una sensación estable y orgánica.
        static let pulseIntensity: CGFloat = 0.30
        /// Intervalo mínimo entre pulsos (más denso al inicio de inhalación / final de exhalación).
        static let minPulseIntervalSeconds: Double = 0.055
        /// Intervalo máximo entre pulsos (más espaciado al final de inhalación / inicio de exhalación).
        static let maxPulseIntervalSeconds: Double = 0.16
        /// Frecuencia de muestreo del motor háptico para mantener sincronía temporal.
        static let schedulerTickNanos: UInt64 = 4_000_000
    }

    //Control del Orbe
    enum Orb {
        /// Factor base del radio del orbe respecto al canvas.
        static let baseRadiusFactor: CGFloat = 0.34
        /// Escala minima del orbe (cerrado).
        static let minScale: CGFloat = 0.78
        /// Delta de escala maxima (abierto = minScale + scaleRange).
        static let scaleRange: CGFloat = 0.22
        /// Factor del radio usado para dibujar la roseta dentro del orbe.
        static let rosetteRadiusFactor: CGFloat = 0.98
        /// Expansion del anillo exterior del orbe.
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

    //Control de roseta
    enum Rosette {
        /// Radio minimo de la roseta cuando esta cerrada.
        static let minRadiusFactor: CGFloat = 0.08
        /// Radio maximo de la roseta cuando esta abierta.
        static let maxRadiusFactor: CGFloat = 1.5
        /// Grados totales de rotacion dinamica de la roseta.
        static let rotationDegrees: CGFloat = 90.0
        /// Numero de petalos.
        static let petalCount = 12
        /// Distancia del centro de cada petalo respecto al centro de roseta.
        static let petalOrbitFactor: CGFloat = 0.34
        /// Escala minima del ancho de petalo.
        static let widthScaleMin: CGFloat = 0.62
        /// Escala maxima del ancho de petalo.
        static let widthScaleMax: CGFloat = 1.04
        /// Escala minima del largo de petalo.
        static let lengthScaleMin: CGFloat = 0.72
        /// Escala maxima del largo de petalo.
        static let lengthScaleMax: CGFloat = 1.0
        /// Factor base del radio largo del petalo.
        static let petalLengthBaseFactor: CGFloat = 0.33
        /// Factor base del radio ancho del petalo.
        static let petalWidthBaseFactor: CGFloat = 0.33
        /// Color de relleno del petalo.
        static let petalFillColor = Color(red: 0.29, green: 0.78, blue: 0.66, opacity: 0.66)
        /// Color de trazo del petalo.
        static let petalStrokeColor = Color(red: 0.19, green: 0.51, blue: 0.44, opacity: 0.72)
        /// Grosor de trazo del petalo.
        static let petalStrokeWidth: CGFloat = 0.9
    }
}
