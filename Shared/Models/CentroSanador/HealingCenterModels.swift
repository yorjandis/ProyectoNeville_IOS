import Foundation

struct HealingCatalog: Decodable {
    let schemaVersion: Int
    let contentVersion: String
    let reviewedAt: String
    let disclaimer: String
    let situations: [HealingSituation]
}

struct HealingSituation: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let palette: HealingPalette
    let immediateExplanation: String
    let biologicalExplanation: String
    let reassurance: String
    let searchTerms: [String]
    let redFlags: [String]
    let whenToSeekHelp: [String]
    let protocols: [HealingProtocol]
    let practicalTips: [HealingPracticalTip]
    let sources: [HealingEvidenceSource]

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        guard !normalizedQuery.isEmpty else { return true }

        let searchableText = ([title, subtitle] + searchTerms)
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return searchableText.contains(normalizedQuery)
    }
}

struct HealingPracticalTip: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

enum HealingPalette: String, Decodable, Hashable {
    case ocean
    case amber
    case violet
    case forest
    case rose
    case slate
}

struct HealingProtocol: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let symbol: String
    let kind: HealingInterventionKind
    let evidence: HealingEvidenceLevel
    let caution: String?
    let steps: [HealingProtocolStep]

    var durationSeconds: Int {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }

    var durationLabel: String {
        let total = durationSeconds
        if total < 60 {
            return L10n.format(
                "healing.duration.seconds",
                fallback: "{0} s",
                "\(total)"
            )
        }
        let minutes = total / 60
        let seconds = total % 60
        if seconds == 0 {
            return L10n.format(
                "healing.duration.minutes",
                fallback: "{0} min",
                "\(minutes)"
            )
        }
        return L10n.format(
            "healing.duration.minutes_seconds",
            fallback: "{0} min {1} s",
            "\(minutes)",
            "\(seconds)"
        )
    }
}

enum HealingInterventionKind: String, Decodable, Hashable {
    case breathing
    case grounding
    case muscleRelease
    case movement
    case reflection
    case acupressure
    case vocalization
    case conflictPause
}

enum HealingEvidenceLevel: String, Decodable, Hashable {
    case supported
    case promising
    case complementary
    case experimental

    var title: String {
        switch self {
        case .supported: return L10n.exact("Apoyo sólido")
        case .promising: return L10n.exact("Evidencia prometedora")
        case .complementary: return L10n.exact("Técnica complementaria")
        case .experimental: return L10n.exact("Evidencia limitada")
        }
    }
}

struct HealingProtocolStep: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let instruction: String
    let durationSeconds: Int
    let phase: HealingStepPhase
    let accessibilityCue: String?
}

enum HealingStepPhase: String, Decodable, Hashable {
    case prepare
    case inhale
    case exhale
    case observe
    case orient
    case move
    case press
    case sound
    case reflect
    case finish
}

struct HealingEvidenceSource: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let organization: String
    let url: URL
    let note: String
}
