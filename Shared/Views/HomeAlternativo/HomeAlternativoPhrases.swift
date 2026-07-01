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
        "Empieza desde tu mejor versión",
        "Hoy eliges quién ser",
        "Tu momento es ahora",
        "Avanza hoy con intención",
        "Recuerda, todo comienza en ti",
        "Hoy dirige tu energía sabiamente",
        "Hoy siembras tu futuro",
        "Actúa desde tu visión futura",
        "Comienza este día con propósito",
        "Hoy eliges tu estado interior",
        "Hoy construyes desde la calma",
        "Hoy lideras tu experiencia",
        "Honra este nuevo comienzo",
        "Hoy conviertes intención en acción"
        
        
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
        "Tu siguiente elección también cuenta",
        "Vuelve al momento presente",
        "Has una pausa, respira y continúa",
        "Regresa a tu centro",
        "Mantén viva tu intención",
        "Elige calma otra vez",
        "Este instante también importa",
        "Observa antes de reaccionar",
        "Sigue creando conscientemente",
        "Tu poder sigue aquí, contigo",
        "Vuelve a lo esencial",
        "Permanece presente",
        "Conecta con tu propósito",
        "Una pausa puede cambiarlo todo",
        "Recuerda quién estás siendo",
        "Aún puedes elegir",
        "Vuelve a sentir plenitud",
        "Crea desde este instante",
        "Recupera tu enfoque",
        "Sigue alineado contigo"
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
        "Mañana empieza en el estado que duermes hoy",
        "Agradece lo vivido hoy",
        "Integra las lecciones del día",
        "Descansa en confianza",
        "Honra tu progreso",
        "Suelta lo que ya pasó",
        "Conserva lo aprendido",
        "Termina el día en paz",
        "Observa con compasión",
        "Reconoce tu crecimiento",
        "Deja espacio para la calma",
        "Agradece y descansa",
        "Permite que todo se asiente",
        "Encuentra sentido en la experiencia",
        "Libera el peso del día",
        "Abraza lo que descubriste",
        "Descansa en tu nueva identidad",
        "Cierra el día conscientemente",
        "Todo aprendizaje suma",
        "Mañana continúa la creación",
        "Duerme en coherencia",
        "Relájate y disfruta tu descanso",
        "Cada noche es una oportunidad de crear",
        "Recupera e integra las experiencias del día",
        "Bendice este día",
        "Descansa en la certeza de tu poder creativo",
        "No dejes psar este día sin bendecirte",
        "Agradece, todo está en su justo lugar"
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
 

 
    static let night: [String] = [
        
    ]

}
