//
//  HomeAlternativoPhrases.swift
//  Neville_iOS
//
//  Created by Codex on 29/06/26.
//

import Foundation

enum HomeAlternativoDayMoment {
    case morning
    case afternoon
    case night

    static func current(for date: Date = Date(), calendar: Calendar = .current) -> HomeAlternativoDayMoment {
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12:
            return .morning
        case 12..<20:
            return .afternoon
        default:
            return .night
        }
    }
}

enum HomeAlternativoPhrases {
    static let morning: [String] = [
        "Meditar en la mañana organiza tu energía",
        "Hoy despiertas en un nuevo estado",
        "Empieza el día desde la versión que eliges ser",
        "Tu mañana obedece a la historia que aceptas",
        "Asume temprano lo que deseas vivir",
        "Tu atención abre el camino del día",
        "Respira, elige y crea desde adentro",
        "Este día responde a tu nueva identidad",
        "Tu cuerpo escucha la intención con la que comienzas",
        "Entra al día como quien ya lo logró",
        "La primera imagen interna dirige tus pasos",
        "Hoy practicas el futuro que quieres habitar",
        "Cada amanecer puede reeducar tu mente",
        "Empieza en calma y el mundo se ordena",
        "Tu percepción de hoy cambia tu biología",
        "El día nace desde el estado que sostienes",
        "Imagina con fe antes de actuar",
        "Tu energía de inicio marca la dirección",
        "Hoy eliges presencia antes que pasado",
        "Declara internamente quién eres ahora",
        "La mañana es tu primer acto creador",
        "Empieza desde tu mejor versión"
    ]

    static let afternoon: [String] = [
        "Vuelve al estado que elegiste al comenzar",
        "A mitad del día también puedes reiniciar",
        "Tu atención puede cambiar el rumbo ahora",
        "Respira y regresa a tu versión elevada",
        "Cada pausa es una puerta a otro estado",
        "Sostén la visión mientras actúas",
        "Tu cuerpo aprende de la emoción que repites",
        "Elige coherencia en medio del movimiento",
        "Lo externo no manda sobre tu estado",
        "Ahora puedes pensar desde el resultado",
        "Tu tarde se transforma con una nueva percepción",
        "La intención se fortalece con presencia",
        "Haz una cosa desde tu identidad elegida",
        "No negocies con el viejo hábito",
        "Tu mundo cambia cuando vuelves a ti",
        "Siente el resultado antes de perseguirlo",
        "Una emoción elevada reorganiza el día",
        "Actúa como quien ya recuerda su poder",
        "La tarde aún tiene espacio para crear",
        "Tu siguiente elección también cuenta"
    ]

    static let night: [String] = [
        "Cierra el día aceptando tu nuevo estado",
        "La noche integra lo que decides creer",
        "Antes de dormir, habita el resultado",
        "Tu imaginación prepara el mañana",
        "Suelta el día y conserva la visión",
        "Descansa en la identidad que estás creando",
        "La calma nocturna reeduca el cuerpo",
        "Tu subconsciente escucha lo que sientes real",
        "Duerme como quien ya recibió",
        "La gratitud sella una nueva percepción",
        "Esta noche no repites pasado, eliges futuro",
        "Permite que tu cuerpo memorice paz",
        "La quietud también es creación",
        "Revisa el día desde compasión y poder",
        "Antes del sueño, vuelve a la imagen cumplida",
        "Tu descanso puede fortalecer tu intención",
        "Entrega la duda y conserva la certeza",
        "La noche convierte práctica en integración",
        "Imagina suavemente lo que deseas vivir",
        "Mañana empieza en el estado que duermes hoy"
    ]

    static func random(for moment: HomeAlternativoDayMoment) -> String {
        switch moment {
        case .morning:
            return morning.randomElement() ?? "Hoy despiertas en un nuevo estado"
        case .afternoon:
            return afternoon.randomElement() ?? "Tu atención puede cambiar el rumbo ahora"
        case .night:
            return night.randomElement() ?? "Antes de dormir, habita el resultado"
        }
    }
}

//Frases que acompañan cada saludo
enum HomeAlternativoSaludos {
    static let morning: [String] = [
        "haz que este día cuente",
        "empieza desde tu mejor versión",
        "hoy eliges quién ser",
        "crea el día que imaginas",
        "tu momento es ahora",
        "avanza con intención",
        "todo comienza en ti",
        "dirige tu energía sabiamente",
        "abre espacio a lo posible",
        "hoy siembra tu futuro",
        "actúa desde tu visión",
        "comienza con propósito",
        "elige tu estado interior",
        "construye desde la calma",
        "lidera tu experiencia",
        "crea antes de reaccionar",
        "vive desde la posibilidad",
        "honra este nuevo comienzo",
        "da forma a tu día",
        "convierte intención en acción"
    ]

    static let afternoon: [String] = [
        "vuelve al momento presente",
        "respira y continúa",
        "regresa a tu centro",
        "mantén viva tu intención",
        "elige calma otra vez",
        "este instante también importa",
        "observa antes de reaccionar",
        "sigue creando conscientemente",
        "tu poder sigue aquí",
        "vuelve a lo esencial",
        "permanece presente",
        "conecta con tu propósito",
        "una pausa puede cambiarlo todo",
        "recuerda quién estás siendo",
        "la coherencia transforma",
        "aún puedes elegir",
        "vuelve a sentir plenitud",
        "crea desde este instante",
        "recupera tu enfoque",
        "sigue alineado contigo"
    ]

    static let night: [String] = [
        "agradece lo vivido hoy",
        "integra las lecciones del día",
        "descansa en confianza",
        "honra tu progreso",
        "suelta lo que ya pasó",
        "conserva lo aprendido",
        "termina el día en paz",
        "observa con compasión",
        "reconoce tu crecimiento",
        "deja espacio para la calma",
        "agradece y descansa",
        "permite que todo se asiente",
        "encuentra sentido en la experiencia",
        "libera el peso del día",
        "abraza lo que descubriste",
        "descansa en tu nueva identidad",
        "cierra el día conscientemente",
        "todo aprendizaje suma",
        "mañana continúa la creación",
        "duerme en coherencia"
    ]

    static func random(for moment: HomeAlternativoDayMoment) -> String {
        switch moment {
        case .morning:
            return morning.randomElement() ?? "haz que este día cuente"
        case .afternoon:
            return afternoon.randomElement() ?? "vuelve al momento presente"
        case .night:
            return night.randomElement() ?? "agradece lo vivido hoy"
        }
    }
}
