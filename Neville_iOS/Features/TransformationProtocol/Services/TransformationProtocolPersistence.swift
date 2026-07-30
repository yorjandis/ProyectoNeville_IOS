import Foundation

protocol TransformationProtocolPersisting {
    func load() throws -> TransformationProtocolState
    func save(_ state: TransformationProtocolState) throws
}

enum TransformationProtocolPersistenceError: LocalizedError {
    case invalidData

    var errorDescription: String? {
        L10n.exact("No se pudo leer el progreso guardado.")
    }
}

final class TransformationProtocolFilePersistence: TransformationProtocolPersisting {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let stateURL: URL
    private let backupURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directoryURL = support.appendingPathComponent("TransformationProtocol", isDirectory: true)
        stateURL = directoryURL.appendingPathComponent("state.json")
        backupURL = directoryURL.appendingPathComponent("state.backup.json")
    }

    func load() throws -> TransformationProtocolState {
        guard fileManager.fileExists(atPath: stateURL.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: stateURL)
            return try decoder.decode(TransformationProtocolState.self, from: data)
        } catch {
            guard fileManager.fileExists(atPath: backupURL.path) else {
                throw TransformationProtocolPersistenceError.invalidData
            }
            do {
                let backup = try Data(contentsOf: backupURL)
                return try decoder.decode(TransformationProtocolState.self, from: backup)
            } catch {
                throw TransformationProtocolPersistenceError.invalidData
            }
        }
    }

    func save(_ state: TransformationProtocolState) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        if fileManager.fileExists(atPath: stateURL.path),
           let existingData = try? Data(contentsOf: stateURL) {
            try? existingData.write(to: backupURL, options: .atomic)
        }

        let data = try encoder.encode(state)
        try data.write(to: stateURL, options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
