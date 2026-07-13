import Foundation

struct HealingEmergencyContact: Identifiable, Hashable {
    enum Kind: Hashable {
        case emergency
        case emotionalSupport
    }

    let id: String
    let title: String
    let number: String
    let detail: String
    let kind: Kind
    let sourceURL: URL?

    var telephoneURL: URL? {
        let dialable = number.filter { $0.isNumber || $0 == "+" }
        guard !dialable.isEmpty else { return nil }
        return URL(string: "tel:\(dialable)")
    }
}

struct HealingEmergencyResources: Identifiable, Hashable {
    let regionCode: String
    let countryName: String
    let contacts: [HealingEmergencyContact]
    let note: String

    var id: String { regionCode }
    var emergencyContact: HealingEmergencyContact? {
        contacts.first { $0.kind == .emergency }
    }
}

struct HealingEmergencyResourceProvider {
    static let internationalDirectoryURL = URL(string: "https://findahelpline.com/")!

    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    var detectedRegionCode: String {
        locale.region?.identifier ?? "ES"
    }

    var availableRegionCodes: [String] {
        let known = european112Regions.union(["AU", "CA", "GB", "IE", "MX", "NZ", "US", detectedRegionCode])
        return known.sorted {
            countryName(for: $0).localizedCaseInsensitiveCompare(countryName(for: $1)) == .orderedAscending
        }
    }

    func countryName(for regionCode: String) -> String {
        locale.localizedString(forRegionCode: regionCode) ?? regionCode
    }

    func resources(for regionCode: String) -> HealingEmergencyResources {
        let code = regionCode.uppercased()
        let emergencyNumber = emergencyNumber(for: code)
        var contacts: [HealingEmergencyContact] = []

        if let emergencyNumber {
            contacts.append(
                .init(
                    id: "\(code)-emergency",
                    title: "Emergencias",
                    number: emergencyNumber,
                    detail: "Para peligro inmediato o una emergencia médica.",
                    kind: .emergency,
                    sourceURL: emergencySourceURL(for: code)
                )
            )
        }

        contacts.append(contentsOf: emotionalSupportContacts(for: code))

        let note: String
        if emergencyNumber == nil {
            note = "No tenemos verificado un número único para esta región. Usa el número local de emergencias o consulta el directorio internacional."
        } else {
            note = "La región se obtiene de los ajustes del dispositivo, no de tu ubicación. Compruébala antes de llamar."
        }

        return HealingEmergencyResources(
            regionCode: code,
            countryName: countryName(for: code),
            contacts: contacts,
            note: note
        )
    }

    private func emergencyNumber(for code: String) -> String? {
        if european112Regions.contains(code) { return "112" }

        switch code {
        case "US", "CA", "MX": return "911"
        case "GB": return "999"
        case "AU": return "000"
        case "NZ": return "111"
        default: return nil
        }
    }

    private func emotionalSupportContacts(for code: String) -> [HealingEmergencyContact] {
        switch code {
        case "ES":
            return [support(
                code: code,
                id: "024",
                title: "Línea 024",
                number: "024",
                detail: "Atención a la conducta suicida, gratuita, confidencial y disponible 24/7.",
                source: "https://www.sanidad.gob.es/linea024/home.htm"
            )]
        case "US":
            return [support(
                code: code,
                id: "988",
                title: "988 Suicide & Crisis Lifeline",
                number: "988",
                detail: "Llama o envía un mensaje de texto para apoyo en crisis 24/7.",
                source: "https://988lifeline.org"
            )]
        case "CA":
            return [support(
                code: code,
                id: "988",
                title: "9-8-8 Suicide Crisis Helpline",
                number: "988",
                detail: "Llama o envía un mensaje de texto para apoyo en crisis 24/7.",
                source: "https://988.ca"
            )]
        case "GB", "IE":
            return [support(
                code: code,
                id: "samaritans",
                title: "Samaritans",
                number: "116 123",
                detail: "Apoyo emocional gratuito y confidencial, disponible 24/7.",
                source: "https://www.samaritans.org/how-we-can-help/contact-samaritan/"
            )]
        case "AU":
            return [support(
                code: code,
                id: "lifeline",
                title: "Lifeline Australia",
                number: "13 11 14",
                detail: "Apoyo en crisis y prevención del suicidio, disponible 24/7.",
                source: "https://www.lifeline.org.au/131114/"
            )]
        case "NZ":
            return [support(
                code: code,
                id: "1737",
                title: "1737, Need to talk?",
                number: "1737",
                detail: "Llama o envía un mensaje de texto para hablar con una persona capacitada.",
                source: "https://1737.org.nz"
            )]
        case "MX":
            return [support(
                code: code,
                id: "linea-vida",
                title: "Línea de la Vida",
                number: "800 911 2000",
                detail: "Orientación profesional en salud mental, gratuita y disponible 24/7.",
                source: "https://www.gob.mx/lineadelavida"
            )]
        default:
            return []
        }
    }

    private func support(
        code: String,
        id: String,
        title: String,
        number: String,
        detail: String,
        source: String
    ) -> HealingEmergencyContact {
        HealingEmergencyContact(
            id: "\(code)-\(id)",
            title: title,
            number: number,
            detail: detail,
            kind: .emotionalSupport,
            sourceURL: URL(string: source)
        )
    }

    private func emergencySourceURL(for code: String) -> URL? {
        if european112Regions.contains(code) {
            return URL(string: "https://digital-strategy.ec.europa.eu/en/policies/112")
        }
        switch code {
        case "US": return URL(string: "https://www.911.gov")
        case "CA": return URL(string: "https://www.canada.ca/en/public-health/services/mental-health-services/mental-health-get-help.html")
        case "GB": return URL(string: "https://www.gov.uk/guidance/999-and-112-the-uks-national-emergency-numbers")
        case "AU": return URL(string: "https://www.health.gov.au/form/general-enquiries")
        case "NZ": return URL(string: "https://www.govt.nz/browse/health/help-in-a-crisis/emergencies/")
        case "MX": return URL(string: "https://www.gob.mx/911")
        default: return nil
        }
    }

    private var european112Regions: Set<String> {
        [
            "AT", "BE", "BG", "HR", "CY", "CZ", "DE", "DK", "EE", "ES",
            "FI", "FR", "GR", "HU", "IE", "IS", "IT", "LI", "LT", "LU",
            "LV", "MT", "NL", "NO", "PL", "PT", "RO", "SE", "SI", "SK"
        ]
    }
}
