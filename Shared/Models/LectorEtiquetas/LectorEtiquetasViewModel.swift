//
//  LectorEtiquetasViewModel.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import Foundation

#if os(iOS)
@MainActor
final class LectorEtiquetasViewModel: ObservableObject {
    @Published var resultado: ResultadoAnalisisEtiqueta?
    @Published var isAnalizando: Bool = false
    @Published var errorMessage: String?

    @Published var selectedSource: LectorEtiquetasDataSource = .openFoodFacts
    @Published var offlineInfoMessage: String?
    @Published var offlineErrorMessage: String?
    @Published var offlineDatabasePath: String?
    @Published var isPreparingOfflineDatabase: Bool = false
    @Published var isOfflineDatabaseReady: Bool = false
    @Published var offlineNameMatches: [OfflineProductSuggestion] = []
    @Published var offlineItemsCount: Int?

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
            errorMessage = "La búsqueda por nombre solo está disponible en modo BD Offline."
            return
        }

        guard isOfflineDatabaseReady else {
            offlineNameMatches = []
            errorMessage = "Primero descarga y verifica la BD offline."
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
            offlineDatabasePath = status.databaseURL.path
            isOfflineDatabaseReady = true
            saveOfflineDatabasePath(status.databaseURL.path)
            offlineInfoMessage = status.didCopy
                ? "Base offline instalada/actualizada. Versión: \(status.installedVersion)."
                : "Base offline lista. Versión: \(status.installedVersion)."
            await refreshOfflineItemsCount()
        } catch {
            if let path = offlineDatabasePath, FileManager.default.fileExists(atPath: path) {
                isOfflineDatabaseReady = true
            } else {
                isOfflineDatabaseReady = false
            }
            offlineItemsCount = nil
            offlineErrorMessage = error.localizedDescription
        }

        isPreparingOfflineDatabase = false
    }

    func limpiarResultado() {
        resultado = nil
        errorMessage = nil
    }

    private func restoreOfflineDatabaseState() {
        let defaults = UserDefaults.standard
        guard let path = defaults.string(forKey: LectorEtiquetasManagedAssetsConfig.databasePathDefaultsKey),
              FileManager.default.fileExists(atPath: path) else {
            isOfflineDatabaseReady = false
            offlineDatabasePath = nil
            return
        }

        offlineDatabasePath = path
        isOfflineDatabaseReady = true
        offlineInfoMessage = "Base offline OK"
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
            offlineItemsCount = nil
        }
    }
}
#endif
