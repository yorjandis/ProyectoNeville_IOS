import SwiftUI
import Foundation

enum CardioCoherenceConstants {
    
    //Contreol de la pausa en el ciclo
    enum BreathingPattern {
        /// Pausa en milisegundos al final de inhalacion y exhalacion.
        static let topPauseMillis: UInt64 = 1100
        /// Intervalo de refresco de animacion y textos respiratorios.
        static let frameRefreshNanos: UInt64 = 16_000_000
        /// Segundos de exhalación preparatoria inicial antes de la primera inhalación.
        static let initialPreparatoryExhaleSeconds: Double = 7.0
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
        static let ringLineWidth: CGFloat = 2
        /// Cierre adicional del anillo al final de exhalación para continuidad visual del vaciado.
        static let exhalePauseTailShrink: CGFloat = 0.055
        /// Factor de suavizado tipo resorte para la transición del anillo entre fases.
        static let ringSpringSmoothing: CGFloat = 0.8
        /// Paso máximo de escala del anillo por frame para evitar saltos visuales.
        static let maxRingScaleStepPerFrame: CGFloat = 0.006
        /// Fracción inicial de la inhalación en la que se libera el cierre extra del anillo.
        static let inhaleReleaseWindow: CGFloat = 0.56 //0.28
        /// Duración del fade-in inicial del anillo durante la primera inhalación.
        /// A mayor valor, aparición más sutil.
        static let initialRingRevealDurationSeconds: Double = 2.8
        /// Duración de transición entre textos respiratorios (Prepárate/Inhala/Exhala).
        static let breathingCueTransitionDurationSeconds: Double = 0.80

        /// Color central del gradiente radial del orbe.
        static let coreColor = Color(red: 0.13, green: 0.03, blue: 0.13, opacity: 1.0)
        /// Color medio del gradiente radial del orbe.
        static let middleColor = Color(red: 0.13, green: 0.12, blue: 0.16, opacity: 0.22)
        /// Color exterior del gradiente radial del orbe.
        static let outerColor = Color(red: 0.07, green: 0.04, blue: 0.20, opacity: 0.10)
        /// Color del anillo exterior del orbe.
        static let ringColor = Color(red: 0.36, green: 0.39, blue: 0.84)
    }

    //Control de audio de coherencia
    enum Audio {
        /// Nombre del archivo de música de fondo para la vista de coherencia.
        static let backgroundTrackName = "music_coherencia"
        /// Extensión del archivo de música de fondo.
        static let backgroundTrackExtension = "mp3"
        /// Subcarpeta del bundle donde se encuentra la música.
        static let backgroundTrackSubdirectory = "coherenciaMusica"
        /// Clave de persistencia para recordar si la música está habilitada.
        static let backgroundMusicEnabledKey = "coherencia_background_music_enabled"
        /// Volumen de reproducción de la música de coherencia (0.0 a 1.0).
        static let backgroundMusicVolume: Float = 0.8
        /// Segundo desde donde debe iniciar y repetirse la música en la sesión de coherencia.
        static let sessionLoopStartSeconds: TimeInterval = 30.0
        /// Clave para persistir el nombre del fichero de música personalizada de sesión.
        static let customMusicFileNameKey = "coherencia_custom_music_file_name"
        /// Clave para activar/desactivar uso de música personalizada en sesión.
        static let useCustomMusicInSessionKey = "coherencia_use_custom_music_in_session"
    }

    enum Welcome {
        /// Retraso inicial antes de mostrar el primer texto de bienvenida.
        static let initialTextDelaySeconds: TimeInterval = 1.60
        /// Duración del fundido de salida del audio al final de la bienvenida.
        static let audioFadeOutSeconds: TimeInterval = 8.0
        /// Imagen de fondo usada en la pantalla de bienvenida.
        static let backgroundImageName: String = "cc_20"
        /// Extensión de la imagen de fondo de bienvenida.
        static let backgroundImageExtension: String = "JPG"
        /// Textos que aparecen secuencialmente durante la bienvenida (exactamente 4).
        /// Se construyen con una bienvenida fija + un trío aleatorio.
        static var texts: [String] {
            let selectedTrio = phraseTrios.randomElement() ?? defaultTrio
            return [
                "Bienvenido a Coherencia \nCardio - Cerebral",
                selectedTrio.0,
                selectedTrio.1,
                selectedTrio.2
            ]
        }
        /// Duración manual para cada texto, en el mismo orden que `texts` (exactamente 4 valores).
        static let textDurationsSeconds: [TimeInterval] = [6.0 , 8.80, 6.50, 7.0]
        /// Duración total automática (retraso inicial + suma de duraciones de textos).
        static var durationSeconds: TimeInterval {
            initialTextDelaySeconds + textDurationsSeconds.reduce(0, +)
        }

        static let defaultTrio: (String, String, String) = (
            "La coherencia es el lenguaje secreto\nentre tu corazón y tu mente",
            "Todo lo que necesitas\nya habita en tu interior",
            "Entra a tu espacio sagrado y que la magia ocurra"
        )

        /// Colección unificada de tríos para construir una narrativa completa.
        static let phraseTrios: [(String, String, String)] = [
            (
                "La coherencia es el lenguaje secreto\nentre tu corazón y tu mente",
                "Todo lo que necesitas\nya habita en tu interior",
                "Entra a tu espacio sagrado y que la magia ocurra"
            ),
            (
                "Cuando entras en coherencia,\ntu biología recuerda su perfección",
                "Hoy eliges elevar tu estado,\ny transformar tu realidad",
                "Deja que el misterio te envuelva\ny revele su verdad"
            ),
            (
                "Tu corazón sabe el camino,\ntu mente aprende a seguirlo",
                "Eres más poderoso de lo que recuerdas",
                "Respira y cruza el umbral\ndonde tu esencia se revela"
            ),
            (
                "Aquí comienza la alineación\nentre lo que sientes\ny lo que eres",
                "Tu corazón sabe el camino a tu estado de perfección",
                "Vamos a hacer que la magia ocurra!"
            ),
            (
                "Cada latido es una puerta\nhacia tu equilibrio natural",
                "Estás recordando quién eres\nmás allá del pensamiento",
                "Entrégate al ritmo interno\ny deja que te guíe"
            ),
            (
                "Cuando mente y corazón se encuentran,\nnace un nuevo estado de ser",
                "Hoy creas desde la coherencia,\nno desde la reacción",
                "Confía en lo que emerge\nsin necesidad de entenderlo"
            ),
            (
                    "Tu corazón marca el ritmo\nde tu verdad más profunda",
                    "Hoy eliges responder desde la calma\ny no desde el impulso",
                    "Deja que esa calma\nse convierta en claridad"
                ),
            (
                    "Tu campo energético responde\na lo que sientes ahora",
                    "Hoy eliges sentir elevación,\napertura y posibilidad",
                    "Deja que esa frecuencia\ncree tu realidad"
                ),
            (
                    "En este instante,\ntodo se reorganiza a tu favor",
                    "Eres el observador y el creador\nde tu experiencia",
                    "Permite que la transformación\nocurra sin resistencia"
                )
        ]
            
    }

        
    //Control de roseta
    enum Rosette {
        /// Radio minimo de la roseta cuando esta cerrada.
        static let minRadiusFactor: CGFloat = 0.08
        /// Radio maximo de la roseta cuando esta abierta.
        static let maxRadiusFactor: CGFloat = 1.55
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
        /// Intensidad de variación dinámica del ancho de pétalo durante rotación/desenrollado.
        /// Ajuste fino: 0.0 desactiva la variación; valores ~0.12...0.30 generan efecto orgánico.
        static let petalWidthVariationIntensity: CGFloat = 0.22
        /// Color de relleno del petalo.
        static let petalFillColor = Color(red: 0.29, green: 0.78, blue: 0.66, opacity: 0.66)
        /// Color de trazo del petalo.
        static let petalStrokeColor = Color(red: 0.19, green: 0.51, blue: 0.44, opacity: 0.72)
        /// Grosor de trazo del petalo.
        static let petalStrokeWidth: CGFloat = 0.9
    }
}
