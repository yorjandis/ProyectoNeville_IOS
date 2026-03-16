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

    private let service: LectorEtiquetasService

    init(service: LectorEtiquetasService = LectorEtiquetasService()) {
        self.service = service
    }

    func analizar(codigoBarras: String) async {
        isAnalizando = true
        errorMessage = nil

        do {
            resultado = try await service.analizar(codigoBarras: codigoBarras, source: selectedSource)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalizando = false
    }

    func analizarOffline(codigoBarras: String) async {
        isAnalizando = true
        errorMessage = nil

        do {
            resultado = try await service.analizar(codigoBarras: codigoBarras, source: .offlineSQLite)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalizando = false
    }

    func prepararBaseOffline() async {
        isPreparingOfflineDatabase = true
        offlineErrorMessage = nil
        offlineInfoMessage = nil

        do {
            let status = try await service.prepareOfflineDatabase()
            offlineDatabasePath = status.databaseURL.path
            isOfflineDatabaseReady = true
            offlineInfoMessage = status.didCopy
                ? "Base offline instalada/actualizada. Versión: \(status.installedVersion)."
                : "Base offline lista. Versión: \(status.installedVersion)."
        } catch {
            isOfflineDatabaseReady = false
            offlineErrorMessage = error.localizedDescription
        }

        isPreparingOfflineDatabase = false
    }

    func limpiarResultado() {
        resultado = nil
        errorMessage = nil
    }
}
#endif
