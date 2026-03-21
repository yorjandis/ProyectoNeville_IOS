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
    @State private var showNutritionInfoSheet: Bool = false
    @State private var showHealthyEatingGuideSheet: Bool = false
    @State private var isBarcodeCardExpanded: Bool = true
    @State private var currentProductImageIndex: Int = 0
    @State private var expandedProductImage: ExpandedProductImage?
    @State private var selectedNutrientInfoTarget: NutritionScoringTarget?
    @State private var selectedPrincipalScoreInfo: PrincipalScoreInfo?
    @State private var showOfflineUpdatePrompt: Bool = false

    private let proprietaryRiskEngine = DefaultLectorEtiquetasFoodRiskScoringEngine()

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
                    Button {
                        showHealthyEatingGuideSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .help("Guía para elegir alimentos saludables")
                    .disabled(viewModel.isAnalizando)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Limpiar") {
                        barcodeInput = ""
                        isBarcodeCardExpanded = true
                        currentProductImageIndex = 0
                        expandedProductImage = nil
                        selectedNutrientInfoTarget = nil
                        selectedPrincipalScoreInfo = nil
                        expandedAditivos.removeAll()
                        viewModel.offlineNameMatches = []
                        viewModel.limpiarResultado()
                    }
                    .disabled(viewModel.isAnalizando)
                }

                if viewModel.selectedSource == .offlineSQLite, viewModel.isOfflineDatabaseReady {
                    if viewModel.hasPendingOfflineUpdate {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await viewModel.prepararBaseOffline(forceRefresh: true) }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            .help("Descargar actualización de la BD offline")
                            .disabled(viewModel.isAnalizando || viewModel.isPreparingOfflineDatabase)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Chequear BD offline", systemImage: "shippingbox") {
                                Task { await viewModel.buscar(query: barcodeInput) }
                            }
                            .disabled(barcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAnalizando)

                            Button("Buscar actualización", systemImage: "arrow.clockwise") {
                                Task {
                                    let hasUpdate = await viewModel.verificarActualizacionOffline()
                                    if hasUpdate {
                                        showOfflineUpdatePrompt = true
                                    } else {
                                        viewModel.offlineInfoMessage = "No hay una nueva versión disponible."
                                    }
                                }
                            }
                            .disabled(viewModel.isAnalizando || viewModel.isPreparingOfflineDatabase)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                barcodeScannerSheet
            }
            .sheet(isPresented: $showNutritionInfoSheet) {
                NutritionInfoSheetView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showHealthyEatingGuideSheet) {
                HealthyEatingGuideSheetView()
                    .presentationDetents([.medium])
            }
            .sheet(item: $selectedNutrientInfoTarget) { target in
                NutrientDetailSheetView(target: target)
                    .presentationDetents([.medium])
            }
            .sheet(item: $selectedPrincipalScoreInfo) { info in
                PrincipalScoreDetailSheetView(info: info)
                    .presentationDetents([.medium])
            }
            .sheet(item: $expandedProductImage, onDismiss: {
                expandedProductImage = nil
            }) { item in
                ExpandedProductImageGallerySheetView(
                    imageURLs: item.imageURLs,
                    initialIndex: item.initialIndex
                )
                .presentationDetents([.medium])
            }
            .alert("Nueva versión de BD offline disponible", isPresented: $showOfflineUpdatePrompt) {
                Button("Luego", role: .cancel) {}
                Button("Descargar ahora") {
                    Task { await viewModel.prepararBaseOffline(forceRefresh: true) }
                }
            } message: {
                let versionText = viewModel.pendingOfflineVersion.map(String.init) ?? "más reciente"
                Text("Se detectó una nueva versión (\(versionText)). ¿Quieres descargarla y verificarla ahora?")
            }
            .onChange(of: viewModel.selectedSource) { _, _ in
                clearSearchStateForModeChange()
                if viewModel.selectedSource == .offlineSQLite, viewModel.isOfflineDatabaseReady {
                    Task {
                        let hasUpdate = await viewModel.verificarActualizacionOffline()
                        if hasUpdate {
                            showOfflineUpdatePrompt = true
                        }
                    }
                }
            }
            .onChange(of: viewModel.resultado != nil) { _, hasResult in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isBarcodeCardExpanded = !hasResult
                }
                currentProductImageIndex = 0
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.96, blue: 0.86),
                Color(red: 0.66, green: 0.82, blue: 0.64),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var HeadSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack{
                Text("Inspector de Alimentos")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.black)
                
                Text("(Beta)")
                    .font(.body)
                    .foregroundStyle(.red.opacity(0.8)).bold()
                    .padding(.horizontal, 2)
            }
            
            /*
             Text("Consulta por código de barras usando API de OpenFoodFacts o base SQLite offline.")
                 .font(.system(.subheadline, design: .rounded))
                 .foregroundStyle(.black)

             Text("DEBUG · Ítems BD offline: \(viewModel.offlineItemsCount.map(String.init) ?? "N/D")")
                 .font(.system(.caption2, design: .monospaced))
                 .foregroundStyle(.black)
             */
           
        }
        .padding(.horizontal, 4)
    }

    private var barcodeCard: some View {
        let canCollapse = viewModel.resultado != nil

        return card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text("Escanear o buscar por nombre")
                        .font(.system(.headline, design: .rounded, weight: .semibold))

                    Spacer()

                    if canCollapse {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isBarcodeCardExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isBarcodeCardExpanded ? "chevron.up.circle" : "chevron.down.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.top, 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isBarcodeCardExpanded ? "Colapsar tarjeta" : "Expandir tarjeta")
                    }
                }

                if isBarcodeCardExpanded || !canCollapse {
                    Picker("", selection: $viewModel.selectedSource) {
                        ForEach(LectorEtiquetasDataSource.allCases) { source in
                            Text(source.title).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(6)
                    .background(Color.blue.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                    }

                    TextField(
                        viewModel.selectedSource == .offlineSQLite
                            ? "Código de barras o nombre de producto"
                            : "Ejemplo: 8410076475898",
                        text: $barcodeInput
                    )
                        .keyboardType(viewModel.selectedSource == .offlineSQLite ? .default : .numberPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(Color.black.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.22), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if viewModel.selectedSource == .openFoodFacts || viewModel.isOfflineDatabaseReady {
                        HStack(spacing: 10) {
                            Button {
                                Task {
                                    await viewModel.buscar(query: barcodeInput)
                                }
                            } label: {
                                Label("Buscar", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
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
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            if !viewModel.isOfflineDatabaseReady {
                                Button {
                                    Task { await viewModel.prepararBaseOffline() }
                                } label: {
                                    Label("Descargar y verificar BD offline", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(Color.indigo)
                                .disabled(viewModel.isAnalizando || viewModel.isPreparingOfflineDatabase)
                            } else {
                                if !viewModel.offlineNameMatches.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Resultados")
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                            .foregroundStyle(.secondary)
                                        ForEach(viewModel.offlineNameMatches) { match in
                                            Button {
                                                barcodeInput = match.barcode
                                                Task { await viewModel.buscar(query: match.barcode) }
                                            } label: {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(match.productName)
                                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                        .foregroundStyle(.primary)
                                                    Text("\(match.barcode)\(match.brands.map { " • \($0)" } ?? "")")
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundStyle(.secondary)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.vertical, 4)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

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
                                    .foregroundStyle(.black).bold()
                            }

                            if let errorMessage = viewModel.offlineErrorMessage {
                                Text(errorMessage)
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } else {
                    HStack{
                        Text( viewModel.selectedSource == .offlineSQLite ?   "Off-Line" : "Online")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
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
                headerSection(resultado, resumen: resumen)
                productoSection(resumen)
                ecologicoSection(resumen)
                aditivosSection(resultado)
                nutricionSection(resumen)
                
            }
        }
    }

    private func headerSection(_ resultado: ResultadoAnalisisEtiqueta, resumen: EtiquetaResumenProducto) -> some View {
        let proprietaryRisk = proprietaryRiskEngine.score(
            input: LectorEtiquetasFoodRiskScoringInput(
                hallazgos: resultado.hallazgos,
                perfilAlimentario: resumen.perfilAlimentario,
                evaluacionEcologica: resumen.evaluacionEcologica,
                nutrientesDetectados: resultado.nutrientesDetectados,
                nutrimentsFormatted: resultado.metadata?.nutrimentsFormatted ?? [],
                alergenos: resumen.alergenos,
                ingredientesDetectadosCount: resultado.ingredientesDetectados.count,
                novaGroup: resumen.novaGroup
            )
        )
        let principalScoreInfo = buildPrincipalScoreInfo(
            resultado: resultado,
            resumen: resumen,
            risk: proprietaryRisk
        )

        return card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Resultado (\(resultado.metadata?.source.title ?? "N/A"))")
                        .font(.system(.headline, design: .rounded, weight: .semibold))

                    Spacer()

                    Button {
                        selectedPrincipalScoreInfo = principalScoreInfo
                    } label: {
                        Text(proprietaryRisk.classification.title)
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(proprietaryRisk.classification.badgeColor.opacity(0.28))
                            .overlay {
                                Capsule()
                                    .stroke(proprietaryRisk.classification.badgeColor.opacity(0.55), lineWidth: 1.2)
                            }
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                            .shadow(color: proprietaryRisk.classification.badgeColor.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    headerBadge(
                        title: "Score:",
                        value: "\(proprietaryRisk.score)/100",
                        color: proprietaryRisk.classification.badgeColor
                    )

                    Spacer()

                    //Valor de Nutri Scrore
                    nutriScoreImageBadge(
                        grade: resumen.nutritionGrade,
                        action: { showNutritionInfoSheet = true }
                    )
                    .padding(.horizontal, 15)

                    headerBadge(
                        title: "NOVA",
                        value: novaBadgeValue(resumen.novaGroup),
                        color: novaGroupColor(resumen.novaGroup),
                        showsBackground: false,
                        action: { showNutritionInfoSheet = true }
                    )
                    
                }
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
                    Text("No se detectaron aditivos") // de la base additives.json
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
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(.primary)
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Producto")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                HStack(alignment: .top, spacing: 12) {
                    productImageGallery(resumen.imageURLs)
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(title: "Nombre del producto", value: resumen.nombreProducto)
                        estadoRow(title: "Vegano", value: resumen.perfilAlimentario.esVegano)
                        estadoRow(title: "Vegetariano", value: resumen.perfilAlimentario.esVegetariano)
                        estadoRow(title: "Orgánico", value: resumen.perfilAlimentario.esOrganico)
                        siNoRow(title: "Contiene gluten", value: resumen.perfilAlimentario.contieneGluten)
                    }
                }

                infoRow(title: "Código de barras", value: resumen.codigoBarras)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alergenos:")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(resumen.alergenos.isEmpty ? "No informados" : resumen.alergenos.joined(separator: ", "))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.black)
                }
            }
        }
    }

    @ViewBuilder
    private func productImageGallery(_ imageURLs: [URL]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.55))

            if imageURLs.isEmpty {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    TabView(selection: $currentProductImageIndex) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            productAsyncImage(
                                imageURL,
                                imageURLs: imageURLs,
                                index: index
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    if imageURLs.count > 1 {
                        HStack(spacing: 5) {
                            ForEach(Array(imageURLs.indices), id: \.self) { index in
                                Circle()
                                    .fill(index == currentProductImageIndex ? Color.primary.opacity(0.6) : Color.secondary.opacity(0.25))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                }
                .padding(6)
                .onChange(of: imageURLs.count) { _, newCount in
                    if currentProductImageIndex >= newCount {
                        currentProductImageIndex = 0
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func productAsyncImage(
        _ imageURL: URL,
        imageURLs: [URL],
        index: Int
    ) -> some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            expandedProductImage = ExpandedProductImage(
                imageURLs: imageURLs,
                initialIndex: index
            )
        }
    }

    private func nutricionSection(_ resumen: EtiquetaResumenProducto) -> some View {
        let nutritionEvaluation = buildNutritionEvaluation(from: resumen.nutrientesClave)
        let nutrientNameColumnWidth: CGFloat = 128

        return card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Información nutricional")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                if nutritionEvaluation.insights.isEmpty {
                    if resumen.nutrientesClave.isEmpty {
                        Text("No hay información nutricional disponible.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Información parcial: falta al menos un nutriente clave para evaluar todos los indicadores.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)

                        Divider()

                        ForEach(resumen.nutrientesClave) { nutrient in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(nutrient.titulo)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .frame(width: nutrientNameColumnWidth, alignment: .leading)

                                Text(nutrient.valor)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                } else {
                    HStack{
                        Spacer()
                        Text("Por 100g")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    

                    ForEach(nutritionEvaluation.insights) { insight in
                        Divider()

                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Button {
                                        selectedNutrientInfoTarget = insight.target
                                    } label: {
                                        Text(insight.title)
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(.primary)
                                    }
                                    .buttonStyle(.plain)

                                    Text(insight.rawValueText)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text(insight.levelDescription)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.black).bold()//insight.level.color)
                            }

                            Spacer(minLength: 8)

                            VStack(alignment: .trailing, spacing: 6) {
                                nutritionTrafficLine(markerPosition: insight.markerPosition)
                                    .frame(width: 130)
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
                        .foregroundStyle(.black)
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

    private func estadoRow(title: String, value: Bool?, isNegativeWhenTrue: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)

            if let value {
                let isPositive = isNegativeWhenTrue ? !value : value
                Text(isPositive ? "Si" : "No")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
                /*
                 Image(systemName: isPositive ? "checkmark.circle.fill" : "nosign")
                     .font(.system(size: 16, weight: .semibold))
                     .foregroundStyle(isPositive ? .green : .red)
                 */
                
            } else {
                Text("N/D")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func siNoRow(title: String, value: Bool?) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)

            if let value {
                Text(value ? "Si" : "No")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
            } else {
                Text("N/D")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func headerBadge(
        title: String,
        value: String,
        color: Color,
        showsBackground: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Group {
                if let action {
                    Button(action: action) {
                        Text(value)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(showsBackground ? color.opacity(0.15) : .clear)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(value)
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(showsBackground ? color.opacity(0.15) : .clear)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 10)
        }
    }

    private func nutriScoreImageBadge(grade: String?, action: (() -> Void)? = nil) -> some View {
        let imageName = nutriScoreAssetName(for: grade)
        return VStack(alignment: .leading, spacing: 2) {
            
            Text("")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)

            Group {
                if let action {
                    Button(action: action) {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 60)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.75))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 60)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.75))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func nutriScoreAssetName(for grade: String?) -> String {
        switch grade?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "A": return "nutriscore_a"
        case "B": return "nutriscore_b"
        case "C": return "nutriscore_c"
        case "D": return "nutriscore_d"
        default: return "nutriscore_nd"
        }
    }

    private func nutritionGradeColor(_ grade: String?) -> Color {
        switch grade?.uppercased() {
        case "A", "B": return .green
        case "C": return .orange
        case "D", "E": return .red
        default: return .secondary
        }
    }

    private func novaGroupColor(_ group: Int?) -> Color {
        switch group {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .secondary
        }
    }

    private func novaBadgeValue(_ group: Int?) -> String {
        switch group {
        case 1: return "1️⃣"
        case 2: return "2️⃣"
        case 3: return "3️⃣"
        case 4: return "4️⃣"
        default: return "N/D"
        }
    }

    private func buildNutritionEvaluation(from nutrients: [EtiquetaNutrienteClave]) -> NutritionEvaluation {
        let byID = Dictionary(uniqueKeysWithValues: nutrients.map { ($0.id, $0) })

        let proteinGrams = byID[NutritionScoringTarget.proteinas.id].flatMap { extractGrams(from: $0.valor) }
        let calories = byID[NutritionScoringTarget.valorEnergetico.id].flatMap { extractEnergyKcal(from: $0.valor) }

        let insights: [NutritionInsight] = [
            makeProteinNutritionInsight(
                title: byID[NutritionScoringTarget.proteinas.id]?.titulo ?? "Proteína",
                rawValueText: byID[NutritionScoringTarget.proteinas.id]?.valor ?? "N/D",
                proteinGrams: proteinGrams,
                calories: calories
            ),
            makeNutritionInsight(
                target: .grasasSaturadas,
                title: byID[NutritionScoringTarget.grasasSaturadas.id]?.titulo ?? "Grasas saturadas",
                rawValueText: byID[NutritionScoringTarget.grasasSaturadas.id]?.valor ?? "N/D",
                value: byID[NutritionScoringTarget.grasasSaturadas.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .fibra,
                title: byID[NutritionScoringTarget.fibra.id]?.titulo ?? "Fibra",
                rawValueText: byID[NutritionScoringTarget.fibra.id]?.valor ?? "N/D",
                value: byID[NutritionScoringTarget.fibra.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .azucar,
                title: byID[NutritionScoringTarget.azucar.id]?.titulo ?? "Azúcar",
                rawValueText: byID[NutritionScoringTarget.azucar.id]?.valor ?? "N/D",
                value: byID[NutritionScoringTarget.azucar.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .sal,
                title: byID[NutritionScoringTarget.sal.id]?.titulo ?? "Sal",
                rawValueText: byID[NutritionScoringTarget.sal.id]?.valor ?? "N/D",
                value: byID[NutritionScoringTarget.sal.id].flatMap { extractGrams(from: $0.valor) }
            ),
            makeNutritionInsight(
                target: .valorEnergetico,
                title: byID[NutritionScoringTarget.valorEnergetico.id]?.titulo ?? "Valor calórico",
                rawValueText: byID[NutritionScoringTarget.valorEnergetico.id]?.valor ?? "N/D",
                value: calories
            )
        ]
        .compactMap { $0 }

        return NutritionEvaluation(insights: insights)
    }

    private func makeProteinNutritionInsight(
        title: String,
        rawValueText: String,
        proteinGrams: Double?,
        calories: Double?
    ) -> NutritionInsight? {
        guard let proteinGrams else { return nil }

        let safeCalories = calories ?? 0
        let level = classifyProteinLevelByEnergyPercentage(proteinGrams: proteinGrams, calories: safeCalories)
        let markerPosition = proteinMarkerPosition(proteinGrams: proteinGrams)

        return NutritionInsight(
            id: NutritionScoringTarget.proteinas.id,
            target: .proteinas,
            title: title,
            rawValueText: rawValueText,
            level: level,
            markerPosition: markerPosition,
            levelDescription: nutrientLevelDescription(level: level, target: .proteinas)
        )
    }

    private func makeNutritionInsight(
        target: NutritionScoringTarget,
        title: String,
        rawValueText: String,
        value: Double?
    ) -> NutritionInsight? {
        guard let value else { return nil }

        let level = nutrientConcentrationLevel(for: value, target: target)
        return NutritionInsight(
            id: target.id,
            target: target,
            title: title,
            rawValueText: rawValueText,
            level: level,
            markerPosition: nutrientMarkerPosition(for: value, target: target),
            levelDescription: nutrientLevelDescription(level: level, target: target)
        )
    }

    private func nutritionTrafficLine(markerPosition: CGFloat) -> some View {
        GeometryReader { proxy in
            let markerX = markerPosition * proxy.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.18, green: 0.72, blue: 0.34), location: 0.00),
                                .init(color: Color(red: 0.43, green: 0.80, blue: 0.27), location: 0.24),
                                .init(color: Color(red: 0.95, green: 0.82, blue: 0.22), location: 0.50),
                                .init(color: Color(red: 0.94, green: 0.57, blue: 0.17), location: 0.76),
                                .init(color: Color(red: 0.88, green: 0.30, blue: 0.19), location: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)
                    .overlay {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .blur(radius: 1.2)
                            .padding(.horizontal, 1)
                    }

                Circle()
                    .fill(Color.gray)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    }
                    .offset(x: max(0, min(proxy.size.width - 14, markerX - 7)))
            }
        }
        .frame(height: 14)
    }

    private func nutrientConcentrationLevel(for value: Double, target: NutritionScoringTarget) -> NutritionConcentrationLevel {
        let config = nutrientDialConfig(for: target)
        if value <= config.lowUpperBound {
            return .baja
        }
        if value <= config.mediumUpperBound {
            return .media
        }
        return .alta
    }

    // Clasificación pura y reusable: porcentaje de energía aportada por proteína.
    private func classifyProteinLevelByEnergyPercentage(
        proteinGrams: Double,
        calories: Double
    ) -> NutritionConcentrationLevel {
        guard let proteinEnergyPct = proteinEnergyPercentage(proteinGrams: proteinGrams, calories: calories) else {
            return .baja
        }

        if proteinEnergyPct < 12 {
            return .baja
        }
        if proteinEnergyPct < 20 {
            return .media
        }
        return .alta
    }

    private func proteinEnergyPercentage(proteinGrams: Double, calories: Double) -> Double? {
        guard calories > 0 else { return nil }
        return (proteinGrams * 4 / calories) * 100
    }

    private func proteinMarkerPosition(proteinGrams: Double) -> CGFloat {
        let config = nutrientDialConfig(for: .proteinas)
        return markerPosition(for: proteinGrams, config: config)
    }

    private func nutrientMarkerPosition(for value: Double, target: NutritionScoringTarget) -> CGFloat {
        let config = nutrientDialConfig(for: target)
        return markerPosition(for: value, config: config)
    }

    private func markerPosition(for value: Double, config: NutritionDialConfig) -> CGFloat {
        let clampedValue = max(0, min(value, config.maxReference))
        let normalized = clampedValue / config.maxReference
        let oriented = config.higherIsBetter ? (1 - normalized) : normalized
        return CGFloat((oriented * 0.92) + 0.04)
    }

    private func nutrientLevelDescription(level: NutritionConcentrationLevel, target: NutritionScoringTarget) -> String {
        if target == .fibra {
            switch level {
            case .baja: return "Fibra escasa"
            case .media: return "Buena fuente de fibra"
            case .alta: return "Alta en fibra"
            }
        }

        if target == .proteinas {
            switch level {
            case .baja: return "Aporte proteico bajo"
            case .media: return "Aporte proteico medio"
            case .alta: return "Aporte proteico alto"
            }
        }

        switch level {
        case .media:
            return "Concentración media"
        case .baja:
            return nutrientDialConfig(for: target).higherIsBetter ? "Concentración baja (a mejorar)" : "Concentración baja (favorable)"
        case .alta:
            return nutrientDialConfig(for: target).higherIsBetter ? "Concentración alta (favorable)" : "Concentración alta (a vigilar)"
        }
    }

    private func nutrientDialConfig(for target: NutritionScoringTarget) -> NutritionDialConfig {
        switch target {
        case .proteinas:
            return NutritionDialConfig(lowUpperBound: 5, mediumUpperBound: 10, maxReference: 30, higherIsBetter: false)
        case .fibra:
            return NutritionDialConfig(lowUpperBound: 3, mediumUpperBound: 6, maxReference: 20, higherIsBetter: false)
        case .grasasSaturadas:
            return NutritionDialConfig(lowUpperBound: 1.5, mediumUpperBound: 5, maxReference: 15, higherIsBetter: false)
        case .azucar:
            return NutritionDialConfig(lowUpperBound: 5, mediumUpperBound: 22.5, maxReference: 50, higherIsBetter: false)
        case .sal:
            return NutritionDialConfig(lowUpperBound: 0.3, mediumUpperBound: 1.5, maxReference: 3, higherIsBetter: false)
        case .valorEnergetico:
            return NutritionDialConfig(lowUpperBound: 120, mediumUpperBound: 225, maxReference: 500, higherIsBetter: false)
        }
    }

    private func extractEnergyKcal(from rawValue: String) -> Double? {
        guard let numericValue = firstNumericValue(in: rawValue) else { return nil }
        let normalized = normalizeNutrientText(rawValue)
        if normalized.contains("kj") && !normalized.contains("kcal") {
            return numericValue / 4.184
        }
        return numericValue
    }

    private func extractGrams(from rawValue: String) -> Double? {
        guard let numericValue = firstNumericValue(in: rawValue) else { return nil }
        let normalized = normalizeNutrientText(rawValue)
        if normalized.contains("mg") {
            return numericValue / 1000
        }
        return numericValue
    }

    private func firstNumericValue(in rawValue: String) -> Double? {
        let pattern = #"-?\d+(?:[.,]\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(rawValue.startIndex..<rawValue.endIndex, in: rawValue)
        guard let match = regex.firstMatch(in: rawValue, range: range),
              let matchRange = Range(match.range, in: rawValue) else { return nil }

        let token = rawValue[matchRange].replacingOccurrences(of: ",", with: ".")
        return Double(token)
    }

    private func normalizeNutrientText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.black)
            .background(Color(red: 0.97, green: 0.99, blue: 0.96).opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0.74, green: 0.86, blue: 0.74).opacity(0.55), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func aditivoIdentifier(_ aditivo: HallazgoRiesgoEtiqueta) -> String {
        "\(aditivo.titulo)|\(aditivo.detalle)"
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

    private func buildPrincipalScoreInfo(
        resultado: ResultadoAnalisisEtiqueta,
        resumen: EtiquetaResumenProducto,
        risk: LectorEtiquetasFoodRiskScoreResult
    ) -> PrincipalScoreInfo {
        var criteria: [String] = []

        criteria.append("Analizamos \(risk.criteriosEvaluados) criterios y hubo \(risk.criteriosSinDatos) sin datos suficientes.")

        let aditivos = resultado.hallazgos.filter { $0.categoria == .aditivoDeRiesgo }
        let highOrCriticalCount = aditivos.filter { $0.nivel == .alto || $0.nivel == .critico }.count
        let mediumCount = aditivos.filter { $0.nivel == .medio }.count
        let hasAdditiveRiskAtOrAboveMedium = mediumCount > 0 || highOrCriticalCount > 0

        let inferredContainsGluten: Bool? = {
            if let contains = resumen.perfilAlimentario.contieneGluten { return contains }
            if resultado.hallazgos.contains(where: { $0.categoria == .indicioGluten }) { return true }
            if containsGlutenKeyword(in: resumen.alergenos) { return true }
            return nil
        }()

        let isOrganic = resumen.perfilAlimentario.esOrganico

        if let novaGroup = resumen.novaGroup,
           (1...2).contains(novaGroup),
           !hasAdditiveRiskAtOrAboveMedium {
            let novaDescription = novaGroup == 1 ? "alimento sin procesar o mínimamente procesado (NOVA 1)" : "alimento mínimamente procesado (NOVA 2)"
            criteria.append("Se aplicó una regla prioritaria porque es un \(novaDescription).")
            criteria.append("No contiene aditivos de riesgo medio, alto o crítico.")

            if let inferredContainsGluten {
                criteria.append("Gluten: \(inferredContainsGluten ? "presente" : "no detectado").")
            } else {
                criteria.append("Gluten: sin dato concluyente.")
            }

            if let isOrganic {
                criteria.append(isOrganic ? "Se declara como orgánico." : "No se declara como orgánico.")
            } else {
                criteria.append("Orgánico: sin dato disponible.")
            }

            let overrideClassification: LectorEtiquetasFoodRiskClassification = (
                inferredContainsGluten == false && isOrganic == true
            ) ? .excelente : .bueno

            criteria.append("Por esta combinación, la calificación final es \(overrideClassification.title).")

            return PrincipalScoreInfo(
                title: risk.classification.title,
                scoreText: "\(risk.score)/100",
                criteria: criteria
            )
        }

        if highOrCriticalCount >= 1 || mediumCount >= 3 {
            criteria.append("Contiene aditivos de mayor o moderado riesgo (al menos 1 alto/crítico o 3 medios), por eso aplica penalización máxima.")
        } else if aditivos.isEmpty {
            criteria.append("No se detectaron aditivos de riesgo relevantes.")
        } else {
            criteria.append("Se detectaron \(aditivos.count) aditivos, pero sin llegar al umbral de penalización máxima (medios: \(mediumCount), altos/críticos: \(highOrCriticalCount)).")
        }

        if let esOrganico = resumen.perfilAlimentario.esOrganico {
            criteria.append(esOrganico ? "El producto se declara como orgánico." : "El producto no se declara como orgánico.")
        } else {
            criteria.append("No hay dato directo de orgánico; usamos señales ecológicas y el resultado fue: \(resumen.evaluacionEcologica.estado.titulo.lowercased()).")
        }

        if let contieneGluten = resumen.perfilAlimentario.contieneGluten {
            criteria.append("Gluten: \(contieneGluten ? "presente" : "no detectado") según la información del producto.")
        } else if let glutenFinding = resultado.hallazgos
            .filter({ $0.categoria == .indicioGluten })
            .max(by: { $0.nivel.rawValue < $1.nivel.rawValue }) {
            criteria.append("Gluten: se encontraron indicios \(glutenFinding.nivel.badgeText.lowercased()) en ingredientes.")
        } else if containsGlutenKeyword(in: resumen.alergenos) {
            criteria.append("Gluten: aparece en la sección de alérgenos del producto.")
        } else {
            criteria.append("Gluten: no hay evidencia clara; se aplica una evaluación conservadora.")
        }

        if let sugar = highestFindingLevel(in: resultado.hallazgos, categories: [.excesoAzucar]) {
            criteria.append("Azúcar: nivel \(sugar.badgeText.lowercased()), lo que impacta negativamente el score.")
        }
        if let salt = highestFindingLevel(in: resultado.hallazgos, categories: [.excesoSal, .sodioElevado]) {
            criteria.append("Sal/Sodio: nivel \(salt.badgeText.lowercased()), considerado en la puntuación final.")
        }
        if let satFat = highestFindingLevel(in: resultado.hallazgos, categories: [.excesoGrasaSaturada]) {
            criteria.append("Grasa saturada: nivel \(satFat.badgeText.lowercased()), con efecto en la calificación.")
        }

        return PrincipalScoreInfo(
            title: risk.classification.title,
            scoreText: "\(risk.score)/100",
            criteria: criteria
        )
    }

    private func highestFindingLevel(
        in hallazgos: [HallazgoRiesgoEtiqueta],
        categories: [CategoriaRiesgoEtiqueta]
    ) -> NivelRiesgoEtiqueta? {
        hallazgos
            .filter { categories.contains($0.categoria) }
            .map(\.nivel)
            .max()
    }

    private func containsGlutenKeyword(in allergens: [String]) -> Bool {
        let markers = ["gluten", "trigo", "wheat", "cebada", "barley", "centeno", "rye", "espelta", "spelt"]
        return allergens.contains { allergen in
            let normalized = allergen.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
            return markers.contains(where: { normalized.contains($0) })
        }
    }

    private func boolText(_ value: Bool?) -> String {
        guard let value else { return "No disponible" }
        return value ? "Sí" : "No"
    }

    private func clearSearchStateForModeChange() {
        barcodeInput = ""
        isBarcodeCardExpanded = true
        currentProductImageIndex = 0
        expandedProductImage = nil
        selectedNutrientInfoTarget = nil
        selectedPrincipalScoreInfo = nil
        showOfflineUpdatePrompt = false
        expandedAditivos.removeAll()
        viewModel.offlineNameMatches = []
        viewModel.limpiarResultado()
    }

    private var barcodeScannerSheet: some View {
        CodeScannerView(codeTypes: [.ean8, .ean13, .upce, .code128]) { result in
            switch result {
            case .success(let scan):
                let code = scan.string.trimmingCharacters(in: .whitespacesAndNewlines)
                barcodeInput = code
                Task {
                    await viewModel.buscar(query: code)
                }
            case .failure:
                viewModel.errorMessage = "No se pudo leer el código de barras."
            }
        }
        .ignoresSafeArea()
    }
}

private struct NutritionInfoSheetView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cómo interpretar Nutrition Grade y NOVA")
                    .font(.title3.bold())

                Text("Nutrition Grade (A-E)")
                    .font(.headline)
                Text("Resume la calidad nutricional global del producto. A es mejor perfil nutricional y E es el menos favorable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Interpretación rápida:")
                    .font(.subheadline.bold())
                Text("A/B: favorable • C: intermedio • D/E: menos favorable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Text("NOVA (1-4)")
                    .font(.headline)
                Text("Clasifica el nivel de procesamiento del alimento.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Interpretación rápida:")
                    .font(.subheadline.bold())
                Text("1: mínimamente procesado • 2: ingrediente culinario • 3: procesado • 4: ultraprocesado")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

private struct HealthyEatingGuideSheetView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Guía rápida de alimentación saludable")
                    .font(.title3.bold())

                Text("Cómo elegir mejor")
                    .font(.headline)
                Text("Prioriza alimentos frescos o mínimamente procesados (NOVA 1-2), listas cortas de ingredientes y pocos aditivos de riesgo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Cómo leer una etiqueta")
                    .font(.headline)
                Text("1) Mira el procesamiento (NOVA). 2) Revisa azúcar, sal y grasas saturadas por 100 g. 3) Verifica fibra y proteína. 4) Si tienes sensibilidad, confirma alérgenos (por ejemplo gluten).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Hábitos saludables (pros)")
                    .font(.headline)
                Text("Mejor energía diaria, mayor saciedad, mejor salud digestiva y metabólica, y menor riesgo cardiovascular a largo plazo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Hábitos nocivos (contras)")
                    .font(.headline)
                Text("Exceso frecuente de ultraprocesados, azúcar, sal y grasas saturadas puede aumentar fatiga, apetito desregulado y riesgo de enfermedades crónicas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

private struct NutrientDetailSheetView: View {
    let target: NutritionScoringTarget

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(target.infoTitle)
                    .font(.title3.bold())

                Text("Función")
                    .font(.headline)
                Text(target.functionSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Concentración y salud")
                    .font(.headline)
                Text(target.concentrationSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Cantidad recomendada")
                    .font(.headline)
                Text(target.recommendedAmountSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

private struct PrincipalScoreDetailSheetView: View {
    let info: PrincipalScoreInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Score principal")
                    .font(.title3.bold())

                Text("Resultado: \(info.title) (\(info.scoreText))")
                    .font(.headline)

                Text("Criterios aplicados")
                    .font(.headline)

                ForEach(Array(info.criteria.enumerated()), id: \.offset) { _, item in
                    Text("• \(item)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

private struct PrincipalScoreInfo: Identifiable {
    let id = UUID()
    let title: String
    let scoreText: String
    let criteria: [String]
}

private struct ExpandedProductImage: Identifiable {
    let id = UUID()
    let imageURLs: [URL]
    let initialIndex: Int
}

private struct ExpandedProductImageGallerySheetView: View {
    let imageURLs: [URL]
    let initialIndex: Int

    @State private var currentIndex: Int

    init(imageURLs: [URL], initialIndex: Int) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: max(0, min(initialIndex, max(0, imageURLs.count - 1))))
    }

    var body: some View {
        VStack(spacing: 10) {
            if imageURLs.isEmpty {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if imageURLs.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(Array(imageURLs.indices), id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.primary.opacity(0.7) : Color.secondary.opacity(0.25))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

private struct NutritionEvaluation {
    let insights: [NutritionInsight]
}

private struct NutritionInsight: Identifiable {
    let id: String
    let target: NutritionScoringTarget
    let title: String
    let rawValueText: String
    let level: NutritionConcentrationLevel
    let markerPosition: CGFloat
    let levelDescription: String
}

private enum NutritionConcentrationLevel {
    case baja
    case media
    case alta
}

private struct NutritionDialConfig {
    let lowUpperBound: Double
    let mediumUpperBound: Double
    let maxReference: Double
    let higherIsBetter: Bool
}

private enum NutritionScoringTarget: CaseIterable, Identifiable {
    case proteinas
    case fibra
    case grasasSaturadas
    case azucar
    case sal
    case valorEnergetico

    var id: String {
        switch self {
        case .proteinas: return "proteinas"
        case .fibra: return "fibra"
        case .grasasSaturadas: return "grasas_saturadas"
        case .azucar: return "azucar"
        case .sal: return "sal"
        case .valorEnergetico: return "valor_energetico"
        }
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

private extension LectorEtiquetasFoodRiskClassification {
    var badgeColor: Color {
        switch self {
        case .excelente: return .green
        case .bueno: return .orange
        case .malo: return .red
        case .informacionInsuficiente: return .yellow
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

private extension NutritionScoringTarget {
    var infoTitle: String {
        switch self {
        case .proteinas: return "Proteínas"
        case .fibra: return "Fibra"
        case .grasasSaturadas: return "Grasas saturadas"
        case .azucar: return "Azúcar"
        case .sal: return "Sal"
        case .valorEnergetico: return "Valor calórico"
        }
    }

    var functionSummary: String {
        switch self {
        case .proteinas:
            return "Ayudan a reparar y mantener músculo, piel, enzimas y hormonas."
        case .fibra:
            return "Mejora el tránsito intestinal, la saciedad y el control de glucosa."
        case .grasasSaturadas:
            return "Aportan energía, pero no son esenciales frente a grasas insaturadas."
        case .azucar:
            return "Fuente rápida de energía; el exceso desplaza nutrientes de mejor calidad."
        case .sal:
            return "Necesaria en pequeñas cantidades para equilibrio hídrico y función nerviosa."
        case .valorEnergetico:
            return "Representa la energía total del alimento para cubrir requerimientos diarios."
        }
    }

    var concentrationSummary: String {
        switch self {
        case .proteinas:
            return "Un aporte adecuado favorece masa muscular y saciedad. Muy bajo puede ser insuficiente según contexto dietético."
        case .fibra:
            return "Concentración baja suele asociarse a menor saciedad y peor salud digestiva. Buena o alta favorece salud metabólica e intestinal."
        case .grasasSaturadas:
            return "Concentraciones altas y frecuentes se asocian a mayor riesgo cardiovascular. Conviene priorizar niveles bajos o moderados."
        case .azucar:
            return "Concentraciones altas aumentan carga glucémica y exceso calórico. Se recomienda mantenerla baja, especialmente en ultraprocesados."
        case .sal:
            return "Concentraciones altas elevan riesgo de hipertensión en consumo habitual. Es preferible una concentración baja."
        case .valorEnergetico:
            return "Mayor densidad energética facilita exceder calorías si la porción no se controla; depende del patrón global de alimentación."
        }
    }

    var recommendedAmountSummary: String {
        switch self {
        case .proteinas:
            return "Adultos: ~0.8 g/kg/día como mínimo (aprox. 10-35% de la energía diaria)."
        case .fibra:
            return "Objetivo general: 14 g por cada 1000 kcal (aprox. 25-38 g/día en adultos)."
        case .grasasSaturadas:
            return "Limitar a <10% de las calorías diarias; idealmente sustituir por grasas insaturadas."
        case .azucar:
            return "Azúcares libres/añadidos: <10% de las calorías; idealmente <5% si es posible."
        case .sal:
            return "Límite recomendado: <5 g de sal al día (≈2 g de sodio)."
        case .valorEnergetico:
            return "Depende de edad, sexo y actividad. Referencia habitual en etiquetado: ~2000 kcal/día."
        }
    }
}
#endif
