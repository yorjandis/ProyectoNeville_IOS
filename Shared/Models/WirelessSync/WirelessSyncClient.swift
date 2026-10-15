#if os(iOS) || os(macOS)
import Foundation
@preconcurrency import Network
import Security

nonisolated final class WirelessSyncSession: @unchecked Sendable {
    private let connection: NWConnection
    private let maximumPayloadBytes = MigrationFormat.maximumFileBytes

    init(connection: NWConnection) {
        self.connection = connection
    }

    func send(type: WirelessFrameType, payload: Data = Data()) async throws {
        guard payload.count <= maximumPayloadBytes else {
            throw WirelessSyncError.protocolViolation("El mensaje supera el tamaño permitido")
        }
        var bytes = Data([type.rawValue])
        var length = UInt32(payload.count).bigEndian
        withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }
        bytes.append(payload)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: bytes, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: WirelessSyncError.connection(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            })
        }
    }

    func receive() async throws -> WirelessFrame {
        let header = try await receiveExactly(5)
        guard let rawType = header.first,
              let type = WirelessFrameType(rawValue: rawType) else {
            throw WirelessSyncError.protocolViolation("Tipo de mensaje desconocido")
        }
        let length = header.dropFirst().reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        guard length <= UInt32(maximumPayloadBytes) else {
            throw WirelessSyncError.protocolViolation("Longitud de mensaje inválida")
        }
        return WirelessFrame(type: type, payload: try await receiveExactly(Int(length)))
    }

    func cancel() {
        connection.cancel()
    }

    private func receiveExactly(_ count: Int) async throws -> Data {
        guard count > 0 else { return Data() }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            connection.receive(
                minimumIncompleteLength: count,
                maximumLength: count
            ) { data, _, _, error in
                if let error {
                    continuation.resume(throwing: WirelessSyncError.connection(error.localizedDescription))
                } else if let data, data.count == count {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: WirelessSyncError.connection("La conexión terminó antes de completar la transferencia"))
                }
            }
        }
    }
}

nonisolated final class WirelessSyncClient: @unchecked Sendable {
    func connect(to descriptor: WirelessSessionDescriptor) async throws -> WirelessSyncSession {
        let endpoint = try await discoverEndpoint(
            serviceName: descriptor.serviceName,
            timeoutSeconds: 45
        )
        let connection = NWConnection(to: endpoint, using: .tcp)
        try await start(connection)
        let session = WirelessSyncSession(connection: connection)
        do {
            try await authenticate(session: session, descriptor: descriptor)
            return session
        } catch {
            session.cancel()
            throw error
        }
    }

    private func discoverEndpoint(serviceName: String, timeoutSeconds: UInt64) async throws -> NWEndpoint {
        try await withThrowingTaskGroup(of: NWEndpoint.self) { group in
            group.addTask {
                let stream = AsyncThrowingStream<NWEndpoint, Error> { continuation in
                    let browser = NWBrowser(
                        for: .bonjour(type: WirelessSessionDescriptor.serviceType, domain: nil),
                        using: .tcp
                    )
                    browser.stateUpdateHandler = { state in
                        if case .failed(let error) = state {
                            continuation.finish(throwing: WirelessSyncError.connection(error.localizedDescription))
                        }
                    }
                    browser.browseResultsChangedHandler = { results, _ in
                        for result in results {
                            if case .service(let name, _, _, _) = result.endpoint,
                               name == serviceName {
                                continuation.yield(result.endpoint)
                                continuation.finish()
                                browser.cancel()
                                break
                            }
                        }
                    }
                    continuation.onTermination = { _ in browser.cancel() }
                    browser.start(queue: DispatchQueue(label: "com.ypg.neville.wireless.browser"))
                }
                for try await endpoint in stream { return endpoint }
                throw WirelessSyncError.discoveryTimedOut
            }
            group.addTask {
                try await Task.sleep(for: .seconds(timeoutSeconds))
                throw WirelessSyncError.discoveryTimedOut
            }
            guard let endpoint = try await group.next() else {
                throw WirelessSyncError.discoveryTimedOut
            }
            group.cancelAll()
            return endpoint
        }
    }

    private func start(_ connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.stateUpdateHandler = nil
                    continuation.resume()
                case .failed(let error), .waiting(let error):
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: WirelessSyncError.connection(error.localizedDescription))
                case .cancelled:
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: WirelessSyncError.connection("Conexión cancelada"))
                default:
                    break
                }
            }
            connection.start(queue: DispatchQueue(label: "com.ypg.neville.wireless.connection"))
        }
    }

    private func authenticate(
        session: WirelessSyncSession,
        descriptor: WirelessSessionDescriptor
    ) async throws {
        let clientNonce = try secureRandomData(count: 16)
        let hello = try JSONSerialization.data(withJSONObject: [
            "sid": descriptor.sessionId,
            "nonce": clientNonce.base64EncodedString()
        ])
        try await session.send(type: .hello, payload: hello)
        let challengeFrame = try await session.receive()
        guard challengeFrame.type == .challenge,
              let challenge = try JSONSerialization.jsonObject(with: challengeFrame.payload) as? [String: Any],
              let nonceString = challenge["nonce"] as? String,
              let serverNonce = Data(base64Encoded: nonceString),
              serverNonce.count == 16 else {
            throw WirelessSyncError.protocolViolation("El desafío de autenticación no es válido")
        }
        let proof = WirelessSessionAuthenticator.proof(
            secret: descriptor.secretData,
            sessionId: descriptor.sessionId,
            clientNonce: clientNonce,
            serverNonce: serverNonce
        )
        try await session.send(type: .authentication, payload: proof)
        let response = try await session.receive()
        guard response.type == .authenticationOK else {
            throw WirelessSyncError.protocolViolation("Android rechazó la autenticación")
        }
    }

    private func secureRandomData(count: Int) throws -> Data {
        var data = Data(count: count)
        let status = data.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw WirelessSyncError.connection("No se pudo crear una sesión segura")
        }
        return data
    }
}
#endif
