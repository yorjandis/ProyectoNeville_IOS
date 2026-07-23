//
//  ProgramasPreestablecidos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//

/*
 Para Agregar un nuevo programa preestablecido solo debemos crear el json del programa y luego
 colocar su case en el enum ProgramaArchivo
 */

import SwiftUI




//Archivos json de programas Preestablecidos:
nonisolated enum ProgramaArchivo: String, CaseIterable {
    case prog_dieta_semanal_1
    case prog_dieta_semanal_2
    case prog_dieta_semanal_3
    case prog_dieta_semanal_4
    case prog_dejar_fumar_1
    case prog_dejar_fumar_2
    case prog_dejar_alcohol_1
    case prog_dejar_alcohol_2
    case prog_respiracion_buteyko
    case prog_anti_ansiedad
    case prog_anti_ansiedad_2
    case prog_reset_dopaminergico_1
    case prog_reset_dopaminergico_2
    case prog_regulacion_digital_menores_1
    case prog_regulacion_digital_menores_2
    
    case prog_visualizacion_creativa_neville_1
    case prog_visualizacion_creativa_neville_2
    case prog_visualizacion_creativa_neville_3
 
}

//Creamos los grupos Base: elimnando los números al final de los programas
extension ProgramaArchivo{
    var grupoBase: String {
        rawValue.replacingOccurrences(
            of: "_\\d+$",
            with: "",
            options: .regularExpression
        )
    }
}

//Agrupación Automática final:
extension ProgramaArchivo {

    static var agrupados: [(String, [ProgramaArchivo])] {

        let dic = Dictionary(grouping: allCases) {
            $0.grupoBase
        }

        return dic
            .map { ($0.key, $0.value.sorted { $0.rawValue < $1.rawValue }) }
            .sorted { $0.0 < $1.0 }
    }
}

extension ProgramaArchivo {
    static func localizedGroupTitle(for groupID: String) -> String {
        let key: String
        let fallback: String

        switch groupID {
        case "prog_anti_ansiedad":
            key = "goals.program_category.anxiety_relief"
            fallback = "Anti Ansiedad"
        case "prog_dejar_alcohol":
            key = "goals.program_category.quit_drinking"
            fallback = "Dejar el Alcohol"
        case "prog_dejar_fumar":
            key = "goals.program_category.quit_smoking"
            fallback = "Dejar de Fumar"
        case "prog_dieta_semanal":
            key = "goals.program_category.weekly_meal_plans"
            fallback = "Dietas Semanales"
        case "prog_regulacion_digital_menores":
            key = "goals.program_category.digital_balance_youth"
            fallback = "Regulación Digital para Menores"
        case "prog_reset_dopaminergico":
            key = "goals.program_category.dopamine_reset"
            fallback = "Reinicio Dopaminérgico"
        case "prog_respiracion_buteyko":
            key = "goals.program_category.buteyko_breathing"
            fallback = "Respiración Buteyko"
        case "prog_visualizacion_creativa_neville":
            key = "goals.program_category.neville_visualization"
            fallback = "Visualización Creativa de Neville"
        default:
            return groupID
                .replacingOccurrences(of: "prog_", with: "")
                .replacingOccurrences(of: "_", with: " ")
                .localizedCapitalized
        }

        return GoalsL10n.text(key, fallback: fallback)
    }
}






//Modelo del Json
nonisolated struct UnidadesInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let info: String
    
    enum CodingKeys: String, CodingKey {
            case name
            case info
        }
        
        init(name: String, info: String) {
            self.id = UUID()
            self.name = name
            self.info = info
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.info = try container.decode(String.self, forKey: .info)
            self.id = UUID() // 👈 generado automáticamente
        }
}

nonisolated struct ProgramasPreestablecido: Codable, Identifiable {
    let id: UUID
    let title: String
    let detalles : String
    let description: String
    let unidadesinfo: [UnidadesInfo]
    let noUnidades: Int
    let tipoUnidad : TimeUnit
    let frecuencia : Int
    let scheduleType: GoalScheduleType
    let weeklyDaysPerWeek: Int
    let dayPeriod: GoalDayPeriod
    let customUnitLabel: String
    /// Fechas ISO `yyyy-MM-dd`. Se mantienen como texto en el JSON para que el
    /// formato sea legible y estable entre plataformas.
    let specificDates: [String]
    
    enum CodingKeys: String, CodingKey {
            case title
            case detalles
            case description
            case unidadesinfo
            case noUnidades
            case tipoUnidad
            case frecuencia
            case scheduleType
            case weeklyDaysPerWeek
            case dayPeriod
            case customUnitLabel
            case specificDates
        }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.decode(String.self, forKey: .title)
        self.detalles = try container.decode(String.self, forKey: .detalles)
        self.description = try container.decode(String.self, forKey: .description)
        self.unidadesinfo = try container.decode([UnidadesInfo].self, forKey: .unidadesinfo)
        self.noUnidades = try container.decode(Int.self, forKey: .noUnidades)
        self.tipoUnidad = try container.decode(TimeUnit.self, forKey: .tipoUnidad)
        self.frecuencia = try container.decode(Int.self, forKey: .frecuencia)
        self.scheduleType = try container.decodeIfPresent(GoalScheduleType.self, forKey: .scheduleType) ?? .interval
        self.weeklyDaysPerWeek = min(max(try container.decodeIfPresent(Int.self, forKey: .weeklyDaysPerWeek) ?? 3, 1), 7)
        self.dayPeriod = try container.decodeIfPresent(GoalDayPeriod.self, forKey: .dayPeriod) ?? .anytime
        self.customUnitLabel = try container.decodeIfPresent(String.self, forKey: .customUnitLabel) ?? ""
        self.specificDates = try container.decodeIfPresent([String].self, forKey: .specificDates) ?? []

        if scheduleType == .specificDates,
           (specificDates.count != noUnidades || Self.resolveDates(specificDates).count != noUnidades) {
            throw DecodingError.dataCorruptedError(
                forKey: .specificDates,
                in: container,
                debugDescription: "Una programación por fechas específicas necesita una fecha ISO yyyy-MM-dd válida por cada unidad."
            )
        }

        self.id = UUID()
    }
        
    init(title: String,
         detalles: String,
         description: String,
         unidadesNotes: [UnidadesInfo],
         noUnidades: Int,
         tipoUnidad: TimeUnit,
         frecuencia: Int,
         scheduleType: GoalScheduleType = .interval,
         weeklyDaysPerWeek: Int = 3,
         dayPeriod: GoalDayPeriod = .anytime,
         customUnitLabel: String = "",
         specificDates: [String] = []) {

        self.id = UUID()
        self.title = title
        self.detalles = detalles
        self.description = description
        self.unidadesinfo = unidadesNotes
        self.noUnidades = noUnidades
        self.tipoUnidad = tipoUnidad
        self.frecuencia = frecuencia
        self.scheduleType = scheduleType
        self.weeklyDaysPerWeek = min(max(weeklyDaysPerWeek, 1), 7)
        self.dayPeriod = dayPeriod
        self.customUnitLabel = customUnitLabel
        self.specificDates = specificDates
    }

    var resolvedSpecificDates: [Date] {
        Self.resolveDates(specificDates)
    }

    private static func resolveDates(_ values: [String]) -> [Date] {
        values.compactMap { value in
            let parts = value.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        }
    }

    var scheduleSummary: String {
        let unitLabel = customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityLabel = unitLabel.isEmpty ? tipoUnidad.description(for: noUnidades) : unitLabel
        let cadence: String
        switch scheduleType {
        case .interval:
            cadence = GoalsL10n.intervalCadence(frequency: frecuencia, unit: tipoUnidad)
        case .weekly:
            cadence = GoalsL10n.weeklyCadence(days: weeklyDaysPerWeek)
        case .specificDates:
            cadence = GoalsL10n.specificDatesCadence()
        }
        return GoalsL10n.format(
            "goals.dynamic.quantity_schedule_summary",
            fallback: "{0} {1}, {2}",
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
