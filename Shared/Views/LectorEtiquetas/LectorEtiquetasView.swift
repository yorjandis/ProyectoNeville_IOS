//
//  LectorEtiquetasView.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import SwiftUI

#if os(iOS)
import AVFoundation

struct LectorEtiquetasView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LectorEtiquetasViewModel()

    @State private var barcodeInput: String = ""
    @State private var showBarcodeScanner: Bool = false
    @State private var expandedAditivos: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HeadSection
                        barcodeCard
                        statusSection
                        resultadoSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Lector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Limpiar") {
                        barcodeInput = ""
                        expandedAditivos.removeAll()
                        viewModel.limpiarResultado()
                    }
                    .disabled(viewModel.isAnalizando)
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                barcodeScannerSheet
            }
            .onChange(of: viewModel.selectedSource) { _, _ in
                clearSearchStateForModeChange()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .blue.opacity(0.3),
                .blue.opacity(0.7),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var HeadSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Lector de Alimentos")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.primary)

            Text("Consulta por código de barras usando API de OpenFoodFacts o base SQLite offline.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var barcodeCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Código de barras")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                Picker("Fuente de datos", selection: $viewModel.selectedSource) {
                    ForEach(LectorEtiquetasDataSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Ejemplo: 8410076475898", text: $barcodeInput)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.22), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if viewModel.selectedSource == .openFoodFacts || viewModel.isOfflineDatabaseReady {
                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await viewModel.analizar(codigoBarras: barcodeInput)
                            }
                        } label: {
                            Label(viewModel.selectedSource == .offlineSQLite ? "Buscar offline" : "Buscar", systemImage: "barcode.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.blue)
                        .disabled(
                            barcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            viewModel.isAnalizando
                        )

                        Button {
                            showBarcodeScanner = true
                        } label: {
                            Label("Escanear", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.blue)
                        .disabled(viewModel.isAnalizando)
                    }
                }

                if viewModel.selectedSource == .offlineSQLite {
                    if viewModel.isOfflineDatabaseReady {
                        Button {
                            Task { await viewModel.analizarOffline(codigoBarras: barcodeInput) }
                        } label: {
                            Label("Chequear en BD offline", systemImage: "shippingbox")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.indigo)
                        .disabled(
                            barcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            viewModel.isAnalizando
                        )
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            Task { await viewModel.prepararBaseOffline() }
                        } label: {
                            Label("Descargar y verificar BD offline", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.indigo)
                        .disabled(viewModel.isAnalizando || viewModel.isPreparingOfflineDatabase)

                        if !viewModel.isOfflineDatabaseReady {
                            Text("Primero descarga y verifica la BD offline para habilitar escaneo y búsqueda.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        if viewModel.isPreparingOfflineDatabase {
                            ProgressView("Preparando base SQLite offline...")
                                .font(.system(.footnote, design: .rounded))
                        }

                        if let infoMessage = viewModel.offlineInfoMessage {
                            Text(infoMessage)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.green)
                        }

                        if let databasePath = viewModel.offlineDatabasePath {
                            Text("Ruta SQLite")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(databasePath)
                                .font(.caption2.monospaced())
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                        }

                        if let errorMessage = viewModel.offlineErrorMessage {
                            Text(errorMessage)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.isAnalizando {
            card {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(viewModel.selectedSource == .offlineSQLite ? "Consultando base SQLite offline..." : "Consultando OpenFoodFacts...")
                        .font(.system(.subheadline, design: .rounded))
                }
            }
        }

        if let error = viewModel.errorMessage {
            card {
                Text(error)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var resultadoSection: some View {
        if let resultado = viewModel.resultado,
           let resumen = resultado.resumenProducto() {
            VStack(alignment: .leading, spacing: 12) {
                headerSection(resultado)
                productoSection(resumen)
                perfilSection(resumen)
                ecologicoSection(resumen)
                aditivosSection(resultado)
                nutricionSection(resumen)
                
            }
        }
    }

    private func headerSection(_ resultado: ResultadoAnalisisEtiqueta) -> some View {
        card {
            HStack {
                Text("Resultado (\(resultado.metadata?.source.title ?? "N/A"))")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                Spacer()

                Text(resultado.nivelGeneral.badgeText)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(resultado.nivelGeneral.badgeColor.opacity(0.18))
                    .foregroundStyle(resultado.nivelGeneral.badgeColor)
                    .clipShape(Capsule())
            }
        }
    }

    private func aditivosSection(_ resultado: ResultadoAnalisisEtiqueta) -> some View {
        let aditivos = resultado.hallazgos.filter { $0.categoria == .aditivoDeRiesgo }

        return card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Aditivos detectados")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                if aditivos.isEmpty {
                    Text("No se detectaron aditivos de la base additives.json.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(aditivos, id: \.self) { aditivo in
                        let rowID = aditivoIdentifier(aditivo)
                        let expanded = expandedAditivos.contains(rowID)
                        let toxicidad = extractToxicidad(from: aditivo.recomendacion)

                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                toggleAditivo(rowID)
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(aditivoDisplayTitle(aditivo.titulo))
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)

                                        if let toxicidad {
                                            Text("Toxicidad: \(toxicidad.capitalized)")
                                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                                .foregroundStyle(toxicidadColor(toxicidad))
                                        }
                                    }

                                    Spacer(minLength: 8)

                                    Image(systemName: expanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Color.blue.opacity(0.8))
                                }
                            }
                            .buttonStyle(.plain)

                            if expanded {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(aditivo.detalle)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.primary)

                                    Text("Detectado en: \(aditivo.textoDetectado)")
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.66))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                        }
                    }
                }
            }
        }
    }

    private func productoSection(_ resumen: EtiquetaResumenProducto) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Producto")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                infoRow(title: "Nombre", value: resumen.nombreProducto)
                infoRow(title: "Código de barras", value: resumen.codigoBarras)
                infoRow(
                    title: "Alérgenos",
                    value: resumen.alergenos.isEmpty ? "No informados" : resumen.alergenos.joined(separator: ", ")
                )
            }
        }
    }

    private func perfilSection(_ resumen: EtiquetaResumenProducto) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Perfil alimentario")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                infoRow(title: "Vegano", value: boolText(resumen.perfilAlimentario.esVegano))
                infoRow(title: "Vegetariano", value: boolText(resumen.perfilAlimentario.esVegetariano))
                infoRow(title: "Orgánico", value: boolText(resumen.perfilAlimentario.esOrganico))
                infoRow(title: "Contiene gluten", value: boolText(resumen.perfilAlimentario.contieneGluten))
            }
        }
    }

    private func nutricionSection(_ resumen: EtiquetaResumenProducto) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Información nutricional")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                if resumen.nutrientesClave.isEmpty {
                    Text("No hay información nutricional disponible.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                        GridRow {
                            Text("Nutriente")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text("Valor")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(.secondary)
                        }

                        ForEach(resumen.nutrientesClave) { nutriente in
                            Divider().gridCellUnsizedAxes(.horizontal)

                            GridRow {
                                Text(nutriente.titulo)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                Text(nutriente.valor)
                                    .font(.system(.subheadline, design: .rounded))
                            }
                        }
                    }
                }
            }
        }
    }

    private func ecologicoSection(_ resumen: EtiquetaResumenProducto) -> some View {
        let ecologico = resumen.evaluacionEcologica

        return card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Evaluación ecológica")
                        .font(.system(.headline, design: .rounded, weight: .semibold))

                    Spacer()

                    Text(ecologico.estado.titulo)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ecologico.estado.color.opacity(0.20))
                        .foregroundStyle(ecologico.estado.color)
                        .clipShape(Capsule())
                }

                infoRow(title: "Región aplicada", value: ecologico.regionDetectada)

                Text(ecologico.resumen)
                    .font(.system(.footnote, design: .rounded))

                if !ecologico.evidencias.isEmpty {
                    Text("Evidencias")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    ForEach(ecologico.evidencias, id: \.self) { evidencia in
                        Text("• \(evidencia)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.black)
            .background(Color.green.opacity(0.80))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func aditivoIdentifier(_ aditivo: HallazgoRiesgoEtiqueta) -> String {
        "\(aditivo.titulo)|\(aditivo.textoDetectado)"
    }

    private func aditivoDisplayTitle(_ title: String) -> String {
        title.replacingOccurrences(of: "Aditivo detectado:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggleAditivo(_ id: String) {
        if expandedAditivos.contains(id) {
            expandedAditivos.remove(id)
        } else {
            expandedAditivos.insert(id)
        }
    }

    private func extractToxicidad(from text: String) -> String? {
        let normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard let range = normalized.range(of: "toxicidad:") else { return nil }
        let suffix = normalized[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        let value = suffix.components(separatedBy: ".").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else { return nil }
        return value
    }

    private func toxicidadColor(_ toxicidad: String) -> Color {
        switch toxicidad.lowercased() {
        case "alto": return .red
        case "medio": return .orange
        default: return .green
        }
    }

    private func boolText(_ value: Bool?) -> String {
        guard let value else { return "No disponible" }
        return value ? "Sí" : "No"
    }

    private func clearSearchStateForModeChange() {
        barcodeInput = ""
        expandedAditivos.removeAll()
        viewModel.limpiarResultado()
    }

    private var barcodeScannerSheet: some View {
        CodeScannerView(codeTypes: [.ean8, .ean13, .upce, .code128]) { result in
            switch result {
            case .success(let scan):
                let code = scan.string.trimmingCharacters(in: .whitespacesAndNewlines)
                barcodeInput = code
                Task {
                    await viewModel.analizar(codigoBarras: code)
                }
            case .failure:
                viewModel.errorMessage = "No se pudo leer el código de barras."
            }
        }
        .ignoresSafeArea()
    }
}

private extension NivelRiesgoEtiqueta {
    var badgeText: String {
        switch self {
        case .bajo: return "Bajo"
        case .medio: return "Medio"
        case .alto: return "Alto"
        case .critico: return "Crítico"
        }
    }

    var badgeColor: Color {
        switch self {
        case .bajo: return .green
        case .medio: return .yellow
        case .alto: return .orange
        case .critico: return .red
        }
    }
}

private extension EstadoEcologicoEtiqueta {
    var color: Color {
        switch self {
        case .confirmado: return .green
        case .probable: return .orange
        case .noConfirmado: return .black
        }
    }
}
#endif
