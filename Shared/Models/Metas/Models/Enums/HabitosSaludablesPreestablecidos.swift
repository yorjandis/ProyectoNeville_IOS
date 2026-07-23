//
//  HabitosSaludablesPreestablecidos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

import SwiftUI

nonisolated struct MetaPreestablecida{
    let titulo: String
    let description: String
    let unidadesInfo: [UnidadesInfo]
    var noUnidades : Int = 21
    var noFrecuencias : Int = 1
    var tipoUnidad: TimeUnit = .dias
    var scheduleType: GoalScheduleType = .interval
    var weeklyDaysPerWeek: Int = 3
    var dayPeriod: GoalDayPeriod = .anytime
    var customUnitLabel: String = ""
    var specificDates: [Date] = []

    var scheduleSummary: String {
        let label = customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityLabel = label.isEmpty ? GoalsL10n.unitNoun(count: noUnidades) : label
        let cadence: String
        switch scheduleType {
        case .interval:
            cadence = GoalsL10n.intervalCadence(frequency: noFrecuencias, unit: tipoUnidad)
        case .weekly:
            cadence = GoalsL10n.weeklyCadence(days: weeklyDaysPerWeek)
        case .specificDates:
            cadence = GoalsL10n.specificDatesCadence()
        }
        return GoalsL10n.format(
            "goals.dynamic.preset_schedule_summary",
            fallback: "{0} {1} · {2}",
            String(noUnidades),
            quantityLabel,
            GoalsL10n.addingPeriod(
                cadence,
                period: GoalSchedulingRules.normalizedDayPeriod(
                    scheduleType: scheduleType,
                    intervalUnit: tipoUnidad,
                    requestedPeriod: dayPeriod,
                    weeklyTimeMinutes: nil
                )
            )
        )
    }
}

nonisolated enum MetasPreestablecidas: String, CaseIterable, Identifiable {
    case CaminarPorLaMañana
    case HidratacionDiaria
    case RespiracionProfunda
    case EstiramientosMatutinos
    case Dormir8Horas
    case ComerVerdurasDiarias
    case EvitarAzucarProcesada
    case SuplementosVitaminicos
    case YogaDiario
    case MeditacionCorta
    
    // Longevidad
    case AyunoIntermitente
    case SaunaSemanal
    case EjercicioDeFuerza
    case ExposicionSolSegura
    case PaseosAlAireLibre
    case MasajesRelajantes
    case LecturaDiaria
    case ReduccionEstrés
    case ConectarConNaturaleza
    case DiarioGratitud
    
    // Neurociencia y mente
    case NeuroplasticidadEjercicio
    case AprenderAlgoNuevo
    case PracticarMindfulness
    case VisualizacionCreativa
    case DiarioDePensamientos
    case MusicaParaCerebro
    case LimitarRedesSociales
    case ConcentracionPomodoro
    case RespiracionCoherenciaCardiaca
    case DesafioMentalDiario
    
    // Enseñanzas Neville Goddard
    case VisualizarDeseos
    case SentirElDeseoComoRealidad
    case ReescribirElPasado
    case ImaginacionCreativaDiaria
    case EstadoDeGracias
    case ActuarComoSi
    case AfirmacionesDiarias
    case MeditacionImaginativa
    case RevisarSueños
    case ConectarConSubconsciente
    
    // Enseñanzas Joe Dispenza
    case MeditacionDiaria
    case CambioDeCreencias
    case RomperHabitosLimitantes
    case EmocionesPositivasDiarias
    case CrearNuevaRealidad
    case CoherenciaCorazonCerebro
    case TransformacionMental
    case RespiracionPotente
    case PracticaDeVision
    case LiberacionEmocional
    
    // Combinación hábitos prácticos adicionales
    case BeberAguaAlDespertar
    case CaminataDespuesComida
    case DiarioDeExito
    case RevisarMetasSemanal
    case DormirSinPantallas
    case ComerFrutasDiarias
    case PriorizarProteinas
    case EvitarCafeNoche
    case PausasActivasTrabajo
    case ReflexionAntesDormir
    case MeditacionCaminando
    case PracticarBondad
    case ContactoSocial
    case RespiracionProfundaTrabajo
    case YogaAntesDormir
    case PlanificacionDiaria
    case EvaluacionEmociones
    case PrácticaDePerdón
    case VisualizarExitoLaboral
    case MusicaParaRelajación
    
    //Otros Hábitos:
    case ExposiciónAlFrioControlada
    case CenaTemprana
    case DiaSinUltraprocesados
    case ControlGlucosaPostComida
    case TiempoSinEstimulos
    case ExposicionLuzMatutina
    case SilencioConsciente
    case TrabajoDeMovilidadProfunda
    case EntrenamientoEnZona2
    case EquilibrioYPropiocepcion
    case DetoxDigitalNocturno
    case ConsumoInformativoLimitado
    case PracticarIncomodidadVoluntaria
    case EspaciosOrdenadosDiarios
    case CaminarDescalzoSobreTierra_Hierba
    
    
    var id: String { self.rawValue }

    private var canonicalTitle: String {
        rawValue
            .replacingOccurrences(of: "([a-z])([A-Z])",
                                  with: "$1 $2",
                                  options: .regularExpression)
    }

    var getDescription: String {
        GoalEditorialLocalization.habitTitle(id: rawValue, fallback: canonicalTitle)
    }

    var getMeta: MetaPreestablecida {
        GoalEditorialLocalization.habit(id: rawValue, fallback: canonicalMeta)
    }

    private var canonicalMeta: MetaPreestablecida {
        switch self {
            
        case .ExposiciónAlFrioControlada:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Ducha fría progresiva o inmersión breve. \n Beneficio: activación simpática controlada, resiliencia metabólica.",
                unidadesInfo: [],
                noUnidades: 45
            )
            
        case .CenaTemprana:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Cenar 2–3h antes de dormir. \n Beneficio: mejora glucosa nocturna y sueño profundo",
                unidadesInfo: [],
                noUnidades: 30,
                dayPeriod: .afternoon,
                customUnitLabel: "cenas tempranas"
            )
            
        case .DiaSinUltraprocesados:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "1 día limpio total, por semana o diario",
                unidadesInfo: []
            )
            
        case .ControlGlucosaPostComida:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Caminar 10–15 min tras comidas principales",
                unidadesInfo: []
            )
            
        case .TiempoSinEstimulos:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "30–60 min sin móvil, música ni inputs. Entrena tolerancia al aburrimiento. Mejora dopamina basal.",
                unidadesInfo: [],
                noUnidades: 30
            )
            
        case .ExposicionLuzMatutina:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "10–20 min luz solar en primera hora. Sincronización circadiana",
                unidadesInfo: [],
                dayPeriod: .morning,
                customUnitLabel: "sesiones"
            )
            
        case .SilencioConsciente:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "5–10 min diarios de silencio total. Regulación del sistema nervioso",
                unidadesInfo: [],
                noUnidades: 30
            )
            
        case .EntrenamientoEnZona2:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Cardio suave 3–4 veces por semana. Adaptación mitocondrial progresiva",
                unidadesInfo: [],
                noUnidades: 60,
                tipoUnidad: .semanas,
                scheduleType: .weekly,
                weeklyDaysPerWeek: 3,
                customUnitLabel: "sesiones"
            )
            
        case .EquilibrioYPropiocepcion:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Ejercicios en una pierna, estabilidad. Prevención de caídas futura",
                unidadesInfo: [],
                noUnidades: 30
            )
            
        case .TrabajoDeMovilidadProfunda:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Movilidad de cadera, hombros, columna",
                unidadesInfo: [],
                noUnidades: 45
            )
            
        case .DetoxDigitalNocturno:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Sin pantallas 90 min antes dormir. Similar a DormirSinPantallas pero más estructurado.",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "noches"
            )    
        case .ConsumoInformativoLimitado:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Limitar noticias/redes a franja fija. Regulación dopaminérgica",
                unidadesInfo: [],
                noUnidades: 30
            )
        
        case .PracticarIncomodidadVoluntaria:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Hacer algo incómodo cada día. Ejemplos: Conversación difícil, Ducharse con agua más fría, Trabajo profundo sin distracción. Esto fortalece resiliencia psicológica",
                unidadesInfo: [],
                noUnidades: 45
            )
            
        case .EspaciosOrdenadosDiarios:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Orden mínimo antes dormir. Ejemplos: No dejar cosas desordenadas en la cama, no dejar teléfonos o dispositivos electrónicos a la vista. Esto fortalece la conciencia corporal y mental",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "noches"
            )
            
        case .CaminarDescalzoSobreTierra_Hierba:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Caminar descalzo en naturaleza",
                unidadesInfo: [],
                noUnidades: 30
            )
            
            // Salud física
        case .CaminarPorLaMañana:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Caminar 20-30 minutos por la mañana para activar cuerpo y mente",
                unidadesInfo: [],
                noUnidades: 21,
                tipoUnidad: .semanas,
                scheduleType: .weekly,
                weeklyDaysPerWeek: 3,
                dayPeriod: .morning,
                customUnitLabel: "caminatas"
            )
        case .HidratacionDiaria:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Beber al menos 2 litros de agua al día",
                unidadesInfo: [],
                customUnitLabel: "días hidratados"
            )
        case .RespiracionProfunda:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar respiraciones profundas varias veces al día para reducir estrés y aumentar oxigenación",
                unidadesInfo: []
            )
        case .EstiramientosMatutinos:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar estiramientos al despertar para mejorar movilidad y circulación",
                unidadesInfo: [],
                dayPeriod: .morning,
                customUnitLabel: "sesiones"
            )
        case .Dormir8Horas:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Dormir 8 horas cada noche para favorecer la recuperación física y mental",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "noches"
            )
        case .ComerVerdurasDiarias:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Incluir verduras en todas las comidas principales para una alimentación balanceada",
                unidadesInfo: []
            )
        case .EvitarAzucarProcesada:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Reducir el consumo de azúcares refinados y procesados",
                unidadesInfo: []
            )
        case .SuplementosVitaminicos:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Tomar suplementos vitamínicos según necesidad y recomendaciones médicas",
                unidadesInfo: []
            )
        case .YogaDiario:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar yoga diariamente para flexibilidad y relajación",
                unidadesInfo: [],
                customUnitLabel: "sesiones"
            )
        case .MeditacionCorta:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar meditaciones cortas de 5-10 minutos diariamente",
                unidadesInfo: [],
                customUnitLabel: "sesiones"
            )
            
            // Longevidad
        case .AyunoIntermitente:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Aplicar ayuno intermitente según horario personal \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .SaunaSemanal:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Asistir a la sauna al menos una vez por semana para desintoxicación y relajación \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días",
                unidadesInfo: [],
                noUnidades: 60,
                noFrecuencias: 1,
                tipoUnidad: .semanas,
                scheduleType: .weekly,
                weeklyDaysPerWeek: 1,
                customUnitLabel: "sesiones"
            )
        case .EjercicioDeFuerza:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar ejercicios de fuerza 2-3 veces por semana \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días",
                unidadesInfo: [],
                noUnidades: 45,
                tipoUnidad: .semanas,
                scheduleType: .weekly,
                weeklyDaysPerWeek: 3,
                customUnitLabel: "entrenamientos"
            )
        case .ExposicionSolSegura:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Exponerse al sol de forma segura para obtener vitamina D",
                unidadesInfo: []
            )
        case .PaseosAlAireLibre:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Dar paseos al aire libre diariamente para oxigenación y bienestar mental",
                unidadesInfo: [],
                noUnidades: 30
            )
        case .MasajesRelajantes:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Recibir masajes relajantes regularmente",
                unidadesInfo: []
            )
        case .LecturaDiaria:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Leer diariamente para estimular mente y conocimiento",
                unidadesInfo: [],
                customUnitLabel: "páginas"
            )
        case .ReduccionEstrés:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar prácticas para reducir el estrés diariamente \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días\nCambiar patrones emocionales no es solo repetir una acción, sino cambiar interpretación automática",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .ConectarConNaturaleza:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Pasar tiempo en la naturaleza para equilibrio mental y físico",
                unidadesInfo: [],
                noUnidades: 30
            )
        case .DiarioGratitud:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Escribir diariamente en un diario de gratitud",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "entradas"
            )
            
            // Neurociencia y mente
        case .NeuroplasticidadEjercicio:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar ejercicios para estimular la neuroplasticidad \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 90
                
            )
        case .AprenderAlgoNuevo:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Aprender algo nuevo semanalmente para desafiar la mente  \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 90
            )
        case .PracticarMindfulness:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar mindfulness diariamente para concentración y calma",
                unidadesInfo: []
            )
        case .VisualizacionCreativa:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Ejercitar visualización creativa regularmente",
                unidadesInfo: []
            )
        case .DiarioDePensamientos:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Escribir pensamientos y reflexiones para claridad mental",
                unidadesInfo: []
            )
        case .MusicaParaCerebro:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Escuchar música que estimule el cerebro",
                unidadesInfo: []
            )
        case .LimitarRedesSociales:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Limitar tiempo en redes sociales para mejorar foco",
                unidadesInfo: []
            )
        case .ConcentracionPomodoro:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Usar técnica Pomodoro para mejorar concentración",
                unidadesInfo: []
            )
        case .RespiracionCoherenciaCardiaca:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar respiración para coherencia cardíaca",
                unidadesInfo: []
            )
        case .DesafioMentalDiario:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar un desafío mental diario",
                unidadesInfo: []
            )
            
            // Enseñanzas Neville Goddard
        case .VisualizarDeseos:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Visualizar deseos cumplidos diariamente",
                unidadesInfo: [],
                noUnidades: 60,
                dayPeriod: .night,
                customUnitLabel: "sesiones"
            )
        case .SentirElDeseoComoRealidad:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Imaginar y sentir un deseo como si ya fuera real. Vivir mentalmente la satisfacción del deseo ya realizado",
                unidadesInfo: []
            )
        case .ReescribirElPasado:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Reescribir memorias limitantes para transformación personal\n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 60,
                dayPeriod: .night,
                customUnitLabel: "revisiones"
            )
        case .ImaginacionCreativaDiaria:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Ejercitar imaginación creativa diariamente",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "sesiones"
            )
        case .EstadoDeGracias:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Mantener un estado de gratitud constante",
                unidadesInfo: [],
                noUnidades: 60
            )
        case .ActuarComoSi:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Actuar como si ya se hubiera logrado el objetivo",
                unidadesInfo: [],
                noUnidades: 60
            )
        case .AfirmacionesDiarias:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Repetir afirmaciones positivas diariamente",
                unidadesInfo: [],
                noUnidades: 60
            )
        case .MeditacionImaginativa:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Meditación enfocada en la imaginación creativa",
                unidadesInfo: [],
                noUnidades: 60,
                dayPeriod: .night,
                customUnitLabel: "sesiones"
            )
        case .RevisarSueños:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Revisar y reflexionar sobre sueños cada día",
                unidadesInfo: [],
                dayPeriod: .morning,
                customUnitLabel: "registros"
            )
        case .ConectarConSubconsciente:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Conectarse con el subconsciente para transformación personal",
                unidadesInfo: []
            )
            
            // Enseñanzas Joe Dispenza
        case .MeditacionDiaria:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar meditación diaria según enseñanzas de Joe Dispenza",
                unidadesInfo: []
            )
        case .CambioDeCreencias:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Transformar creencias limitantes para mejorar vida personal \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 90
            )
        case .RomperHabitosLimitantes:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Romper hábitos que impiden el crecimiento personal \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 90
            )
        case .EmocionesPositivasDiarias:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Cultivar emociones positivas diariamente \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días\nCambiar patrones emocionales no es solo repetir una acción, sino cambiar interpretación automática",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .CrearNuevaRealidad:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Crear una nueva realidad personal a través de prácticas diarias\n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 90
            )
        case .CoherenciaCorazonCerebro:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Práctica de coherencia entre corazón y cerebro \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .TransformacionMental:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Transformación mental diaria mediante meditación y ejercicios \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 90
            )
        case .RespiracionPotente:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Respiración profunda para generar energía y enfoque \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .PracticaDeVision:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Práctica diaria de visión personal y metas",
                unidadesInfo: [],
                noUnidades: 60
            )
        case .LiberacionEmocional:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Liberación emocional diaria para bienestar mental \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 60-90 días",
                unidadesInfo: [],
                noUnidades: 60
            )
            
            // Combinación hábitos prácticos adicionales
        case .BeberAguaAlDespertar:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Beber agua al despertar para rehidratar el cuerpo",
                unidadesInfo: []
            )
        case .CaminataDespuesComida:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Caminar después de cada comida para mejorar digestión",
                unidadesInfo: []
            )
        case .DiarioDeExito:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Registrar logros y éxitos diarios",
                unidadesInfo: []
            )
        case .RevisarMetasSemanal:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Revisar progreso de metas semanalmente",
                unidadesInfo: [],
                noUnidades: 60,
                noFrecuencias: 1,
                tipoUnidad: .semanas,
                scheduleType: .weekly,
                weeklyDaysPerWeek: 1,
                customUnitLabel: "revisiones"
            )
        case .DormirSinPantallas:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Evitar pantallas antes de dormir para mejorar sueño",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "noches"
            )
        case .ComerFrutasDiarias:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Incluir frutas diariamente en la dieta",
                unidadesInfo: []
            )
        case .PriorizarProteinas:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Priorizar proteínas en las comidas principales",
                unidadesInfo: []
            )
        case .EvitarCafeNoche:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Evitar consumir cafeína en la noche",
                unidadesInfo: []
            )
        case .PausasActivasTrabajo:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Tomar pausas activas durante el trabajo para movilidad",
                unidadesInfo: []
            )
        case .ReflexionAntesDormir:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Reflexionar sobre el día antes de dormir",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "reflexiones"
            )
        case .MeditacionCaminando:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar meditación caminando",
                unidadesInfo: []
            )
        case .PracticarBondad:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Realizar actos de bondad diariamente",
                unidadesInfo: [],
                noUnidades: 30
            )
        case .ContactoSocial:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Mantener contacto social regular para bienestar emocional",
                unidadesInfo: [],
                noUnidades: 30
            )
        case .RespiracionProfundaTrabajo:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar respiración profunda en momentos de estrés laboral",
                unidadesInfo: []
            )
        case .YogaAntesDormir:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar yoga antes de dormir para relajación",
                unidadesInfo: [],
                dayPeriod: .night,
                customUnitLabel: "sesiones"
            )
        case .PlanificacionDiaria:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Planificar tareas y objetivos diarios",
                unidadesInfo: [],
                dayPeriod: .morning,
                customUnitLabel: "planificaciones"
            )
        case .EvaluacionEmociones:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Evaluar emociones diariamente para autoconciencia \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días\nCambiar patrones emocionales no es solo repetir una acción, sino cambiar interpretación automática",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .PrácticaDePerdón:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Practicar perdón a uno mismo y a otros \n Nota: La evidencia en neurociencia indica que la consolidación sináptica estable, para este hábito, requiere repetición prolongada: 30-60 días\nCambiar patrones emocionales no es solo repetir una acción, sino cambiar interpretación automática",
                unidadesInfo: [],
                noUnidades: 45
            )
        case .VisualizarExitoLaboral:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Visualizar el éxito laboral y profesional",
                unidadesInfo: []
            )
        case .MusicaParaRelajación:
            return MetaPreestablecida(
                titulo: self.getDescription,
                description: "Escuchar música para relajación y calma mental",
                unidadesInfo: []
            )
            
        }
    }
}
