//
//  GoalEditorialLocalization.swift
//  Neville_iOS
//
//  Localización del contenido editorial de hábitos y programas preestablecidos.
//  La planificación y las métricas siempre proceden de las fuentes españolas.
//

import Foundation

nonisolated private struct HealthyHabitTranslation: Decodable, Sendable {
    let title: String
    let description: String
    let customUnitLabel: String
}

nonisolated private struct LocalizedProgramUnit: Decodable, Sendable {
    let name: String
    let info: String
}

nonisolated private struct GoalProgramTranslation: Decodable, Sendable {
    let title: String
    let detalles: String
    let description: String
    let customUnitLabel: String
    let unidadesinfo: [LocalizedProgramUnit]
}

nonisolated enum GoalEditorialLocalization {
    private static let habitCatalogs: [AppLanguage: [String: HealthyHabitTranslation]] =
        decodeCatalogs(named: "HealthyHabits")
    private static let programCatalogs: [AppLanguage: [String: GoalProgramTranslation]] =
        decodeCatalogs(named: "GoalPrograms")

    static func habitTitle(id: String, fallback: String) -> String {
        habitCatalog()[id]?.title ?? fallback
    }

    static func habit(id: String, fallback: MetaPreestablecida) -> MetaPreestablecida {
        guard let translation = habitCatalog()[id] else { return fallback }
        return MetaPreestablecida(
            titulo: translation.title,
            description: translation.description,
            unidadesInfo: fallback.unidadesInfo,
            noUnidades: fallback.noUnidades,
            noFrecuencias: fallback.noFrecuencias,
            tipoUnidad: fallback.tipoUnidad,
            scheduleType: fallback.scheduleType,
            weeklyDaysPerWeek: fallback.weeklyDaysPerWeek,
            dayPeriod: fallback.dayPeriod,
            customUnitLabel: translation.customUnitLabel,
            specificDates: fallback.specificDates
        )
    }

    static func program(
        filename: String,
        fallback: ProgramasPreestablecido
    ) -> ProgramasPreestablecido {
        guard let translation = programCatalog()[filename],
              translation.unidadesinfo.count == fallback.unidadesinfo.count else {
            return fallback
        }
        return ProgramasPreestablecido(
            title: translation.title,
            detalles: translation.detalles,
            description: translation.description,
            unidadesNotes: translation.unidadesinfo.map {
                UnidadesInfo(name: $0.name, info: $0.info)
            },
            noUnidades: fallback.noUnidades,
            tipoUnidad: fallback.tipoUnidad,
            frecuencia: fallback.frecuencia,
            scheduleType: fallback.scheduleType,
            weeklyDaysPerWeek: fallback.weeklyDaysPerWeek,
            dayPeriod: fallback.dayPeriod,
            customUnitLabel: translation.customUnitLabel,
            specificDates: fallback.specificDates
        )
    }

    private static func habitCatalog(
        language: AppLanguage = .current
    ) -> [String: HealthyHabitTranslation] {
        guard language != .spanish else { return [:] }
        return habitCatalogs[language] ?? [:]
    }

    private static func programCatalog(
        language: AppLanguage = .current
    ) -> [String: GoalProgramTranslation] {
        guard language != .spanish else { return [:] }
        return programCatalogs[language] ?? [:]
    }

    private static func decodeCatalogs<Value: Decodable & Sendable>(
        named resourceName: String
    ) -> [AppLanguage: [String: Value]] {
        var result: [AppLanguage: [String: Value]] = [:]
        for language in [AppLanguage.english, .simplifiedChinese] {
            guard let bundle = language.localizedBundle(),
                  let url = bundle.url(forResource: resourceName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let catalog = try? JSONDecoder().decode([String: Value].self, from: data) else {
                continue
            }
            result[language] = catalog
        }
        return result
    }
}
