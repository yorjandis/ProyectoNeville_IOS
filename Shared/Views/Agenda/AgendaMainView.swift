#if os(iOS) || os(macOS)
import SwiftUI
import Combine
import UniformTypeIdentifiers
import MapKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum PetSettings {
    static let isEnabledKey = "pets.enabled"
    static let selectedPetKey = "pets.selectedAssetName"
    static let defaultPetAssetName = "nini"
    static let settingsCarouselPetSize: CGFloat = 32

    /// Mascotas disponibles en el bundle: imágenes PNG cuyo nombre no contiene `_`.
    static var availablePetAssetNames: [String] {
        let bundledNames = (Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])
            .filter { $0.pathExtension.lowercased() == "png" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .filter { !$0.contains("_") && !$0.localizedCaseInsensitiveContains("appicon") }

        return Array(Set(bundledNames))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    static func resolvedAssetName(_ assetName: String) -> String {
        let availablePets = availablePetAssetNames
        return availablePets.contains(assetName) ? assetName : (availablePets.first ?? assetName)
    }

    static func displayName(for assetName: String) -> String {
        assetName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    static func imageURL(for assetName: String) -> URL? {
        let supportedExtensions = ["png", "jpg", "jpeg", "webp"]
        return supportedExtensions.lazy.compactMap {
            Bundle.main.url(forResource: assetName, withExtension: $0)
        }.first
    }
}

struct PetImage: View {
    let assetName: String

    var body: some View {
#if os(macOS)
        if let url = PetSettings.imageURL(for: assetName), let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        }
#else
        if let url = PetSettings.imageURL(for: assetName), let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
#endif
    }
}

enum AgendaUIConstants {
    static let calendarBackgroundOpacity: Double = 0.5
    static let activityCardBackgroundOpacity: Double = 0.5
    static let priorityBackgroundOpacity: Double = 0.7

    // Ajustes manuales de la mascota del estado vacío de Agenda.
    static let emptyTodayPetSize: CGFloat = 250
    static let emptyTodayPetOffset = CGSize(width: 0, height: -48)
    static let emptyTodayPetEntranceDuration: Double = 0.65

#if os(macOS)
    static let activityCardCornerRadius: CGFloat = 10
#else
    static let activityCardCornerRadius: CGFloat = 10
#endif
}

enum CheckFilter: String, CaseIterable, Identifiable {
    case todas = "Todas"
    case activas = "Activas"
    case completadas = "Completadas"
    var id: String { rawValue }
    var title: String { L10n.exact(rawValue) }
}

#if os(iOS)
/// Replica el selector de disposición de Notas para que Agenda pueda seguir la
/// orientación del iPad o forzar cualquiera de los dos espacios de trabajo.
private enum AgendaIPadLayoutMode: String, CaseIterable {
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

    func resolvedLayout(for size: CGSize) -> AgendaSplitLayout {
        switch self {
        case .automatic:
            return size.width >= size.height ? .sideBySide : .stacked
        case .sideBySide:
            return .sideBySide
        case .stacked:
            return .stacked
        }
    }
}

private enum AgendaSplitLayout {
    case sideBySide
    case stacked
}

private enum AgendaInlineEditorField: Hashable {
    case title
    case location
    case content
}

/// Conserva la presentación tipo hoja en iPhone, pero permite que los destinos
/// adaptados aprovechen toda la superficie del iPad.
extension View {
    @ViewBuilder
    func iPadFullScreenPresentation<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            fullScreenCover(isPresented: isPresented, content: content)
        } else {
            sheet(isPresented: isPresented, content: content)
        }
    }

    func iPadFullScreenPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        shouldUseFullScreen: @escaping (Item) -> Bool,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        let fullScreenItem = Binding<Item?>(
            get: {
                guard UIDevice.current.userInterfaceIdiom == .pad,
                      let value = item.wrappedValue,
                      shouldUseFullScreen(value) else { return nil }
                return value
            },
            set: { item.wrappedValue = $0 }
        )
        let sheetItem = Binding<Item?>(
            get: {
                guard let value = item.wrappedValue else { return nil }
                if UIDevice.current.userInterfaceIdiom == .pad && shouldUseFullScreen(value) {
                    return nil
                }
                return value
            },
            set: { item.wrappedValue = $0 }
        )

        return fullScreenCover(item: fullScreenItem, content: content)
            .sheet(item: sheetItem, content: content)
    }

    @ViewBuilder
    func iPadFullScreenDismissButton(
        alignment: Alignment = .topTrailing
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            overlay(alignment: alignment) {
                IPadFullScreenDismissButton()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        } else {
            self
        }
    }
}

private struct IPadFullScreenDismissButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Label("Cerrar", systemImage: "xmark")
                .font(.callout.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .tint(.black.opacity(0.72))
        .accessibilityHint("Cierra la vista y vuelve a la pantalla anterior")
    }
}
#endif

struct AgendaMainView: View {
    private let presentsNewItemOnAppear: Bool

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = AgendaViewModel()
    @State private var editorItem: AgendaItemData?
    @State private var hasPresentedInitialItem = false
    @State private var showReminderManager = false
    @State private var isCalendarExpanded = false
    @State private var expandedContentIDs: Set<UUID> = []
    @State private var displayedMonth: Date = Date()
    @State private var showReminderValidationAlert = false
    @State private var reminderValidationMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var itemPendingDelete: AgendaItemData?
    @State private var showBulkDeleteConfirmation = false
    @State private var bulkDeleteItems: [AgendaItemData] = []
    @State private var showInterchangeAlert = false
    @State private var interchangeAlertMessage = ""
    @State private var showMapsAlert = false
    @State private var mapsAlertMessage = ""
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName: String = "Agenda.pdf"
    @State private var multiSelectionMode = false
    @State private var selectedItemsIDs: Set<UUID> = []
    @State private var pendingBulkAction: AgendaBulkAction?
    @State private var showBulkActionConfirmation = false
    @State private var showMigrationPasswordSheet = false
    @State private var showMigrationExporter = false
    @State private var migrationPassword = ""
    @State private var migrationPasswordConfirmation = ""
    @State private var migrationDocument: MigrationDataDocument?
    @State private var migrationExportFileName = "neville-agenda.ypgexp"
    @State private var migrationExportCount = 0
    @State private var showPastActivities: Bool = false
    @AppStorage("agendaSearchBarVisible") private var showSearchBar = false
    @State private var searchText: String = ""
    @State private var revealLocationIDs: Set<UUID> = []
    @State private var hasEvaluatedInitialTodayAvailability = false
    @State private var hasCompletedPetEntrance = false
    @State private var checkFilter: CheckFilter = .todas
#if os(iOS)
    @AppStorage("agendaIPadLayoutMode") private var iPadLayoutMode: AgendaIPadLayoutMode = .automatic
    @AppStorage("agendaIPadSidePanelFraction") private var iPadSidePanelFraction = 0.38
    @AppStorage("agendaIPadTopPanelFraction") private var iPadTopPanelFraction = 0.43
    @AppStorage("agendaIPadCalendarVisible") private var isIPadCalendarVisible = true
    @State private var selectedAgendaItemID: UUID?
    @State private var iPadListScrollTargetID: UUID?
    @State private var iPadListScrollTargetDate: Date?
    @State private var iPadListScrollRequest = 0
    @State private var inlineEditingAgendaItemID: UUID?
    @State private var inlineDraftTitle = ""
    @State private var inlineDraftHour = Date()
    @State private var inlineDraftReminderEnabled = false
    @State private var inlineDraftPriority: AgendaPriority = .neutral
    @State private var inlineDraftContent = ""
    @State private var inlineDraftLocation = ""
    @StateObject private var inlineLocationCapture = AgendaLocationCapture()
    @State private var isCapturingInlineLocation = false
    @State private var showInlineLocationAlert = false
    @State private var inlineLocationAlertMessage = ""
    @State private var inlineLocationCanOpenSettings = false
    @FocusState private var focusedInlineEditorField: AgendaInlineEditorField?
#endif
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage(PetSettings.isEnabledKey) private var petsEnabled = true
    @AppStorage(PetSettings.selectedPetKey) private var selectedPetAssetName = PetSettings.defaultPetAssetName

    private enum AgendaBulkAction: Identifiable {
        case delete
        case markCompleted
        case clearCheck
        case activateReminders
        case deactivateReminders
        case exportPDF
        case exportMigration
#if os(iOS)
        case exportAppleCalendar
        case exportAppleReminders
#endif

        var id: String {
            switch self {
            case .delete:
                return "delete"
            case .markCompleted:
                return "markCompleted"
            case .clearCheck:
                return "clearCheck"
            case .activateReminders:
                return "activateReminders"
            case .deactivateReminders:
                return "deactivateReminders"
            case .exportPDF:
                return "exportPDF"
            case .exportMigration:
                return "exportMigration"
#if os(iOS)
            case .exportAppleCalendar:
                return "exportAppleCalendar"
            case .exportAppleReminders:
                return "exportAppleReminders"
#endif
            }
        }

        var confirmTitle: String {
            switch self {
            case .delete:
                return L10n.exact("Eliminar")
            case .markCompleted:
                return L10n.exact("Marcar completadas")
            case .clearCheck:
                return L10n.exact("Quitar check")
            case .activateReminders:
                return L10n.exact("Activar")
            case .deactivateReminders:
                return L10n.exact("Desactivar")
            case .exportPDF:
                return L10n.exact("Exportar PDF")
            case .exportMigration:
                return L10n.exact("Continuar")
#if os(iOS)
            case .exportAppleCalendar:
                return L10n.exact("Exportar a Calendario")
            case .exportAppleReminders:
                return L10n.exact("Exportar a Recordatorios")
#endif
            }
        }

        var role: ButtonRole? {
            switch self {
            case .delete:
                return .destructive
            default:
                return nil
            }
        }

        func message(count: Int) -> String {
            let singular = count == 1
            switch self {
            case .delete:
                return L10n.format(
                    singular ? "agenda.bulk.delete.singular" : "agenda.bulk.delete",
                    fallback: singular
                        ? "Se eliminará {0} actividad seleccionada, incluido su recordatorio."
                        : "Se eliminarán {0} actividades seleccionadas, incluidos sus recordatorios.",
                    "\(count)"
                )
            case .markCompleted:
                return L10n.format(
                    singular ? "agenda.bulk.complete.singular" : "agenda.bulk.complete",
                    fallback: singular ? "Se marcará como completada {0} actividad seleccionada." : "Se marcarán como completadas {0} actividades seleccionadas.",
                    "\(count)"
                )
            case .clearCheck:
                return L10n.format(
                    singular ? "agenda.bulk.clear_check.singular" : "agenda.bulk.clear_check",
                    fallback: singular ? "Se quitará el modo check de {0} actividad seleccionada." : "Se quitará el modo check de {0} actividades seleccionadas.",
                    "\(count)"
                )
            case .activateReminders:
                return L10n.format(
                    singular ? "agenda.bulk.enable_reminders.singular" : "agenda.bulk.enable_reminders",
                    fallback: singular ? "Se activará el recordatorio de {0} actividad seleccionada." : "Se activarán los recordatorios de {0} actividades seleccionadas.",
                    "\(count)"
                )
            case .deactivateReminders:
                return L10n.format(
                    singular ? "agenda.bulk.disable_reminders.singular" : "agenda.bulk.disable_reminders",
                    fallback: singular ? "Se desactivará el recordatorio de {0} actividad seleccionada." : "Se desactivarán los recordatorios de {0} actividades seleccionadas.",
                    "\(count)"
                )
            case .exportPDF:
                return L10n.format(
                    singular ? "agenda.bulk.export_pdf.singular" : "agenda.bulk.export_pdf",
                    fallback: singular ? "Se preparará un PDF con {0} actividad seleccionada." : "Se preparará un PDF con {0} actividades seleccionadas.",
                    "\(count)"
                )
            case .exportMigration:
                return L10n.format(
                    singular ? "agenda.bulk.export_migration.singular" : "agenda.bulk.export_migration",
                    fallback: singular ? "Se preparará un archivo de migración con {0} actividad seleccionada." : "Se preparará un archivo de migración con {0} actividades seleccionadas.",
                    "\(count)"
                )
#if os(iOS)
            case .exportAppleCalendar:
                return singular
                    ? "Se exportará 1 actividad seleccionada a Calendario de Apple."
                    : "Se exportarán \(count) actividades seleccionadas a Calendario de Apple."
            case .exportAppleReminders:
                return singular
                    ? "Se exportará 1 actividad seleccionada a Recordatorios de Apple."
                    : "Se exportarán \(count) actividades seleccionadas a Recordatorios de Apple."
#endif
            }
        }
    }

    private var menuGestion: some View {
        let monthItems = itemsInDisplayedMonth()
        let weekItems = itemsInActiveWeek()
        let listedItems = currentListedItems()
        let hasDeleteActions = !monthItems.isEmpty || !weekItems.isEmpty
        let hasSelectionActions = !listedItems.isEmpty

        return Menu {
            Button("Recordatorios") {
                showReminderManager = true
            }
            Button(L10n.exact(showSearchBar ? "Ocultar búsqueda" : "Mostrar búsqueda")) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSearchBar.toggle()
                    if !showSearchBar {
                        searchText = ""
                    }
                }
            }
            Divider()
            Button("Exportar semana a PDF") {
                exportCurrentWeekToPDF()
            }
            Button("Exportar mes a PDF") {
                exportCurrentMonthToPDF()
            }

            if !monthItems.isEmpty {
                Button("Eliminar mes actual", role: .destructive) {
                    bulkDeleteItems = monthItems
                    showBulkDeleteConfirmation = true
                }
            }
            if !weekItems.isEmpty {
                Button("Eliminar semana actual", role: .destructive) {
                    bulkDeleteItems = weekItems
                    showBulkDeleteConfirmation = true
                }
            }

            if hasDeleteActions && hasSelectionActions {
                Divider()
            }

            if hasSelectionActions {
                Button(L10n.exact(multiSelectionMode ? "Salir selección múltiple" : "Selección múltiple")) {
                    multiSelectionMode.toggle()
                    if !multiSelectionMode { selectedItemsIDs.removeAll() }
                }
            }

            if !hasDeleteActions && !hasSelectionActions {
                Text("Sin acciones disponibles")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    init(presentsNewItemOnAppear: Bool = false) {
        self.presentsNewItemOnAppear = presentsNewItemOnAppear
    }

    private var addButton: some View {
        Button {
            editorItem = viewModel.create(selectedDate: viewModel.selectedDate)
        } label: {
            Image(systemName: "plus")
        }
    }

    private var quickFilterMenuLabel: some View {
        HStack(spacing: 6) {
            Text("Filtro")
            Text(viewModel.quickFilter.title)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(.black)
#if os(iOS)
        .padding(.horizontal, 0)
#else
        .padding(.horizontal, 10)
#endif
        .padding(.vertical, 8)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }

    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.black.opacity(0.6))
            TextField(
                "",
                text: $searchText,
                prompt: Text("Buscar en título, nota,contenido,prioridad, estado check")
                    .foregroundStyle(.black.opacity(0.75))
            )
            .foregroundStyle(.black)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
#else
            .textFieldStyle(.plain)
#endif
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.black.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            if multiSelectionMode {
                selectionHeader
            }
            topControls
            if showSearchBar {
                searchBarView
            }
            if isCalendarExpanded {
                customCalendarView
                    .padding(10)
                    .background(.white.opacity(AgendaUIConstants.calendarBackgroundOpacity), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            activitiesList
            if multiSelectionMode {
                bulkActionsBar()
            }
        }
        .padding(.horizontal, 10)
    }

#if os(iOS)
    private var isIPadInterface: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var iPadListedItems: [AgendaItemData] {
        let regularItems = filteredItems(viewModel.itemsForSelectedDay)
        guard showPastActivities else { return regularItems }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let pastItems = filteredItems(
            viewModel.items.filter {
                Calendar.current.startOfDay(for: $0.fechaActividad) < startOfToday
            }
        )

        // Si el calendario ya apunta a una fecha pasada, evita repetir esa
        // entrada al activar el botón de actividades pasadas.
        var seenIDs = Set<UUID>()
        return (pastItems + regularItems)
            .filter { seenIDs.insert($0.id).inserted }
            .sorted { left, right in
                if Calendar.current.isDate(left.fechaActividad, inSameDayAs: right.fechaActividad) {
                    return left.hora < right.hora
                }
                return left.fechaActividad > right.fechaActividad
            }
    }

    private var activeAgendaItem: AgendaItemData? {
        if let selectedAgendaItemID,
           let selected = iPadListedItems.first(where: { $0.id == selectedAgendaItemID }) {
            return selected
        }
        return iPadListedItems.first
    }

    private var activeAgendaItemID: UUID? {
        activeAgendaItem?.id
    }

    private var iPadListSections: [(date: Date, items: [AgendaItemData])] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let grouped = Dictionary(grouping: iPadListedItems) {
            calendar.startOfDay(for: $0.fechaActividad)
        }
        let orderedDates = grouped.keys.sorted { left, right in
            guard showPastActivities else { return left < right }
            let leftIsPast = left < startOfToday
            let rightIsPast = right < startOfToday
            if leftIsPast != rightIsPast {
                return leftIsPast
            }
            return leftIsPast ? left > right : left < right
        }
        return orderedDates.map { date in
            let items = (grouped[date] ?? []).sorted { left, right in
                left.hora < right.hora
            }
            return (date: date, items: items)
        }
    }

    /// En apaisado el panel maestro queda a la izquierda. En retrato, el panel
    /// maestro pasa arriba y organiza lista/calendario en dos columnas.
    private var iPadAgendaWorkspace: some View {
        Group {
            if inlineEditingAgendaItemID != nil {
                // Durante la edición el detalle ocupa todo el espacio disponible.
                // Así desaparece el panel adyacente y el sistema puede colocar el
                // formulario por encima del teclado sin recalcular el divisor.
                iPadAgendaDetailPanel(showsPet: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
            } else {
                iPadAgendaSplitWorkspace
                    // Fuera del editor conservamos estable la geometría de los
                    // paneles ante teclados auxiliares, como el de búsqueda.
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .onChange(of: activeAgendaItemID) { _, newValue in
            if let inlineEditingAgendaItemID,
               inlineEditingAgendaItemID != newValue {
                cancelInlineAgendaEditing()
            }
        }
    }

    private var iPadAgendaSplitWorkspace: some View {
        GeometryReader { proxy in
            let layout = iPadLayoutMode.resolvedLayout(for: proxy.size)

            AdjustableAgendaSplitView(
                layout: layout,
                primaryFraction: layout == .sideBySide
                    ? $iPadSidePanelFraction
                    : $iPadTopPanelFraction,
                minimumPrimaryLength: layout == .sideBySide ? 330 : 360,
                minimumSecondaryLength: layout == .sideBySide ? 420 : 250
            ) {
                if layout == .sideBySide {
                    iPadLandscapeMasterPanel
                } else {
                    iPadPortraitMasterPanel
                }
            } secondary: {
                iPadAgendaDetailPanel(showsPet: layout == .sideBySide)
            }
        }
    }

    private var iPadLandscapeMasterPanel: some View {
        VStack(spacing: 0) {
            if isIPadCalendarVisible {
                customCalendarView
                    .padding(12)
                    .transition(.move(edge: .top).combined(with: .opacity))

                Divider()
            }
            iPadListControls
            Divider()
            iPadAgendaList
        }
        .agendaIPadPanel(material: .thinMaterial)
    }

    private var iPadPortraitMasterPanel: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                iPadListControls
                Divider()
                iPadAgendaList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isIPadCalendarVisible {
                Divider()

                ScrollView {
                    VStack(spacing: 8) {
                        customCalendarView
                            .padding(12)

                        if shouldShowEmptyTodayPet {
                            interactiveAgendaPet(size: 150)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 10)
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .agendaIPadPanel(material: .thinMaterial)
    }

    private var iPadListControls: some View {
        VStack(spacing: 8) {
            if multiSelectionMode {
                selectionHeader
            }

            HStack(spacing: 8) {
                filterMenu
                checkFilterMenu
                
                Spacer(minLength: 0)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPastActivities.toggle()
                    }
                } label: {
                    Image(systemName: showPastActivities ? "clock.arrow.circlepath" : "clock")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black.opacity(0.65))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(
                    showPastActivities ? "Ocultar actividades pasadas" : "Mostrar actividades pasadas"
                )
                .padding(.horizontal, 10)
                
               
                
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isIPadCalendarVisible.toggle()
                    }
                } label: {
                    Image(
                        systemName: isIPadCalendarVisible
                            ? "calendar.badge.minus"
                            : "calendar.badge.plus"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black.opacity(0.65))
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isIPadCalendarVisible ? "Ocultar calendario" : "Mostrar calendario"
                )
                .accessibilityHint("También oculta o muestra la mascota situada bajo el calendario")
            }

            if showSearchBar {
                searchBarView
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var iPadAgendaList: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    if iPadListSections.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.title2)
                            Text("No hay entradas para este filtro")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.black.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(iPadListSections, id: \.date) { section in
                        Section {
                            ForEach(section.items) { item in
                                agendaCard(item, fixedHeight: false)
                            }
                        } header: {
                            Text(daySectionTitle(section.date))
                                .foregroundStyle(.black)
                                .id(iPadAgendaSectionScrollID(section.date))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: iPadListScrollRequest) { _, _ in
                    guard let target = iPadListScrollTargetID else { return }
                    let targetDate = iPadListScrollTargetDate

                    Task { @MainActor in
                        await Task.yield()

                        if let targetDate {
                            // La cabecera es un hijo estable de List. Situarnos
                            // primero en ella permite materializar tarjetas de
                            // días anteriores que aún estén fuera de pantalla.
                            proxy.scrollTo(iPadAgendaSectionScrollID(targetDate), anchor: .top)
                            await Task.yield()
                            await Task.yield()
                        }

                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
            }

            if multiSelectionMode {
                bulkActionsBar()
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            }
        }
    }

    private func iPadAgendaDetailPanel(showsPet: Bool) -> some View {
        ZStack {
            if let item = activeAgendaItem {
                ScrollView {
                    agendaDetailContent(item)
                        .id(item.id)
                        .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.system(size: 46, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("Selecciona una entrada")
                        .font(.title3.weight(.semibold))
                    Text("El contenido de la Agenda aparecerá en este panel.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
            }

            if showsPet && shouldShowEmptyTodayPet {
                emptyTodayPet
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .agendaIPadPanel(material: .ultraThinMaterial)
    }

    private func agendaDetailContent(_ item: AgendaItemData) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    if isInlineEditing(item) {
                        TextField("Título", text: $inlineDraftTitle)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.black)
                            .textFieldStyle(.plain)
                            .focused($focusedInlineEditorField, equals: .title)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        Text(item.titulo.isEmpty ? "Sin título" : item.titulo)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.black)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                revealIPadDetailItemInList(item)
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Muestra y selecciona la tarjeta correspondiente en el listado")
                    }
                    Text(item.fechaActividad.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.7))
                }

                Spacer()

                if isInlineEditing(item) {
                    HStack(spacing: 8) {
                        Button("Cancelar") {
                            cancelInlineAgendaEditing()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)

                        Button("Actualizar") {
                            updateInlineAgendaItem(item)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black.opacity(0.82))
                        .foregroundStyle(.white)
                        .disabled(inlineDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    Button("Editar") {
                        beginInlineAgendaEditing(item)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black.opacity(0.78))
                    .foregroundStyle(.white)
                }
            }

            if isInlineEditing(item) {
                agendaDetailSection(title: "Programación", systemImage: "calendar.badge.clock") {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker(
                            "Hora",
                            selection: $inlineDraftHour,
                            displayedComponents: .hourAndMinute
                        )

                        Toggle("Activar recordatorio", isOn: $inlineDraftReminderEnabled)

                        Picker("Prioridad", selection: $inlineDraftPriority) {
                            ForEach(AgendaPriority.allCases) { priority in
                                Text(priority.title).tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .tint(.black)
                }

                agendaDetailSection(title: "Lugar", systemImage: "mappin.and.ellipse") {
                    HStack(alignment: .center, spacing: 10) {
                        TextField("Lugar o coordenadas", text: $inlineDraftLocation, axis: .vertical)
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
                                Image(
                                    systemName: inlineDraftLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? "location.fill"
                                        : "checkmark.circle.fill"
                                )
                                .foregroundStyle(
                                    inlineDraftLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.black
                                        : Color.green
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.black.opacity(0.75))
                        .disabled(isCapturingInlineLocation)
                        .accessibilityLabel("Obtener ubicación actual")
                        .accessibilityHint("Solicita permiso de ubicación y guarda las coordenadas actuales")
                    }
                }

                agendaDetailSection(title: "Contenido", systemImage: "text.alignleft") {
                    TextField("Contenido", text: $inlineDraftContent, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(5...12)
                        .focused($focusedInlineEditorField, equals: .content)
                        .frame(minHeight: 130, alignment: .topLeading)
                        .padding(8)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                }
            } else {
                HStack(spacing: 10) {
                    AgendaDetailBadge(
                        title: item.hora.formatted(date: .omitted, time: .shortened),
                        systemImage: "clock"
                    )
                    AgendaDetailBadge(
                        title: item.prioridad.title,
                        systemImage: "flag.fill",
                        tint: item.prioridad.tint
                    )
                    if item.recordatorioActivo {
                        AgendaDetailBadge(title: "Recordatorio", systemImage: "bell.fill")
                    }
                }

                if let completada = item.completada {
                    AgendaStatusLabel(completada: completada)
                }

                if !item.lugar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    agendaDetailSection(title: "Lugar", systemImage: "mappin.and.ellipse") {
                        Button(item.lugar) {
                            openInMaps(address: item.lugar)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.black.opacity(0.82))
                    }
                }

                let content = item.contenido.trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    agendaDetailSection(title: "Contenido", systemImage: "text.alignleft") {
                        Text(content)
                            .textSelection(.enabled)
                    }
                }

                let note = item.nota.trimmingCharacters(in: .whitespacesAndNewlines)
                if !note.isEmpty {
                    agendaDetailSection(title: "Nota", systemImage: "note.text") {
                        Text(note)
                            .textSelection(.enabled)
                    }
                }

                if content.isEmpty && note.isEmpty {
                    Text("Esta entrada no contiene texto adicional.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                }
            }
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func agendaDetailSection<Content: View>(
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.48))
        )
    }

    private func revealIPadDetailItemInList(_ item: AgendaItemData) {
        let calendar = Calendar.current
        let itemDate = calendar.startOfDay(for: item.fechaActividad)
        let startOfToday = calendar.startOfDay(for: Date())

        selectedAgendaItemID = item.id

        // Las entradas anteriores viven en un bloque opcional. Al revelar una,
        // lo hacemos visible antes de solicitar el desplazamiento.
        if itemDate < startOfToday {
            showPastActivities = true
        }

        iPadListScrollTargetDate = itemDate
        iPadListScrollTargetID = item.id
        iPadListScrollRequest &+= 1
    }

    private func iPadAgendaSectionScrollID(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func isInlineEditing(_ item: AgendaItemData) -> Bool {
        inlineEditingAgendaItemID == item.id
    }

    private func beginInlineAgendaEditing(_ item: AgendaItemData) {
        inlineEditingAgendaItemID = item.id
        inlineDraftTitle = item.titulo
        inlineDraftHour = item.hora
        inlineDraftReminderEnabled = item.recordatorioActivo
        inlineDraftPriority = item.prioridad
        inlineDraftContent = item.contenido
        inlineDraftLocation = item.lugar
    }

    private func cancelInlineAgendaEditing() {
        dismissInlineEditorKeyboard()

        // La restauración se pospone un ciclo de la cola principal para que el
        // teclado comience a cerrarse antes de reconstruir el diseño dividido.
        DispatchQueue.main.async {
            inlineEditingAgendaItemID = nil
            inlineDraftTitle = ""
            inlineDraftContent = ""
            inlineDraftLocation = ""
            isCapturingInlineLocation = false
        }
    }

    private func dismissInlineEditorKeyboard() {
        focusedInlineEditorField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func captureInlineCurrentLocation() {
        guard !isCapturingInlineLocation else { return }
        isCapturingInlineLocation = true
        inlineLocationCanOpenSettings = false

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

    private func openLocationPrivacySettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    private func updateInlineAgendaItem(_ originalItem: AgendaItemData) {
        guard inlineEditingAgendaItemID == originalItem.id else { return }
        focusedInlineEditorField = nil

        var updated = originalItem
        updated.titulo = inlineDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.hora = inlineDraftHour
        updated.recordatorioActivo = inlineDraftReminderEnabled
        updated.prioridad = inlineDraftPriority
        updated.contenido = inlineDraftContent
        updated.lugar = inlineDraftLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.fechaModificacion = Date()

        if inlineDraftReminderEnabled && !viewModel.reminderCanBeEnabled(for: updated) {
            reminderValidationMessage = L10n.exact("La hora seleccionada ya pasó. Ajusta la hora a un momento futuro para poder activar el recordatorio.")
            showReminderValidationAlert = true
            return
        }

        // Si ya existía un recordatorio, se cancela antes de guardar para que
        // los cambios de título, hora o contenido queden también reprogramados.
        if originalItem.recordatorioActivo {
            viewModel.updateReminder(for: originalItem, enabled: false)
            updated.reminderID = nil
        }

        if inlineDraftReminderEnabled {
            updated.recordatorioActivo = false
            updated.reminderID = nil
            viewModel.updateReminder(for: updated, enabled: true)
        } else {
            updated.recordatorioActivo = false
            updated.reminderID = nil
            viewModel.save(updated)
        }

        selectedAgendaItemID = updated.id
        cancelInlineAgendaEditing()
    }
#endif

    private var selectionHeader: some View {
        HStack {
            Text("Seleccionadas: \(selectedItemsIDs.count)")
                .foregroundStyle(.black.opacity(0.75))
                .font(.footnote)
            Spacer()
            Button("Cancelar") {
                multiSelectionMode = false
                selectedItemsIDs.removeAll()
            }
            .foregroundStyle(.black)
        }
        .padding(.horizontal, 4)
    }

    private var topControls: some View {
        HStack(spacing: 10) {
            Spacer()
            filterMenu
            checkFilterMenu
            Text("Calendario")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.75))
                .onTapGesture {
                    toggleCalendarExpanded()
                }
            Button {
                toggleCalendarExpanded()
            } label: {
                Image(systemName: isCalendarExpanded ? "chevron.up.circle" : "chevron.down.circle")
                    .font(.title3)
                    .foregroundStyle(.black.opacity(0.65))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.exact(isCalendarExpanded ? "Ocultar calendario" : "Mostrar calendario"))
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private var filterMenu: some View {
        Menu {
            ForEach(AgendaViewModel.QuickFilter.allCases) { filter in
                Button {
                    viewModel.quickFilter = filter
                } label: {
                    Text(viewModel.quickFilter == filter ? "\(filter.title) ✓" : filter.title)
                }
            }
        } label: {
            quickFilterMenuLabel
        }
        .buttonStyle(.plain)
    }

    private var checkFilterMenu: some View {
        Menu {
            ForEach(CheckFilter.allCases) { filter in
                Button {
                    checkFilter = filter
                } label: {
                    Text(checkFilter == filter ? "\(filter.title) ✓" : filter.title)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("Check")
                Text(checkFilter.title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var activitiesList: some View {
        List {
            if isCalendarExpanded {
                expandedCalendarList
            } else {
                collapsedAgendaList
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var expandedCalendarList: some View {
        ForEach(filteredItems(viewModel.itemsForSelectedDay)) { item in
            agendaCard(item, fixedHeight: true)
        }
    }

    private var collapsedAgendaList: some View {
        let splitSections = splitCollapsedSectionsByTime()
        let filteredPastSections = filteredSections(splitSections.past)
        let filteredUpcomingSections = filteredSections(splitSections.todayAndFuture)
        let shouldShowPastContent = showPastActivities || isSearchActive

        return Group {
            if !filteredPastSections.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPastActivities.toggle()
                                }
                            } label: {
                                Text("Actividades pasadas")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.black)
                            }
                            .buttonStyle(.plain)

                            Menu {
                                Button("Eliminar actividades pasadas", role: .destructive) {
                                    requestBulkDelete(filteredPastSections.flatMap(\.items))
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.black.opacity(0.65))
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Opciones de actividades pasadas")

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPastActivities.toggle()
                                }
                            } label: {
                                Image(systemName: pastActivitiesChevronName)
                                    .foregroundStyle(.black.opacity(0.65))
                            }
                            .buttonStyle(.plain)
                        }

                        if shouldShowPastContent {
                            pastActivitiesList(filteredPastSections)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.4))
                    )
                    .clipped()
                    .animation(.easeInOut(duration: 0.28), value: showPastActivities)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            ForEach(filteredUpcomingSections, id: \.date) { section in
                Section {
                    ForEach(section.items) { item in
                        agendaCard(item, fixedHeight: false)
                    }
                } header: {
                    Text(daySectionTitle(section.date))
                        .foregroundStyle(.black)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            if purchaseStatus || yorjPremium {
                agendaAuthenticatedView
            } else {
                PremiumFeaturePreviewView(feature: .agenda)
            }
        }
    }

    private var agendaAuthenticatedView: some View {
        agendaRootView
#if os(iOS)
                .sheet(item: $editorItem) { item in
                    agendaEditorView(for: item)
                }
#else
                .onChange(of: editorItem) { _, item in
                    guard let item else { return }
                    showWindow(
                        for: agendaEditorView(for: item),
                        environmentObjects: [],
                        title: L10n.exact(item.titulo.isEmpty ? "Nueva actividad" : "Editar actividad"),
                        size: .percentage(width: 0.38, height: 0.52),
                        isModal: false
                    )
                    editorItem = nil
                }
#endif
                .sheet(isPresented: $showReminderManager) {
                    AgendaReminderManagementView(viewModel: viewModel)
                }
                .onAppear(perform: handleAgendaAppear)
                .onReceive(Timer.publish(every: 6, on: .main, in: .common).autoconnect(), perform: handleAgendaTimerTick)
                .onChange(of: scenePhase, handleAgendaScenePhaseChange)
                .alert("Recordatorio", isPresented: $showReminderValidationAlert) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(reminderValidationMessage)
                }
                .alert("Agenda", isPresented: $showInterchangeAlert) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(interchangeAlertMessage)
                }
                .alert("Mapas", isPresented: $showMapsAlert) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(mapsAlertMessage)
                }
#if os(iOS)
                .alert("Ubicación", isPresented: $showInlineLocationAlert) {
                    if inlineLocationCanOpenSettings {
                        Button("Abrir Ajustes") {
                            openLocationPrivacySettings()
                        }
                    }
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(inlineLocationAlertMessage)
                }
#endif
                .confirmationDialog("¿Eliminar actividad?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Solo esta actividad", role: .destructive) {
                        if let itemPendingDelete {
                            withAnimation(.easeInOut(duration: 0.24)) {
                                viewModel.delete(itemPendingDelete, scope: .onlyThis)
                            }
                        }
                        itemPendingDelete = nil
                    }
                    if itemPendingDelete?.seriesID != nil {
                        Button("Toda la serie", role: .destructive) {
                            if let itemPendingDelete {
                                withAnimation(.easeInOut(duration: 0.24)) {
                                    viewModel.delete(itemPendingDelete, scope: .wholeSeries)
                                }
                            }
                            itemPendingDelete = nil
                        }
                    }
                    Button("Cancelar", role: .cancel) {
                        itemPendingDelete = nil
                    }
                } message: {
                    Text("Esta acción no se puede deshacer.")
                }
                .confirmationDialog("¿Eliminar actividades?", isPresented: $showBulkDeleteConfirmation, titleVisibility: .visible) {
                    Button(bulkDeleteConfirmationTitle, role: .destructive) {
                        deleteBulkSelectedItems()
                    }
                    Button("Cancelar", role: .cancel) {
                        clearBulkDeleteSelection()
                    }
                } message: {
                    Text(bulkDeleteConfirmationMessage)
                }
                .onChange(of: viewModel.quickFilter, handleQuickFilterChange)
                .fileExporter(
                    isPresented: $showPDFExporter,
                    document: exportedPDFDocument,
                    contentType: .pdf,
                    defaultFilename: exportedPDFFileName
                ) { _ in }
                .fileExporter(
                    isPresented: $showMigrationExporter,
                    document: migrationDocument ?? MigrationDataDocument(),
                    contentType: .ypgExport,
                    defaultFilename: migrationExportFileName
                ) { handleMigrationExportResult($0) }
                .sheet(isPresented: $showMigrationPasswordSheet) {
                    let selectedCount = selectedListedItems().count
                    migrationPasswordSheet(
                        title: L10n.exact("Exportar actividades seleccionadas"),
                        countLabel: L10n.format(
                            selectedCount == 1 ? "agenda.activity_count.singular" : "agenda.activity_count",
                            fallback: selectedCount == 1 ? "{0} actividad" : "{0} actividades",
                            "\(selectedCount)"
                        ),
                        exportAction: exportSelectedAgendaToMigration
                    )
                }
                .confirmationDialog("Confirmar acción", isPresented: $showBulkActionConfirmation, titleVisibility: .visible) {
                    agendaBulkConfirmationActions()
                } message: {
                    agendaBulkConfirmationMessage()
                }
    }

    private var agendaRootView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .blue.opacity(6),
                    .blue.opacity(2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            agendaAdaptiveContent

            if shouldShowRootEmptyTodayPet {
                emptyTodayPet
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: shouldShowEmptyTodayPet)
        .animation(.easeInOut(duration: AgendaUIConstants.emptyTodayPetEntranceDuration), value: hasCompletedPetEntrance)
        .navigationTitle("Agenda")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
#endif
        .tint(.black)
        .toolbar {
            agendaToolbar
        }
    }

    @ViewBuilder
    private var agendaAdaptiveContent: some View {
#if os(iOS)
        if isIPadInterface {
            iPadAgendaWorkspace
        } else {
            mainContent
        }
#else
        mainContent
#endif
    }

    private var shouldShowRootEmptyTodayPet: Bool {
#if os(iOS)
        return !isIPadInterface && shouldShowEmptyTodayPet
#else
        return shouldShowEmptyTodayPet
#endif
    }

    private var hasNoEntriesToday: Bool {
        !viewModel.items.contains {
            Calendar.current.isDateInToday($0.fechaActividad)
        }
    }

    private var shouldShowEmptyTodayPet: Bool {
        petsEnabled && hasNoEntriesToday && currentListedItems().isEmpty && !showPastActivities
    }

    private var resolvedPetAssetName: String {
        PetSettings.resolvedAssetName(selectedPetAssetName)
    }

    private var emptyTodayPet: some View {
        VStack {
            Spacer()
            interactiveAgendaPet(size: AgendaUIConstants.emptyTodayPetSize)
                .offset(
                    x: AgendaUIConstants.emptyTodayPetOffset.width,
                    y: AgendaUIConstants.emptyTodayPetOffset.height
                )
        }
        .accessibilityLabel("Mascota de Agenda")
        .accessibilityHint("Toca dos veces para crear una entrada para hoy. Mantén pulsado para cambiar u ocultar la mascota")
    }

    private func interactiveAgendaPet(size: CGFloat) -> some View {
        PetImage(assetName: resolvedPetAssetName)
            .frame(width: size)
            .scaleEffect(hasCompletedPetEntrance ? 1 : 0.18)
            .opacity(hasCompletedPetEntrance ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                editorItem = viewModel.create(selectedDate: Date())
            }
            .contextMenu {
                Button {
                    petsEnabled = false
                } label: {
                    Label("Ocultar mascota", systemImage: "eye.slash")
                }

                Menu {
                    ForEach(PetSettings.availablePetAssetNames, id: \.self) { assetName in
                        Button {
                            selectedPetAssetName = assetName
                        } label: {
                            Label(
                                PetSettings.displayName(for: assetName),
                                systemImage: resolvedPetAssetName == assetName ? "checkmark" : "pawprint"
                            )
                        }
                    }
                } label: {
                    Label("Cambiar mascota", systemImage: "pawprint")
                }
            }
            .accessibilityLabel("Mascota de Agenda")
    }

    @ToolbarContentBuilder
    private var agendaToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Agenda")
                .foregroundStyle(.black)
                .font(.headline)
        }
#if os(iOS)
        if isIPadInterface {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Cerrar Agenda")
            }
        }
        if isIPadInterface {
            ToolbarItem(placement: .navigationBarTrailing) {
                iPadLayoutMenu
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            menuGestion
        }
#else
        ToolbarItem {
            menuGestion
        }
#endif
#if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            addButton
        }
        if isIPadInterface && inlineEditingAgendaItemID != nil {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Ocultar teclado") {
                    focusedInlineEditorField = nil
                }
            }
        }
#else
        ToolbarItem {
            addButton
        }
#endif
    }

#if os(iOS)
    private var iPadLayoutMenu: some View {
        Menu {
            ForEach(AgendaIPadLayoutMode.allCases, id: \.rawValue) { mode in
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

    private func agendaEditorView(for item: AgendaItemData) -> some View {
        AgendaEditorView(baseItem: item) { updatedItems in
            viewModel.saveBatch(updatedItems)
            for updated in updatedItems where updated.recordatorioActivo {
                viewModel.updateReminder(for: updated, enabled: true)
            }
        }
    }

    private func handleAgendaAppear() {
        viewModel.load()
        displayedMonth = monthStart(of: viewModel.selectedDate)
        animatePetEntranceIfNeeded()

        if presentsNewItemOnAppear && !hasPresentedInitialItem {
            hasPresentedInitialItem = true
            editorItem = viewModel.create(selectedDate: viewModel.selectedDate)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            evaluateInitialTodayAvailability()
        }
    }

    private func animatePetEntranceIfNeeded() {
        guard !hasCompletedPetEntrance else { return }

        guard shouldShowEmptyTodayPet else {
            hasCompletedPetEntrance = true
            return
        }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: AgendaUIConstants.emptyTodayPetEntranceDuration)) {
                hasCompletedPetEntrance = true
            }
        }
    }

    private func handleAgendaTimerTick(_: Date) {
        viewModel.load()
    }

    private func handleAgendaScenePhaseChange(_: ScenePhase, _ phase: ScenePhase) {
        if phase == .active {
            viewModel.load()
        }
    }

    private func handleQuickFilterChange(_: AgendaViewModel.QuickFilter, _ newValue: AgendaViewModel.QuickFilter) {
        if newValue == .hoy {
            let now = Date()
            viewModel.selectedDate = now
            displayedMonth = monthStart(of: now)
        }
    }

    private func evaluateInitialTodayAvailability() {
        guard !hasEvaluatedInitialTodayAvailability else { return }
        guard viewModel.quickFilter == .hoy else {
            hasEvaluatedInitialTodayAvailability = true
            return
        }

        hasEvaluatedInitialTodayAvailability = true
        if viewModel.itemsForSelectedDay.isEmpty {
            isCalendarExpanded = true
        }
    }

    private func checkActionTitle(for item: AgendaItemData) -> String {
        switch item.completada {
        case nil:
            return L10n.exact("Activar check")
        case .some(true):
            return L10n.exact("Reactivar")
        case .some(false):
            return L10n.exact("Quitar check")
        }
    }

    private var pastActivitiesChevronName: String {
        showPastActivities ? "chevron.up.circle.fill" : "chevron.down.circle.fill"
    }

    private func pastActivitiesList(_ sections: [(date: Date, items: [AgendaItemData])]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(sections, id: \.date) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(daySectionTitle(section.date))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.7))
                            .padding(.horizontal, 6)
                        ForEach(section.items) { item in
                            agendaCard(item, fixedHeight: false)
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .frame(height: 350)
    }

    private func checkActionTint(for item: AgendaItemData) -> Color {
        switch item.completada {
        case nil:
            return .orange
        case .some(true):
            return .blue
        case .some(false):
            return .mint
        }
    }

    @ViewBuilder
    private func agendaCard(_ item: AgendaItemData, fixedHeight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if multiSelectionMode {
                    Image(systemName: selectedItemsIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedItemsIDs.contains(item.id) ? .blue : .black.opacity(0.55))
                }
                Text(item.titulo)
                    .font(.headline)
                    .foregroundStyle(.black)
                if item.recordatorioActivo {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(Color.black)
                }
                Spacer()
                Text(item.hora.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(.black.opacity(0.7))
                Menu {
                    Button("Editar") {
                        editorItem = item
                    }

                    Menu("Prioridad") {
                        ForEach(AgendaPriority.allCases) { priority in
                            Button {
                                var updated = item
                                updated.prioridad = priority
                                updated.fechaModificacion = Date()
                                viewModel.save(updated)
                            } label: {
                                if item.prioridad == priority {
                                    Label(priority.title, systemImage: "checkmark")
                                } else {
                                    Text(priority.title)
                                }
                            }
                        }
                    }

                    Menu("Check") {
                        Button {
                            var updated = item
                            updated.completada = true
                            updated.fechaModificacion = Date()
                            viewModel.save(updated)
                        } label: {
                            if item.completada == true {
                                Label("Checkeado", systemImage: "checkmark")
                            } else {
                                Text("Checkeado")
                            }
                        }

                        Button {
                            var updated = item
                            updated.completada = false
                            updated.fechaModificacion = Date()
                            viewModel.save(updated)
                        } label: {
                            if item.completada == false {
                                Label("Activo", systemImage: "checkmark")
                            } else {
                                Text("Activo")
                            }
                        }

                        Button {
                            var updated = item
                            updated.completada = nil
                            updated.fechaModificacion = Date()
                            viewModel.save(updated)
                        } label: {
                            if item.completada == nil {
                                Label("Off", systemImage: "checkmark")
                            } else {
                                Text("Off")
                            }
                        }
                    }

                    Button(L10n.exact(item.recordatorioActivo ? "Quitar recordatorio" : "Recordatorio")) {
                        let shouldEnable = !item.recordatorioActivo
                        if shouldEnable, !viewModel.reminderCanBeEnabled(for: item) {
                            reminderValidationMessage = L10n.exact("La hora seleccionada ya pasó. Ajusta la fecha u hora del recordatorio a un momento futuro para poder activarlo.")
                            showReminderValidationAlert = true
                        } else {
                            viewModel.updateReminder(for: item, enabled: shouldEnable)
                        }
                    }

                    Button("Exportar a Notas") {
                        let ok = AgendaInterchangeService.exportAgendaToNotas(item)
                        interchangeAlertMessage = L10n.exact(ok ? "Actividad exportada a Notas." : "No se pudo exportar la actividad a Notas.")
                        showInterchangeAlert = true
                    }

                    Button("Exportar a Diario") {
                        let ok = AgendaInterchangeService.exportAgendaToDiario(item)
                        interchangeAlertMessage = L10n.exact(ok ? "Actividad exportada a Diario." : "No se pudo exportar la actividad a Diario.")
                        showInterchangeAlert = true
                    }

                    #if os(iOS)
                    Menu("Exportar a Apple") {
                        Button("Calendario", systemImage: "calendar.badge.plus") {
                            exportToAppleCalendar(item)
                        }

                        Button("Recordatorios", systemImage: "checklist") {
                            exportToAppleReminders(item)
                        }
                    }
                    #endif

                    if !item.lugar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Abrir en Mapas") {
                            openInMaps(address: item.lugar)
                        }
                    }

                    Button("Eliminar", role: .destructive) {
                        itemPendingDelete = item
                        showDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.black.opacity(0.75))
                }
                .menuStyle(.borderlessButton)
            }
            if let completada = item.completada {
                AgendaStatusLabel(completada: completada)
            }
            if !item.lugar.isEmpty {
                locationRow(for: item)
            }
            Text(cardDetailText(for: item).isEmpty ? " " : cardDetailText(for: item))
                .font(.body)
                .foregroundStyle(.black.opacity(0.82))
                .lineLimit(expandedContentIDs.contains(item.id) ? nil : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .contentShape(Rectangle())
                .onTapGesture {
#if os(iOS)
                    if isIPadInterface && !multiSelectionMode {
                        selectedAgendaItemID = item.id
                    }
#endif
                    guard !cardDetailText(for: item).isEmpty else { return }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        if expandedContentIDs.contains(item.id) {
                            expandedContentIDs.remove(item.id)
                        } else {
                            expandedContentIDs.insert(item.id)
                        }
                    }
                }
        }
#if os(iOS)
        .frame(minHeight: fixedHeight ? 122 : 80, alignment: .top)
#else
        .frame(minHeight: fixedHeight ? 122 : 0, alignment: .top)
#endif
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: expandedContentIDs.contains(item.id))
        .contentShape(Rectangle())
        .onTapGesture {
            if multiSelectionMode {
                if selectedItemsIDs.contains(item.id) {
                    selectedItemsIDs.remove(item.id)
                } else {
                    selectedItemsIDs.insert(item.id)
                }
                return
            }
#if os(iOS)
            if isIPadInterface {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedAgendaItemID = item.id
                }
            }
#endif
        }
#if os(iOS)
        .padding(.vertical, 2)
        .padding(.horizontal, 1)
#else
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
#endif
        .background(
            RoundedRectangle(cornerRadius: AgendaUIConstants.activityCardCornerRadius, style: .continuous)
                .fill(backgroundColor(for: item.prioridad))
        )
        .clipShape(RoundedRectangle(cornerRadius: AgendaUIConstants.activityCardCornerRadius, style: .continuous))
        .id(item.id)
#if os(iOS)
        .overlay {
            if isIPadInterface && activeAgendaItemID == item.id {
                RoundedRectangle(cornerRadius: AgendaUIConstants.activityCardCornerRadius, style: .continuous)
                    .stroke(Color(red: 0.86, green: 0.30, blue: 0.34).opacity(0.72), lineWidth: 2)
            }
        }
#endif
#if os(iOS)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
#endif
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func bulkActionsBar() -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Seleccionadas: \(selectedListedItems().count)")
                    .font(.footnote)
                    .foregroundStyle(.black.opacity(0.75))
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(L10n.exact(areAllListedItemsSelected ? "Quitar sel." : "Sel. todas")) {
                        withAnimation {
                            toggleListedItemsSelection()
                        }
                    }
                    .foregroundStyle(.black).bold()
                    .tint(.gray)
                    .buttonStyle(.bordered)
                    .disabled(currentListedItems().isEmpty)

                    Button {
                        requestBulkActionConfirmation(.delete)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Eliminar")
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(selectedListedItems().isEmpty)

                    Button("PDF") {
                        requestBulkActionConfirmation(.exportPDF)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(selectedListedItems().isEmpty)

                    Button("Migrar") {
                        requestBulkActionConfirmation(.exportMigration)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .disabled(selectedListedItems().isEmpty)

                    Button("Completadas") {
                        requestBulkActionConfirmation(.markCompleted)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(selectedListedItems().isEmpty)

                    Button("Quitar check") {
                        requestBulkActionConfirmation(.clearCheck)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(selectedListedItems().isEmpty)

                    Button("Rec. ON") {
                        requestBulkActionConfirmation(.activateReminders)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .disabled(selectedListedItems().isEmpty)

                    Button("Rec. OFF") {
                        requestBulkActionConfirmation(.deactivateReminders)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .disabled(selectedListedItems().isEmpty)

#if os(iOS)
                    Menu("Apple") {
                        Button("Calendario", systemImage: "calendar.badge.plus") {
                            requestBulkActionConfirmation(.exportAppleCalendar)
                        }
                        Button("Recordatorios", systemImage: "checklist") {
                            requestBulkActionConfirmation(.exportAppleReminders)
                        }
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .disabled(selectedListedItems().isEmpty)
#endif
                }
                .fixedSize()
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func agendaBulkConfirmationActions() -> some View {
        if let action = pendingBulkAction {
            Button(action.confirmTitle, role: action.role) {
                performConfirmedBulkAction(action)
                pendingBulkAction = nil
            }
        }
        Button("Cancelar", role: .cancel) {
            pendingBulkAction = nil
        }
    }

    private func agendaBulkConfirmationMessage() -> Text {
        Text(pendingBulkAction?.message(count: selectedListedItems().count) ?? "")
    }

    private var bulkDeleteConfirmationTitle: String {
        L10n.format(
            bulkDeleteItems.count == 1 ? "agenda.delete_count.singular" : "agenda.delete_count",
            fallback: bulkDeleteItems.count == 1 ? "Eliminar {0} actividad" : "Eliminar {0} actividades",
            "\(bulkDeleteItems.count)"
        )
    }

    private var bulkDeleteConfirmationMessage: String {
        L10n.exact("También se eliminarán sus recordatorios. Esta acción no se puede deshacer.")
    }

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func requestBulkDelete(_ items: [AgendaItemData]) {
        guard !items.isEmpty else { return }
        bulkDeleteItems = items
        showBulkDeleteConfirmation = true
    }

    private func deleteBulkSelectedItems() {
        let idsToRemove = bulkDeleteItems.map(\.id)
        withAnimation(.easeInOut(duration: 0.24)) {
            for item in bulkDeleteItems {
                viewModel.delete(item, scope: .onlyThis)
            }
            selectedItemsIDs.subtract(idsToRemove)
            bulkDeleteItems.removeAll()
        }
    }

    private func deleteSelectedAgendaItems() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.24)) {
            for item in selected {
                viewModel.delete(item, scope: .onlyThis)
            }
            finishMultiSelectionOperation()
        }
    }

    private func clearBulkDeleteSelection() {
        bulkDeleteItems.removeAll()
    }

    private func toggleCalendarExpanded() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isCalendarExpanded {
                viewModel.quickFilter = .todos
            }
            isCalendarExpanded.toggle()
        }
    }

    private func openInMaps(address: String) {
        let cleaned = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            mapsAlertMessage = L10n.exact("La ubicación está vacía.")
            showMapsAlert = true
            return
        }

        Task { @MainActor in
            let didOpen = await LocationMapOpener.open(cleaned)
            if !didOpen {
                mapsAlertMessage = L10n.exact("No se pudo abrir Mapas para esta ubicación.")
                showMapsAlert = true
            }
        }
    }

#if os(iOS)
    private func exportToAppleCalendar(_ item: AgendaItemData) {
        Task { @MainActor in
            do {
                try await AgendaInterchangeService.exportAgendaToAppleCalendar(item)
                interchangeAlertMessage = L10n.exact("Actividad exportada a Calendario.")
            } catch {
                interchangeAlertMessage = error.localizedDescription
            }
            showInterchangeAlert = true
        }
    }

    private func exportToAppleReminders(_ item: AgendaItemData) {
        Task { @MainActor in
            do {
                try await AgendaInterchangeService.exportAgendaToAppleReminders(item)
                interchangeAlertMessage = L10n.exact("Actividad exportada a Recordatorios.")
            } catch {
                interchangeAlertMessage = error.localizedDescription
            }
            showInterchangeAlert = true
        }
    }
#endif

    private func exportCurrentMonthToPDF() {
        let monthItems = itemsInDisplayedMonth()
        exportItemsToPDF(monthItems, scopeName: L10n.exact("Mes"))
    }

    private func exportCurrentWeekToPDF() {
        let weekItems = itemsInActiveWeek()
        exportItemsToPDF(weekItems, scopeName: L10n.exact("Semana"))
    }

    @discardableResult
    private func exportItemsToPDF(_ items: [AgendaItemData], scopeName: String) -> Bool {
        guard !items.isEmpty else {
            interchangeAlertMessage = L10n.format("agenda.export.empty", fallback: "No hay actividades para exportar en {0}.", scopeName.lowercased())
            showInterchangeAlert = true
            return false
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items.sorted { $0.fechaActividad < $1.fechaActividad }) {
            calendar.startOfDay(for: $0.fechaActividad)
        }

        let sections: [PDFExportSection] = grouped.keys.sorted().map { day in
            let dayItems = (grouped[day] ?? []).sorted { $0.hora < $1.hora }
            let lines = dayItems.map { item in
                let details = [
                    L10n.format("agenda.pdf.time", fallback: "Hora: {0}", item.hora.formatted(date: .omitted, time: .shortened)),
                    item.lugar.isEmpty ? nil : L10n.format("agenda.pdf.location", fallback: "Lugar: {0}", item.lugar),
                    item.contenido.isEmpty ? nil : item.contenido,
                    item.nota.isEmpty ? nil : L10n.format("agenda.pdf.note", fallback: "Nota: {0}", item.nota)
                ]
                    .compactMap { $0 }
                    .joined(separator: "\n")
                return PDFExportLine(title: item.titulo, detail: details)
            }
            return PDFExportSection(
                title: day.formatted(date: .complete, time: .omitted),
                lines: lines
            )
        }

        let descriptor = PDFExportDocumentDescriptor(
            title: L10n.format("agenda.pdf.title", fallback: "Agenda - {0} actual", scopeName),
            subtitle: L10n.format("agenda.pdf.generated", fallback: "Generado el {0}", Date().formatted(date: .abbreviated, time: .shortened)),
            sections: sections
        )

        do {
            let data = try PDFExportModule.render(descriptor, useBlueSectionBullets: true)
            exportedPDFDocument = ExportedPDFDocument(data: data)
            let dateLabel = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
            exportedPDFFileName = "Agenda-\(scopeName)-\(dateLabel)"
            showPDFExporter = true
            return true
        } catch {
            interchangeAlertMessage = L10n.exact("No se pudo generar el PDF.")
            showInterchangeAlert = true
            return false
        }
    }

    private func authenticateBeforeMigrationExport() {
        UtilFuncs.authenticateDeviceOwner(reason: L10n.exact("Autentícate para exportar las actividades seleccionadas.")) { success, errorMessage in
            if success {
                migrationPassword = ""
                migrationPasswordConfirmation = ""
                showMigrationPasswordSheet = true
            } else {
                interchangeAlertMessage = errorMessage ?? L10n.exact("No se pudo autenticar el acceso a la exportación.")
                showInterchangeAlert = true
            }
        }
    }

    private func exportSelectedAgendaToMigration() {
        guard migrationPassword == migrationPasswordConfirmation, !migrationPassword.isEmpty else {
            interchangeAlertMessage = L10n.exact("La contraseña de exportación está vacía o no coincide.")
            showInterchangeAlert = true
            return
        }

        let selected = selectedListedItems()
        guard !selected.isEmpty else {
            interchangeAlertMessage = L10n.exact("Selecciona al menos una actividad para exportar.")
            showInterchangeAlert = true
            return
        }

        do {
            let bridge = CoreDataCanonicalMigrationBridge()
            let records = try bridge.exportRecords(agendaItems: selected)
            let result = try MyAppMigrationService().export(records: records, password: migrationPassword)
            migrationDocument = MigrationDataDocument(data: result.bytes)
            migrationExportCount = selected.count
            migrationExportFileName = "neville-agenda-\(selected.count).ypgexp"
            showMigrationPasswordSheet = false
            showMigrationExporter = true
        } catch {
            interchangeAlertMessage = L10n.format("agenda.migration.prepare_error", fallback: "No se pudo preparar el archivo de migración: {0}", error.localizedDescription)
            showInterchangeAlert = true
        }
    }

    private func handleMigrationExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            interchangeAlertMessage = L10n.format(
                migrationExportCount == 1 ? "agenda.migration.success.singular" : "agenda.migration.success",
                fallback: migrationExportCount == 1
                    ? "Archivo de migración exportado correctamente: {0} actividad."
                    : "Archivo de migración exportado correctamente: {0} actividades.",
                "\(migrationExportCount)"
            )
            finishMultiSelectionOperation()
        case .failure(let error):
            interchangeAlertMessage = L10n.format("agenda.migration.save_error", fallback: "No se pudo guardar el archivo de migración: {0}", error.localizedDescription)
        }
        migrationPassword = ""
        migrationPasswordConfirmation = ""
        migrationDocument = nil
        showInterchangeAlert = true
    }

    private func migrationPasswordSheet(title: String, countLabel: String, exportAction: @escaping () -> Void) -> some View {
        NavigationStack {
            Form {
                Section(title) {
                    Text("Se creará un archivo seguro con \(countLabel). La contraseña solo se usa para proteger este archivo y no se guarda.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    SecureField("Contraseña del archivo", text: $migrationPassword)
                    SecureField("Repetir contraseña", text: $migrationPasswordConfirmation)
                }
            }
            .navigationTitle("Archivo .ypgexp")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showMigrationPasswordSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Exportar") {
                        exportAction()
                    }
                    .disabled(migrationPassword.isEmpty || migrationPassword != migrationPasswordConfirmation)
                }
            }
        }
    }

    private func matchesSearch(_ item: AgendaItemData) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return true }

        let checkStateText: String
        switch item.completada {
        case .some(true):
            checkStateText = "checkeado"
        case .some(false):
            checkStateText = "activo"
        case .none:
            checkStateText = "off"
        }

        let searchable = [
            item.titulo,
            item.nota,
            item.contenido,
            item.prioridad.title,
            item.prioridad.rawValue,
            checkStateText
        ]
            .joined(separator: " ")
            .lowercased()

        return searchable.contains(query)
    }

    private func filteredByCheck(_ items: [AgendaItemData]) -> [AgendaItemData] {
        switch checkFilter {
        case .todas:
            return items
        case .activas:
            return items.filter { $0.completada == false }
        case .completadas:
            return items.filter { $0.completada == true }
        }
    }

    private func filteredItems(_ items: [AgendaItemData]) -> [AgendaItemData] {
        return filteredByCheck(items.filter(matchesSearch))
    }

    private func filteredSections(_ sections: [(date: Date, items: [AgendaItemData])]) -> [(date: Date, items: [AgendaItemData])] {
        sections.compactMap { section in
            let filtered = filteredItems(section.items)
            guard !filtered.isEmpty else { return nil }
            return (date: section.date, items: filtered)
        }
    }

    private func splitCollapsedSectionsByTime() -> (past: [(date: Date, items: [AgendaItemData])], todayAndFuture: [(date: Date, items: [AgendaItemData])]) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sections = viewModel.collapsedSectionsForActiveFilter

        let past: [(date: Date, items: [AgendaItemData])]
        if !isCalendarExpanded && viewModel.quickFilter == .todos {
            // «Todos» debe incluir el histórico completo cuando el calendario
            // está oculto, no solo las entradas pasadas del mes actual.
            let pastItems = viewModel.items.filter {
                calendar.startOfDay(for: $0.fechaActividad) < startOfToday
            }
            let groupedPastItems = Dictionary(grouping: pastItems) {
                calendar.startOfDay(for: $0.fechaActividad)
            }
            past = groupedPastItems.keys.sorted(by: >).map { date in
                let items = (groupedPastItems[date] ?? []).sorted { left, right in
                    left.hora < right.hora
                }
                return (date: date, items: items)
            }
        } else {
            past = sections.filter { calendar.startOfDay(for: $0.date) < startOfToday }
        }
        let todayAndFuture = sections.filter { calendar.startOfDay(for: $0.date) >= startOfToday }
        return (past: past, todayAndFuture: todayAndFuture)
    }

    private func currentListedItems() -> [AgendaItemData] {
#if os(iOS)
        if isIPadInterface {
            return iPadListedItems
        }
#endif
        if isCalendarExpanded {
            return filteredItems(viewModel.itemsForSelectedDay)
        }

        let splitSections = splitCollapsedSectionsByTime()
        let filteredPast = filteredSections(splitSections.past)
        let filteredUpcoming = filteredSections(splitSections.todayAndFuture)
        let includePast = showPastActivities || isSearchActive

        let pastItems = includePast ? filteredPast.flatMap(\.items) : []
        let todayAndFutureItems = filteredUpcoming.flatMap(\.items)
        return pastItems + todayAndFutureItems
    }

    private func selectedListedItems() -> [AgendaItemData] {
        let ids = selectedItemsIDs
        return currentListedItems().filter { ids.contains($0.id) }
    }

    private var areAllListedItemsSelected: Bool {
        let listedIDs = Set(currentListedItems().map(\.id))
        return !listedIDs.isEmpty && selectedItemsIDs.isSuperset(of: listedIDs)
    }

    private func toggleListedItemsSelection() {
        let listedIDs = Set(currentListedItems().map(\.id))
        if areAllListedItemsSelected {
            selectedItemsIDs.subtract(listedIDs)
        } else {
            selectedItemsIDs.formUnion(listedIDs)
        }
    }

    private func requestBulkActionConfirmation(_ action: AgendaBulkAction) {
        guard !selectedListedItems().isEmpty else { return }
        DispatchQueue.main.async {
            pendingBulkAction = action
            showBulkActionConfirmation = true
        }
    }

    private func performConfirmedBulkAction(_ action: AgendaBulkAction) {
        switch action {
        case .delete:
            deleteSelectedAgendaItems()
        case .markCompleted:
            markSelectedAsCompleted()
        case .clearCheck:
            clearCheckModeForSelected()
        case .activateReminders:
            activateReminderForSelected()
        case .deactivateReminders:
            deactivateReminderForSelected()
        case .exportPDF:
            if exportItemsToPDF(selectedListedItems(), scopeName: L10n.exact("Seleccionadas")) {
                finishMultiSelectionOperation()
            }
        case .exportMigration:
            authenticateBeforeMigrationExport()
#if os(iOS)
        case .exportAppleCalendar:
            exportSelectedAgendaItemsToAppleCalendar()
        case .exportAppleReminders:
            exportSelectedAgendaItemsToAppleReminders()
#endif
        }
    }

#if os(iOS)
    private func exportSelectedAgendaItemsToAppleCalendar() {
        let items = selectedListedItems()
        Task { @MainActor in
            do {
                let count = try await AgendaInterchangeService.exportAgendaItemsToAppleCalendar(items)
                interchangeAlertMessage = count == 1
                    ? L10n.exact("1 actividad exportada a Calendario.")
                    : L10n.exact("\(count) actividades exportadas a Calendario.")
                finishMultiSelectionOperation()
            } catch {
                interchangeAlertMessage = error.localizedDescription
            }
            showInterchangeAlert = true
        }
    }

    private func exportSelectedAgendaItemsToAppleReminders() {
        let items = selectedListedItems()
        Task { @MainActor in
            do {
                let count = try await AgendaInterchangeService.exportAgendaItemsToAppleReminders(items)
                interchangeAlertMessage = count == 1
                    ? L10n.exact("1 actividad exportada a Recordatorios.")
                    : L10n.exact("\(count) actividades exportadas a Recordatorios.")
                finishMultiSelectionOperation()
            } catch {
                interchangeAlertMessage = error.localizedDescription
            }
            showInterchangeAlert = true
        }
    }
#endif

    private func finishMultiSelectionOperation() {
        selectedItemsIDs.removeAll()
        multiSelectionMode = false
    }

    private func itemsInDisplayedMonth() -> [AgendaItemData] {
        let calendar = Calendar.current
        let anchor = displayedMonth
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: anchor)) ?? anchor
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? anchor
        return viewModel.items.filter { $0.fechaActividad >= start && $0.fechaActividad < end }
    }

    private func itemsInActiveWeek() -> [AgendaItemData] {
        let calendar = Calendar.current
        let anchor = viewModel.selectedDate
        let startOfDay = calendar.startOfDay(for: anchor)

        // Semana activa fija de lunes a domingo.
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offsetToMonday = (weekday + 5) % 7
        guard let start = calendar.date(byAdding: .day, value: -offsetToMonday, to: startOfDay),
              let end = calendar.date(byAdding: .day, value: 7, to: start) else {
            return []
        }

        return viewModel.items.filter { $0.fechaActividad >= start && $0.fechaActividad < end }
    }

    private func activateReminderForSelected() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }
        let invalidExists = selected.contains { !viewModel.reminderCanBeEnabled(for: $0) && !$0.recordatorioActivo }
        if invalidExists {
            reminderValidationMessage = L10n.exact("No se activó ningún recordatorio: al menos una actividad seleccionada tiene una hora pasada. Ajusta esas horas a futuro y vuelve a intentarlo.")
            showReminderValidationAlert = true
            return
        }
        for item in selected {
            if !item.recordatorioActivo {
                viewModel.updateReminder(for: item, enabled: true)
            }
        }
        finishMultiSelectionOperation()
    }

    private func deactivateReminderForSelected() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }
        for item in selected where item.recordatorioActivo {
            viewModel.updateReminder(for: item, enabled: false)
        }
        finishMultiSelectionOperation()
    }

    private func markSelectedAsCompleted() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }
        for item in selected {
            var updated = item
            updated.completada = true
            updated.fechaModificacion = Date()
            viewModel.save(updated)
        }
        finishMultiSelectionOperation()
    }

    private func clearCheckModeForSelected() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }
        for item in selected {
            var updated = item
            updated.completada = nil
            updated.fechaModificacion = Date()
            viewModel.save(updated)
        }
        finishMultiSelectionOperation()
    }

    private func backgroundColor(for priority: AgendaPriority) -> Color {
        switch priority {
        case .neutral:
            return Color.white.opacity(AgendaUIConstants.activityCardBackgroundOpacity)
        case .baja:
            return Color(red: 0.82, green: 0.93, blue: 0.82).opacity(AgendaUIConstants.priorityBackgroundOpacity)
        case .media:
            return Color(red: 0.96, green: 0.90, blue: 0.74).opacity(AgendaUIConstants.priorityBackgroundOpacity)
        case .alta:
            return Color(red: 0.96, green: 0.80, blue: 0.78).opacity(AgendaUIConstants.priorityBackgroundOpacity)
        }
    }

    private func daySectionTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        let title = formatter.string(from: date).capitalized
        if Calendar.current.isDateInToday(date) {
            return L10n.format("agenda.today_section", fallback: "Hoy · {0}", title)
        }
        return title
    }

    private func cardDetailText(for item: AgendaItemData) -> String {
        let content = item.contenido.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = item.nota.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty && !note.isEmpty {
            return "\(content) · \(note)"
        }
        return !content.isEmpty ? content : note
    }

    @ViewBuilder
    private func locationRow(for item: AgendaItemData) -> some View {
        let showingAddress = revealLocationIDs.contains(item.id)
        HStack(spacing: 8) {
            Text("Lugar")
                .foregroundStyle(.black.opacity(0.85))
                .underline()
                .onTapGesture {
                    toggleLocationVisibility(for: item.id)
                }

            if showingAddress {
                Text(": \(item.lugar)")
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Button {
                    openInMaps(address: item.lugar)
                } label: {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Abrir ubicación en Mapas")
            }
        }
    }

    private func toggleLocationVisibility(for id: UUID) {
        if revealLocationIDs.contains(id) {
            revealLocationIDs.remove(id)
        } else {
            revealLocationIDs.insert(id)
        }
    }

    private var customCalendarView: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle(displayedMonth))
                    .font(.headline)
                    .foregroundStyle(.black)

                Spacer()

                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }

            let calendar = Calendar.current
            let baseSymbols = calendar.shortWeekdaySymbols
            let firstWeekdayIndex = max(0, min(baseSymbols.count - 1, calendar.firstWeekday - 1))
            let symbols = Array(baseSymbols[firstWeekdayIndex...]) + Array(baseSymbols[..<firstWeekdayIndex])

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(symbols.indices, id: \.self) { idx in
                    Text(symbols[idx])
                        .font(.caption2)
                        .foregroundStyle(.black.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }

                let monthDays = daysForDisplayedMonth()
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let hasActivity = hasActivities(on: date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = Calendar.current.isDateInToday(date)

        return Button {
            viewModel.selectedDate = date
            viewModel.quickFilter = .todos
        } label: {
            Text("\(Calendar.current.component(.day, from: date))")
                .fontWeight(hasActivity ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.black : (hasActivity ? Color.blue : Color.black))
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(
                    Circle()
                        .fill(isSelected ? Color(red: 0.95, green: 0.67, blue: 0.37) : .clear)
                )
                .overlay(
                    Circle()
                        .stroke(
                            isToday ? Color.black.opacity(0.7) : .clear,
                            style: StrokeStyle(lineWidth: 1.2, dash: [3, 2])
                        )
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                viewModel.selectedDate = date
                viewModel.quickFilter = .todos
                editorItem = viewModel.create(selectedDate: date)
            }
        )
    }

    private func daysForDisplayedMonth() -> [Date?] {
        let calendar = Calendar.current
        let monthStartDate = monthStart(of: displayedMonth)
        guard let range = calendar.range(of: .day, in: .month, for: monthStartDate) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStartDate)
        let leadingEmpty = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStartDate) {
                days.append(date)
            }
        }
        return days
    }

    private func hasActivities(on date: Date) -> Bool {
        let calendar = Calendar.current
        return viewModel.items.contains { item in
            calendar.isDate(item.fechaActividad, inSameDayAs: date)
        }
    }

    private func monthStart(of date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date).capitalized
    }
}

#if os(iOS)
private struct AgendaDetailBadge: View {
    let title: String
    let systemImage: String
    var tint: Color = .black.opacity(0.72)

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.5), in: Capsule(style: .continuous))
    }
}

private extension View {
    func agendaIPadPanel(material: Material) -> some View {
        background(material)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            }
    }
}

/// El mismo comportamiento de divisor empleado por Notas, aislado aquí para
/// mantener independientes las dos pantallas y sus proporciones persistentes.
private struct AdjustableAgendaSplitView<Primary: View, Secondary: View>: View {
    @Environment(\.locale) private var locale

    let layout: AgendaSplitLayout
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

            Group {
                if layout == .sideBySide {
                    HStack(spacing: 0) {
                        primary()
                            .frame(width: primaryLength)
                        divider(availableLength: availableLength, limits: limits)
                        secondary()
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        primary()
                            .frame(height: primaryLength)
                        divider(availableLength: availableLength, limits: limits)
                        secondary()
                            .frame(maxHeight: .infinity)
                    }
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
                .frame(
                    width: layout == .sideBySide ? 1 : nil,
                    height: layout == .stacked ? 1 : nil
                )

            Capsule(style: .continuous)
                .fill(.secondary.opacity(0.55))
                .frame(
                    width: layout == .sideBySide ? 4 : 42,
                    height: layout == .sideBySide ? 42 : 4
                )
        }
        .frame(
            width: layout == .sideBySide ? dividerLength : nil,
            height: layout == .stacked ? dividerLength : nil
        )
        .contentShape(Rectangle())
        .gesture(
            // El espacio global evita que la referencia del gesto se desplace
            // junto con el propio divisor, que era la causa del temblor visual.
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

                    // AppStorage se actualiza únicamente al terminar el gesto;
                    // durante el arrastre se usa GestureState, mucho más ligero.
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

struct AgendaReminderManagementView: View {
    @ObservedObject var viewModel: AgendaViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.reminderItems) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.titulo)
                                .foregroundStyle(.black)
                            Text(item.fechaActividad.formatted(date: .abbreviated, time: .omitted) + " · " + item.hora.formatted(date: .omitted, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.black.opacity(0.7))
                        }
                        Spacer()
                        Button("Desactivar") {
                            viewModel.updateReminder(for: item, enabled: false)
                        }
                        .buttonStyle(.bordered)
                    }
                    .listRowBackground(Color.white.opacity(0.4))
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.86, green: 0.95, blue: 0.84),
                        Color(red: 0.76, green: 0.9, blue: 0.76)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Recordatorios Agenda")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
#endif
            .tint(.black)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Recordatorios Agenda")
                        .foregroundStyle(.black)
                        .font(.headline)
                }
#if os(macOS)
                ToolbarItem {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
#endif
            }
        }
    }
}

private struct AgendaStatusLabel: View {
    let completada: Bool

    var body: some View {
        HStack(spacing: 5) {
            statusIcon
            Text(L10n.exact(completada ? "Completada" : "Activa"))
                .font(.body)
                .foregroundStyle(.black)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if completada {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.palette)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white, Color(red: 0.0, green: 0.48, blue: 0.22))
                .background(completedIconBackdrop)
        } else {
            Image(systemName: "circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.brown.opacity(0.75))
        }
    }

    private var completedIconBackdrop: some View {
        Circle()
            .fill(.white.opacity(0.92))
            .frame(width: 14, height: 14)
    }
}

#endif
