import SwiftUI
import Foundation

#if os(iOS)
extension LectorEtiquetasView {
    /// Devuelve el nombre del asset de Nutri-Score según el grado recibido.
    func nutriScoreAssetName(for grade: String?) -> String {
        switch grade?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "A": return "nutriscore_a"
        case "B": return "nutriscore_b"
        case "C": return "nutriscore_c"
        case "D": return "nutriscore_d"
        default: return "nutriscore_nd"
        }
    }

    /// Mapea el grado nutricional a un color semántico para la interfaz.
    func nutritionGradeColor(_ grade: String?) -> Color {
        switch grade?.uppercased() {
        case "A", "B": return .green
        case "C": return .orange
        case "D", "E": return .red
        default: return .secondary
        }
    }

    /// Mapea el grupo NOVA a un color de referencia visual.
    func novaGroupColor(_ group: Int?) -> Color {
        switch group {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .secondary
        }
    }

    /// Devuelve el badge textual para representar el grupo NOVA.
    func novaBadgeValue(_ group: Int?) -> String {
        switch group {
        case 1: return "1️⃣"
        case 2: return "2️⃣"
        case 3: return "3️⃣"
        case 4: return "4️⃣"
        default: return "N/D"
        }
    }

    /// Construye la evaluación nutricional consolidando insights por nutriente clave.
    func buildNutritionEvaluation(from nutrients: [EtiquetaNutrienteClave]) -> NutritionEvaluation {
        let byID = Dictionary(uniqueKeysWithValues: nutrients.map { ($0.id, $0) })

        let proteinGrams = byID[NutritionScoringTarget.proteinas.id].flatMap { extractGrams(from: $0.valor) }
        let calories = byID[NutritionScoringTarget.valorEnergetico.id].flatMap { extractEnergyKcal(from: $0.valor) }

        let insights: [NutritionInsight] = [
            makeProteinNutritionInsight(
                title: byID[NutritionScoringTarget.proteinas.id]?.titulo ?? L10n.exact("Proteína"),
                rawValueText: byID[NutritionScoringTarget.proteinas.id]?.valor ?? L10n.exact("N/D"),
                proteinGrams: proteinGrams,
                calories: calories
            ),
            makeNutritionInsight(
                target: .grasasSaturadas,
                title: byID[NutritionScoringTarget.grasasSaturadas.id]?.titulo ?? L10n.exact("Grasas saturadas"),
                rawValueText: byID[NutritionScoringTarget.grasasSaturadas.id]?.valor ?? L10n.exact("N/D"),
                value: byID[NutritionScoringTarget.grasasSaturadas.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .fibra,
                title: byID[NutritionScoringTarget.fibra.id]?.titulo ?? L10n.exact("Fibra"),
                rawValueText: byID[NutritionScoringTarget.fibra.id]?.valor ?? L10n.exact("N/D"),
                value: byID[NutritionScoringTarget.fibra.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .azucar,
                title: byID[NutritionScoringTarget.azucar.id]?.titulo ?? L10n.exact("Azúcar"),
                rawValueText: byID[NutritionScoringTarget.azucar.id]?.valor ?? L10n.exact("N/D"),
                value: byID[NutritionScoringTarget.azucar.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .sal,
                title: byID[NutritionScoringTarget.sal.id]?.titulo ?? L10n.exact("Sal"),
                rawValueText: byID[NutritionScoringTarget.sal.id]?.valor ?? L10n.exact("N/D"),
                value: byID[NutritionScoringTarget.sal.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .valorEnergetico,
                title: byID[NutritionScoringTarget.valorEnergetico.id]?.titulo ?? L10n.exact("Valor calórico"),
                rawValueText: byID[NutritionScoringTarget.valorEnergetico.id]?.valor ?? L10n.exact("N/D"),
                value: calories
            )
        ]
        .compactMap { $0 }

        return NutritionEvaluation(insights: insights)
    }

    /// Crea el insight de proteínas usando porcentaje energético y posición de marcador.
    func makeProteinNutritionInsight(
        title: String,
        rawValueText: String,
        proteinGrams: Double?,
        calories: Double?
    ) -> NutritionInsight? {
        guard let proteinGrams else { return nil }

        let safeCalories = calories ?? 0
        let level = classifyProteinLevelByEnergyPercentage(proteinGrams: proteinGrams, calories: safeCalories)
        let markerPosition = proteinMarkerPosition(proteinGrams: proteinGrams)

        return NutritionInsight(
            id: NutritionScoringTarget.proteinas.id,
            target: .proteinas,
            title: title,
            rawValueText: rawValueText,
            level: level,
            markerPosition: markerPosition,
            levelDescription: nutrientLevelDescription(level: level, target: .proteinas)
        )
    }

    /// Crea un insight nutricional genérico para el nutriente indicado.
    func makeNutritionInsight(
        target: NutritionScoringTarget,
        title: String,
        rawValueText: String,
        value: Double?
    ) -> NutritionInsight? {
        guard let value else { return nil }

        let level = nutrientConcentrationLevel(for: value, target: target)
        return NutritionInsight(
            id: target.id,
            target: target,
            title: title,
            rawValueText: rawValueText,
            level: level,
            markerPosition: nutrientMarkerPosition(for: value, target: target),
            levelDescription: nutrientLevelDescription(level: level, target: target)
        )
    }

    /// Renderiza la barra semáforo con el marcador posicionado según el nivel del nutriente.
    func nutritionTrafficLine(markerPosition: CGFloat) -> some View {
        GeometryReader { proxy in
            let markerX = markerPosition * proxy.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.18, green: 0.72, blue: 0.34), location: 0.00),
                                .init(color: Color(red: 0.43, green: 0.80, blue: 0.27), location: 0.24),
                                .init(color: Color(red: 0.95, green: 0.82, blue: 0.22), location: 0.50),
                                .init(color: Color(red: 0.94, green: 0.57, blue: 0.17), location: 0.76),
                                .init(color: Color(red: 0.88, green: 0.30, blue: 0.19), location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)
                    .overlay {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .blur(radius: 1.2)
                            .padding(.horizontal, 1)
                    }

                Circle()
                    .fill(Color.gray)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    }
                    .offset(x: max(0, min(proxy.size.width - 14, markerX - 7)))
            }
        }
        .frame(height: 14)
    }

    /// Clasifica la concentración de un nutriente en baja, media o alta.
    func nutrientConcentrationLevel(for value: Double, target: NutritionScoringTarget) -> NutritionConcentrationLevel {
        let config = nutrientDialConfig(for: target)
        if value <= config.lowUpperBound {
            return .baja
        }
        if value <= config.mediumUpperBound {
            return .media
        }
        return .alta
    }

    /// Clasifica proteínas por porcentaje de energía aportada.
    func classifyProteinLevelByEnergyPercentage(
        proteinGrams: Double,
        calories: Double
    ) -> NutritionConcentrationLevel {
        guard let proteinEnergyPct = proteinEnergyPercentage(proteinGrams: proteinGrams, calories: calories) else {
            return .baja
        }

        if proteinEnergyPct < 12 {
            return .baja
        }
        if proteinEnergyPct < 20 {
            return .media
        }
        return .alta
    }

    /// Calcula el porcentaje de energía derivada de proteína.
    func proteinEnergyPercentage(proteinGrams: Double, calories: Double) -> Double? {
        guard calories > 0 else { return nil }
        return (proteinGrams * 4 / calories) * 100
    }

    /// Calcula la posición del marcador para proteínas.
    func proteinMarkerPosition(proteinGrams: Double) -> CGFloat {
        let config = nutrientDialConfig(for: .proteinas)
        return markerPosition(for: proteinGrams, config: config)
    }

    /// Calcula la posición del marcador para un nutriente específico.
    func nutrientMarkerPosition(for value: Double, target: NutritionScoringTarget) -> CGFloat {
        let config = nutrientDialConfig(for: target)
        return markerPosition(for: value, config: config)
    }

    /// Normaliza un valor al rango visual del dial y devuelve su posición.
    func markerPosition(for value: Double, config: NutritionDialConfig) -> CGFloat {
        let clampedValue = max(0, min(value, config.maxReference))
        let normalized = clampedValue / config.maxReference
        let oriented = config.higherIsBetter ? (1 - normalized) : normalized
        return CGFloat((oriented * 0.92) + 0.04)
    }

    /// Construye una descripción textual del nivel nutricional detectado.
    func nutrientLevelDescription(level: NutritionConcentrationLevel, target: NutritionScoringTarget) -> String {
        if target == .fibra {
            switch level {
            case .baja: return L10n.exact("Fibra escasa")
            case .media: return L10n.exact("Buena fuente de fibra")
            case .alta: return L10n.exact("Alta en fibra")
            }
        }

        if target == .proteinas {
            switch level {
            case .baja: return L10n.exact("Poca proteína")
            case .media: return L10n.exact("Aporte proteico medio")
            case .alta: return L10n.exact("Aporte proteico alto")
            }
        }

        switch level {
        case .media:
            return L10n.exact("Concentración media")
        case .baja:
            return nutrientDialConfig(for: target).higherIsBetter
                ? L10n.exact("Concentración baja (a mejorar)")
                : L10n.exact("Concentración baja (favorable)")
        case .alta:
            return nutrientDialConfig(for: target).higherIsBetter
                ? L10n.exact("Concentración alta (favorable)")
                : L10n.exact("Concentración alta (a vigilar)")
        }
    }

    /// Devuelve los umbrales de clasificación por nutriente.
    func nutrientDialConfig(for target: NutritionScoringTarget) -> NutritionDialConfig {
        switch target {
        case .proteinas:
            return NutritionDialConfig(lowUpperBound: 5, mediumUpperBound: 10, maxReference: 30, higherIsBetter: false)
        case .fibra:
            return NutritionDialConfig(lowUpperBound: 3, mediumUpperBound: 6, maxReference: 20, higherIsBetter: false)
        case .grasasSaturadas:
            return NutritionDialConfig(lowUpperBound: 1.5, mediumUpperBound: 5, maxReference: 15, higherIsBetter: false)
        case .azucar:
            return NutritionDialConfig(lowUpperBound: 5, mediumUpperBound: 22.5, maxReference: 50, higherIsBetter: false)
        case .sal:
            return NutritionDialConfig(lowUpperBound: 0.3, mediumUpperBound: 1.5, maxReference: 3, higherIsBetter: false)
        case .valorEnergetico:
            return NutritionDialConfig(lowUpperBound: 120, mediumUpperBound: 225, maxReference: 500, higherIsBetter: false)
        }
    }

    /// Extrae energía en kcal desde texto, convirtiendo desde kJ cuando aplica.
    func extractEnergyKcal(from rawValue: String) -> Double? {
        guard let numericValue = firstNumericValue(in: rawValue) else { return nil }
        let normalized = normalizeNutrientText(rawValue)
        if normalized.contains("kj") && !normalized.contains("kcal") {
            return numericValue / 4.184
        }
        return numericValue
    }

    /// Extrae gramos desde texto, convirtiendo mg a g cuando corresponde.
    func extractGrams(from rawValue: String) -> Double? {
        guard let numericValue = firstNumericValue(in: rawValue) else { return nil }
        let normalized = normalizeNutrientText(rawValue)
        if normalized.contains("mg") {
            return numericValue / 1000
        }
        return numericValue
    }

    /// Obtiene el primer valor numérico detectado en un texto libre.
    func firstNumericValue(in rawValue: String) -> Double? {
        let pattern = #"-?\d+(?:[.,]\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(rawValue.startIndex..<rawValue.endIndex, in: rawValue)
        guard let match = regex.firstMatch(in: rawValue, range: range),
              let matchRange = Range(match.range, in: rawValue) else { return nil }

        let token = rawValue[matchRange].replacingOccurrences(of: ",", with: ".")
        return Double(token)
    }

    /// Normaliza texto nutricional para facilitar comparación de unidades.
    func normalizeNutrientText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }

    /// Genera un identificador estable para expandir/colapsar filas de aditivos.
    func aditivoIdentifier(_ aditivo: HallazgoRiesgoEtiqueta) -> String {
        "\(aditivo.titulo)|\(aditivo.detalle)"
    }

    /// Limpia el título de un hallazgo de aditivo para mostrarlo en UI.
    func aditivoDisplayTitle(_ title: String) -> String {
        title.replacingOccurrences(of: "Aditivo detectado:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extrae el valor de toxicidad desde el texto explicativo del aditivo.
    func extractToxicidad(from text: String) -> String? {
        let normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard let range = normalized.range(of: "toxicidad:") else { return nil }
        let suffix = normalized[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        let value = suffix.components(separatedBy: ".").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else { return nil }
        return value
    }

    /// Asigna color según nivel textual de toxicidad.
    func toxicidadColor(_ toxicidad: String) -> Color {
        switch toxicidad.lowercased() {
        case "alto": return .red
        case "medio": return .orange
        default: return .green
        }
    }

    /// Construye el detalle explicativo del score principal de riesgo alimentario.
    func buildPrincipalScoreInfo(
        resultado: ResultadoAnalisisEtiqueta,
        resumen: EtiquetaResumenProducto,
        risk: LectorEtiquetasFoodRiskScoreResult
    ) -> PrincipalScoreInfo {
        var criteria: [String] = []

        if risk.criteriosSinDatos == 0 {
            criteria.append(L10n.format(
                "label_reader.score.criteria_count",
                fallback: "Analizamos {0} criterios.",
                "\(risk.criteriosEvaluados)"
            ))
        }else{
            criteria.append(L10n.format(
                "label_reader.score.criteria_missing",
                fallback: "Analizamos {0} criterios y hubo {1} sin datos suficientes.",
                "\(risk.criteriosEvaluados)",
                "\(risk.criteriosSinDatos)"
            ))
        }
        

        let aditivos = resultado.hallazgos.filter { $0.categoria == .aditivoDeRiesgo }
        let highOrCriticalCount = aditivos.filter { $0.nivel == .alto || $0.nivel == .critico }.count
        let mediumCount = aditivos.filter { $0.nivel == .medio }.count
        let hasAdditiveRiskAtOrAboveMedium = mediumCount > 0 || highOrCriticalCount > 0

        let inferredContainsGluten: Bool? = {
            if let contains = resumen.perfilAlimentario.contieneGluten { return contains }
            if resultado.hallazgos.contains(where: { $0.categoria == .indicioGluten }) { return true }
            if containsGlutenKeyword(in: resumen.alergenos) { return true }
            return nil
        }()

        let isOrganic = resumen.perfilAlimentario.esOrganico

        if let novaGroup = resumen.novaGroup,
           (1...2).contains(novaGroup),
           !hasAdditiveRiskAtOrAboveMedium {
            let novaDescription = novaGroup == 1
                ? L10n.exact("alimento sin procesar o mínimamente procesado (NOVA 1)")
                : L10n.exact("alimento mínimamente procesado (NOVA 2)")
            criteria.append(L10n.format(
                "label_reader.score.nova_priority",
                fallback: "Se aplicó una regla prioritaria porque es un {0}.",
                novaDescription
            ))
            criteria.append(L10n.exact("No contiene aditivos de riesgo medio, alto o crítico."))

            if let inferredContainsGluten {
                criteria.append(L10n.format(
                    "label_reader.score.gluten_state",
                    fallback: "Gluten: {0}.",
                    L10n.exact(inferredContainsGluten ? "presente" : "no detectado")
                ))
            } else {
                criteria.append(L10n.exact("Gluten: sin dato concluyente."))
            }

            if let isOrganic {
                criteria.append(L10n.exact(isOrganic ? "Se declara como orgánico." : "No se declara como orgánico."))
            } else {
                criteria.append(L10n.exact("Orgánico: sin dato disponible."))
            }

            let overrideClassification: LectorEtiquetasFoodRiskClassification = (
                inferredContainsGluten == false && isOrganic == true
            ) ? .excelente : .bueno

            criteria.append(L10n.format(
                "label_reader.score.final_rating",
                fallback: "Por esta combinación, la calificación final es {0}.",
                overrideClassification.title
            ))

            return PrincipalScoreInfo(
                title: risk.classification.title,
                scoreText: "\(risk.score)/100",
                criteria: criteria
            )
        }

        if highOrCriticalCount >= 1 || mediumCount >= 3 {
            criteria.append(L10n.exact("Contiene aditivos de mayor o moderado riesgo (al menos 1 alto/crítico o 3 medios), por eso aplica penalización máxima."))
        } else if aditivos.isEmpty {
            criteria.append(L10n.exact("No se detectaron aditivos de riesgo relevantes."))
        } else {
            criteria.append(L10n.format(
                "label_reader.score.additive_counts",
                fallback: "Se detectaron {0} aditivos, pero sin llegar al umbral de penalización máxima (medios: {1}, altos/críticos: {2}).",
                "\(aditivos.count)",
                "\(mediumCount)",
                "\(highOrCriticalCount)"
            ))
        }

        if let esOrganico = resumen.perfilAlimentario.esOrganico {
            criteria.append(L10n.exact(esOrganico ? "El producto se declara como orgánico." : "El producto no se declara como orgánico."))
        } else {
            criteria.append(L10n.format(
                "label_reader.score.ecological_result",
                fallback: "No hay dato directo de orgánico; usamos señales ecológicas y el resultado fue: {0}.",
                resumen.evaluacionEcologica.estado.titulo.lowercased()
            ))
        }

        if let contieneGluten = resumen.perfilAlimentario.contieneGluten {
            criteria.append(L10n.format(
                "label_reader.score.gluten_product",
                fallback: "Gluten: {0} según la información del producto.",
                L10n.exact(contieneGluten ? "presente" : "no detectado")
            ))
        } else if let glutenFinding = resultado.hallazgos
            .filter({ $0.categoria == .indicioGluten })
            .max(by: { $0.nivel.rawValue < $1.nivel.rawValue }) {
            criteria.append(L10n.format(
                "label_reader.score.gluten_indications",
                fallback: "Gluten: se encontraron indicios {0} en ingredientes.",
                glutenFinding.nivel.badgeText.lowercased()
            ))
        } else if containsGlutenKeyword(in: resumen.alergenos) {
            criteria.append(L10n.exact("Gluten: aparece en la sección de alérgenos del producto."))
        } else {
            criteria.append(L10n.exact("Gluten: no hay evidencia clara; se aplica una evaluación conservadora."))
        }

        if let sugar = highestFindingLevel(in: resultado.hallazgos, categories: [.excesoAzucar]) {
            criteria.append(L10n.format(
                "label_reader.score.sugar_level",
                fallback: "Azúcar: nivel {0}, lo que impacta negativamente el score.",
                sugar.badgeText.lowercased()
            ))
        }
        if let salt = highestFindingLevel(in: resultado.hallazgos, categories: [.excesoSal, .sodioElevado]) {
            criteria.append(L10n.format(
                "label_reader.score.salt_level",
                fallback: "Sal/Sodio: nivel {0}, considerado en la puntuación final.",
                salt.badgeText.lowercased()
            ))
        }
        if let satFat = highestFindingLevel(in: resultado.hallazgos, categories: [.excesoGrasaSaturada]) {
            criteria.append(L10n.format(
                "label_reader.score.saturated_fat_level",
                fallback: "Grasa saturada: nivel {0}, con efecto en la calificación.",
                satFat.badgeText.lowercased()
            ))
        }

        return PrincipalScoreInfo(
            title: risk.classification.title,
            scoreText: "\(risk.score)/100",
            criteria: criteria
        )
    }

    /// Obtiene el nivel de riesgo más alto para un conjunto de categorías.
    func highestFindingLevel(
        in hallazgos: [HallazgoRiesgoEtiqueta],
        categories: [CategoriaRiesgoEtiqueta]
    ) -> NivelRiesgoEtiqueta? {
        hallazgos
            .filter { categories.contains($0.categoria) }
            .map(\.nivel)
            .max()
    }

    /// Detecta términos relacionados con gluten dentro de alérgenos.
    func containsGlutenKeyword(in allergens: [String]) -> Bool {
        let markers = ["gluten", "trigo", "wheat", "cebada", "barley", "centeno", "rye", "espelta", "spelt"]
        return allergens.contains { allergen in
            let normalized = allergen.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
            return markers.contains(where: { normalized.contains($0) })
        }
    }

    /// Convierte un booleano opcional a texto legible para UI.
    func boolText(_ value: Bool?) -> String {
        guard let value else { return L10n.exact("No disponible") }
        return L10n.exact(value ? "Sí" : "No")
    }
}
#endif
