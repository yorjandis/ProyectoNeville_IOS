import SwiftUI

/// Una meta completa y reutilizable que sirve como punto de partida para el formulario.
struct GoalExample: Identifiable {
    let id: String
    let category: String
    let symbol: String
    let tint: Color
    let title: String
    let details: String
    let configurationSummary: String
    let customUnitLabel: String
    let executionTargetValue: Double
    let completionBasis: GoalCompletionBasis
    let amount: Int
    let durationValue: Int
    let durationUnit: TimeUnit
    let scheduleType: GoalScheduleType
    let intervalUnit: TimeUnit
    let frequency: Int
    let weeklyDays: Set<GoalWeekday>
    let dayPeriod: GoalDayPeriod
    let weeklyTimeMinutes: Int?
    let specificDateOffsets: [Int]

    static var examples: [GoalExample] {
        spanishExamples.map {
            GoalEditorialLocalization.example(id: $0.id, fallback: $0)
        }
    }

    private static let spanishExamples: [GoalExample] = [
        GoalExample(
            id: "meditacion-diaria",
            category: "Bienestar",
            symbol: "brain.head.profile",
            tint: .purple,
            title: "Meditar 10 minutos",
            details: "Reservar un momento tranquilo cada mañana para respirar y empezar el día con más claridad.",
            configurationSummary: "Cada día · mañana · durante 30 días",
            customUnitLabel: "minutos",
            executionTargetValue: 10,
            completionBasis: .duration,
            amount: 30,
            durationValue: 30,
            durationUnit: .dias,
            scheduleType: .interval,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .morning,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "caminar-cinco-km",
            category: "Salud",
            symbol: "figure.walk",
            tint: .green,
            title: "Caminar 5 km",
            details: "Completar una caminata a buen ritmo para mejorar la resistencia y despejar la mente.",
            configurationSummary: "Lunes, miércoles y viernes · tarde · 36 veces",
            customUnitLabel: "km",
            executionTargetValue: 5,
            completionBasis: .executions,
            amount: 36,
            durationValue: 30,
            durationUnit: .dias,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.monday, .wednesday, .friday],
            dayPeriod: .afternoon,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "leer-libros",
            category: "Aprendizaje",
            symbol: "books.vertical.fill",
            tint: .indigo,
            title: "Leer 20 páginas",
            details: "Avanzar cada noche en un libro y sustituir unos minutos de pantalla por lectura.",
            configurationSummary: "Cada día · noche · 25 veces",
            customUnitLabel: "páginas",
            executionTargetValue: 20,
            completionBasis: .executions,
            amount: 25,
            durationValue: 30,
            durationUnit: .dias,
            scheduleType: .interval,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .night,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "entrenamiento-fuerza",
            category: "Deporte",
            symbol: "dumbbell.fill",
            tint: .orange,
            title: "Entrenar fuerza 45 minutos",
            details: "Realizar una sesión completa de fuerza con calentamiento, ejercicios principales y vuelta a la calma.",
            configurationSummary: "Martes, jueves y sábado · 18:30 · 24 veces",
            customUnitLabel: "minutos",
            executionTargetValue: 45,
            completionBasis: .executions,
            amount: 24,
            durationValue: 30,
            durationUnit: .dias,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.tuesday, .thursday, .saturday],
            dayPeriod: .anytime,
            weeklyTimeMinutes: 18 * 60 + 30,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "ahorro-mensual",
            category: "Finanzas",
            symbol: "eurosign.circle.fill",
            tint: .mint,
            title: "Ahorrar 100 € al mes",
            details: "Separar el ahorro nada más empezar el mes y mantenerlo fuera de la cuenta de gastos cotidianos.",
            configurationSummary: "Cada mes · 100 euros · 12 veces",
            customUnitLabel: "euros",
            executionTargetValue: 100,
            completionBasis: .executions,
            amount: 12,
            durationValue: 1,
            durationUnit: .años,
            scheduleType: .interval,
            intervalUnit: .meses,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "llamar-familia",
            category: "Relaciones",
            symbol: "phone.fill",
            tint: .pink,
            title: "Llamar a mi familia",
            details: "Dedicar una conversación sin prisas a ponerse al día y cuidar el vínculo con las personas importantes.",
            configurationSummary: "Domingos · tarde · 12 veces",
            customUnitLabel: "llamada",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 12,
            durationValue: 3,
            durationUnit: .meses,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.sunday],
            dayPeriod: .afternoon,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "beber-agua",
            category: "Salud",
            symbol: "drop.fill",
            tint: .cyan,
            title: "Beber 8 vasos de agua",
            details: "Registrar al final del día que se alcanzó una hidratación suficiente, repartida a lo largo de la jornada.",
            configurationSummary: "Cada día · 8 vasos · durante 30 días",
            customUnitLabel: "vasos",
            executionTargetValue: 8,
            completionBasis: .duration,
            amount: 30,
            durationValue: 30,
            durationUnit: .dias,
            scheduleType: .interval,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "ordenar-casa",
            category: "Hogar",
            symbol: "house.fill",
            tint: .brown,
            title: "Ordenar una zona de casa",
            details: "Elegir un cajón, armario o rincón, retirar lo innecesario y dejarlo organizado de forma sostenible.",
            configurationSummary: "Sábados · mañana · 8 zonas",
            customUnitLabel: "zona",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 8,
            durationValue: 2,
            durationUnit: .meses,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.saturday],
            dayPeriod: .morning,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "estudiar-idioma",
            category: "Aprendizaje",
            symbol: "character.book.closed.fill",
            tint: .blue,
            title: "Estudiar un idioma 30 minutos",
            details: "Combinar vocabulario, comprensión y conversación en una sesión breve pero constante.",
            configurationSummary: "De lunes a viernes · 20:00 · durante 3 meses",
            customUnitLabel: "minutos",
            executionTargetValue: 30,
            completionBasis: .duration,
            amount: 60,
            durationValue: 3,
            durationUnit: .meses,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            dayPeriod: .anytime,
            weeklyTimeMinutes: 20 * 60,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "escritura-creativa",
            category: "Creatividad",
            symbol: "pencil.and.outline",
            tint: .teal,
            title: "Escribir 500 palabras",
            details: "Producir un primer borrador sin editar para avanzar de forma constante en un relato, diario o proyecto.",
            configurationSummary: "Cada 2 días · mañana · 30 veces",
            customUnitLabel: "palabras",
            executionTargetValue: 500,
            completionBasis: .executions,
            amount: 30,
            durationValue: 2,
            durationUnit: .meses,
            scheduleType: .interval,
            intervalUnit: .dias,
            frequency: 2,
            weeklyDays: [],
            dayPeriod: .morning,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "desconexion-digital",
            category: "Bienestar",
            symbol: "iphone.slash",
            tint: .red,
            title: "Desconectar del móvil 2 horas",
            details: "Dejar el teléfono fuera de alcance para disfrutar de una tarde semanal sin redes ni notificaciones.",
            configurationSummary: "Domingos · 17:00 · 12 veces",
            customUnitLabel: "horas",
            executionTargetValue: 2,
            completionBasis: .executions,
            amount: 12,
            durationValue: 3,
            durationUnit: .meses,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.sunday],
            dayPeriod: .anytime,
            weeklyTimeMinutes: 17 * 60,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "revisiones-preventivas",
            category: "Organización",
            symbol: "calendar.badge.checkmark",
            tint: .gray,
            title: "Completar mis revisiones preventivas",
            details: "Programar tres hitos para pedir cita, realizar la revisión y comprobar o archivar los resultados.",
            configurationSummary: "3 fechas específicas · en 7, 30 y 60 días",
            customUnitLabel: "revisión",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 3,
            durationValue: 2,
            durationUnit: .meses,
            scheduleType: .specificDates,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .morning,
            weeklyTimeMinutes: nil,
            specificDateOffsets: [7, 30, 60]
        ),
        GoalExample(
            id: "pausa-visual",
            category: "Salud digital",
            symbol: "eye.fill",
            tint: .cyan,
            title: "Descansar la vista 20 segundos",
            details: "Apartar la mirada de la pantalla y enfocar un punto lejano para reducir la fatiga visual durante una jornada intensa.",
            configurationSummary: "Cada 30 minutos · 20 segundos · 12 veces",
            customUnitLabel: "segundos",
            executionTargetValue: 20,
            completionBasis: .executions,
            amount: 12,
            durationValue: 1,
            durationUnit: .dias,
            scheduleType: .interval,
            intervalUnit: .minutos,
            frequency: 30,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "pausa-activa",
            category: "Salud",
            symbol: "figure.cooldown",
            tint: .green,
            title: "Hacer una pausa activa de 5 minutos",
            details: "Levantarse, movilizar hombros y cadera y caminar un poco para romper periodos largos de sedentarismo.",
            configurationSummary: "Cada 2 horas · 5 minutos · 8 veces",
            customUnitLabel: "minutos",
            executionTargetValue: 5,
            completionBasis: .executions,
            amount: 8,
            durationValue: 1,
            durationUnit: .dias,
            scheduleType: .interval,
            intervalUnit: .horas,
            frequency: 2,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "revision-semanal",
            category: "Organización",
            symbol: "checklist.checked",
            tint: .indigo,
            title: "Hacer una revisión semanal",
            details: "Revisar compromisos, celebrar avances, cerrar pendientes y elegir las tres prioridades de la siguiente semana.",
            configurationSummary: "Cada semana · 30 minutos · durante 3 meses",
            customUnitLabel: "minutos",
            executionTargetValue: 30,
            completionBasis: .duration,
            amount: 12,
            durationValue: 3,
            durationUnit: .meses,
            scheduleType: .interval,
            intervalUnit: .semanas,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "salida-naturaleza",
            category: "Bienestar",
            symbol: "leaf.fill",
            tint: .green,
            title: "Pasar 90 minutos en la naturaleza",
            details: "Salir a un parque, bosque o entorno natural sin prisas, caminar y prestar atención consciente al entorno.",
            configurationSummary: "Cada 2 semanas · 90 minutos · durante 6 meses",
            customUnitLabel: "minutos",
            executionTargetValue: 90,
            completionBasis: .duration,
            amount: 13,
            durationValue: 6,
            durationUnit: .meses,
            scheduleType: .interval,
            intervalUnit: .semanas,
            frequency: 2,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "limpieza-digital-mensual",
            category: "Organización",
            symbol: "externaldrive.fill.badge.minus",
            tint: .gray,
            title: "Ordenar 50 archivos digitales",
            details: "Eliminar duplicados, archivar documentos útiles y vaciar descargas para mantener un espacio digital manejable.",
            configurationSummary: "Cada mes · 50 archivos · 6 veces",
            customUnitLabel: "archivos",
            executionTargetValue: 50,
            completionBasis: .executions,
            amount: 6,
            durationValue: 6,
            durationUnit: .meses,
            scheduleType: .interval,
            intervalUnit: .meses,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "chequeo-anual",
            category: "Salud",
            symbol: "cross.case.fill",
            tint: .red,
            title: "Realizar un chequeo preventivo anual",
            details: "Revisar con un profesional qué controles corresponden según la edad y los antecedentes, y dar seguimiento a los resultados.",
            configurationSummary: "Cada año · 1 chequeo · durante 3 años",
            customUnitLabel: "chequeo",
            executionTargetValue: 1,
            completionBasis: .duration,
            amount: 3,
            durationValue: 3,
            durationUnit: .años,
            scheduleType: .interval,
            intervalUnit: .años,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "diario-gratitud",
            category: "Bienestar",
            symbol: "heart.text.square.fill",
            tint: .pink,
            title: "Escribir 3 motivos de gratitud",
            details: "Anotar experiencias concretas, personas o pequeños detalles positivos para entrenar una mirada más equilibrada del día.",
            configurationSummary: "Lunes, miércoles y viernes · noche · durante 8 semanas",
            customUnitLabel: "motivos",
            executionTargetValue: 3,
            completionBasis: .duration,
            amount: 24,
            durationValue: 8,
            durationUnit: .semanas,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.monday, .wednesday, .friday],
            dayPeriod: .night,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "luz-natural",
            category: "Sueño",
            symbol: "sun.max.fill",
            tint: .orange,
            title: "Tomar 15 minutos de luz natural",
            details: "Salir al exterior al empezar el día para apoyar el ritmo circadiano, el estado de alerta y el descanso nocturno.",
            configurationSummary: "Cada día · mañana · durante 6 semanas",
            customUnitLabel: "minutos",
            executionTargetValue: 15,
            completionBasis: .duration,
            amount: 42,
            durationValue: 6,
            durationUnit: .semanas,
            scheduleType: .interval,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .morning,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "planificar-comidas",
            category: "Nutrición",
            symbol: "fork.knife.circle.fill",
            tint: .mint,
            title: "Planificar 5 comidas saludables",
            details: "Elegir platos sencillos, comprobar ingredientes y preparar una lista de compra para reducir decisiones impulsivas.",
            configurationSummary: "Domingos · 11:00 · durante 3 meses",
            customUnitLabel: "comidas",
            executionTargetValue: 5,
            completionBasis: .duration,
            amount: 13,
            durationValue: 3,
            durationUnit: .meses,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.sunday],
            dayPeriod: .anytime,
            weeklyTimeMinutes: 11 * 60,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "yoga-matutino",
            category: "Movimiento",
            symbol: "figure.mind.and.body",
            tint: .purple,
            title: "Practicar yoga 25 minutos",
            details: "Combinar movilidad, respiración y posturas básicas para comenzar el día con el cuerpo activo y la mente centrada.",
            configurationSummary: "Martes y jueves · 07:00 · durante 8 semanas",
            customUnitLabel: "minutos",
            executionTargetValue: 25,
            completionBasis: .duration,
            amount: 16,
            durationValue: 8,
            durationUnit: .semanas,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.tuesday, .thursday],
            dayPeriod: .anytime,
            weeklyTimeMinutes: 7 * 60,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "trabajo-profundo",
            category: "Productividad",
            symbol: "timer",
            tint: .blue,
            title: "Completar 90 minutos de trabajo profundo",
            details: "Trabajar en una prioridad importante con notificaciones silenciadas, una tarea definida y sin cambiar de contexto.",
            configurationSummary: "De lunes a viernes · 09:00 · 40 sesiones",
            customUnitLabel: "minutos",
            executionTargetValue: 90,
            completionBasis: .executions,
            amount: 40,
            durationValue: 8,
            durationUnit: .semanas,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            dayPeriod: .anytime,
            weeklyTimeMinutes: 9 * 60,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "cocinar-cenas-saludables",
            category: "Nutrición",
            symbol: "carrot.fill",
            tint: .orange,
            title: "Cocinar una cena saludable",
            details: "Preparar una cena basada en alimentos poco procesados, con verdura, proteína y una ración adecuada.",
            configurationSummary: "Lunes, miércoles y domingo · noche · 24 cenas",
            customUnitLabel: "cena",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 24,
            durationValue: 8,
            durationUnit: .semanas,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.monday, .wednesday, .sunday],
            dayPeriod: .night,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "rutina-sueno",
            category: "Sueño",
            symbol: "moon.zzz.fill",
            tint: .indigo,
            title: "Completar una rutina de sueño de 30 minutos",
            details: "Bajar la luz, dejar pantallas, preparar el día siguiente y realizar una actividad tranquila antes de acostarse.",
            configurationSummary: "Cada día · noche · durante 6 semanas",
            customUnitLabel: "minutos",
            executionTargetValue: 30,
            completionBasis: .duration,
            amount: 42,
            durationValue: 6,
            durationUnit: .semanas,
            scheduleType: .interval,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .night,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "reflexion-terapeutica",
            category: "Autoconocimiento",
            symbol: "bubble.left.and.text.bubble.right.fill",
            tint: .teal,
            title: "Realizar 4 sesiones de reflexión guiada",
            details: "Usar cada sesión para identificar patrones, preparar preguntas, registrar aprendizajes y acordar una acción concreta.",
            configurationSummary: "4 fechas específicas · tarde · cada 2 semanas",
            customUnitLabel: "sesión",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 4,
            durationValue: 2,
            durationUnit: .meses,
            scheduleType: .specificDates,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .afternoon,
            weeklyTimeMinutes: nil,
            specificDateOffsets: [7, 21, 35, 49]
        ),
        GoalExample(
            id: "revision-valores",
            category: "Crecimiento personal",
            symbol: "compass.drawing",
            tint: .purple,
            title: "Revisar mis valores y prioridades",
            details: "Responder por escrito qué importa ahora, qué está recibiendo mi tiempo y qué ajuste concreto quiero hacer.",
            configurationSummary: "4 fechas específicas · noche · en 1, 3, 6 y 12 meses",
            customUnitLabel: "revisión",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 4,
            durationValue: 1,
            durationUnit: .años,
            scheduleType: .specificDates,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .night,
            weeklyTimeMinutes: nil,
            specificDateOffsets: [30, 90, 180, 365]
        ),
        GoalExample(
            id: "aprendizaje-primeros-auxilios",
            category: "Aprendizaje",
            symbol: "cross.fill",
            tint: .red,
            title: "Completar un curso de primeros auxilios",
            details: "Dividir el aprendizaje en cuatro hitos: teoría básica, práctica, repaso de emergencias y evaluación final.",
            configurationSummary: "4 fechas específicas · cualquier momento · en 2 meses",
            customUnitLabel: "módulo",
            executionTargetValue: 1,
            completionBasis: .executions,
            amount: 4,
            durationValue: 2,
            durationUnit: .meses,
            scheduleType: .specificDates,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: [7, 21, 42, 60]
        ),
        GoalExample(
            id: "acto-amabilidad",
            category: "Relaciones",
            symbol: "hands.sparkles.fill",
            tint: .pink,
            title: "Realizar un acto consciente de amabilidad",
            details: "Ofrecer ayuda, agradecer de forma específica o dedicar atención plena a alguien sin esperar nada a cambio.",
            configurationSummary: "Martes y viernes · tarde · durante 10 semanas",
            customUnitLabel: "acto",
            executionTargetValue: 1,
            completionBasis: .duration,
            amount: 20,
            durationValue: 10,
            durationUnit: .semanas,
            scheduleType: .weekly,
            intervalUnit: .dias,
            frequency: 1,
            weeklyDays: [.tuesday, .friday],
            dayPeriod: .afternoon,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        ),
        GoalExample(
            id: "voluntariado",
            category: "Propósito",
            symbol: "person.2.fill",
            tint: .blue,
            title: "Dedicar 2 horas a una causa",
            details: "Colaborar de forma periódica con una iniciativa local alineada con los propios valores y necesidades de la comunidad.",
            configurationSummary: "Cada mes · 2 horas · 6 veces",
            customUnitLabel: "horas",
            executionTargetValue: 2,
            completionBasis: .executions,
            amount: 6,
            durationValue: 6,
            durationUnit: .meses,
            scheduleType: .interval,
            intervalUnit: .meses,
            frequency: 1,
            weeklyDays: [],
            dayPeriod: .anytime,
            weeklyTimeMinutes: nil,
            specificDateOffsets: []
        )
    ]
}

struct GoalExamplesView: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (GoalExample) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(GoalExample.examples) { example in
                        GoalExampleCard(example: example) {
                            onSelect(example)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(Color.secondary.opacity(0.08))
            .navigationTitle("Ideas para tus metas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 520, idealWidth: 580, minHeight: 560, idealHeight: 680)
#endif
    }
}

private struct GoalExampleCard: View {
    let example: GoalExample
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: example.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(example.tint.gradient, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(example.category.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(example.tint)
                    Text(example.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }

            Text(example.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Label(example.configurationSummary, systemImage: "slider.horizontal.3")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Button(action: onSelect) {
                Label("Usar este ejemplo", systemImage: "arrow.down.doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(example.tint)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(example.tint.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}
