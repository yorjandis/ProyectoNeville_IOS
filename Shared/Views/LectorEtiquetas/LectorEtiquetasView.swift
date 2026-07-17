//
//  LectorEtiquetasView.swift
//  Neville_iOS
//
//  Created by Codex on 12/03/26.
//

import SwiftUI

#if os(iOS)
import AVFoundation

private enum LectorEtiquetasPetLayout {
    /// Ajustes manuales de la mascota flotante del lector de etiquetas.
    static let assetName = "mascota_comiendo"
    static let size: CGFloat = 200
    static let offset = CGSize(width: 0, height: 5)
}

struct LectorEtiquetasView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LectorEtiquetasViewModel()

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage(PetSettings.isEnabledKey) private var petsEnabled = true

    @State private var barcodeInput: String = ""
    @State private var showBarcodeScanner: Bool = false
    @State private var expandedAditivos: Set<String> = []
    @State private var showNutritionInfoSheet: Bool = false
    @State private var showHealthyEatingGuideSheet: Bool = false
    @State private var showLabelInterpretationSheet: Bool = false
    @State private var isBarcodeCardExpanded: Bool = true
    @State private var currentProductImageIndex: Int = 0
    @State private var expandedProductImage: ExpandedProductImage?
    @State private var selectedNutrientInfoTarget: NutritionScoringTarget?
    @State private var selectedPrincipalScoreInfo: PrincipalScoreInfo?
    @State private var selectedNutritionConsumptionWarning: NutritionConsumptionWarning?
    @State private var showOfflineUpdatePrompt: Bool = false

    private let proprietaryRiskEngine = DefaultLectorEtiquetasFoodRiskScoringEngine()

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    var body: some View {
        NavigationStack {
            if hasPremiumAccess {
                ZStack {
                    backgroundGradient
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HeadSection
                            barcodeCard
                            statusSection
                            resultadoSection
                            disclaimerSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
                .overlay(alignment: .bottom) {
                    if petsEnabled {
                        PetImage(assetName: LectorEtiquetasPetLayout.assetName)
                            .frame(
                                width: LectorEtiquetasPetLayout.size,
                                height: LectorEtiquetasPetLayout.size
                            )
                            .offset(LectorEtiquetasPetLayout.offset)
                            .opacity(viewModel.resultado == nil ? 1 : 0)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.resultado != nil)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
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

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed)
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
                                Button("Comprobar BD offline", systemImage: "shippingbox") {
                                    Task { await viewModel.buscar(query: barcodeInput) }
                                }
                                .disabled(barcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAnalizando)

                                Button("Buscar actualización", systemImage: "arrow.clockwise") {
                                    Task {
                                        let hasUpdate = await viewModel.verificarActualizacionOffline()
                                        if hasUpdate {
                                            showOfflineUpdatePrompt = true
                                        } else {
                                            viewModel.offlineInfoMessage = L10n.exact("No hay una nueva versión disponible.")
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
                .sheet(isPresented: $showLabelInterpretationSheet) {
                    LabelInterpretationSheetView()
                        .presentationDetents([.medium, .large])
                }
                .sheet(item: $selectedNutrientInfoTarget) { target in
                    NutrientDetailSheetView(target: target)
                        .presentationDetents([.medium])
                }
                .sheet(item: $selectedPrincipalScoreInfo) { info in
                    PrincipalScoreDetailSheetView(info: info)
                        .presentationDetents([.medium])
                }
                .sheet(item: $selectedNutritionConsumptionWarning) { warning in
                    NutritionConsumptionWarningSheetView(warning: warning)
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
                    let versionText = viewModel.pendingOfflineVersion.map(String.init) ?? L10n.exact("más reciente")
                    Text(L10n.format(
                        "label_reader.offline.update_prompt",
                        fallback: "Se detectó una nueva versión ({0}). ¿Quieres descargarla y verificarla ahora?",
                        versionText
                    ))
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
                .overlay(alignment: .bottomTrailing) {
                    floatingScanButton
                        .offset(y : -100)
                }
            } else {
                PurchaseView()
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
                        .accessibilityLabel(L10n.exact(isBarcodeCardExpanded ? "Colapsar tarjeta" : "Expandir tarjeta"))
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
                        L10n.exact(viewModel.selectedSource == .offlineSQLite
                            ? "Código de barras o nombre de producto"
                            : "Ejemplo: 8410076475898"),
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
                                handleScanButtonTapped()
                            } label: {
                                Label("Escanear", systemImage: "barcode.viewfinder")
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
                                Text("Primero descarga la BD offline para habilitar escaneo y búsqueda.")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            if viewModel.isPreparingOfflineDatabase {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProgressView("Preparando base SQLite offline...")
                                        .font(.system(.footnote, design: .rounded))

                                    ProgressView()
                                        .progressViewStyle(.linear)
                                }
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
                        Text(L10n.exact(viewModel.selectedSource == .offlineSQLite ? "Off-Line" : "Online"))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            handleScanButtonTapped()
                        } label: {
                            Label("Escanear", systemImage: "barcode.viewfinder")
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
    private var floatingScanButton: some View {
        if canShowScanButton {
            Group {
                if #available(iOS 26.0, *) {
                    Button {
                        handleScanButtonTapped()
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 36, height: 36   )
                    }
                    .buttonStyle(.glass(.regular.tint(.white.opacity(0.18)).interactive()))
                } else {
                    Button {
                        handleScanButtonTapped()
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .disabled(viewModel.isAnalizando)
            .accessibilityLabel("Escanear")
        }
    }

    private var canShowScanButton: Bool {
        viewModel.selectedSource == .openFoodFacts || viewModel.isOfflineDatabaseReady
    }

    private func handleScanButtonTapped() {
        showBarcodeScanner = true
    }

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.isAnalizando {
            card {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(L10n.exact(
                        viewModel.selectedSource == .offlineSQLite
                            ? "Consultando base SQLite offline..."
                            : "Consultando OpenFoodFacts..."
                    ))
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

    private var disclaimerSection: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Label("Nota Importante", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.blue)

                Text("Esta información es solo orientativa y no definitiva ni concluyente. Puede variar en futuras actualizaciones.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("Lee siempre la etiqueta del producto.")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)

                Button {
                    showLabelInterpretationSheet = true
                } label: {
                    Label("Cómo leer la etiqueta de un producto", systemImage: "book.pages")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
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
                    Text(L10n.format(
                        "label_reader.result.source",
                        fallback: "Resultado ({0})",
                        resultado.metadata?.source.title ?? L10n.exact("N/D")
                    ))
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
                HStack{
                    Text("Aditivos detectados")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Spacer()
                    if aditivos.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if aditivos.isEmpty {
                    Text("No se detectaron aditivos") // de la base additives.json
                        .font(.system(.body, design: .rounded))
                        .bold()
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
                                            Text(L10n.format(
                                                "label_reader.additive.toxicity",
                                                fallback: "Toxicidad: {0}",
                                                L10n.exact(toxicidad.capitalized)
                                            ))
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
                    Text("Alérgenos:")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(resumen.alergenos.isEmpty
                         ? L10n.exact("No informados")
                         : resumen.alergenos.joined(separator: ", "))
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
                        Text("Por 100 g")
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

                                if let warning = consumptionWarning(for: insight) {
                                    Button {
                                        selectedNutritionConsumptionWarning = warning
                                    } label: {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(L10n.format(
                                        "label_reader.nutrition.consumption_warning_accessibility",
                                        fallback: "Ver advertencia de consumo para {0}",
                                        insight.title
                                    ))
                                }
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

    private func consumptionWarning(for insight: NutritionInsight) -> NutritionConsumptionWarning? {
        let grams = extractGrams(from: insight.rawValueText)

        switch insight.target {
        case .azucar:
            guard let grams else { return nil }
            if grams > 15 {
                return NutritionConsumptionWarning(
                    nutrientTitle: insight.title,
                    valueText: insight.rawValueText,
                    warningText: L10n.exact("Azúcar mayor de 15 g por 100 g: se recomienda evitar su consumo por su mayor impacto metabólico.")
                )
            }
            if grams >= 5 {
                return NutritionConsumptionWarning(
                    nutrientTitle: insight.title,
                    valueText: insight.rawValueText,
                    warningText: L10n.exact("Azúcar entre 5 g y 15 g por 100 g: se recomienda moderar su consumo en grandes cantidades o con frecuencia.")
                )
            }
            return nil
        case .grasasSaturadas:
            guard let grams, grams >= 5 else { return nil }
            return NutritionConsumptionWarning(
                nutrientTitle: insight.title,
                valueText: insight.rawValueText,
                warningText: L10n.exact("Grasas saturadas iguales o mayores a 5 g por 100 g: se aconseja regular su consumo habitual por mayor riesgo cardiovascular.")
            )
        case .sal:
            guard let grams, grams > 1.5 else { return nil }
            return NutritionConsumptionWarning(
                nutrientTitle: insight.title,
                valueText: insight.rawValueText,
                warningText: L10n.exact("Sal mayor de 1.5 g por 100 g: se recomienda vigilar su consumo y no exceder 5 g de sal al día, salvo pérdida elevada por sudoración excesiva.")
            )
        default:
            return nil
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.exact(title))
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    private func estadoRow(title: String, value: Bool?, isNegativeWhenTrue: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(L10n.exact(title))
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)

            if let value {
                let isPositive = isNegativeWhenTrue ? !value : value
                Text(L10n.exact(isPositive ? "Sí" : "No"))
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
                /*
                 Image(systemName: isPositive ? "checkmark.circle.fill" : "nosign")
                     .font(.system(size: 16, weight: .semibold))
                     .foregroundStyle(isPositive ? .green : .red)
                 */
                
            } else {
                Text(L10n.exact("N/D"))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func siNoRow(title: String, value: Bool?) -> some View {
        HStack(spacing: 8) {
            Text(L10n.exact(title))
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)

            if let value {
                Text(L10n.exact(value ? "Sí" : "No"))
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
            } else {
                Text(L10n.exact("N/D"))
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
            Text(L10n.exact(title))
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


    private func toggleAditivo(_ id: String) {
        if expandedAditivos.contains(id) {
            expandedAditivos.remove(id)
        } else {
            expandedAditivos.insert(id)
        }
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

    private func clearFieldsBeforeScanAttempt() {
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

    private var barcodeScannerSheet: some View {
        CodeScannerView(codeTypes: [.ean8, .ean13, .upce, .code128]) { result in
            clearFieldsBeforeScanAttempt()

            switch result {
            case .success(let scan):
                let code = scan.string.trimmingCharacters(in: .whitespacesAndNewlines)
                barcodeInput = code
                Task {
                    await viewModel.buscar(query: code)
                }
            case .failure:
                viewModel.errorMessage = L10n.exact("No se pudo leer el código de barras.")
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
                    .font(.body)
                Text("Prioriza alimentos frescos o mínimamente procesados (NOVA 1-2), listas cortas de ingredientes y pocos aditivos de riesgo.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Cómo leer una etiqueta")
                    .font(.body)
                Text("1) Mira el procesamiento (NOVA). 2) Revisa azúcar, sal y grasas saturadas por 100 g. 3) Verifica fibra y proteína. 4) Si tienes sensibilidad, confirma alérgenos (por ejemplo gluten). 5) Revisa presencia de aditivos.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Exceso frecuente de ultraprocesados, azúcar, sal y grasas saturadas puede aumentar fatiga, apetito desregulado y riesgo de enfermedades crónicas.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

private struct LabelInterpretationSheetView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack{
                    Text("Cómo leer la etiqueta")
                        .font(.title3.bold())
                    Text("💡")
                        .font(.title3.bold())
                }

                Text("Empieza por el tamaño de porción y revisa también los valores por 100 g o 100 ml para comparar productos de forma justa. Un alimento puede parecer ligero por porción, pero resultar alto en azúcar, sal o grasa al mirar la referencia estándar.")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Después observa la lista de ingredientes en orden de cantidad: los primeros son los que más aporta el producto. Si aparecen azúcares añadidos, harinas refinadas o varios aditivos en los primeros lugares, suele indicar mayor procesamiento y menor calidad nutricional global.")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Por último, interpreta el conjunto: combinación de nutrientes críticos (azúcar, sodio, grasas saturadas), fibra, proteína y nivel de procesamiento (NOVA), junto con alérgenos si tienes sensibilidad. \n\nUtiliza esta herramienta como orientación inicial y confirma siempre en la etiqueta física del envase, antes de decidir su consumo.")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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

                Text(L10n.format(
                    "label_reader.score.result",
                    fallback: "Resultado: {0} ({1})",
                    info.title,
                    info.scoreText
                ))
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

struct PrincipalScoreInfo: Identifiable {
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

private struct NutritionConsumptionWarning: Identifiable {
    let id = UUID()
    let nutrientTitle: String
    let valueText: String
    let warningText: String
}

private struct NutritionConsumptionWarningSheetView: View {
    let warning: NutritionConsumptionWarning

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Advertencia de consumo", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.red)

                Text(warning.nutrientTitle)
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                Text(L10n.format(
                    "label_reader.nutrition.reported_value",
                    fallback: "Valor reportado: {0} por 100 g",
                    warning.valueText
                ))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(warning.warningText)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding()
        }
    }
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

struct NutritionEvaluation {
    let insights: [NutritionInsight]
}

struct NutritionInsight: Identifiable {
    let id: String
    let target: NutritionScoringTarget
    let title: String
    let rawValueText: String
    let level: NutritionConcentrationLevel
    let markerPosition: CGFloat
    let levelDescription: String
}

enum NutritionConcentrationLevel {
    case baja
    case media
    case alta
}

struct NutritionDialConfig {
    let lowUpperBound: Double
    let mediumUpperBound: Double
    let maxReference: Double
    let higherIsBetter: Bool
}

enum NutritionScoringTarget: CaseIterable, Identifiable {
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

extension NivelRiesgoEtiqueta {
    var badgeText: String {
        switch self {
        case .bajo: return L10n.exact("Bajo")
        case .medio: return L10n.exact("Medio")
        case .alto: return L10n.exact("Alto")
        case .critico: return L10n.exact("Crítico")
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
        case .proteinas: return L10n.exact("Proteínas")
        case .fibra: return L10n.exact("Fibra")
        case .grasasSaturadas: return L10n.exact("Grasas saturadas")
        case .azucar: return L10n.exact("Azúcar")
        case .sal: return L10n.exact("Sal")
        case .valorEnergetico: return L10n.exact("Valor calórico")
        }
    }

    var functionSummary: String {
        switch self {
        case .proteinas:
            return L10n.exact("Ayudan a reparar y mantener músculo, piel, enzimas y hormonas.")
        case .fibra:
            return L10n.exact("Mejora el tránsito intestinal, la saciedad y el control de glucosa.")
        case .grasasSaturadas:
            return L10n.exact("Aportan energía, pero no son esenciales frente a grasas insaturadas.")
        case .azucar:
            return L10n.exact("Fuente rápida de energía; el exceso desplaza nutrientes de mejor calidad.")
        case .sal:
            return L10n.exact("Necesaria en pequeñas cantidades para equilibrio hídrico y función nerviosa.")
        case .valorEnergetico:
            return L10n.exact("Representa la energía total del alimento para cubrir requerimientos diarios.")
        }
    }

    var concentrationSummary: String {
        switch self {
        case .proteinas:
            return L10n.exact("Un aporte adecuado favorece masa muscular y saciedad. Muy bajo puede ser insuficiente según contexto dietético.")
        case .fibra:
            return L10n.exact("Concentración baja suele asociarse a menor saciedad y peor salud digestiva. Buena o alta favorece salud metabólica e intestinal.")
        case .grasasSaturadas:
            return L10n.exact("Concentraciones altas y frecuentes se asocian a mayor riesgo cardiovascular. Conviene priorizar niveles bajos o moderados.")
        case .azucar:
            return L10n.exact("Concentraciones altas aumentan carga glucémica y exceso calórico. Se recomienda mantenerla baja, especialmente en ultraprocesados.")
        case .sal:
            return L10n.exact("Concentraciones altas elevan riesgo de hipertensión en consumo habitual. Es preferible una concentración baja.")
        case .valorEnergetico:
            return L10n.exact("Mayor densidad energética facilita exceder calorías si la porción no se controla; depende del patrón global de alimentación.")
        }
    }

    var recommendedAmountSummary: String {
        switch self {
        case .proteinas:
            return L10n.exact("Adultos: ~0.8 g/kg/día como mínimo (aprox. 10 a 35 por ciento de la energía diaria).")
        case .fibra:
            return L10n.exact("Objetivo general: 14 g por cada 1000 kcal (aprox. 25-38 g/día en adultos).")
        case .grasasSaturadas:
            return L10n.exact("Limitar a menos del 10 por ciento de las calorías diarias; idealmente sustituir por grasas insaturadas.")
        case .azucar:
            return L10n.exact("Azúcares libres/añadidos: menos del 10 por ciento de las calorías; idealmente menos del 5 por ciento si es posible.")
        case .sal:
            return L10n.exact("Límite recomendado: <5 g de sal al día (≈2 g de sodio).")
        case .valorEnergetico:
            return L10n.exact("Depende de edad, sexo y actividad. Referencia habitual en etiquetado: ~2000 kcal/día.")
        }
    }
}
#endif
