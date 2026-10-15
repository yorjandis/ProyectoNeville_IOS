#if os(iOS)
import Foundation
import CryptoKit

enum WirelessSyncDirection: String, Codable, Sendable {
    case androidToIOS = "android_to_ios"
    case iosToAndroid = "ios_to_android"
    case bidirectional = "bidirectional"
}

struct WirelessNetworkCredentials: Codable, Sendable {
    let ssid: String
    let password: String
    let security: String
}

struct WirelessSessionDescriptor: Codable, Sendable {
    static let supportedVersion = 2
    static let uriPrefix = "neville://sync/"
    static let serviceType = "_nevillesync._tcp"

    let version: Int
    let sessionId: String
    let direction: WirelessSyncDirection
    let serviceName: String
    let secret: String
    let expiresAtEpochSeconds: Int64
    let network: WirelessNetworkCredentials?
    let includedTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case sessionId = "sid"
        case direction
        case serviceName = "service"
        case secret
        case expiresAtEpochSeconds = "expires"
        case network
        case includedTypes = "types"
    }

    static func parse(qrPayload: String) throws -> WirelessSessionDescriptor {
        guard qrPayload.hasPrefix(uriPrefix) else {
            throw WirelessSyncError.invalidLink("El código no pertenece a Neville")
        }
        let encoded = String(qrPayload.dropFirst(uriPrefix.count))
        guard let data = Data(base64URL: encoded) else {
            throw WirelessSyncError.invalidLink("El código de enlace está dañado")
        }
        let descriptor = try JSONDecoder().decode(WirelessSessionDescriptor.self, from: data)
        guard descriptor.version == supportedVersion else {
            throw WirelessSyncError.invalidLink("Esta versión del enlace no es compatible")
        }
        guard descriptor.secretData.count == 32 else {
            throw WirelessSyncError.invalidLink("La clave de sesión no es válida")
        }
        guard Int64(Date().timeIntervalSince1970) <= descriptor.expiresAtEpochSeconds else {
            throw WirelessSyncError.expired
        }
        return descriptor
    }

    var secretData: Data {
        Data(base64URL: secret) ?? Data()
    }
}

struct WirelessImportResult: Codable, Equatable, Sendable {
    let inserted: Int
    let updated: Int
    let skipped: Int
    let conflicts: Int
    let errors: Int
    let message: String

    init(summary: MigrationSummary, message: String) {
        inserted = summary.inserted
        updated = summary.updated
        skipped = summary.skipped
        conflicts = summary.conflicts
        errors = summary.errors
        self.message = message
    }

    static let empty = WirelessImportResult(
        summary: MigrationSummary(),
        message: ""
    )
}

struct WirelessTransferSummary: Identifiable, Equatable, Sendable {
    let id = UUID()
    let direction: WirelessSyncDirection
    let sent: Int
    let received: Int
    let localImport: WirelessImportResult
    let remoteImport: WirelessImportResult

    var totalInserted: Int { localImport.inserted + remoteImport.inserted }
    var totalUpdated: Int { localImport.updated + remoteImport.updated }
    var totalSkipped: Int { localImport.skipped + remoteImport.skipped }
    var totalConflicts: Int { localImport.conflicts + remoteImport.conflicts }
    var totalErrors: Int { localImport.errors + remoteImport.errors }
}

enum WirelessSyncError: LocalizedError {
    case invalidLink(String)
    case expired
    case discoveryTimedOut
    case connection(String)
    case protocolViolation(String)

    var errorDescription: String? {
        switch self {
        case .invalidLink(let message), .connection(let message), .protocolViolation(let message):
            return message
        case .expired:
            return "El enlace ha caducado. Genera un código nuevo en Android."
        case .discoveryTimedOut:
            return "No se encontró el dispositivo Android en la red local."
        }
    }
}

enum WirelessFrameType: UInt8 {
    case hello = 1
    case challenge = 2
    case authentication = 3
    case authenticationOK = 4
    case package = 5
    case result = 6
    case error = 7
}

struct WirelessFrame: Sendable {
    let type: WirelessFrameType
    let payload: Data
}

enum WirelessSessionAuthenticator {
    static func proof(
        secret: Data,
        sessionId: String,
        clientNonce: Data,
        serverNonce: Data
    ) -> Data {
        var message = Data()
        [
            Data("neville-sync-v1".utf8),
            Data(sessionId.utf8),
            clientNonce,
            serverNonce
        ].forEach { part in
            message.append(0)
            message.append(part)
        }
        let key = SymmetricKey(data: secret)
        return Data(HMAC<SHA256>.authenticationCode(for: message, using: key))
    }
}

extension Data {
    init?(base64URL: String) {
        var value = base64URL.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = value.count % 4
        if remainder != 0 {
            value += String(repeating: "=", count: 4 - remainder)
        }
        self.init(base64Encoded: value)
    }
}
#endif
