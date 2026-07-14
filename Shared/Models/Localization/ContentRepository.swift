//
//  ContentRepository.swift
//  Neville_iOS
//
//  Separa la identidad permanente del contenido de su título y fichero localizados.
//

import Foundation

struct ContentID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum ContentKind: String, Codable, CaseIterable, Sendable {
    case conference
    case quote
    case question
    case help

    var legacyPrefix: String {
        switch self {
        case .conference: "conf_"
        case .quote: "cita_"
        case .question: "preg_"
        case .help: "ayud_"
        }
    }
}

struct LocalizedContentDescriptor: Codable, Hashable, Sendable {
    let id: ContentID
    let kind: ContentKind
    let resourceName: String
    let title: String
    let locale: String
}

private struct ContentManifest: Codable {
    let version: Int
    let locale: String
    let entries: [LocalizedContentDescriptor]
}

struct ContentRepository {
    static let shared = ContentRepository()

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func descriptors(
        of kind: ContentKind,
        language: AppLanguage = .current
    ) -> [LocalizedContentDescriptor] {
        let canonical = legacyDescriptors(of: kind)
        guard language != .spanish else { return canonical.sorted(by: titleSort) }

        let translated = manifest(for: language)?.entries.filter { $0.kind == kind } ?? []
        let translatedByID = Dictionary(uniqueKeysWithValues: translated.map { ($0.id, $0) })
        return canonical
            .map { translatedByID[$0.id] ?? $0 }
            .sorted(by: titleSort)
    }

    func descriptor(
        named titleOrLegacyName: String,
        kind: ContentKind,
        language: AppLanguage = .current
    ) -> LocalizedContentDescriptor? {
        let wanted = normalizedLookup(titleOrLegacyName)
        return descriptors(of: kind, language: language).first {
            normalizedLookup($0.title) == wanted
                || normalizedLookup(legacyDisplayName(resourceName: $0.resourceName, kind: kind)) == wanted
                || normalizedLookup($0.resourceName) == wanted
        }
    }

    func descriptor(
        id: ContentID,
        kind: ContentKind,
        language: AppLanguage = .current
    ) -> LocalizedContentDescriptor? {
        descriptors(of: kind, language: language).first { $0.id == id }
    }

    func stableID(forLegacyName name: String, kind: ContentKind) -> ContentID {
        if let descriptor = descriptor(named: name, kind: kind, language: .spanish) {
            return descriptor.id
        }

        let resource = name.hasPrefix(kind.legacyPrefix) ? name : kind.legacyPrefix + name
        return makeLegacyID(resourceName: resource, kind: kind)
    }

    func content(
        for descriptor: LocalizedContentDescriptor,
        language: AppLanguage = .current
    ) -> String {
        let canonical = legacyDescriptors(of: descriptor.kind).first { $0.id == descriptor.id }
        let candidates = language.fallbackChain
        for candidate in candidates {
            let candidateResource: String
            if candidate == .spanish {
                candidateResource = canonical?.resourceName ?? descriptor.resourceName
            } else if let localizedEntry = manifest(for: candidate)?.entries.first(where: {
                $0.id == descriptor.id
            }) {
                candidateResource = localizedEntry.resourceName
            } else {
                candidateResource = descriptor.resourceName
            }

            if let localizedBundle = candidate.localizedBundle(in: bundle),
               let url = localizedBundle.url(forResource: candidateResource, withExtension: "txt"),
               let value = readText(at: url) {
                return value
            }
        }

        let fallbackResource = canonical?.resourceName ?? descriptor.resourceName
        guard let url = bundle.url(forResource: fallbackResource, withExtension: "txt"),
              let value = readText(at: url) else {
            return ""
        }
        return value
    }

    private func legacyDescriptors(of kind: ContentKind) -> [LocalizedContentDescriptor] {
        guard let resourcePath = bundle.resourcePath,
              let items = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) else {
            return []
        }

        return items.compactMap { item in
            guard item.hasPrefix(kind.legacyPrefix), item.hasSuffix(".txt") else { return nil }
            let resourceName = String(item.dropLast(4))
            return LocalizedContentDescriptor(
                id: makeLegacyID(resourceName: resourceName, kind: kind),
                kind: kind,
                resourceName: resourceName,
                title: legacyDisplayName(resourceName: resourceName, kind: kind),
                locale: AppLanguage.spanish.rawValue
            )
        }
    }

    private func manifest(for language: AppLanguage) -> ContentManifest? {
        let resourceName = "ContentManifest.\(language.rawValue)"
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(ContentManifest.self, from: data)
    }

    private func makeLegacyID(resourceName: String, kind: ContentKind) -> ContentID {
        let canonical = resourceName
            .precomposedStringWithCanonicalMapping
            .lowercased(with: Locale(identifier: "es"))
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
        let encoded = canonical.addingPercentEncoding(withAllowedCharacters: allowed) ?? canonical
        return ContentID(rawValue: "\(kind.rawValue):\(encoded)")
    }

    private func legacyDisplayName(resourceName: String, kind: ContentKind) -> String {
        let base = resourceName.hasPrefix(kind.legacyPrefix)
            ? String(resourceName.dropFirst(kind.legacyPrefix.count))
            : resourceName
        return base.capitalized(with: Locale(identifier: "es"))
    }

    private func normalizedLookup(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    private func readText(at url: URL) -> String? {
        guard let value = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private func titleSort(
        _ lhs: LocalizedContentDescriptor,
        _ rhs: LocalizedContentDescriptor
    ) -> Bool {
        lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}
