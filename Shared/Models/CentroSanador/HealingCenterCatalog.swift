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
            return "No se encontró el catálogo de apoyo incluido en la aplicación."
        case .invalidSchema(let reason):
            return "El catálogo de apoyo no es válido: \(reason)"
        }
    }
}

struct BundledHealingCatalogRepository: HealingCatalogProviding {
    private let bundle: Bundle
    private let resourceName: String

    init(bundle: Bundle = .main, resourceName: String = "healing_center_es") {
        self.bundle = bundle
        self.resourceName = resourceName
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
        guard catalog.schemaVersion == 1 else {
            throw HealingCatalogError.invalidSchema("versión de esquema no compatible")
        }
        guard !catalog.situations.isEmpty else {
            throw HealingCatalogError.invalidSchema("no contiene situaciones")
        }

        try ensureUnique(catalog.situations.map(\.id), label: "situaciones")

        for situation in catalog.situations {
            guard !situation.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw HealingCatalogError.invalidSchema("hay una situación sin título")
            }
            guard !situation.protocols.isEmpty else {
                throw HealingCatalogError.invalidSchema("\(situation.id) no contiene técnicas")
            }
            guard !situation.sources.isEmpty else {
                throw HealingCatalogError.invalidSchema("\(situation.id) no contiene fuentes")
            }

            try ensureUnique(situation.protocols.map(\.id), label: "técnicas de \(situation.id)")

            for healingProtocol in situation.protocols {
                guard !healingProtocol.steps.isEmpty else {
                    throw HealingCatalogError.invalidSchema("\(healingProtocol.id) no contiene pasos")
                }
                try ensureUnique(healingProtocol.steps.map(\.id), label: "pasos de \(healingProtocol.id)")

                for step in healingProtocol.steps where !(3...120).contains(step.durationSeconds) {
                    throw HealingCatalogError.invalidSchema(
                        "\(healingProtocol.id) contiene una duración fuera del rango seguro"
                    )
                }
            }
        }
    }

    private func ensureUnique(_ ids: [String], label: String) throws {
        guard Set(ids).count == ids.count else {
            throw HealingCatalogError.invalidSchema("hay identificadores duplicados en \(label)")
        }
    }
}

