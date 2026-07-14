//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct DiarioListView: View {

    @Environment(\.dismiss) var dimiss
    @Environment(\.managedObjectContext) var context

    @StateObject private var modelDiario = DiarioModel.shared
    @StateObject private var securityModel : SecurityModel = SecurityModel.shared
    
    
    //Para filtros en fechas
    enum TypeOfSearch{case fix, interval}

    private enum DiarioListMode {
        case all
        case groupedByChapter
    }
    
    //Para Buscar en títulos
    @State private var showAlertFilterByTitles = false
    @State private var textfielTitles = ""
    //Para Buscar en contenido
    @State private var showAlertFilterByContent = false
    //Para buscar en fechas:
    @State private var showSheetFecha       = false
    @State private var showSheetRangoFecha  = false
    @State private var typeOfFechaSearch : TypeFecha = .FechaCreacion
    @State private var fecha1 = Date.now
    @State private var fecha2 = Date.now
    
    @State private var datepicker : Date = Date.now
    @State private var textfielContent = ""
    

    
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
    @State private var selectedListMode: DiarioListMode = .all
    @State private var collapsedChapterNames: Set<String> = []
    @State private var showBatchChapterAlert = false
    @State private var batchChapterDraft = ""
    @State private var pendingBatchAction: DiarioBatchAction?
    @State private var showBatchActionConfirmation = false
    @State private var showMigrationPasswordSheet = false
    @State private var showMigrationExporter = false
    @State private var showRitualReviewUpdate = false
    @State private var ritualReviewNeedsUpdate = false
    @State private var migrationPassword = ""
    @State private var migrationPasswordConfirmation = ""
    @State private var migrationDocument: MigrationDataDocument?
    @State private var migrationExportFileName = "neville-diario.ypgexp"
    @State private var migrationExportCount = 0
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage("ritual_private_reflections_protected") private var privateRitualReflections = false
    
    
    //Ordenar las entradas del Diario por fechaCreación/fechaModificación
    @AppStorage(AppCons.UD_setting_OrdenarEntradaDiario) var ordenarEntradaDiario : Bool = true // true es fechaCreación; false es fecha de modificación
    @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false //Para poder manejar el acceso al diario
 
    //Almacena la contraeña de acceso en el Llavero, si existe:
    @State private var hasPassword = false

    private var hasPremiumPDFAccess: Bool {
        purchaseStatus || yorjPremium
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

    private var groupedDiarioByChapter: [(chapter: String, entries: [Diario])] {
        let grouped = Dictionary(grouping: modelDiario.list) { item in
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

    private var batchMigrationCountLabel: String {
        L10n.format(
            "diary.selected_entries.count",
            fallback: "{0} entrada(s)",
            String(batchSelectedDiarioIDs.count)
        )
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

    private enum DiarioBatchAction: Identifiable {
        case updateEmotion(Emociones)
        case updateChapter(String)
        case exportMigration

        var id: String {
            switch self {
            case .updateEmotion(let emotion):
                return "updateEmotion-\(emotion.rawValue)"
            case .updateChapter(let chapter):
                return "updateChapter-\(chapter)"
            case .exportMigration:
                return "exportMigration"
            }
        }

        var confirmTitle: String {
            switch self {
            case .updateEmotion:
                return L10n.exact("Actualizar emoción")
            case .updateChapter:
                return L10n.exact("Actualizar capítulo")
            case .exportMigration:
                return L10n.exact("Continuar")
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
            case .exportMigration:
                return L10n.format(
                    count == 1 ? "diary.batch.export.one" : "diary.batch.export.other",
                    fallback: count == 1 ? "Se preparará un archivo de migración con {0} entrada seleccionada" : "Se preparará un archivo de migración con {0} entradas seleccionadas",
                    String(count)
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

        content = AnyView(content.navigationTitle("Diario"))

            #if os(iOS)
        content = AnyView(content.navigationBarTitleDisplayMode(.inline))
            #endif

        content = AnyView(content.toolbar {
            ritualUpdateToolbar
        })

        content = AnyView(
            content.alert("Filtrar por Título", isPresented: $showAlertFilterByTitles) {
                TextField("", text: $textfielTitles)
                Button("Cancelar"){
                    textfielTitles = ""
                    dimiss()
                }
                Button("Filtrar"){
                    withAnimation {
                        modelDiario.list = modelDiario.filterByTitle(criterio: textfielTitles)
                    }
                    textfielTitles = ""
                }
                
            }
        )

        content = AnyView(
            content.alert("Filtrar por Contenido", isPresented: $showAlertFilterByContent) {
                TextField("", text: $textfielContent)
                Button("Cancelar"){
                    textfielContent = ""
                    dimiss()
                }
                Button("Filtrar"){
                    withAnimation {
                        modelDiario.list = modelDiario.filterByContent(criterio: textfielContent)
                    }
                    
                    textfielContent = ""
                }
            }
        )

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

        content = AnyView(
            content.sheet(isPresented: $showNewEntryEditor) {
                NewDiarioEntryView(
                    title: newEntryTitle,
                    content: newEntryContent,
                    emocion: newEntryEmotion,
                    fechaCreacion: newEntryDate
                ) { savedDate in
                    refreshAfterEntryCreation(savedDate)
                }
            }
        )

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
            }
        )

        content = AnyView(
            content.onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: CoreDataController.shared.context)) { _ in
                ritualReviewNeedsUpdate = hasRitualReviewUpdateToday
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
            content.fileExporter(
                isPresented: $showMigrationExporter,
                document: migrationDocument ?? MigrationDataDocument(),
                contentType: .ypgExport,
                defaultFilename: migrationExportFileName
            ) { handleMigrationExportResult($0) }
        )

        content = AnyView(
            content.sheet(isPresented: $showMigrationPasswordSheet) {
                selectedEntriesMigrationPasswordSheet
            }
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

    private var singleDateSearchSheet: some View {
        VStack {
            DatePicker("Fecha de creación", selection: $fecha1, displayedComponents: [.date])
                .padding(.top, 50)
            Button {
                Task {
                    modelDiario.list = modelDiario.searchPorFecha(for: fecha1, typeFecha: typeOfFechaSearch)
                }
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
                Task {
                    modelDiario.list = modelDiario.searchPorRangoFecha(from: fecha1, to: fecha2, typeFecha: typeOfFechaSearch)
                }
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

    private var selectedEntriesMigrationPasswordSheet: some View {
        migrationPasswordSheet(
            title: "Exportar entradas seleccionadas",
            countLabel: batchMigrationCountLabel
        )
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
        VStack {
            Text("") //Para que las entradas no sobrepasen el area segura superior

            diarioTopActions
                .padding(.horizontal, 15)
                .padding(.top, 8)

            if showCalendar {
                diarioCalendarSection
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
        }
        .onChange(of: modelDiario.list.map { $0.id }) { _, ids in
            let visibleIDs = Set(ids.compactMap { $0 })
            batchSelectedDiarioIDs = batchSelectedDiarioIDs.intersection(visibleIDs)
        }
    }

    private var diarioTopActions: some View {
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

                Button {
                    toggleCalendar()
                } label: {
                    Label(showCalendar ? "Ocultar calendario" : "Mostrar calendario", systemImage: "calendar")
                }
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
                    showAlertFilterByTitles = true
                } label: {
                    Label("Buscar en títulos", systemImage: "text.magnifyingglass")
                }

                Button {
                    showAlertFilterByContent = true
                } label: {
                    Label("Buscar en el contenido", systemImage: "text.magnifyingglass")
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
    }

    private func toggleCalendar() {
        withAnimation {
            showCalendar.toggle()
            if showCalendar == false {
                selectedCalendarDate = nil
                modelDiario.getAllItem()
            }
        }
    }

    private func showAllEntries() {
        withAnimation {
            selectedListMode = .all
            selectedCalendarDate = nil
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
        modelDiario.list = modelDiario.filterByFav()
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
            onMonthEntriesLoaded: { _ in
                selectedCalendarDate = nil
            },
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
                modelDiario.list = modelDiario.searchPorFecha(for: date)
            }
        }
        .background(Color.black.opacity(0.05))
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
        ForEach(modelDiario.list) { item in
            diarioCard(for: item)
        }
    }

    @ViewBuilder
    private var diarioGroupedList: some View {
        ForEach(groupedDiarioByChapter, id: \.chapter) { section in
            diarioChapterSection(section)
        }
    }

    @ViewBuilder
    private func diarioChapterSection(_ section: (chapter: String, entries: [Diario])) -> some View {
        DiarioChapterSectionView(
            chapter: section.chapter,
            entries: section.entries,
            isCollapsed: collapsedChapterNames.contains(section.chapter),
            isSelectionMode: isBatchSelectionMode,
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

                Button {
                    requestBatchActionConfirmation(.exportMigration)
                } label: {
                    Label("Exportar migración", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .disabled(batchSelectedDiarioIDs.isEmpty)
                .help("Exportar seleccionadas a archivo de migración")

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

    private func migrationPasswordSheet(title: String, countLabel: String) -> some View {
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
                        exportSelectedDiarioToMigration()
                    }
                    .disabled(migrationPassword.isEmpty || migrationPassword != migrationPasswordConfirmation)
                }
            }
        }
    }

    @ViewBuilder
    private func diarioCard(for item: Diario) -> some View {
        let isSelected = isDiarioSelected(item)

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
            }
        )
        .padding(15)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.black)
        .background(.white.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
    }

    private var visibleDiarioIDs: Set<UUID> {
        Set(modelDiario.list.compactMap { $0.id })
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
        withAnimation {
            if collapsedChapterNames.contains(chapter) {
                collapsedChapterNames.remove(chapter)
            } else {
                collapsedChapterNames.insert(chapter)
            }
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
        case .exportMigration:
            authenticateBeforeMigrationExport()
        }
    }

    private func authenticateBeforeMigrationExport() {
        UtilFuncs.authenticateDeviceOwner(reason: L10n.exact("Autentícate para exportar las entradas seleccionadas.")) { success, errorMessage in
            if success {
                migrationPassword = ""
                migrationPasswordConfirmation = ""
                showMigrationPasswordSheet = true
            } else {
                alertMessage = L10n.exact(errorMessage ?? "No se pudo autenticar el acceso a la exportación.")
                showAlert = true
            }
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

    private func exportSelectedDiarioToMigration() {
        guard migrationPassword == migrationPasswordConfirmation, !migrationPassword.isEmpty else {
            alertMessage = L10n.exact("La contraseña de exportación está vacía o no coincide.")
            showAlert = true
            return
        }

        let entries = privateRitualReflections
            ? selectedDiarioEntries.filter { chapterValue(for: $0) != "Cierre consciente" }
            : selectedDiarioEntries
        guard !entries.isEmpty else {
            alertMessage = L10n.exact("Selecciona al menos una entrada de diario para exportar.")
            showAlert = true
            return
        }

        do {
            let bridge = CoreDataCanonicalMigrationBridge()
            let records = try bridge.exportRecords(diaryEntries: entries)
            let result = try MyAppMigrationService().export(records: records, password: migrationPassword)
            migrationDocument = MigrationDataDocument(data: result.bytes)
            migrationExportCount = entries.count
            migrationExportFileName = "neville-diario-\(entries.count).ypgexp"
            showMigrationPasswordSheet = false
            showMigrationExporter = true
        } catch {
            alertMessage = L10n.format("migration.prepare.error", fallback: "No se pudo preparar el archivo de migración: {0}", error.localizedDescription)
            showAlert = true
        }
    }

    private func handleMigrationExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            alertMessage = L10n.format("diary.migration.success", fallback: "Archivo de migración exportado correctamente: {0} entrada(s) de diario.", String(migrationExportCount))
            finishBatchOperation()
        case .failure(let error):
            alertMessage = L10n.format("migration.save.error", fallback: "No se pudo guardar el archivo de migración: {0}", error.localizedDescription)
        }
        migrationPassword = ""
        migrationPasswordConfirmation = ""
        migrationDocument = nil
        showAlert = true
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

private struct DiarioChapterSectionView<RowContent: View>: View {
    let chapter: String
    let entries: [Diario]
    let isCollapsed: Bool
    let isSelectionMode: Bool
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
                        .font(.headline)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

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

                Spacer()
                Text("\(entries.count)")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if !isCollapsed {
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
