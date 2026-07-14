import Foundation
import CryptoKit

enum MigrationFormat {
    static let fileExtension = ".ypgexp"
    static let formatName = "com.ypg.neville.ndjson.export"
    static let formatVersion = 1
    static let schemaVersion = 1
    static let magic = "MYAPPEXPORT-1"
    static let cipher = "AES-256-GCM"
    static let kdf = "PBKDF2-HMAC-SHA256"
    static let kdfIterations = 310_000
    static let saltBytes = 16
    static let nonceBytes = 12
    static let keyBits = 256
    static let tagBits = 128

    struct PlainPackage {
        let manifest: [String: Any]
        let ndjson: String
    }

    static func utcNow() -> String {
        isoString(fromMilliseconds: Int64((Date().timeIntervalSince1970 * 1000).rounded()))
    }

    static func isoString(from date: Date) -> String {
        isoString(fromMilliseconds: Int64((date.timeIntervalSince1970 * 1000).rounded()))
    }

    static func isoString(fromMilliseconds milliseconds: Int64) -> String {
        let seconds = milliseconds / 1000
        let millis = abs(milliseconds % 1000)
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let base = String(
            format: "%04d-%02d-%02dT%02d:%02d:%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1,
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
        return millis == 0 ? "\(base)Z" : "\(base).\(String(format: "%03d", millis))Z"
    }

    static func milliseconds(fromISO8601 value: String) throws -> Int64 {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return Int64((date.timeIntervalSince1970 * 1000).rounded())
        }

        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: value) else {
            throw MigrationError.validation("Fecha ISO-8601 inválida: \(value)")
        }
        return Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    static func date(fromISO8601 value: String) throws -> Date {
        Date(timeIntervalSince1970: TimeInterval(try milliseconds(fromISO8601: value)) / 1000)
    }

    static func packPlaintext(manifest: [String: Any], ndjson: String) throws -> Data {
        let manifestBytes = try JSONSerialization.data(withJSONObject: manifest, options: [])
        var output = Data()
        var size = UInt32(manifestBytes.count).bigEndian
        withUnsafeBytes(of: &size) { output.append(contentsOf: $0) }
        output.append(manifestBytes)
        output.append(Data(ndjson.utf8))
        return output
    }

    static func unpackPlaintext(_ bytes: Data) throws -> PlainPackage {
        guard bytes.count >= 4 else {
            throw MigrationError.validation("Paquete descifrado incompleto")
        }
        let manifestSize = bytes.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let manifestEnd = 4 + Int(manifestSize)
        guard manifestSize > 0, bytes.count >= manifestEnd else {
            throw MigrationError.validation("Tamaño de manifiesto inválido")
        }
        let manifestData = bytes.subdata(in: 4..<manifestEnd)
        let manifestObject = try JSONSerialization.jsonObject(with: manifestData)
        guard let manifest = manifestObject as? [String: Any] else {
            throw MigrationError.validation("Manifiesto inválido")
        }
        let ndjsonData = bytes.subdata(in: manifestEnd..<bytes.count)
        guard let ndjson = String(data: ndjsonData, encoding: .utf8) else {
            throw MigrationError.validation("data.ndjson no es UTF-8 válido")
        }
        return PlainPackage(manifest: manifest, ndjson: ndjson)
    }

    static func encodeBase64(_ data: Data) -> String {
        data.base64EncodedString()
    }

    static func decodeBase64(_ value: String) throws -> Data {
        guard let data = Data(base64Encoded: value) else {
            throw MigrationError.validation("Base64 inválido")
        }
        return data
    }
}

enum MigrationRecordType {
    static let note = "note"
    static let diary = "diary_entry"
    static let agenda = "agenda_entry"
    static let goal = "goal"
    static let archivedGoal = "archived_goal"
    static let personalPhrase = "personal_phrase"
    static let personalReflection = "personal_reflection"
    static let dayRitualArchive = "day_ritual_archive"
    static let calmPersonalPhrase = "calm_personal_phrase"
}

enum ImportPolicy {
    case skipExisting
    case overwriteExisting
}

struct CanonicalMigrationRecord: Identifiable {
    let type: String
    let id: String
    let createdAt: String
    let updatedAt: String
    let schemaVersion: Int
    let payload: [String: Any]

    func jsonLine() throws -> String {
        try OrderedJSONWriter.recordLine(self)
    }

    func contentFingerprint() throws -> String {
        try MigrationIds.sha256Hex("\(type)|\(createdAt)|\(OrderedJSONWriter.objectString(payload, preferredOrder: OrderedJSONWriter.payloadOrder(for: type)))")
    }

    static func fromJsonLine(_ line: String) throws -> CanonicalMigrationRecord {
        guard let data = line.data(using: .utf8) else {
            throw MigrationError.validation("Línea no es UTF-8")
        }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            throw MigrationError.validation("Registro JSON inválido")
        }
        guard let type = (json["type"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !type.isEmpty else {
            throw MigrationError.validation("type vacío")
        }
        guard let id = (json["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            throw MigrationError.validation("id vacío")
        }
        guard let createdAt = (json["createdAt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let updatedAt = (json["updatedAt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw MigrationError.validation("Fechas requeridas")
        }
        let schemaVersion = (json["schemaVersion"] as? NSNumber)?.intValue ?? MigrationFormat.schemaVersion
        guard schemaVersion <= MigrationFormat.schemaVersion else {
            throw MigrationError.validation("schemaVersion no soportado: \(schemaVersion)")
        }
        _ = try MigrationFormat.milliseconds(fromISO8601: createdAt)
        _ = try MigrationFormat.milliseconds(fromISO8601: updatedAt)
        guard let payload = json["payload"] as? [String: Any] else {
            throw MigrationError.validation("payload inválido")
        }
        return CanonicalMigrationRecord(
            type: type,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            schemaVersion: schemaVersion,
            payload: payload
        )
    }
}

struct ImportConflict: Identifiable {
    let id = UUID()
    let type: String
    let recordId: String
    let reason: String
}

struct MigrationSummary {
    var inserted = 0
    var updated = 0
    var skipped = 0
    var conflicts = 0
    var errors = 0

    static func + (left: MigrationSummary, right: MigrationSummary) -> MigrationSummary {
        MigrationSummary(
            inserted: left.inserted + right.inserted,
            updated: left.updated + right.updated,
            skipped: left.skipped + right.skipped,
            conflicts: left.conflicts + right.conflicts,
            errors: left.errors + right.errors
        )
    }
}

struct ExportResult {
    let exportId: String
    let countsByType: [String: Int]
    let bytes: Data
}

struct ImportPreview {
    let manifest: [String: Any]
    let records: [CanonicalMigrationRecord]
    let countsByType: [String: Int]
    let conflicts: [ImportConflict]
    let errors: [String]
}

enum MigrationError: LocalizedError {
    case validation(String)
    case crypto(String)

    var errorDescription: String? {
        switch self {
        case .validation(let message), .crypto(let message):
            return message
        }
    }
}

enum MigrationIds {
    static func stableId(type: String, parts: Any?...) throws -> String {
        let source = ([type.lowercased()] + parts.map { part in
            String(describing: part ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }).joined(separator: "|")
        return "sha256:\(try sha256Hex(source))"
    }

    static func stableLongId(type: String, parts: Any?...) throws -> Int64 {
        let hex = try stableId(type: type, parts: parts).replacingOccurrences(of: "sha256:", with: "")
        return Int64(hex.prefix(15), radix: 16) ?? 1
    }

    static func sha256Hex(_ value: String) throws -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func deterministicUUID(from value: String) -> UUID {
        if let uuid = UUID(uuidString: value) {
            return uuid
        }
        let digest = SHA256.hash(data: Data(value.utf8))
        let bytes = Array(digest.prefix(16))
        let uuid = uuid_t(
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            (bytes[6] & 0x0f) | 0x50,
            bytes[7],
            (bytes[8] & 0x3f) | 0x80,
            bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuid)
    }
}

enum OrderedJSONWriter {
    static func recordLine(_ record: CanonicalMigrationRecord) throws -> String {
        let fields: [(String, Any?)] = [
            ("type", record.type),
            ("id", record.id),
            ("createdAt", record.createdAt),
            ("updatedAt", record.updatedAt),
            ("schemaVersion", record.schemaVersion),
            ("payload", record.payload)
        ]
        return try objectString(fields, nestedPreferredOrder: payloadOrder(for: record.type))
    }

    static func payloadOrder(for type: String) -> [String] {
        switch type {
        case MigrationRecordType.note:
            return ["title", "body", "tags", "category", "favorite", "isChecklist", "checklistJson"]
        case MigrationRecordType.diary:
            return ["title", "body", "emotion", "chapter", "favorite"]
        case MigrationRecordType.agenda:
            return ["title", "note", "activityDateMillis", "activityTimeMillis", "place", "content", "priority", "colorHex", "completed", "reminderActive", "reminderId"]
        case MigrationRecordType.goal:
            return ["title", "descriptionText", "totalUnits", "unitType", "frequency", "scheduleType", "weeklyDaysPerWeek", "dayPeriod", "customUnitLabel", "executionTargetValue", "completionBasis", "durationValue", "durationUnit", "isStarted", "startDate", "notifyOnUnitAvailable", "lastNotifiedUnitIndex", "status", "units"]
        case MigrationRecordType.archivedGoal:
            return ["title", "descriptionText", "totalUnits", "unitType", "frequency", "scheduleType", "weeklyDaysPerWeek", "dayPeriod", "customUnitLabel", "executionTargetValue", "completionBasis", "durationValue", "durationUnit", "completionDate", "status", "units"]
        case MigrationRecordType.personalPhrase:
            return ["phrase", "author", "source", "favorite", "note", "category"]
        case MigrationRecordType.personalReflection:
            return ["title", "content", "favorite", "note", "author"]
        case MigrationRecordType.dayRitualArchive:
            return ["sessionId", "diarioId", "createdAtMillis", "iosSessionId", "sessionDateEpochDay", "completed", "noteText"]
        case MigrationRecordType.calmPersonalPhrase:
            return ["phrase"]
        default:
            return []
        }
    }

    static func objectString(_ object: [String: Any], preferredOrder: [String] = []) throws -> String {
        let orderedKeys = preferredOrder.filter { object.keys.contains($0) } + object.keys.sorted().filter { !preferredOrder.contains($0) }
        let fields = orderedKeys.map { ($0, object[$0]) }
        return try objectString(fields, nestedPreferredOrder: [])
    }

    private static func objectString(_ fields: [(String, Any?)], nestedPreferredOrder: [String]) throws -> String {
        let body = try fields.map { key, value in
            try "\(stringLiteral(key)):\(valueString(value ?? NSNull(), nestedPreferredOrder: nestedPreferredOrder))"
        }.joined(separator: ",")
        return "{\(body)}"
    }

    private static func valueString(_ value: Any, nestedPreferredOrder: [String]) throws -> String {
        if value is NSNull {
            return "null"
        }
        if let string = value as? String {
            return stringLiteral(string)
        }
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }
        if let int = value as? Int {
            return String(int)
        }
        if let int64 = value as? Int64 {
            return String(int64)
        }
        if let double = value as? Double {
            return String(double)
        }
        if let array = value as? [Any] {
            return try "[" + array.map { try valueString($0, nestedPreferredOrder: nestedPreferredOrder) }.joined(separator: ",") + "]"
        }
        if let object = value as? [String: Any] {
            return try objectString(object, preferredOrder: nestedPreferredOrder)
        }
        throw MigrationError.validation("Valor JSON no soportado: \(type(of: value))")
    }

    private static func stringLiteral(_ value: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [value], options: [])
        let encoded = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
        return String(encoded.dropFirst().dropLast())
    }
}

enum MigrationJSON {
    static func string(_ payload: [String: Any], _ key: String, default defaultValue: String = "") -> String {
        if let value = payload[key] as? String { return value }
        if payload[key] is NSNull { return defaultValue }
        return defaultValue
    }

    static func bool(_ payload: [String: Any], _ key: String, default defaultValue: Bool = false) -> Bool {
        if let value = payload[key] as? Bool { return value }
        if let value = payload[key] as? NSNumber { return value.boolValue }
        return defaultValue
    }

    static func int(_ payload: [String: Any], _ key: String, default defaultValue: Int = 0) -> Int {
        if let value = payload[key] as? Int { return value }
        if let value = payload[key] as? NSNumber { return value.intValue }
        return defaultValue
    }

    static func double(_ payload: [String: Any], _ key: String, default defaultValue: Double = 0) -> Double {
        if let value = payload[key] as? Double { return value }
        if let value = payload[key] as? NSNumber { return value.doubleValue }
        return defaultValue
    }

    static func int64(_ payload: [String: Any], _ key: String, default defaultValue: Int64 = 0) -> Int64 {
        if let value = payload[key] as? Int64 { return value }
        if let value = payload[key] as? Int { return Int64(value) }
        if let value = payload[key] as? NSNumber { return value.int64Value }
        return defaultValue
    }

    static func optionalInt64(_ payload: [String: Any], _ key: String) -> Int64? {
        guard payload[key] != nil, !(payload[key] is NSNull) else { return nil }
        return int64(payload, key)
    }
}
