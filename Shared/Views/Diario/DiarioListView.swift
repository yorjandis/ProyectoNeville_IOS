//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#endif

/// Ajustes visuales específicos de la mascota de la cabecera del Diario.
/// Modifica estos valores para reajustar manualmente su tamaño y posición.
private enum DiarioUIConstants {
    static let topBarPetSize: CGFloat = 145
    static let topBarPetOffset = CGSize(width: 50, height: -35)
    /// Tamaño del título de cada capítulo en la vista agrupada.
    static let chapterTitleFontSize: CGFloat = 19
    /// Separación superior antes del primer capítulo de la vista agrupada.
    static let chapterListTopPadding: CGFloat = 12
}

#if os(iOS)
/// La disposición puede seguir la orientación del iPad o intercambiarse desde
/// la barra de herramientas, igual que en Notas y Agenda.
private enum DiarioIPadLayoutMode: String, CaseIterable {
    case automatic
    case sideBySide
    case stacked

    var title: String {
        switch self {
        case .automatic: return "Automático"
        case .sideBySide: return "Panel lateral"
        case .stacked: return "Panel superior"
        }
    }

    var systemImage: String {
        switch self {
        case .automatic: return "rectangle.2.swap"
        case .sideBySide: return "rectangle.split.2x1"
        case .stacked: return "rectangle.split.1x2"
        }
    }

    func resolvedLayout(for size: CGSize) -> DiarioSplitLayout {
        switch self {
        case .automatic: return size.width >= size.height ? .sideBySide : .stacked
        case .sideBySide: return .sideBySide
        case .stacked: return .stacked
        }
    }
}

private enum DiarioSplitLayout {
    case sideBySide
    case stacked
}

private enum DiarioInlineEditorField: Hashable {
    case title
    case content
    case chapter
    case location
}
#endif

struct DiarioListView: View {

    @Environment(\.managedObjectContext) var context

    @StateObject private var modelDiario = DiarioModel.shared
    @StateObject private var securityModel : SecurityModel = SecurityModel.shared
    @AppStorage(PetSettings.isEnabledKey) private var petsEnabled = true
    
    
    private enum DiarioListMode: String {
        case all
        case groupedByChapter
    }
    
    // Búsqueda general por título, contenido y nombre de anexo.
    @AppStorage("diarySearchBarVisible") private var isDiarySearchVisible = false
    @State private var diarySearchText = ""
    @State private var diaryAttachmentNamesByEntryID: [NSManagedObjectID: [String]] = [:]
    @FocusState private var isDiarySearchFocused: Bool
    //Para buscar en fechas:
    @State private var showSheetFecha       = false
    @State private var showSheetRangoFecha  = false
    @State private var typeOfFechaSearch : TypeFecha = .FechaCreacion
    @State private var fecha1 = Date.now
    @State private var fecha2 = Date.now
    
    let titlesExamples : [(String,String)] = [
    ("Revisión de este día", "neutral"),
    ("¿Como me he sentido hoy?", "neutral" ),
    ("Hoy agradezco:", "feliz"),
    ("¿Que debo mejorar?", "desanimado"),
    ("¿Que he aprendido hoy?","neutral"),
    ("Mi vida es maravillosa porque...", "feliz"),
    ("!Hoy se ha materializado un deseo!","feliz"),
    ("!No es maravillo si...!","feliz"),
    ("Hoy nace un deseo!","feliz"),
    ("!Lo he logrado!","feliz")]
    

    //@State var canOpenDiario : Bool = false
    @State var claveAcceso : String? = nil //Clave para acceder al Diario en dispisitivos son biometría
    
    //Alert:
    @State var showAlert = false
    @State var alertMessage = ""
    
    //Mostrar la ventana de FeedBackReview
    @State private var sheetShowFeedBackReview: Bool = false
    
    
    @State private var showCalendar: Bool = false   //Mostrar/Ocultar el calendario. Por defecto aparece oculto
    @State private var showDiarioStats: Bool = false
    @State private var selectedCalendarDate: Date? = nil
    @State private var isCalendarEntryScopeActive = false
    @State private var calendarRefreshTrigger: Int = 0
    @State private var showNewEntryEditor: Bool = false
    @State private var newEntryTitle: String = ""
    @State private var newEntryContent: String = ""
    @State private var newEntryEmotion: Emociones = .neutral
    @State private var newEntryDate: Date = Date.now
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName: String = "Diario.pdf"
    @State private var showExportRangeSheet = false
    @State private var showManualExportSheet = false
    @State private var exportFromDate = Date.now
    @State private var exportToDate = Date.now
    @State private var manuallySelectedDiarioIDs: Set<UUID> = []
    @State private var isBatchSelectionMode = false
    @State private var batchSelectedDiarioIDs: Set<UUID> = []
    @State private var showBatchDeleteConfirmation = false
    @AppStorage("diaryListMode") private var selectedListMode: DiarioListMode = .all
    @State private var collapsedChapterNames: Set<String> = []
    @State private var showBatchChapterAlert = false
    @State private var batchChapterDraft = ""
    @State private var pendingBatchAction: DiarioBatchAction?
    @State private var showBatchActionConfirmation = false
    @State private var showRitualReviewUpdate = false
    @State private var ritualReviewNeedsUpdate = false
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage("ritual_private_reflections_protected") private var privateRitualReflections = false
    
    
    //Ordenar las entradas del Diario por fechaCreación/fechaModificación
    @AppStorage(AppCons.UD_setting_OrdenarEntradaDiario) var ordenarEntradaDiario : Bool = true // true es fechaCreación; false es fecha de modificación
    @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false //Para poder manejar el acceso al diario
 
    //Almacena la contraeña de acceso en el Llavero, si existe:
    @State private var hasPassword = false

#if os(iOS)
    @AppStorage("diaryIPadLayoutMode") private var iPadLayoutMode: DiarioIPadLayoutMode = .automatic
    @AppStorage("diaryIPadSidePanelFraction") private var iPadSidePanelFraction = 0.35
    @AppStorage("diaryIPadTopPanelFraction") private var iPadTopPanelFraction = 0.42
    @AppStorage("diaryIPadDetailHeaderCollapsed") private var isIPadDetailHeaderCollapsed = false
    @State private var selectedDiarioID: UUID?
    @State private var iPadListScrollTargetID: NSManagedObjectID?
    @State private var iPadListScrollTargetChapter: String?
    @State private var iPadListScrollRequest = 0
    @State private var iPadQuickTitleEntryID: UUID?
    @State private var iPadQuickTitleDraft = ""
    @State private var showIPadQuickTitleAlert = false
    @State private var inlineEditingDiarioID: UUID?
    @State private var inlineDraftTitle = ""
    @State private var inlineDraftContent = ""
    @State private var inlineDraftChapter = ""
    @State private var inlineDraftLocation = ""
    @State private var inlineDraftEmotion: Emociones = .neutral
    @State private var inlineNewChapterDraft = ""
    @State private var showInlineNewChapterAlert = false
    @State private var immediateChapterEntryID: UUID?
    @StateObject private var inlineLocationCapture = AgendaLocationCapture()
    @State private var isCapturingInlineLocation = false
    @State private var showInlineLocationAlert = false
    @State private var inlineLocationAlertMessage = ""
    @State private var inlineLocationCanOpenSettings = false
    @State private var iPadDetailAttachmentCount = 0
    @State private var isIPadDetailAttachmentsExpanded = false
    @State private var inlinePendingAttachments: [PendingDiaryAttachment] = []
    @State private var isSavingInlineDiario = false
    @AppStorage(AppCons.UD_setting_DiarioAttachmentImageQuality)
    private var inlineAttachmentImageQuality = 0.82
    @FocusState private var focusedInlineEditorField: DiarioInlineEditorField?

    // Ajustes visuales manuales del encabezado de detalle en iPad.
    // Cambia este valor para desplazar la mascota: negativo hacia la izquierda,
    // positivo hacia la derecha.
    private let iPadDiaryPetHorizontalOffset: CGFloat = 50
    private let iPadDiaryCalendarVerticalPadding: CGFloat = 6
#endif

    private var hasPremiumPDFAccess: Bool {
        purchaseStatus || yorjPremium
    }

    private var canApplyGlobalEntryFilters: Bool {
        !showCalendar || !isCalendarEntryScopeActive
    }

    private var hasRitualReviewUpdateToday: Bool {
        let epochDay = Int(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 / 86_400)
        let request = NSFetchRequest<NSManagedObject>(entityName: "RitualSessionEntity")
        request.predicate = NSPredicate(format: "kind == %@ AND sessionDateEpochDay == %lld", "evening", Int64(epochDay))
        request.fetchLimit = 1
        guard let review = try? CoreDataController.shared.context.fetch(request).first else { return false }
        let snapshot = EveningDaySnapshot.load()
        return Int(review.value(forKey: "agendaCompletedCount") as? Int32 ?? 0) != snapshot.agendaCompleted.count
            || Int(review.value(forKey: "goalUnitsCompletedCount") as? Int32 ?? 0) != snapshot.completedGoalUnits.count
            || Int(review.value(forKey: "presenceReturns") as? Int32 ?? 0) != snapshot.presenceReturns
            || Int(review.value(forKey: "automaticPilotEvents") as? Int32 ?? 0) != snapshot.automaticPilotEvents
    }

    private var diarySearchVisibleEntries: [Diario] {
        let query = diarySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isDiarySearchVisible, !query.isEmpty else { return modelDiario.list }

        return modelDiario.list.filter { entry in
            diarySearchContains(entry.title, query: query)
                || diarySearchContains(entry.content, query: query)
                || (diaryAttachmentNamesByEntryID[entry.objectID] ?? []).contains {
                    diarySearchContains($0, query: query)
                }
        }
    }

    private var groupedDiarioByChapter: [(chapter: String, entries: [Diario])] {
        let grouped = Dictionary(grouping: diarySearchVisibleEntries) { item in
            chapterName(for: item)
        }

        return grouped
            .map { (chapter: $0.key, entries: $0.value) }
            .sorted { left, right in
                if left.chapter == unchapteredTitle { return false }
                if right.chapter == unchapteredTitle { return true }
                return left.chapter.localizedCaseInsensitiveCompare(right.chapter) == .orderedAscending
            }
    }

    @ToolbarContentBuilder
    private var ritualUpdateToolbar: some ToolbarContent {
        if ritualReviewNeedsUpdate {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showRitualReviewUpdate = true
                } label: {
                    Label("Actualizar cierre", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

#if os(iOS)
    @ToolbarContentBuilder
    private var diarioIPadToolbar: some ToolbarContent {
        if isIPadInterface && securityModel.canOpenDiario {
            ToolbarItem(placement: .navigationBarTrailing) {
                iPadLayoutMenu
            }
        }
    }
#endif

    private enum DiarioBatchAction: Identifiable {
        case updateEmotion(Emociones)
        case updateChapter(String)

        var id: String {
            switch self {
            case .updateEmotion(let emotion):
                return "updateEmotion-\(emotion.rawValue)"
            case .updateChapter(let chapter):
                return "updateChapter-\(chapter)"
            }
        }

        var confirmTitle: String {
            switch self {
            case .updateEmotion:
                return L10n.exact("Actualizar emoción")
            case .updateChapter:
                return L10n.exact("Actualizar capítulo")
            }
        }

        func message(count: Int) -> String {
            switch self {
            case .updateEmotion(let emotion):
                return L10n.format(
                    count == 1 ? "diary.batch.emotion.one" : "diary.batch.emotion.other",
                    fallback: count == 1 ? "Se cambiará la emoción de {0} entrada a {1}." : "Se cambiará la emoción de {0} entradas a {1}.",
                    String(count), emotion.localizedTitle
                )
            case .updateChapter(let chapter):
                let target = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
                if target.isEmpty {
                    return L10n.format(
                        count == 1 ? "diary.batch.remove_chapter.one" : "diary.batch.remove_chapter.other",
                        fallback: count == 1 ? "Se quitará el capítulo de {0} entrada seleccionada" : "Se quitará el capítulo de {0} entradas seleccionadas",
                        String(count)
                    )
                }
                return L10n.format(
                    count == 1 ? "diary.batch.assign_chapter.one" : "diary.batch.assign_chapter.other",
                    fallback: count == 1 ? "Se asignará el capítulo «{0}» a {1} entrada seleccionada" : "Se asignará el capítulo «{0}» a {1} entradas seleccionadas",
                    target, String(count)
                )
            }
        }
    }

    var body: some View {
        NavigationStack {
            configuredDiarioContent
         }
    }

    private var configuredDiarioContent: AnyView {
        var content = AnyView(diarioContent)

        content = AnyView(
            content.onDisappear {
                //Al cerrar la ventana del Diario se chequea si la opción de mentener la ventana abierta.
                //De estar activada, se mantiene la variable canOpenDiario activa
                //De lo contrario, la variable canOpenDiario se pone a false, bloqueando el diario.
                if self.setting_DiarioSiempreOpenFaceID == true {
                    self.securityModel.canOpenDiario = true
                } else {
                    self.securityModel.canOpenDiario = false
                }
            }
        )

        content = AnyView(content.toolbar {
            ritualUpdateToolbar
#if os(iOS)
            diarioIPadToolbar
#endif
        })

        content = AnyView(
            content.sheet(isPresented: $showSheetFecha) {
                singleDateSearchSheet
            }
        )

        content = AnyView(
            content.sheet(isPresented: $showSheetRangoFecha) {
                dateRangeSearchSheet
            }
        )

#if os(iOS)
        if isIPadInterface {
            content = AnyView(
                content.fullScreenCover(isPresented: $showNewEntryEditor) {
                    newDiarioEntryEditor
                }
            )
        } else {
            content = AnyView(
                content.sheet(isPresented: $showNewEntryEditor) {
                    newDiarioEntryEditor
                }
            )
        }
#else
        content = AnyView(
            content.sheet(isPresented: $showNewEntryEditor) {
                newDiarioEntryEditor
            }
        )
#endif

        content = AnyView(
            content.sheet(isPresented: self.$sheetShowFeedBackReview, content: {
                FeedbackView(showTextBotton: true)
            })
        )

        content = AnyView(
            content.sheet(isPresented: $showDiarioStats) {
                DiarioStatsView()
            }
        )

        content = AnyView(
            content.sheet(isPresented: $showRitualReviewUpdate) {
                RitualEveningReviewEntryView()
            }
        )

        content = AnyView(
            content.onAppear {
                ritualReviewNeedsUpdate = hasRitualReviewUpdateToday
                refreshDiaryAttachmentSearchIndex()
            }
        )

        content = AnyView(
            content.onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: CoreDataController.shared.context)) { _ in
                ritualReviewNeedsUpdate = hasRitualReviewUpdateToday
                refreshDiaryAttachmentSearchIndex()
            }
        )

        content = AnyView(
            content.onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                refreshDiaryAttachmentSearchIndex()
            }
        )

        content = AnyView(
            content.sheet(isPresented: $showExportRangeSheet) {
                exportRangeSheet
            }
        )

        content = AnyView(
            content.sheet(isPresented: $showManualExportSheet) {
                manualDiarioExportSheet
            }
        )

        content = AnyView(
            content.fileExporter(
                isPresented: $showPDFExporter,
                document: exportedPDFDocument,
                contentType: .pdf,
                defaultFilename: exportedPDFFileName
            ) { _ in }
        )

        content = AnyView(
            content.alert("Diario", isPresented: $showAlert) {
                
            } message: {
                Text(self.alertMessage)
            }
        )

        content = AnyView(
            content.alert("¿Desea eliminar las entradas seleccionadas?", isPresented: $showBatchDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    deleteSelectedEntries()
                }
            } message: {
                Text("Esta acción no puede deshacerse.")
            }
        )

        content = AnyView(
            content.confirmationDialog("Confirmar acción", isPresented: $showBatchActionConfirmation) {
                diarioBatchConfirmationActions()
            } message: {
                diarioBatchConfirmationMessage()
            }
        )

        content = AnyView(
            content.alert("Cambiar capítulo", isPresented: $showBatchChapterAlert) {
                TextField("Capítulo", text: $batchChapterDraft, axis: .vertical)
                Button("Cancelar", role: .cancel) {}
                Button("Actualizar") {
                    requestBatchActionConfirmation(.updateChapter(batchChapterDraft))
                }
            } message: {
                Text("Se actualizarán las entradas seleccionadas.")
            }
        )

        return content
    }

    private var newDiarioEntryEditor: some View {
        NewDiarioEntryView(
            title: newEntryTitle,
            content: newEntryContent,
            emocion: newEntryEmotion,
            fechaCreacion: newEntryDate
        ) { savedDate in
            refreshAfterEntryCreation(savedDate)
        }
    }

    private var singleDateSearchSheet: some View {
        VStack {
            DatePicker(dateFilterTitle, selection: $fecha1, displayedComponents: [.date])
                .padding(.top, 50)
            Button {
                withAnimation {
                    modelDiario.list = modelDiario.searchPorFecha(for: fecha1, typeFecha: typeOfFechaSearch)
                    didApplyGlobalFilter()
                }
                showSheetFecha = false
            } label: {
                Text("Buscar")
                    .padding(.vertical, 10)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding([.vertical, .horizontal])
            .buttonStyle(PlainButtonStyle())
        }
        .ignoresSafeArea()
    }

    private var dateRangeSearchSheet: some View {
        ScrollView {
            DatePicker("Fecha Inicio", selection: $fecha1, displayedComponents: [.date])
                .frame(height: 70)
                .padding(.top, 30)

            DatePicker("Fecha final", selection: $fecha2, displayedComponents: [.date])
                .frame(height: 70)

            Button {
                withAnimation {
                    modelDiario.list = modelDiario.searchPorRangoFecha(from: fecha1, to: fecha2, typeFecha: typeOfFechaSearch)
                    didApplyGlobalFilter()
                }
                showSheetRangoFecha = false
            } label: {
                Text("Buscar")
                    .padding(.vertical, 10)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding([.vertical, .horizontal])
            .buttonStyle(PlainButtonStyle())
        }
        .ignoresSafeArea()
    }

    private var exportRangeSheet: some View {
        VStack(spacing: 16) {
            DatePicker("Desde", selection: $exportFromDate, displayedComponents: [.date])
            DatePicker("Hasta", selection: $exportToDate, displayedComponents: [.date])
            Button("Exportar PDF") {
                exportDiarioRangeToPDF(from: exportFromDate, to: exportToDate)
                showExportRangeSheet = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var manualDiarioExportSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selecciona entradas para exportar")
                .font(.headline)
            List {
                ForEach(modelDiario.list) { item in
                    Button {
                        toggleManualDiarioSelection(item)
                    } label: {
                        manualExportRow(for: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button("Exportar PDF") {
                let selected = modelDiario.list.filter { item in
                    guard let id = item.id else { return false }
                    return manuallySelectedDiarioIDs.contains(id)
                }
                exportDiarioToPDF(selected, scopeName: "Manual")
                showManualExportSheet = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func manualExportRow(for item: Diario) -> some View {
        HStack {
            Image(systemName: manuallySelectedDiarioIDs.contains(item.id ?? UUID()) ? "checkmark.circle.fill" : "circle")
            Text(item.title ?? "Sin título")
            Spacer()
            if let date = item.fecha {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func diarioBatchConfirmationActions() -> some View {
        if let action = pendingBatchAction {
            Button(action.confirmTitle) {
                performConfirmedBatchAction(action)
                pendingBatchAction = nil
            }
        }
        Button("Cancelar", role: .cancel) {
            pendingBatchAction = nil
        }
    }

    private func diarioBatchConfirmationMessage() -> Text {
        Text(pendingBatchAction?.message(count: batchSelectedDiarioIDs.count) ?? "")
    }

    @ViewBuilder
    private var diarioContent: some View {
        ZStack {
            LinearGradient(colors: [Color(red:0.45, green:0.50, blue: 0.50), .orange], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .onAppear {
                    //Lee la contraseña de acceso del diario
                    hasPassword = KeychainHelper.shared.getPassword() != nil
                }

            if securityModel.canOpenDiario {
                diarioUnlockedContent
            } else {
                diarioLockedContent
            }
        }
    }

    @ViewBuilder
    private var diarioUnlockedContent: some View {
#if os(iOS)
        if isIPadInterface {
            iPadDiarioWorkspace
        } else {
            diarioStandardUnlockedContent
        }
#else
        diarioStandardUnlockedContent
#endif
    }

    @ViewBuilder
    private var diarioStandardUnlockedContent: some View {
        VStack {
            Text("") //Para que las entradas no sobrepasen el area segura superior

            diarioTopActions(showsPet: true)
                .padding(.horizontal, 15)
                .padding(.top, 8)

            if showCalendar {
                diarioCalendarSection
            }

            if isDiarySearchVisible {
                diarySearchBar
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if isBatchSelectionMode {
                batchSelectionToolbar
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            diarioEntriesScroll
        }
        .onAppear {
            selectedCalendarDate = nil
            modelDiario.getAllItem()
            if selectedListMode == .groupedByChapter {
                collapsedChapterNames = Set(groupedDiarioByChapter.map(\.chapter))
            }
        }
        .onChange(of: modelDiario.list.map { $0.id }) { _, ids in
            if let selectedCalendarDate {
                let selectedDayEntries = modelDiario.searchPorFecha(for: selectedCalendarDate)
                let selectedDayIDs = selectedDayEntries.map { $0.id }

                if ids != selectedDayIDs {
                    modelDiario.list = selectedDayEntries
                    return
                }
            }

            let visibleIDs = Set(ids.compactMap { $0 })
            batchSelectedDiarioIDs = batchSelectedDiarioIDs.intersection(visibleIDs)
        }
    }

    private func diarioTopActions(showsPet: Bool) -> some View {
        HStack {
            Spacer()

            Menu {
                Button {
                    showDiarioStats = true
                } label: {
                    Label("Estadísticas", systemImage: "chart.xyaxis.line")
                }

                Button {
                    toggleBatchSelectionMode()
                } label: {
                    Label(isBatchSelectionMode ? "Cancelar selección" : "Seleccionar", systemImage: isBatchSelectionMode ? "xmark.circle" : "checklist")
                }

#if os(iOS)
                if !isIPadInterface {
                    Button {
                        toggleCalendar()
                    } label: {
                        Label(showCalendar ? "Ocultar calendario" : "Mostrar calendario", systemImage: "calendar")
                    }
                }
#else
                Button {
                    toggleCalendar()
                } label: {
                    Label(showCalendar ? "Ocultar calendario" : "Mostrar calendario", systemImage: "calendar")
                }
#endif
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.bordered)
            .disabled(!securityModel.canOpenDiario)

            Menu {
                Button {
                    showAllEntries()
                } label: {
                    Label("Todas las entradas", systemImage: "text.magnifyingglass")
                }

                Button {
                    groupEntriesByChapter()
                } label: {
                    Label("Por capítulos", systemImage: selectedListMode == .groupedByChapter ? "checkmark.circle.fill" : "book.closed")
                }

                Button {
                    showFavoriteEntries()
                } label: {
                    Label("Mostrar favoritas", systemImage: "star")
                }

                Button {
                    showEntriesWithAttachments()
                } label: {
                    Label("Mostrar con anexos", systemImage: "paperclip")
                }
                .disabled(!canApplyGlobalEntryFilters)

                emotionFilterMenu
                    .disabled(!canApplyGlobalEntryFilters)

                diarioDateFilterMenu(
                    type: .FechaCreacion,
                    title: "Fecha de creación",
                    systemImage: "calendar.badge.clock"
                )
                .disabled(!canApplyGlobalEntryFilters)

                diarioDateFilterMenu(
                    type: .FechaModificacion,
                    title: "Fecha de modificación",
                    systemImage: "calendar"
                )
                .disabled(!canApplyGlobalEntryFilters)

                Button {
                    toggleDiarySearch()
                } label: {
                    Label(
                        isDiarySearchVisible ? "Ocultar búsqueda" : "Mostrar búsqueda",
                        systemImage: "magnifyingglass"
                    )
                }

                exportDiarioPDFMenu()
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
            .buttonStyle(.bordered)
            .disabled(!securityModel.canOpenDiario)

            Button {
                openBlankEntryEditor()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!securityModel.canOpenDiario)
        }
        // La superposición evita que el tamaño de la mascota altere la altura de la barra.
        .overlay(alignment: .leading) {
            if showsPet && petsEnabled {
                PetImage(assetName: "peti_escribe")
                    .frame(
                        width: DiarioUIConstants.topBarPetSize,
                        height: DiarioUIConstants.topBarPetSize
                    )
                    .offset(
                        x: DiarioUIConstants.topBarPetOffset.width,
                        y: DiarioUIConstants.topBarPetOffset.height
                    )
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
    }

    private var diarySearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar en título, contenido o anexos", text: $diarySearchText)
                .textFieldStyle(.plain)
                .focused($isDiarySearchFocused)
            if !diarySearchText.isEmpty {
                Button {
                    diarySearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

#if os(iOS)
    private var isIPadInterface: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var iPadVisibleEntries: [Diario] {
        diarySearchVisibleEntries
    }

    private var activeDiario: Diario? {
        if let selectedDiarioID,
           let selected = iPadVisibleEntries.first(where: { $0.id == selectedDiarioID }) {
            return selected
        }
        return iPadVisibleEntries.first
    }

    private var activeDiarioID: UUID? {
        activeDiario?.id
    }

    /// En apaisado: lista a la izquierda y calendario compacto + detalle a la
    /// derecha. En retrato: lista y calendario comparten el panel superior.
    private var iPadDiarioWorkspace: some View {
        Group {
            if inlineEditingDiarioID != nil {
                // El editor ocupa el espacio de trabajo completo: al ocultar el
                // calendario y la mascota queda altura real para el contenido.
                iPadDiarioDetailPanel(showsCalendar: false)
                    .transition(.opacity)
            } else {
                GeometryReader { proxy in
                    let layout = iPadLayoutMode.resolvedLayout(for: proxy.size)

                    AdjustableDiarioSplitView(
                        layout: layout,
                        primaryFraction: layout == .sideBySide
                            ? $iPadSidePanelFraction
                            : $iPadTopPanelFraction,
                        minimumPrimaryLength: layout == .sideBySide ? 310 : 270,
                        minimumSecondaryLength: layout == .sideBySide ? 430 : 280
                    ) {
                        if layout == .sideBySide {
                            iPadLandscapeListPanel
                        } else {
                            iPadPortraitTopPanel
                        }
                    } secondary: {
                        iPadDiarioDetailPanel(showsCalendar: layout == .sideBySide)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .onAppear {
            modelDiario.getAllItem()
            if selectedListMode == .groupedByChapter {
                collapsedChapterNames = Set(groupedDiarioByChapter.map(\.chapter))
            }
            refreshIPadDetailAttachmentAvailability()
        }
        .onChange(of: modelDiario.list.map(\.id)) { _, _ in
            refreshIPadDetailAttachmentAvailability()
            guard let activeDiarioID else {
                selectedDiarioID = nil
                inlineEditingDiarioID = nil
                return
            }
            if inlineEditingDiarioID != nil, inlineEditingDiarioID != activeDiarioID {
                cancelInlineDiarioEditing()
            }
        }
        .onChange(of: activeDiarioID) { _, _ in
            isIPadDetailAttachmentsExpanded = false
            refreshIPadDetailAttachmentAvailability()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            refreshIPadDetailAttachmentAvailability()
        }
    }

    private var iPadLandscapeListPanel: some View {
        VStack(spacing: 0) {
            diarioTopActions(showsPet: false)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            if isDiarySearchVisible {
                diarySearchBar
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Divider()
            iPadDiaryEntriesList
        }
        .diaryIPadPanel(material: .thinMaterial)
    }

    private var iPadPortraitTopPanel: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                diarioTopActions(showsPet: false)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                Divider()
                iPadDiaryEntriesList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            VStack(spacing: 0) {
                if isDiarySearchVisible {
                    diarySearchBar
                        .padding(10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                iPadCompactCalendar(showsPet: false)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .diaryIPadPanel(material: .thinMaterial)
    }

    private var iPadDiaryEntriesList: some View {
        ScrollViewReader { proxy in
            List {
                if isBatchSelectionMode {
                    Section {
                        batchSelectionToolbar
                            .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                    }
                }

                if iPadVisibleEntries.isEmpty {
                    ContentUnavailableView(
                        "No hay entradas",
                        systemImage: "book.closed",
                        description: Text(diarySearchText.isEmpty ? "Crea una entrada o cambia el filtro." : "Prueba con otra búsqueda.")
                    )
                    .listRowBackground(Color.clear)
                } else if selectedListMode == .groupedByChapter {
                    ForEach(groupedDiarioByChapter, id: \.chapter) { section in
                        diarioChapterSection(section, includesEntries: false)
                            .id(iPadChapterScrollID(section.chapter))
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        if !collapsedChapterNames.contains(section.chapter) {
                            ForEach(section.entries) { entry in
                                diarioCard(for: entry)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                } else {
                    ForEach(iPadVisibleEntries) { entry in
                        diarioCard(for: entry)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: iPadListScrollRequest) { _, _ in
                guard let target = iPadListScrollTargetID else { return }
                let targetChapter = iPadListScrollTargetChapter
                Task { @MainActor in
                    await Task.yield()

                    if let targetChapter {
                        // La fila del capítulo es un hijo directo de List y
                        // siempre puede localizarse, aunque sus tarjetas aún
                        // no se hayan creado por estar fuera de pantalla.
                        proxy.scrollTo(iPadChapterScrollID(targetChapter), anchor: .top)
                        await Task.yield()
                        await Task.yield()
                    }

                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
    }

    private func iPadCompactCalendar(showsPet: Bool) -> some View {
        HStack(spacing: 0) {
            if showsPet && petsEnabled {
                ZStack(alignment: .center) {
                    Color.clear
                    PetImage(assetName: "peti_escribe")
                        .frame(width: 132, height: 198)
                        .offset(x: iPadDiaryPetHorizontalOffset)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
                .frame(width: 170, height: 245, alignment: .center)
            }
            diarioCalendarSection
                .scaleEffect(0.80, anchor: .top)
                .frame(height: 245, alignment: .top)
                .clipped()
                .padding(.vertical, iPadDiaryCalendarVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 5)
    }

    private func iPadDiarioDetailPanel(showsCalendar: Bool) -> some View {
        VStack(spacing: 0) {
            if showsCalendar {
                iPadCollapsibleDetailHeader
              //  Divider()
            }

            Group {
                if let entry = activeDiario {
                    ScrollView {
                        iPadDiaryDetailContent(entry)
                            .id(entry.id)
                            .padding(16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                } else {
                    ContentUnavailableView(
                        "Selecciona una entrada",
                        systemImage: "book.pages",
                        description: Text("Su contenido aparecerá en este panel."))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .diaryIPadPanel(material: .ultraThinMaterial)
        .alert("Crear capítulo", isPresented: $showInlineNewChapterAlert) {
            TextField("Nombre del capítulo", text: $inlineNewChapterDraft, axis: .vertical)
            Button("Cancelar", role: .cancel) {
                immediateChapterEntryID = nil
            }
            Button("Usar capítulo") {
                useCreatedIPadChapter()
            }
            .disabled(inlineNewChapterDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text(
                immediateChapterEntryID == nil
                    ? "El capítulo se asignará a esta entrada al actualizarla."
                    : "El capítulo se guardará y asignará inmediatamente a esta entrada."
            )
        }
        .alert("Modificar Título", isPresented: $showIPadQuickTitleAlert) {
            TextField("Nuevo título", text: $iPadQuickTitleDraft)
            Button("Cancelar", role: .cancel) {
                iPadQuickTitleEntryID = nil
            }
            Button("Guardar") {
                saveIPadQuickTitle()
            }
        } message: {
            Text("Se actualizará el título de esta entrada del Diario.")
        }
        .alert("Ubicación", isPresented: $showInlineLocationAlert) {
            if inlineLocationCanOpenSettings {
                Button("Abrir Ajustes") {
                    openInlineLocationPrivacySettings()
                }
            }
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(inlineLocationAlertMessage)
        }
    }

    private var iPadCollapsibleDetailHeader: some View {
        Group {
            if isIPadDetailHeaderCollapsed {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isIPadDetailHeaderCollapsed = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Label("Mascota y calendario", systemImage: "calendar")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Despliega la mascota y el calendario")
            } else {
                ZStack(alignment: .topTrailing) {
                    iPadCompactCalendar(showsPet: true)

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            isIPadDetailHeaderCollapsed = true
                        }
                    } label: {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.black.opacity(0.72))
                            .padding(10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ocultar mascota y calendario")
                    .accessibilityHint("Da más espacio al contenido de la entrada")
                }
            }
        }
    }

    private func iPadDiaryDetailContent(_ entry: Diario) -> some View {
        let isEditing = inlineEditingDiarioID == entry.id
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                if isEditing {
                    Menu {
                        ForEach(Emociones.allCases, id: \.self) { emotion in
                            Button("\(emotion.emoji) \(emotion.localizedTitle)") {
                                inlineDraftEmotion = emotion
                            }
                        }
                    } label: {
                        Text(inlineDraftEmotion.emoji)
                            .font(.system(size: 38))
                    }
                } else {
                    Text(Emociones.emoji(from: entry.emotion))
                        .font(.system(size: 38))
                }

                VStack(alignment: .leading, spacing: 5) {
                    if isEditing {
                        TextField("Título", text: $inlineDraftTitle, axis: .vertical)
                            .font(.title2.weight(.semibold))
                            .textFieldStyle(.plain)
                            .focused($focusedInlineEditorField, equals: .title)
                            .padding(10)
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        Text((entry.title ?? "").isEmpty ? "Sin título" : (entry.title ?? ""))
                            .font(.title2.weight(.semibold))
                            .contentShape(Rectangle())
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        revealIPadDetailEntryInList(entry)
                                        presentIPadQuickTitleEditor(for: entry)
                                    }
                                    .exclusively(
                                        before: TapGesture(count: 1)
                                            .onEnded {
                                                revealIPadDetailEntryInList(entry)
                                            }
                                    )
                            )
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Un toque muestra la tarjeta en el listado; dos toques permiten cambiar el título")
                    }
                    if let date = entry.fecha {
                        Text(date.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isEditing {
                    HStack(spacing: 8) {
                        Button("Cancelar") { cancelInlineDiarioEditing() }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.9))
                            .foregroundStyle(.black)
                        Button("Actualizar") { updateInlineDiario(entry) }
                            .buttonStyle(.borderedProminent)
                            .tint(.black.opacity(0.78))
                            .foregroundStyle(.white)
                            .disabled(
                                isSavingInlineDiario
                                    || inlineDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                    }
                } else {
                    HStack(spacing: 8) {
                        if iPadDetailAttachmentCount > 0 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isIPadDetailAttachmentsExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: "paperclip")
                                    .font(.title3)
                                    .foregroundStyle(
                                        isIPadDetailAttachmentsExpanded
                                            ? .black
                                            : .black.opacity(0.72)
                                    )
                                    .padding(6)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                isIPadDetailAttachmentsExpanded ? "Ocultar anexos" : "Mostrar anexos"
                            )
                        }

                        Button("Editar") { beginInlineDiarioEditing(entry) }
                            .buttonStyle(.borderedProminent)
                            .tint(.black.opacity(0.78))
                            .foregroundStyle(.white)
                    }
                }
            }

            iPadDiaryAttachmentsSection(entry, isEditing: isEditing)

            if isEditing {
                iPadDiaryDetailSection(title: "Capítulo", systemImage: "book.closed") {
                    Menu {
                        Button("Sin capítulo") {
                            inlineDraftChapter = ""
                        }

                        if !existingChapters.isEmpty {
                            Divider()
                            ForEach(existingChapters, id: \.self) { chapter in
                                Button(chapter) {
                                    inlineDraftChapter = chapter
                                }
                            }
                        }

                        Divider()
                        Button("Crear capítulo…") {
                            immediateChapterEntryID = nil
                            inlineNewChapterDraft = ""
                            showInlineNewChapterAlert = true
                        }
                    } label: {
                        HStack {
                            Text(inlineDraftChapter.isEmpty ? "Sin capítulo" : inlineDraftChapter)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                iPadDiaryDetailSection(title: "Contenido", systemImage: "text.alignleft") {
                    TextEditor(text: $inlineDraftContent)
                        .focused($focusedInlineEditorField, equals: .content)
                        .foregroundStyle(.black)
                        .tint(.black)
                        .accentColor(.black)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 260, alignment: .topLeading)
                        .padding(8)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                }
                iPadDiaryDetailSection(title: "Coordenadas", systemImage: "mappin.and.ellipse") {
                    HStack(spacing: 10) {
                        TextField("Ej: 40.416775,-3.703790", text: $inlineDraftLocation, axis: .vertical)
                            .textFieldStyle(.plain)
                            .focused($focusedInlineEditorField, equals: .location)
                            .padding(10)
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))

                        Button {
                            captureInlineCurrentLocation()
                        } label: {
                            if isCapturingInlineLocation {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Ubicación actual", systemImage: "location.fill")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.black.opacity(0.75))
                        .disabled(isCapturingInlineLocation)
                        .accessibilityHint("Solicita permiso de ubicación si es necesario y obtiene las coordenadas actuales")
                    }
                }
            } else {
                let content = (entry.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                iPadDiaryChapterLine(entry)
                iPadDiaryDetailSection(title: "Contenido", systemImage: "text.alignleft") {
                    Text(content.isEmpty ? "Esta entrada no contiene texto." : content)
                        .textSelection(.enabled)
                        .italic()
                        .fontDesign(.serif)
                }
                let location = (entry.value(forKey: "direccionMapa") as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !location.isEmpty {
                    iPadDiaryDetailSection(title: "Ubicación", systemImage: "mappin.and.ellipse") {
                        Text(location)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iPadDiaryAttachmentsSection(_ entry: Diario, isEditing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if iPadDetailAttachmentCount > 0 {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isIPadDetailAttachmentsExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Label("Anexos", systemImage: "paperclip")
                                .font(.subheadline.weight(.semibold))
                            Text("\(iPadDetailAttachmentCount)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(
                                systemName: isIPadDetailAttachmentsExpanded
                                    ? "chevron.up.circle.fill"
                                    : "chevron.down.circle"
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        isIPadDetailAttachmentsExpanded ? "Ocultar anexos" : "Mostrar anexos"
                    )

                    if !isEditing {
                        iPadImmediateAttachmentImportMenu(for: entry)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Label("Anexos", systemImage: "paperclip")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if !isEditing {
                        iPadImmediateAttachmentImportMenu(for: entry)
                    }
                }
            }

            if isIPadDetailAttachmentsExpanded && iPadDetailAttachmentCount > 0 {
                DiaryAttachmentsSection(diario: entry, horizontal: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if isEditing && (isIPadDetailAttachmentsExpanded || iPadDetailAttachmentCount == 0) {
                Divider()
                Text("Añadir anexos")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                PendingDiaryAttachmentsPicker(attachments: $inlinePendingAttachments)
            }
        }
        .foregroundStyle(.black)
        .padding(14)
        .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func iPadImmediateAttachmentImportMenu(for entry: Diario) -> some View {
        DiaryAttachmentImportMenu(diario: entry, compact: true) {
            withAnimation(.easeInOut(duration: 0.2)) {
                refreshIPadDetailAttachmentAvailability(for: entry)
                isIPadDetailAttachmentsExpanded = true
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Permite añadir archivos, fotos o imágenes de la cámara")
    }

    private func iPadDiaryChapterLine(_ entry: Diario) -> some View {
        let currentChapter = chapterName(for: entry)
        return Menu {
            Button {
                updateIPadDetailChapter("", for: entry)
            } label: {
                Label(
                    "Sin capítulo",
                    systemImage: currentChapter == unchapteredTitle ? "checkmark" : "book.closed"
                )
            }

            if !existingChapters.isEmpty {
                Divider()
                ForEach(existingChapters, id: \.self) { chapter in
                    Button {
                        updateIPadDetailChapter(chapter, for: entry)
                    } label: {
                        Label(
                            chapter,
                            systemImage: chapter == currentChapter ? "checkmark" : "book.closed"
                        )
                    }
                }
            }

            Divider()
            Button("Crear capítulo…") {
                immediateChapterEntryID = entry.id
                inlineNewChapterDraft = ""
                showInlineNewChapterAlert = true
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "book.closed")
                Text("Capítulo:")
                    .fontWeight(.semibold)
                Text(currentChapter)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 14)
            .frame(height: 42)
            .contentShape(Rectangle())
            .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capítulo: \(currentChapter)")
        .accessibilityHint("Permite cambiar o crear el capítulo de la entrada")
    }

    private func updateIPadDetailChapter(_ chapter: String, for entry: Diario) {
        guard let entryID = entry.id else { return }
        let trimmedChapter = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentValue = chapterValue(for: entry).trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedChapter != currentValue else { return }

        selectedDiarioID = entryID
        withAnimation(.easeInOut(duration: 0.2)) {
            modelDiario.UpdateCapitulo(capitulo: trimmedChapter, ids: [entryID])
            entry.setValue(trimmedChapter, forKey: "capitulo")
            refreshAfterEntryUpdate(entry.fecha)

            if selectedListMode == .groupedByChapter {
                let destination = trimmedChapter.isEmpty ? unchapteredTitle : trimmedChapter
                collapsedChapterNames.remove(destination)
            }
        }
    }

    private func useCreatedIPadChapter() {
        let chapter = inlineNewChapterDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !chapter.isEmpty else { return }

        if let entryID = immediateChapterEntryID,
           let entry = modelDiario.getAllItemGET().first(where: { $0.id == entryID }) {
            updateIPadDetailChapter(chapter, for: entry)
        } else {
            inlineDraftChapter = chapter
        }
        immediateChapterEntryID = nil
    }

    private func iPadDiaryDetailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func revealIPadDetailEntryInList(_ entry: Diario) {
        guard let entryID = entry.id else { return }
        selectedDiarioID = entryID

        if selectedListMode == .groupedByChapter {
            let chapter = chapterName(for: entry)
            collapsedChapterNames.remove(chapter)
            iPadListScrollTargetChapter = chapter
        } else {
            iPadListScrollTargetChapter = nil
        }

        iPadListScrollTargetID = entry.objectID
        iPadListScrollRequest &+= 1
    }

    private func iPadChapterScrollID(_ chapter: String) -> String {
        "diary-ipad-chapter-\(chapter)"
    }

    private func presentIPadQuickTitleEditor(for entry: Diario) {
        iPadQuickTitleEntryID = entry.id
        iPadQuickTitleDraft = entry.title ?? ""
        showIPadQuickTitleAlert = true
    }

    private func saveIPadQuickTitle() {
        guard let entryID = iPadQuickTitleEntryID,
              let entry = modelDiario.getAllItemGET().first(where: { $0.id == entryID }) else {
            iPadQuickTitleEntryID = nil
            return
        }

        modelDiario.UpdateTitle(title: iPadQuickTitleDraft, diario: entry)
        selectedDiarioID = entryID
        refreshAfterEntryUpdate(entry.fecha)
        iPadQuickTitleEntryID = nil
    }

    private func beginInlineDiarioEditing(_ entry: Diario) {
        inlineEditingDiarioID = entry.id
        inlineDraftTitle = entry.title ?? ""
        inlineDraftContent = entry.content ?? ""
        inlineDraftChapter = chapterValue(for: entry).trimmingCharacters(in: .whitespacesAndNewlines)
        inlineDraftLocation = (entry.value(forKey: "direccionMapa") as? String ?? "")
        inlineDraftEmotion = modelDiario.getEmocionesFromStr(value: entry.emotion ?? "neutral")
        inlinePendingAttachments = []
        refreshIPadDetailAttachmentAvailability(for: entry)
        isIPadDetailAttachmentsExpanded = iPadDetailAttachmentCount > 0
    }

    private func cancelInlineDiarioEditing() {
        focusedInlineEditorField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.async {
            inlineEditingDiarioID = nil
            inlineDraftTitle = ""
            inlineDraftContent = ""
            inlineDraftChapter = ""
            inlineDraftLocation = ""
            inlineNewChapterDraft = ""
            inlinePendingAttachments = []
            isCapturingInlineLocation = false
            isSavingInlineDiario = false
        }
    }

    private func refreshIPadDetailAttachmentAvailability(for entry: Diario? = nil) {
        guard let target = entry ?? activeDiario else {
            iPadDetailAttachmentCount = 0
            isIPadDetailAttachmentsExpanded = false
            return
        }

        iPadDetailAttachmentCount = (try? DiaryAttachmentStore.shared.attachments(for: target).count) ?? 0
        if iPadDetailAttachmentCount == 0 {
            isIPadDetailAttachmentsExpanded = false
        }
    }

    private func captureInlineCurrentLocation() {
        guard !isCapturingInlineLocation else { return }
        isCapturingInlineLocation = true
        inlineLocationCanOpenSettings = false

        // AgendaLocationCapture solicita `when in use` si el usuario todavía
        // no ha decidido el permiso; solo abre Ajustes si ya fue denegado.
        inlineLocationCapture.captureCurrentAddress { result in
            isCapturingInlineLocation = false
            switch result {
            case .success(let coordinates):
                inlineDraftLocation = coordinates
            case .failure(let error):
                let nsError = error as NSError
                inlineLocationAlertMessage = error.localizedDescription
                inlineLocationCanOpenSettings = nsError.domain == "AgendaLocationCapture"
                    && [0, 1, 3].contains(nsError.code)
                showInlineLocationAlert = true
            }
        }
    }

    private func openInlineLocationPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func updateInlineDiario(_ entry: Diario) {
        guard inlineEditingDiarioID == entry.id, !isSavingInlineDiario else { return }
        isSavingInlineDiario = true

        Task { @MainActor in
            modelDiario.UpdateItem(
                diario: entry,
                title: inlineDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                content: inlineDraftContent,
                emoticono: inlineDraftEmotion,
                isFav: entry.isFav,
                direccionMapa: inlineDraftLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                capitulo: inlineDraftChapter
            )

            do {
                let pendingAttachments = inlinePendingAttachments
                for attachment in pendingAttachments {
                    try await DiaryAttachmentStore.shared.importData(
                        attachment.data,
                        fileName: attachment.fileName,
                        contentType: attachment.contentType,
                        into: entry,
                        imageQuality: inlineAttachmentImageQuality
                    )
                }
                inlinePendingAttachments.removeAll()
                selectedDiarioID = entry.id
                calendarRefreshTrigger += 1
                refreshAfterEntryUpdate(entry.fecha)
                refreshIPadDetailAttachmentAvailability(for: entry)
                cancelInlineDiarioEditing()
            } catch {
                isSavingInlineDiario = false
                alertMessage = "La entrada se actualizó, pero no se pudieron guardar todos los anexos: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private var iPadLayoutMenu: some View {
        Menu {
            ForEach(DiarioIPadLayoutMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        iPadLayoutMode = mode
                    }
                } label: {
                    Label(
                        mode.title,
                        systemImage: iPadLayoutMode == mode ? "checkmark.circle.fill" : mode.systemImage
                    )
                }
            }
        } label: {
            Image(systemName: iPadLayoutMode.systemImage)
        }
        .accessibilityLabel("Disposición de paneles")
    }
#endif

    private func toggleDiarySearch() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isDiarySearchVisible.toggle()
            if !isDiarySearchVisible {
                diarySearchText = ""
                isDiarySearchFocused = false
            }
        }

        if isDiarySearchVisible {
            refreshDiaryAttachmentSearchIndex()
            DispatchQueue.main.async {
                isDiarySearchFocused = true
            }
        }
    }

    private func diarySearchContains(_ candidate: String?, query: String) -> Bool {
        guard let candidate else { return false }
        return candidate.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) != nil
    }

    private func refreshDiaryAttachmentSearchIndex() {
        diaryAttachmentNamesByEntryID =
            (try? DiaryAttachmentStore.shared.attachmentNamesByDiaryObjectID()) ?? [:]
    }

    private func toggleCalendar() {
        withAnimation {
            showCalendar.toggle()
        }
    }

    private func showAllEntries() {
        withAnimation {
            selectedListMode = .all
            selectedCalendarDate = nil
            isCalendarEntryScopeActive = false
            modelDiario.getAllItem()
        }
    }

    private func groupEntriesByChapter() {
        withAnimation {
            collapsedChapterNames = Set(groupedDiarioByChapter.map(\.chapter))
            selectedListMode = .groupedByChapter
        }
    }

    private func showFavoriteEntries() {
        selectedListMode = .all
        selectedCalendarDate = nil
        isCalendarEntryScopeActive = showCalendar
        modelDiario.list = modelDiario.filterByFav()
    }

    private func showEntriesWithAttachments() {
        withAnimation {
            selectedListMode = .all
            selectedCalendarDate = nil
            isCalendarEntryScopeActive = false
            modelDiario.list = modelDiario.filterByAttachments()
        }
    }

    private var dateFilterTitle: String {
        switch typeOfFechaSearch {
        case .FechaCreacion:
            return L10n.exact("Fecha de creación")
        case .FechaModificacion:
            return L10n.exact("Fecha de modificación")
        }
    }

    @ViewBuilder
    private var emotionFilterMenu: some View {
        Menu {
            ForEach(Emociones.allCases, id: \.self) { emotion in
                Button {
                    withAnimation {
                        modelDiario.list = modelDiario.filterByEmoticono(criterio: emotion.rawValue)
                        didApplyGlobalFilter()
                    }
                } label: {
                    HStack {
                        Text(emotion.localizedTitle)
                        Text(emotion.emoji)
                    }
                }
            }
        } label: {
            Label("Por emoción", systemImage: "face.smiling")
        }
    }

    @ViewBuilder
    private func diarioDateFilterMenu(type: TypeFecha, title: String, systemImage: String) -> some View {
        Menu {
            Button("Fecha") {
                typeOfFechaSearch = type
                fecha1 = Date.now
                showSheetFecha = true
            }

            Button("Intervalo") {
                typeOfFechaSearch = type
                fecha1 = Date.now
                fecha2 = Date.now
                showSheetRangoFecha = true
            }

            Menu("Sugerencias") {
                relativeDateFilterButton("Tres días", period: .tresDias, type: type)
                relativeDateFilterButton("Semana anterior", period: .semana, type: type)
                relativeDateFilterButton("Quincena anterior", period: .quincena, type: type)
                relativeDateFilterButton("Mes anterior", period: .mes, type: type)
                relativeDateFilterButton("Dos meses", period: .dosMeses, type: type)
                relativeDateFilterButton("Tres meses", period: .tresMeses, type: type)
                relativeDateFilterButton("Seis meses", period: .seisMeses, type: type)
                relativeDateFilterButton("Un año", period: .unAno, type: type)
                relativeDateFilterButton("Dos años", period: .dosAnos, type: type)
                relativeDateFilterButton("Tres años", period: .tresAnos, type: type)
                relativeDateFilterButton("Cinco años", period: .cincoAnos, type: type)
                relativeDateFilterButton("Diez años", period: .diezAnos, type: type)
            }
        } label: {
            Label(title, systemImage: systemImage)
        }
    }

    @ViewBuilder
    private func relativeDateFilterButton(
        _ title: LocalizedStringKey,
        period: DiarioModel.Antiguedad,
        type: TypeFecha
    ) -> some View {
        Button(title) {
            withAnimation {
                modelDiario.list = modelDiario.searchPorAntiguedad(for: period, typeFecha: type)
                didApplyGlobalFilter()
            }
        }
    }

    private func didApplyGlobalFilter() {
        selectedListMode = .all
        selectedCalendarDate = nil
        isCalendarEntryScopeActive = false
    }

    private func openBlankEntryEditor() {
        openNewEntryEditor(
            title: "",
            content: "",
            emocion: .neutral,
            date: Date.now
        )
    }

    private var diarioCalendarSection: some View {
        DiarioCalendarView(
            refreshTrigger: calendarRefreshTrigger,
            onRequestCreateEntry: { date in
                openNewEntryEditor(
                    title: "",
                    content: "",
                    emocion: .neutral,
                    date: date
                )
            }
        ) { date in
            withAnimation {
                selectedCalendarDate = Calendar.current.startOfDay(for: date)
                isCalendarEntryScopeActive = true
                modelDiario.list = modelDiario.searchPorFecha(for: date)
            }
        }
    }

    @ViewBuilder
    private var diarioLockedContent: some View {
        VStack {
            Text("El Diario le permite llevar un registro de las actividades y hechos del día. Está protegido y solo usted tiene acceso.")
                .multilineTextAlignment(.center)
                .italic()
                .fontWeight(.heavy)
                .fontDesign(.serif)
                .font(.system(size: 25))
                .foregroundStyle(.black)
                .padding(15)

            if BiometryCheckerSupport.checkBiometricSupport() == .available {
                diarioBiometricAccessContent
            } else {
                diarioPasswordFallbackContent
            }
        }
    }

    @ViewBuilder
    private var diarioBiometricAccessContent: some View {
        Button {
            UtilFuncs.autent(HabilitarContenido: self.$securityModel.canOpenDiario)
        } label: {
            Image(systemName: "key.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(Color.black.opacity(0.7))
                .symbolEffect(.pulse, isActive: true)
        }
        Text("Toque la imagen para acceder.")
            .font(.footnote)
            .padding()
        diarioPasswordAccessButton
            .padding(.vertical, 25)
    }

    @ViewBuilder
    private var diarioPasswordFallbackContent: some View {
        VStack {
            if self.hasPassword {
                Text("Parece que su dispositivo no admite biometría. Utilice el botón debajo para entrar por contraseña.")
                diarioPasswordAccessButton
                    .padding()
                Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                    .font(.footnote)
            } else {
                Text("Parece que su dispositivo no admite biometría. Utilice el botón debajo para crear una contraseña para acceder al Diario.")
                NavigationLink("Crear una Contraseña") {
                    CreatePasswordView()
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .padding()
                Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                    .font(.footnote)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var diarioPasswordAccessButton: some View {
#if os(macOS)
        Button("Acceder por contraseña") {
            showWindow(for: LogginView(ente: .Diario),
                       environmentObjects: [self.securityModel],
                       title: "Acceder Por contraseña",
                       size: AppCons.windows_size_content_small,
                       isModal: true)
        }
        .buttonStyle(.bordered)
        .tint(.black)
#else
        NavigationLink("Acceder por contraseña") {
            LogginView(ente: .Diario)
                .environmentObject(self.securityModel)
        }
        .buttonStyle(.bordered)
        .tint(.black)
#endif
    }

    @ViewBuilder
    private var diarioEntriesScroll: some View {
        ScrollView {
            LazyVStack {
                if selectedListMode == .all {
                    diarioFlatList
                } else {
                    diarioGroupedList
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var diarioFlatList: some View {
        ForEach(diarySearchVisibleEntries) { item in
            diarioCard(for: item)
        }
    }

    @ViewBuilder
    private var diarioGroupedList: some View {
        VStack(spacing: 0) {
            ForEach(groupedDiarioByChapter, id: \.chapter) { section in
                diarioChapterSection(section)
            }
        }
        .padding(.top, DiarioUIConstants.chapterListTopPadding)
    }

    @ViewBuilder
    private func diarioChapterSection(
        _ section: (chapter: String, entries: [Diario]),
        includesEntries: Bool = true
    ) -> some View {
        DiarioChapterSectionView(
            chapter: section.chapter,
            entries: section.entries,
            isCollapsed: collapsedChapterNames.contains(section.chapter),
            isSelectionMode: isBatchSelectionMode,
            includesEntries: includesEntries,
            availableChapters: existingChapters.filter {
                $0.localizedCaseInsensitiveCompare(section.chapter) != .orderedSame
            },
            onCollapseToggle: { toggleChapterCollapse(section.chapter) },
            onRenameChapter: { newChapter in
                renameChapter(section.chapter, to: newChapter)
            },
            onMoveChapter: { destinationChapter in
                moveChapter(section.chapter, to: destinationChapter)
            },
            onDeleteChapter: {
                deleteChapter(section.chapter)
            },
            rowContent: { item in
                diarioCard(for: item)
            }
        )
    }

    private var batchSelectionToolbar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("\(batchSelectedDiarioIDs.count) seleccionadas")
                    .font(.subheadline.bold())
                    .foregroundStyle(.black)

                Spacer()

                Button(areAllVisibleEntriesSelected ? "Deseleccionar todas" : "Seleccionar todas") {
                    toggleVisibleEntriesSelection()
                }
                .font(.subheadline.bold())
                .buttonStyle(.bordered)
                .tint(.black)
                .disabled(visibleDiarioIDs.isEmpty)
                .help(areAllVisibleEntriesSelected ? "Deseleccionar visibles" : "Seleccionar visibles")
            }

            HStack(spacing: 12) {
                Menu {
                    ForEach(Emociones.allCases, id: \.self) { emocion in
                        Button {
                            requestBatchActionConfirmation(.updateEmotion(emocion))
                        } label: {
                            HStack {
                                Text(emocion.localizedTitle)
                                Text(emocion.emoji)
                            }
                        }
                    }
                } label: {
                    Label("Cambiar emoción", systemImage: "face.smiling")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .disabled(batchSelectedDiarioIDs.isEmpty)
                .help("Cambiar emoción")

                Menu {
                    Button("Sin capítulo") {
                        requestBatchActionConfirmation(.updateChapter(""))
                    }
                    ForEach(existingChapters, id: \.self) { chapter in
                        Button(chapter) {
                            requestBatchActionConfirmation(.updateChapter(chapter))
                        }
                    }
                    Button("Otro...") {
                        batchChapterDraft = ""
                        showBatchChapterAlert = true
                    }
                } label: {
                    Label("Cambiar capítulo", systemImage: "book.closed")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .disabled(batchSelectedDiarioIDs.isEmpty)
                .help("Cambiar capítulo")

                Button(role: .destructive) {
                    showBatchDeleteConfirmation = true
                } label: {
                    Label("Borrar", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(batchSelectedDiarioIDs.isEmpty)
                .help("Borrar seleccionadas")
            }
        }
        .padding(10)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 3)
    }

    @ViewBuilder
    private func diarioCard(for item: Diario) -> some View {
        let isSelected = isDiarioSelected(item)
        let isActiveInSplitView = isDiarioActiveInSplitView(item)

        cardItemDiario(
            diario: item,
            onEntryDeleted: { deletedDate in
                withAnimation {
                    refreshAfterEntryDeletion(deletedDate)
                }
            },
            onEntryUpdated: { updatedDate in
                withAnimation {
                    refreshAfterEntryUpdate(updatedDate)
                }
            },
            isSelectionMode: isBatchSelectionMode,
            isSelected: isSelected,
            onSelectionToggle: {
                toggleBatchSelection(item)
            },
            isActiveInSplitView: isActiveInSplitView,
            usesDetailPanel: usesIPadDetailPanel,
            onActivate: {
                activateDiarioInSplitView(item)
            }
        )
        .padding(15)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.black)
        .background(
            isActiveInSplitView
                ? Color(red: 0.96, green: 0.82, blue: 0.66).opacity(0.82)
                : Color.white.opacity(0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? Color.orange : (isActiveInSplitView ? Color.accentColor.opacity(0.75) : Color.clear),
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .id(item.objectID)
    }

    private func isDiarioActiveInSplitView(_ item: Diario) -> Bool {
#if os(iOS)
        return isIPadInterface && activeDiarioID == item.id
#else
        return false
#endif
    }

    private func activateDiarioInSplitView(_ item: Diario) {
#if os(iOS)
        guard isIPadInterface, !isBatchSelectionMode else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDiarioID = item.id
        }
#endif
    }

    private var usesIPadDetailPanel: Bool {
#if os(iOS)
        isIPadInterface
#else
        false
#endif
    }

    private var visibleDiarioIDs: Set<UUID> {
        Set(diarySearchVisibleEntries.compactMap { $0.id })
    }

    private var areAllVisibleEntriesSelected: Bool {
        let ids = visibleDiarioIDs
        return !ids.isEmpty && ids.isSubset(of: batchSelectedDiarioIDs)
    }

    private func toggleBatchSelectionMode() {
        withAnimation {
            isBatchSelectionMode.toggle()
            if !isBatchSelectionMode {
                batchSelectedDiarioIDs.removeAll()
            }
        }
    }

    private func isDiarioSelected(_ item: Diario) -> Bool {
        guard let id = item.id else { return false }
        return batchSelectedDiarioIDs.contains(id)
    }

    private func toggleBatchSelection(_ item: Diario) {
        guard let id = item.id else { return }
        if batchSelectedDiarioIDs.contains(id) {
            batchSelectedDiarioIDs.remove(id)
        } else {
            batchSelectedDiarioIDs.insert(id)
        }
    }

    private func toggleVisibleEntriesSelection() {
        let ids = visibleDiarioIDs
        if areAllVisibleEntriesSelected {
            batchSelectedDiarioIDs.subtract(ids)
        } else {
            batchSelectedDiarioIDs.formUnion(ids)
        }
    }

    private var selectedDiarioEntries: [Diario] {
        modelDiario.list.filter { item in
            guard let id = item.id else { return false }
            return batchSelectedDiarioIDs.contains(id)
        }
    }

    private func toggleChapterCollapse(_ chapter: String) {
        if collapsedChapterNames.contains(chapter) {
            collapsedChapterNames.remove(chapter)
        } else {
            collapsedChapterNames.insert(chapter)
        }
    }

    private func deleteSelectedEntries() {
        let idsToDelete = batchSelectedDiarioIDs
        guard !idsToDelete.isEmpty else { return }

        withAnimation {
            modelDiario.DeleteItems(ids: idsToDelete)
            finishBatchOperation()
            refreshAfterEntryDeletion(nil)
        }
    }

    private func requestBatchActionConfirmation(_ action: DiarioBatchAction) {
        guard !batchSelectedDiarioIDs.isEmpty else { return }
        DispatchQueue.main.async {
            pendingBatchAction = action
            showBatchActionConfirmation = true
        }
    }

    private func performConfirmedBatchAction(_ action: DiarioBatchAction) {
        switch action {
        case .updateEmotion(let emotion):
            updateSelectedEntriesEmotion(emotion)
        case .updateChapter(let chapter):
            updateSelectedEntriesChapter(chapter)
        }
    }

    private func updateSelectedEntriesEmotion(_ emotion: Emociones) {
        let idsToUpdate = batchSelectedDiarioIDs
        guard !idsToUpdate.isEmpty else { return }

        withAnimation {
            modelDiario.UpdateEmoticono(emoticono: emotion, ids: idsToUpdate)
            finishBatchOperation()
            refreshAfterEntryUpdate(nil)
        }
    }

    private func updateSelectedEntriesChapter(_ chapter: String) {
        let idsToUpdate = batchSelectedDiarioIDs
        guard !idsToUpdate.isEmpty else { return }

        withAnimation {
            modelDiario.UpdateCapitulo(capitulo: chapter, ids: idsToUpdate)
            finishBatchOperation()
            refreshAfterEntryUpdate(nil)
        }
    }

    private func renameChapter(_ oldChapter: String, to newChapter: String) {
        let trimmedChapter = newChapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNewChapter = trimmedChapter.isEmpty ? unchapteredTitle : trimmedChapter
        guard oldChapter != normalizedNewChapter else { return }

        let idsToUpdate = Set(modelDiario.list.compactMap { item -> UUID? in
            chapterName(for: item) == oldChapter ? item.id : nil
        })
        guard !idsToUpdate.isEmpty else { return }

        modelDiario.UpdateCapitulo(capitulo: trimmedChapter, ids: idsToUpdate)

        if collapsedChapterNames.remove(oldChapter) != nil {
            collapsedChapterNames.insert(normalizedNewChapter)
        }

        refreshAfterEntryUpdate(nil)
        alertMessage = L10n.format("diary.updated.count", fallback: "{0} entrada(s) actualizada(s).", String(idsToUpdate.count))
        showAlert = true
    }

    private func moveChapter(_ oldChapter: String, to destinationChapter: String) {
        let trimmedChapter = destinationChapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDestination = trimmedChapter.isEmpty ? unchapteredTitle : trimmedChapter
        guard oldChapter != normalizedDestination else { return }

        let idsToUpdate = Set(modelDiario.list.compactMap { item -> UUID? in
            chapterName(for: item) == oldChapter ? item.id : nil
        })
        guard !idsToUpdate.isEmpty else { return }

        modelDiario.UpdateCapitulo(capitulo: trimmedChapter, ids: idsToUpdate)
        collapsedChapterNames.remove(oldChapter)
        if normalizedDestination != unchapteredTitle {
            collapsedChapterNames.remove(normalizedDestination)
        }

        refreshAfterEntryUpdate(nil)
        alertMessage = L10n.format("diary.moved.count", fallback: "{0} entrada(s) movida(s).", String(idsToUpdate.count))
        showAlert = true
    }

    private func deleteChapter(_ chapter: String) {
        let idsToDelete = Set(modelDiario.list.compactMap { item -> UUID? in
            chapterName(for: item) == chapter ? item.id : nil
        })
        guard !idsToDelete.isEmpty else { return }

        modelDiario.DeleteItems(ids: idsToDelete)
        collapsedChapterNames.remove(chapter)
        batchSelectedDiarioIDs.subtract(idsToDelete)
        refreshAfterEntryDeletion(nil)
        alertMessage = L10n.format("diary.deleted.count", fallback: "{0} entrada(s) eliminada(s).", String(idsToDelete.count))
        showAlert = true
    }

    private func finishBatchOperation() {
        batchSelectedDiarioIDs.removeAll()
        isBatchSelectionMode = false
        calendarRefreshTrigger += 1
    }

    private func openNewEntryEditor(title: String, content: String, emocion: Emociones, date: Date) {
        newEntryTitle = title
        newEntryContent = content
        newEntryEmotion = emocion
        newEntryDate = Calendar.current.startOfDay(for: date)

#if os(macOS)
        showWindow(
            for: NewDiarioEntryView(
                title: newEntryTitle,
                content: newEntryContent,
                emocion: newEntryEmotion,
                fechaCreacion: newEntryDate
            ) { savedDate in
                refreshAfterEntryCreation(savedDate)
            },
            environmentObjects: [self.modelDiario],
            title: "Nueva Entrada",
            size: AppCons.windows_size_content,
            isModal: true
        )
#else
        showNewEntryEditor = true
#endif
    }

    private func refreshAfterEntryCreation(_ savedDate: Date) {
        calendarRefreshTrigger += 1
        selectedCalendarDate = Calendar.current.startOfDay(for: savedDate)
        modelDiario.list = modelDiario.searchPorFecha(for: savedDate)

        if FeedBackModel.checkReviewRequest() {
            #if os(macOS)
            showWindow(
                for: FeedbackView(showTextBotton: false),
                environmentObjects: [],
                title: "Enviar una Reseña a la App Store",
                size: AppCons.windows_size_content_small,
                isModal: true
            )
            #else
            sheetShowFeedBackReview = true
            #endif
        }
    }

    private func refreshAfterEntryDeletion(_ : Date?) {
        calendarRefreshTrigger += 1

        if let selectedCalendarDate {
            modelDiario.list = modelDiario.searchPorFecha(for: selectedCalendarDate)
            return
        }

        modelDiario.getAllItem()
    }

    private func refreshAfterEntryUpdate(_ : Date?) {
        if let selectedCalendarDate {
            modelDiario.list = modelDiario.searchPorFecha(for: selectedCalendarDate)
            return
        }

        modelDiario.getAllItem()
    }

    @ViewBuilder
    private func exportDiarioPDFMenu() -> some View {
        Menu {
            Button("Manual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                manuallySelectedDiarioIDs.removeAll()
                showManualExportSheet = true
            }
            Button("Semana actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                exportDiarioToPDF(diarioCurrentWeek(), scopeName: "Semana")
            }
            Button("Mes actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                exportDiarioToPDF(diarioCurrentMonth(), scopeName: "Mes")
            }
            Button("Rango de fechas") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                showExportRangeSheet = true
            }
        } label: {
            Label("Exportar PDF", systemImage: "doc.richtext")
        }
    }

    private func toggleManualDiarioSelection(_ item: Diario) {
        guard let id = item.id else { return }
        if manuallySelectedDiarioIDs.contains(id) {
            manuallySelectedDiarioIDs.remove(id)
        } else {
            manuallySelectedDiarioIDs.insert(id)
        }
    }

    private func diarioCurrentWeek() -> [Diario] {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return diarioInRange(from: interval.start, to: interval.end)
    }

    private func diarioCurrentMonth() -> [Diario] {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .month, for: now) else { return [] }
        return diarioInRange(from: interval.start, to: interval.end)
    }

    private func diarioInRange(from start: Date, to end: Date) -> [Diario] {
        modelDiario.list.filter { item in
            guard let date = item.fecha else { return false }
            return date >= start && date < end
        }
    }

    private func exportDiarioRangeToPDF(from start: Date, to end: Date) {
        let items = modelDiario.searchPorRangoFecha(from: start, to: end, typeFecha: .FechaCreacion)
        exportDiarioToPDF(items, scopeName: "Rango")
    }

    private func exportDiarioToPDF(_ entries: [Diario], scopeName: String) {
        guard hasPremiumPDFAccess else {
            alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
            showAlert = true
            return
        }
        let exportableEntries = privateRitualReflections
            ? entries.filter { chapterValue(for: $0) != "Cierre consciente" }
            : entries
        guard !exportableEntries.isEmpty else {
            alertMessage = L10n.format("diary.pdf.empty", fallback: "No hay entradas para exportar en {0}.", L10n.exact(scopeName).lowercased())
            showAlert = true
            return
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: exportableEntries) { entry in
            calendar.startOfDay(for: entry.fecha ?? Date.distantPast)
        }

        let sections: [PDFExportSection] = grouped.keys.sorted().map { day in
            let dayEntries = (grouped[day] ?? []).sorted { ($0.fecha ?? .distantPast) < ($1.fecha ?? .distantPast) }
            let lines: [PDFExportLine] = dayEntries.map { item in
                let title = (item.title ?? "").isEmpty ? "Sin título" : (item.title ?? "Sin título")
                let emotion = Emociones.emoji(from: item.emotion)
                let content = (item.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let detail = content.isEmpty ? "Estado: \(emotion)" : "Estado: \(emotion)\n\(content)"
                return PDFExportLine(title: title, detail: detail)
            }
            return PDFExportSection(title: day.formatted(date: .complete, time: .omitted), lines: lines)
        }

        let descriptor = PDFExportDocumentDescriptor(
            title: "Diario - \(scopeName)",
            subtitle: "Generado el \(Date().formatted(date: .abbreviated, time: .shortened))",
            sections: sections
        )

        do {
            let data = try PDFExportModule.render(descriptor)
            exportedPDFDocument = ExportedPDFDocument(data: data)
            let dateLabel = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
            exportedPDFFileName = "Diario-\(scopeName)-\(dateLabel)"
            showPDFExporter = true
        } catch {
            alertMessage = L10n.exact("No se pudo generar el PDF.")
            showAlert = true
        }
    }

    private var unchapteredTitle: String {
        L10n.exact("Sin capítulo")
    }

    private func chapterValue(for item: Diario) -> String {
        item.value(forKey: "capitulo") as? String ?? ""
    }

    private func chapterName(for item: Diario) -> String {
        let value = chapterValue(for: item).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? unchapteredTitle : value
    }

    private var existingChapters: [String] {
        Array(Set(modelDiario.getAllItemGET().compactMap { item in
            let value = chapterValue(for: item).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

}

#if os(iOS)
private extension View {
    func diaryIPadPanel(material: Material) -> some View {
        background(material)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            }
    }
}

/// Divisor ajustable y persistente para el área de trabajo del Diario.
private struct AdjustableDiarioSplitView<Primary: View, Secondary: View>: View {
    @Environment(\.locale) private var locale

    let layout: DiarioSplitLayout
    @Binding var primaryFraction: Double
    let minimumPrimaryLength: CGFloat
    let minimumSecondaryLength: CGFloat
    @ViewBuilder let primary: () -> Primary
    @ViewBuilder let secondary: () -> Secondary

    @GestureState private var dragTranslation: CGFloat = 0
    private let dividerLength: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let totalLength = layout == .sideBySide ? proxy.size.width : proxy.size.height
            let availableLength = max(0, totalLength - dividerLength)
            let limits = fractionLimits(availableLength: availableLength)
            let dragFraction = availableLength > 0
                ? Double(dragTranslation / availableLength)
                : 0
            let interactiveFraction = primaryFraction + dragFraction
            let resolvedFraction = min(max(interactiveFraction, limits.lower), limits.upper)
            let primaryLength = availableLength * resolvedFraction

            if layout == .sideBySide {
                HStack(spacing: 0) {
                    primary().frame(width: primaryLength)
                    divider(availableLength: availableLength, limits: limits)
                    secondary().frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 0) {
                    primary().frame(height: primaryLength)
                    divider(availableLength: availableLength, limits: limits)
                    secondary().frame(maxHeight: .infinity)
                }
            }
        }
    }

    private func divider(
        availableLength: CGFloat,
        limits: (lower: Double, upper: Double)
    ) -> some View {
        ZStack {
            Color.clear
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(width: layout == .sideBySide ? 1 : nil, height: layout == .stacked ? 1 : nil)
            Capsule(style: .continuous)
                .fill(.secondary.opacity(0.55))
                .frame(width: layout == .sideBySide ? 4 : 42, height: layout == .sideBySide ? 42 : 4)
        }
        .frame(width: layout == .sideBySide ? dividerLength : nil, height: layout == .stacked ? dividerLength : nil)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .updating($dragTranslation) { value, state, transaction in
                    transaction.disablesAnimations = true
                    state = layout == .sideBySide
                        ? value.translation.width
                        : value.translation.height
                }
                .onEnded { value in
                    guard availableLength > 0 else { return }
                    let translation = layout == .sideBySide
                        ? value.translation.width
                        : value.translation.height
                    let candidate = primaryFraction
                        + Double(translation / availableLength)
                    let finalFraction = min(max(candidate, limits.lower), limits.upper)

                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        primaryFraction = finalFraction
                    }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Ajustar tamaño de los paneles")
        .accessibilityValue(
            primaryFraction.formatted(
                .percent.precision(.fractionLength(0)).locale(locale)
            )
        )
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 0.05 : -0.05
            primaryFraction = min(max(primaryFraction + step, limits.lower), limits.upper)
        }
    }

    private func fractionLimits(availableLength: CGFloat) -> (lower: Double, upper: Double) {
        guard availableLength > 0 else { return (0, 1) }
        let effectivePrimaryMinimum = min(minimumPrimaryLength, availableLength * 0.48)
        let effectiveSecondaryMinimum = min(minimumSecondaryLength, availableLength * 0.48)
        let lower = Double(effectivePrimaryMinimum / availableLength)
        let upper = Double((availableLength - effectiveSecondaryMinimum) / availableLength)
        return (lower, max(lower, upper))
    }
}
#endif

private struct DiarioChapterSectionView<RowContent: View>: View {
    let chapter: String
    let entries: [Diario]
    let isCollapsed: Bool
    let isSelectionMode: Bool
    let includesEntries: Bool
    let availableChapters: [String]
    let onCollapseToggle: () -> Void
    let onRenameChapter: (String) -> Void
    let onMoveChapter: (String) -> Void
    let onDeleteChapter: () -> Void
    let rowContent: (Diario) -> RowContent

    @State private var showRenameAlert = false
    @State private var chapterDraft = ""
    @State private var showMoveAlert = false
    @State private var moveChapterDraft = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    onCollapseToggle()
                } label: {
                    Image(systemName: isCollapsed ? "chevron.right.circle.fill" : "chevron.down.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.black.opacity(0.75))
                }
                .buttonStyle(.plain)

                Button {
                    onCollapseToggle()
                } label: {
                    Text(chapter)
                        .font(.system(size: DiarioUIConstants.chapterTitleFontSize, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(entries.count)")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.7))

                Menu {
                    Text("- Capítulo -")
                    Button {
                        chapterDraft = chapter == "Sin capítulo" ? "" : chapter
                        showRenameAlert = true
                    } label: {
                        Label("Editar nombre", systemImage: "pencil")
                    }
                    Menu {
                        Button("Sin capítulo") {
                            onMoveChapter("")
                        }
                        ForEach(availableChapters, id: \.self) { destinationChapter in
                            Button(destinationChapter) {
                                onMoveChapter(destinationChapter)
                            }
                        }
                        Button("Nuevo...") {
                            moveChapterDraft = ""
                            showMoveAlert = true
                        }
                    } label: {
                        Label("Mover entradas a...", systemImage: "arrowshape.turn.up.right")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Eliminar entradas", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.7))
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                .disabled(isSelectionMode)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if includesEntries && !isCollapsed {
                ForEach(entries) { entry in
                    rowContent(entry)
                }
            }
        }
        .alert("Renombrar capítulo", isPresented: $showRenameAlert) {
            TextField("Capítulo", text: $chapterDraft, axis: .vertical)
            Button("Cancelar", role: .cancel) {}
            Button("Actualizar") {
                onRenameChapter(chapterDraft)
            }
        } message: {
            Text("Se actualizarán las entradas de este capítulo.")
        }
        .alert("Mover entradas", isPresented: $showMoveAlert) {
            TextField("Capítulo", text: $moveChapterDraft, axis: .vertical)
            Button("Cancelar", role: .cancel) {}
            Button("Mover") {
                onMoveChapter(moveChapterDraft)
            }
        } message: {
            Text("Todas las entradas de este capítulo pasarán al capítulo indicado.")
        }
        .confirmationDialog("¿Eliminar todas las entradas de este capítulo?", isPresented: $showDeleteConfirmation) {
            Button("Eliminar \(entries.count) entrada(s)", role: .destructive) {
                onDeleteChapter()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }
}
