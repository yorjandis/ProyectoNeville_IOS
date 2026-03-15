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

    private let service: LectorEtiquetasService

    init(service: LectorEtiquetasService = LectorEtiquetasService()) {
        self.service = service
    }

    func analizar(codigoBarras: String) async {
        self.isAnalizando = true
        self.errorMessage = nil

        do {
            self.resultado = try await service.analizar(codigoBarras: codigoBarras)
        } catch {
            self.errorMessage = error.localizedDescription
        }

        self.isAnalizando = false
    }

    func limpiarResultado() {
        self.resultado = nil
        self.errorMessage = nil
    }
}
#endif
