//
//  LectorEtiquetasViewModel.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation
import Combine

#if os(iOS)
@MainActor
final class LectorEtiquetasViewModel: ObservableObject {
    @Published var resultado: ResultadoAnalisisEtiqueta?
    @Published var isAnalizando: Bool = false
    @Published var errorMessage: String?

    @Published var selectedSource: LectorEtiquetasDataSource = .offlineSQLite
    @Published var offlineInfoMessage: String?
    @Published var offlineErrorMessage: String?
    @Published var offlineDatabasePath: String?
    @Published var isPreparingOfflineDatabase: Bool = false
    @Published var isOfflineDatabaseReady: Bool = false
    @Published var offlineNameMatches: [OfflineProductSuggestion] = []
    @Published var offlineItemsCount: Int?
    @Published var hasPendingOfflineUpdate: Bool = false
    @Published var pendingOfflineVersion: Int?

    private let service: LectorEtiquetasService

    init(service: LectorEtiquetasService = LectorEtiquetasService()) {
        self.service = service
        restoreOfflineDatabaseState()
        Task { await refreshOfflineItemsCount() }
    }

    func buscar(query: String) async {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        if normalized.allSatisfy(\.isNumber) {
            offlineNameMatches = []
            await analizarBarcode(normalized, source: selectedSource)
            return
        }

        guard selectedSource == .offlineSQLite else {
            offlineNameMatches = []
            errorMessage = L10n.exact("La búsqueda por nombre solo está disponible en modo BD Offline.")
            return
        }

        guard isOfflineDatabaseReady else {
            offlineNameMatches = []
            errorMessage = L10n.exact("Primero descarga la BD offline.")
            return
        }

        errorMessage = nil
        do {
            let matches = try await service.buscarProductosOffline(
                nombre: normalized,
                preferredOfflineDatabasePath: offlineDatabasePath
            )
            offlineNameMatches = matches

            if let first = matches.first, matches.count == 1 {
                await analizarBarcode(first.barcode, source: .offlineSQLite)
            }
        } catch {
            offlineNameMatches = []
            errorMessage = error.localizedDescription
        }
    }

    func analizar(codigoBarras: String) async {
        await analizarBarcode(codigoBarras, source: selectedSource)
    }

    func analizarOffline(codigoBarras: String) async {
        await analizarBarcode(codigoBarras, source: .offlineSQLite)
    }

    private func analizarBarcode(_ codigoBarras: String, source: LectorEtiquetasDataSource) async {
        isAnalizando = true
        errorMessage = nil

        do {
            resultado = try await service.analizar(
                codigoBarras: codigoBarras,
                source: source,
                preferredOfflineDatabasePath: offlineDatabasePath
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalizando = false
    }

    func prepararBaseOffline(forceRefresh: Bool = false) async {
        isPreparingOfflineDatabase = true
        offlineErrorMessage = nil
        offlineInfoMessage = nil

        do {
            let status = try await service.prepareOfflineDatabase(forceCopy: forceRefresh)
            let resolvedPath = status.databaseURL.path
            _ = try await service.contarProductosOffline(preferredOfflineDatabasePath: resolvedPath)
            offlineDatabasePath = resolvedPath
            isOfflineDatabaseReady = true
            saveOfflineDatabasePath(resolvedPath)
            offlineInfoMessage = status.didCopy
                ? L10n.format(
                    "label_reader.offline.installed",
                    fallback: "Base offline instalada/actualizada. Versión: {0}.",
                    "\(status.installedVersion)"
                )
                : L10n.format(
                    "label_reader.offline.ready",
                    fallback: "Base offline lista. Versión: {0}.",
                    "\(status.installedVersion)"
                )
            hasPendingOfflineUpdate = false
            pendingOfflineVersion = nil
            await refreshOfflineItemsCount()
        } catch {
            if let path = offlineDatabasePath, isUsableFilePath(path) {
                isOfflineDatabaseReady = true
            } else {
                isOfflineDatabaseReady = false
            }
            offlineItemsCount = nil
            offlineErrorMessage = error.localizedDescription
        }

        isPreparingOfflineDatabase = false
    }

    func verificarActualizacionOffline() async -> Bool {
        do {
            let status = try await service.checkOfflineDatabaseUpdate()
            hasPendingOfflineUpdate = status.hasUpdate
            pendingOfflineVersion = status.hasUpdate ? status.latestVersion : nil
            if status.hasUpdate {
                let installed = status.installedVersion.map(String.init) ?? L10n.exact("N/D")
                offlineInfoMessage = L10n.format(
                    "label_reader.offline.update_available",
                    fallback: "Nueva versión disponible ({0}, actual: {1}).",
                    "\(status.latestVersion)",
                    installed
                )
            }
            return status.hasUpdate
        } catch {
            offlineErrorMessage = error.localizedDescription
            return false
        }
    }

    func limpiarResultado() {
        resultado = nil
        errorMessage = nil
    }

    private func restoreOfflineDatabaseState() {
        let defaults = UserDefaults.standard
        guard let path = defaults.string(forKey: LectorEtiquetasManagedAssetsConfig.databasePathDefaultsKey),
              isUsableFilePath(path) else {
            isOfflineDatabaseReady = false
            offlineDatabasePath = nil
            return
        }

        offlineDatabasePath = path
        isOfflineDatabaseReady = true

        let sharedDefaults = UserDefaults(suiteName: LectorEtiquetasManagedAssetsConfig.appGroupID)
        let installedVersion = (sharedDefaults?.object(forKey: LectorEtiquetasManagedAssetsConfig.versionDefaultsKey) as? NSNumber)?.intValue
        let versionText = installedVersion.map(String.init) ?? L10n.exact("N/D")
        offlineInfoMessage = L10n.format(
            "label_reader.offline.active",
            fallback: "BD offline activa. Versión instalada: {0}.",
            versionText
        )

        Task { _ = await verificarActualizacionOffline() }

    }

    private func saveOfflineDatabasePath(_ path: String) {
        UserDefaults.standard.set(path, forKey: LectorEtiquetasManagedAssetsConfig.databasePathDefaultsKey)
    }

    private func refreshOfflineItemsCount() async {
        guard isOfflineDatabaseReady, offlineDatabasePath != nil else {
            offlineItemsCount = nil
            return
        }

        do {
            offlineItemsCount = try await service.contarProductosOffline(preferredOfflineDatabasePath: offlineDatabasePath)
        } catch {
            isOfflineDatabaseReady = false
            offlineItemsCount = nil
        }
    }

    private func isUsableFilePath(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }
}
#endif
