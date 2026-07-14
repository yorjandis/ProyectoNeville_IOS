import Foundation

enum HealingSafetyPolicy {
    static let urgentSignals = [
        "Hay peligro inmediato o sientes que podrías hacerte daño o dañar a otra persona.",
        "Tienes dolor o presión intensa o nueva en el pecho, te has desmayado o te cuesta mucho respirar.",
        "Notas debilidad repentina, confusión intensa, dificultad para hablar o un síntoma neurológico nuevo.",
        "Has tomado una sobredosis, una sustancia peligrosa o has sufrido una lesión importante.",
        "No puedes mantenerte a salvo o no estás seguro de que esto sea solo una reacción emocional."
    ]

    static func combinedSignals(for situation: HealingSituation) -> [String] {
        var result = urgentSignals
        for signal in situation.redFlags where !result.contains(signal) {
            result.append(signal)
        }
        return result
    }
}

enum HealingSafetyCopy {
    static let informationalDisclaimer = "Esta guía ofrece apoyo educativo y de bienestar. Las técnicas y consejos pueden tener niveles de evidencia distintos. No diagnostica, no sustituye la atención sanitaria y no garantiza que una propuesta funcione en todos los casos."
    static let stopInstruction = "Detén cualquier ejercicio si aumenta el malestar, aparece dolor, mareo intenso o dificultad para respirar. Respira con normalidad y busca ayuda si lo necesitas."
}
