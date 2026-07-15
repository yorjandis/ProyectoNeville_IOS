import Foundation

protocol HealingCatalogProviding {
    func load() throws -> HealingCatalog
}

enum HealingCatalogError: LocalizedError {
    case resourceNotFound
    case invalidSchema(String)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return L10n.exact("No se encontró el catálogo de apoyo incluido en la aplicación.")
        case .invalidSchema(let reason):
            return L10n.format(
                "healing.catalog.invalid",
                fallback: "El catálogo de apoyo no es válido: {0}",
                reason
            )
        }
    }
}

struct BundledHealingCatalogRepository: HealingCatalogProviding {
    private let bundle: Bundle
    private let resourceName: String

    init(
        bundle: Bundle = .main,
        resourceName: String? = nil,
        language: AppLanguage = .current
    ) {
        self.bundle = bundle
        self.resourceName = resourceName ?? language.healingCenterCatalogResourceName
    }

    func load() throws -> HealingCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw HealingCatalogError.resourceNotFound
        }

        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(HealingCatalog.self, from: data)
        try validate(catalog)
        return catalog
    }

    private func validate(_ catalog: HealingCatalog) throws {
        guard catalog.schemaVersion == 2 else {
            throw HealingCatalogError.invalidSchema(L10n.exact("versión de esquema no compatible"))
        }
        guard !catalog.situations.isEmpty else {
            throw HealingCatalogError.invalidSchema(L10n.exact("no contiene situaciones"))
        }

        try ensureUnique(catalog.situations.map(\.id), label: L10n.exact("situaciones"))

        for situation in catalog.situations {
            guard !situation.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw HealingCatalogError.invalidSchema(L10n.exact("hay una situación sin título"))
            }
            guard situation.protocols.count == 3 else {
                throw HealingCatalogError.invalidSchema(L10n.format(
                    "healing.catalog.three_techniques",
                    fallback: "{0} debe contener exactamente tres técnicas",
                    situation.id
                ))
            }
            guard !situation.practicalTips.isEmpty else {
                throw HealingCatalogError.invalidSchema(L10n.format(
                    "healing.catalog.no_tips",
                    fallback: "{0} no contiene consejos prácticos",
                    situation.id
                ))
            }
            guard !situation.sources.isEmpty else {
                throw HealingCatalogError.invalidSchema(L10n.format(
                    "healing.catalog.no_sources",
                    fallback: "{0} no contiene fuentes",
                    situation.id
                ))
            }

            try ensureUnique(
                situation.protocols.map(\.id),
                label: L10n.format("healing.catalog.techniques_of", fallback: "técnicas de {0}", situation.id)
            )
            try ensureUnique(
                situation.practicalTips.map(\.id),
                label: L10n.format("healing.catalog.tips_of", fallback: "consejos de {0}", situation.id)
            )

            for tip in situation.practicalTips {
                guard !tip.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !tip.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw HealingCatalogError.invalidSchema(L10n.format(
                        "healing.catalog.incomplete_tip",
                        fallback: "{0} contiene un consejo incompleto",
                        situation.id
                    ))
                }
            }

            for healingProtocol in situation.protocols {
                guard !healingProtocol.steps.isEmpty else {
                    throw HealingCatalogError.invalidSchema(L10n.format(
                        "healing.catalog.no_steps",
                        fallback: "{0} no contiene pasos",
                        healingProtocol.id
                    ))
                }
                try ensureUnique(
                    healingProtocol.steps.map(\.id),
                    label: L10n.format("healing.catalog.steps_of", fallback: "pasos de {0}", healingProtocol.id)
                )

                for step in healingProtocol.steps where !(3...120).contains(step.durationSeconds) {
                    throw HealingCatalogError.invalidSchema(L10n.format(
                        "healing.catalog.unsafe_duration",
                        fallback: "{0} contiene una duración fuera del rango seguro",
                        healingProtocol.id
                    ))
                }
            }
        }
    }

    private func ensureUnique(_ ids: [String], label: String) throws {
        guard Set(ids).count == ids.count else {
            throw HealingCatalogError.invalidSchema(L10n.format(
                "healing.catalog.duplicate_ids",
                fallback: "hay identificadores duplicados en {0}",
                label
            ))
        }
    }
}

private extension AppLanguage {
    var healingCenterCatalogResourceName: String {
        switch self {
        case .spanish: return "healing_center_es"
        case .english: return "healing_center_en"
        case .simplifiedChinese: return "healing_center_zh-Hans"
        }
    }
}
