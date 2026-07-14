//
//  ListNotasViews.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 3/10/23.
//
//Lista todas las notas creadas y permite modificarlas y eliminarlas
// Y buscar dentro de ellas

import SwiftUI
import CoreData
import LocalAuthentication
import MapKit
import UniformTypeIdentifiers


struct ListNotasViews: View {
    private enum NotesSortOption {
        case creationDate
        case modificationDate
    }

    private enum NotesListMode {
        case all
        case groupedByCategory
    }

    @Environment(\.dismiss) var dimiss
    
    @StateObject private var modelNotas = NotasModel()
    
    @State private var showAddNoteView = false
    //@State private var list : [Notas]  = []
    //Buscar en notas
    @State var showAlertSearch = false
    @State var textField = ""
    //Buscar en títulos y contenido de notas
    @State var showAlertSearchTitle = false
    @State var textFieldTitle = ""
    //Autenticacion FaceID
   private  let contextLA = LAContext()
    @State var canOpenNotas = false
    @State var showAlert = false
    @State var alertMessage = ""
    @State private var selectionMode = false
    @State private var selectedNotaIDs: Set<String> = []
    @State private var showConfirmBulkDelete = false
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName = "Notas.pdf"
    @State private var showExportRangeSheet = false
    @State private var exportFromDate = Date.now
    @State private var exportToDate = Date.now
    @State private var selectedSortOption: NotesSortOption = .creationDate
    @State private var selectedListMode: NotesListMode = .all
    @State private var collapsedCategoryNames: Set<String> = []
    @State private var showBulkCategoryAlert = false
    @State private var bulkCategoryDraft = ""
    @State private var pendingBulkAction: NotesBulkAction?
    @State private var showBulkActionConfirmation = false
    @State private var showMigrationPasswordSheet = false
    @State private var showMigrationExporter = false
    @State private var migrationPassword = ""
    @State private var migrationPasswordConfirmation = ""
    @State private var migrationDocument: MigrationDataDocument?
    @State private var migrationExportFileName = "neville-notas.ypgexp"
    @State private var migrationExportCount = 0
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    
    
    
    private var filtered : [Notas] {
        if self.textFieldTitle.isEmpty {return self.modelNotas.notas}
        return self.modelNotas.notas.filter { nota in
            let titleMatches = nota.title?.localizedCaseInsensitiveContains(self.textFieldTitle) ?? false
            let contentMatches = nota.noteDisplayText.localizedCaseInsensitiveContains(self.textFieldTitle)
            return titleMatches || contentMatches
        }
    }

    private var orderedFiltered: [Notas] {
        filtered.sorted { left, right in
            switch selectedSortOption {
            case .creationDate:
                return creationDate(for: left) > creationDate(for: right)
            case .modificationDate:
                return modificationDate(for: left) > modificationDate(for: right)
            }
        }
    }

    private var groupedFiltered: [(category: String, notas: [Notas])] {
        let grouped = Dictionary(grouping: orderedFiltered) { nota in
            categoryName(for: nota)
        }

        return grouped
            .map { (category: $0.key, notas: $0.value) }
            .sorted { left, right in
                if left.category == uncategorizedCategoryTitle { return false }
                if right.category == uncategorizedCategoryTitle { return true }
                return left.category.localizedCaseInsensitiveCompare(right.category) == .orderedAscending
            }
    }

    private var selectedNotas: [Notas] {
        self.modelNotas.notas.filter { nota in
            guard let id = nota.id else { return false }
            return selectedNotaIDs.contains(id)
        }
    }

    private var canAccessNotasContent: Bool {
        canOpenNotas == true || UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false
    }

    private var hasPremiumPDFAccess: Bool {
        purchaseStatus || yorjPremium
    }

    private enum NotesBulkAction: Identifiable {
        case passToFrases
        case passToCalm
        case setCategory(String)
        case exportMigration

        var id: String {
            switch self {
            case .passToFrases:
                return "passToFrases"
            case .passToCalm:
                return "passToCalm"
            case .setCategory(let category):
                return "setCategory-\(category)"
            case .exportMigration:
                return "exportMigration"
            }
        }

        var confirmTitle: String {
            switch self {
            case .passToFrases:
                return L10n.exact("Pasar a Frases")
            case .passToCalm:
                return L10n.exact("Pasar a Calma")
            case .setCategory:
                return L10n.exact("Actualizar")
            case .exportMigration:
                return L10n.exact("Continuar")
            }
        }

        func message(count: Int) -> String {
            switch self {
            case .passToFrases:
                return L10n.format(
                    count == 1 ? "notes.batch.personal_phrases.one" : "notes.batch.personal_phrases.other",
                    fallback: count == 1 ? "Se copiará {0} nota seleccionada a Frases personales." : "Se copiarán {0} notas seleccionadas a Frases personales.",
                    String(count)
                )
            case .passToCalm:
                return L10n.format(
                    count == 1 ? "notes.batch.calm.one" : "notes.batch.calm.other",
                    fallback: count == 1 ? "Se copiará {0} nota seleccionada a Espacio Calma." : "Se copiarán {0} notas seleccionadas a Espacio Calma.",
                    String(count)
                )
            case .setCategory(let category):
                let target = category.trimmingCharacters(in: .whitespacesAndNewlines)
                if target.isEmpty {
                    return L10n.format(
                        count == 1 ? "notes.batch.remove_category.one" : "notes.batch.remove_category.other",
                        fallback: count == 1 ? "Se quitará la categoría de {0} nota seleccionada" : "Se quitará la categoría de {0} notas seleccionadas",
                        String(count)
                    )
                }
                return L10n.format(
                    count == 1 ? "notes.batch.assign_category.one" : "notes.batch.assign_category.other",
                    fallback: count == 1 ? "Se asignará la categoría «{0}» a {1} nota seleccionada" : "Se asignará la categoría «{0}» a {1} notas seleccionadas",
                    target, String(count)
                )
            case .exportMigration:
                return L10n.format(
                    count == 1 ? "notes.batch.export.one" : "notes.batch.export.other",
                    fallback: count == 1 ? "Se preparará un archivo de migración con {0} nota seleccionada" : "Se preparará un archivo de migración con {0} notas seleccionadas",
                    String(count)
                )
            }
        }
    }
 
    var body: some View {
        NavigationStack {
            rootContent
                .navigationTitle("Notas")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    notasToolbar
                }
                .sheet(isPresented: $showAddNoteView) {
                    AddNotasView()
                        .environmentObject(self.modelNotas)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.hidden)
                    
                }
                .alert("Buscar en Notas", isPresented: $showAlertSearch){
                    TextField("", text: $textField, axis: .vertical)
                    Button("Buscar"){
                        let temp = NotasModel().searchTextInNotas(text: textField, donde: .nota)
                        if temp.count > 0 {
                            self.modelNotas.notas = temp
                        }
                    }
                }
                .alert("Buscar en título de Notas", isPresented: $showAlertSearchTitle){
                    TextField("", text: $textFieldTitle, axis: .vertical)
                    Button("Buscar"){
                        let temp = NotasModel().searchTextInNotas(text: textFieldTitle, donde: .titulo)
                        if temp.count > 0 {
                            self.modelNotas.notas = temp
                        }
                    }
                }
                .alert(isPresented: $showAlert){
                    Alert(title: Text("Notas"), message: Text(alertMessage))
                }
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
                ) { handleNotasMigrationExportResult($0) }
                .sheet(isPresented: $showExportRangeSheet) {
                    VStack(spacing: 16) {
                        DatePicker("Desde", selection: $exportFromDate, displayedComponents: [.date])
                        DatePicker("Hasta", selection: $exportToDate, displayedComponents: [.date])
                        Button("Exportar PDF") {
                            exportNotasRangeToPDF(from: exportFromDate, to: exportToDate)
                            showExportRangeSheet = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                .sheet(isPresented: $showMigrationPasswordSheet) {
                    migrationPasswordSheet(
                        title: "Exportar notas seleccionadas",
                        countLabel: "\(selectedNotaIDs.count) nota(s)",
                        exportAction: exportSelectedNotasToMigration
                    )
                }
                .confirmationDialog("¿Eliminar notas seleccionadas?", isPresented: $showConfirmBulkDelete) {
                    Button("Eliminar \(selectedNotaIDs.count) nota(s)", role: .destructive) {
                        applyDeleteToSelected()
                    }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Esta acción no se puede deshacer.")
                }
                .confirmationDialog("Confirmar acción", isPresented: $showBulkActionConfirmation) {
                    notesBulkConfirmationActions()
                } message: {
                    notesBulkConfirmationMessage()
                }
                .alert("Cambiar categoría", isPresented: $showBulkCategoryAlert) {
                    TextField("Categoría", text: $bulkCategoryDraft, axis: .vertical)
                    Button("Cancelar", role: .cancel) {}
                    Button("Actualizar") {
                        requestBulkActionConfirmation(.setCategory(bulkCategoryDraft))
                    }
                } message: {
                    Text("Se actualizarán las notas seleccionadas.")
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        ZStack {
            LinearGradient(colors: GradientesPreselect.G_natural_3.getColors,
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                if canAccessNotasContent {
                    notesScrollView
                } else {
                    Spacer()
                    autenticationView()
                }

                Spacer()
                if selectionMode && canAccessNotasContent {
                    bulkActionsBar()
                }

                Divider()
                bottomBar
            }
        }
    }

    @ViewBuilder
    private var notesScrollView: some View {
        ScrollView(.vertical) {
            if selectedListMode == .all {
                notesFlatList
            } else {
                notesGroupedList
            }
        }
        #if os(macOS)
        .searchable(text: $textFieldTitle, prompt: "Buscar")
        #else
        .searchable(text: $textFieldTitle, placement: .navigationBarDrawer(displayMode: .always), prompt:"Buscar")
        #endif
        .task {
            self.modelNotas.getAllNotasToModel()
        }
    }

    @ViewBuilder
    private var notesFlatList: some View {
        ForEach(self.orderedFiltered) { nota in
            cardNotas(
                nota: nota,
                selectionMode: self.selectionMode,
                isSelected: self.selectedNotaIDs.contains(nota.id ?? ""),
                onSelectionToggle: { toggleSelection(for: nota) }
            )
            .environmentObject(self.modelNotas)
        }
    }

    @ViewBuilder
    private var notesGroupedList: some View {
        ForEach(groupedFiltered, id: \.category) { section in
            NotesCategorySectionView(
                category: section.category,
                notas: section.notas,
                isCollapsed: collapsedCategoryNames.contains(section.category),
                selectionMode: self.selectionMode,
                selectedNotaIDs: self.selectedNotaIDs,
                onCollapseToggle: { toggleCategoryCollapse(section.category) },
                onRenameCategory: { newCategory in
                    renameCategory(section.category, to: newCategory)
                },
                onDeleteCategory: {
                    deleteCategory(section.category)
                },
                onSelectionToggle: { nota in toggleSelection(for: nota) }
            )
            .environmentObject(self.modelNotas)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        HStack(spacing: 30) {
            Spacer()
            #if os(iOS)
            Button("Volver") {
                dimiss()
            }
            .foregroundStyle(.black)
            .buttonStyle(.bordered)
            .padding(.trailing, 20)
            #endif
        }
        .padding(.bottom, 20)
    }

    @ToolbarContentBuilder
    private var notasToolbar: some ToolbarContent {
        if UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false {
            unlockedNotasToolbar
        } else if self.canOpenNotas {
            protectedNotasToolbar
        }
    }

    @ToolbarContentBuilder
    private var unlockedNotasToolbar: some ToolbarContent {
        ToolbarItem {
            filtersMenu
        }

        if #available(iOS 26.0, macOS 26.0, *) {
            ToolbarSpacer(.fixed)
        }

        ToolbarItem {
            addNotaButton
        }
    }

    @ToolbarContentBuilder
    private var protectedNotasToolbar: some ToolbarContent {
        ToolbarItem {
            filtersMenu
        }

        if #available(iOS 26.0, macOS 26.0, *) {
            ToolbarSpacer(.fixed)
        }

        ToolbarItem {
            addNotaButton
        }
    }

    @ViewBuilder
    private var filtersMenu: some View {
        Menu {
            Button {
                withAnimation {
                    self.modelNotas.getAllNotasToModel()
                    selectedListMode = .all
                }
            } label: {
                Label("Todas las notas", systemImage: "text.magnifyingglass.rtl")
            }

            Button {
                withAnimation {
                    collapsedCategoryNames = Set(groupedFiltered.map(\.category))
                    selectedListMode = .groupedByCategory
                }
            } label: {
                Label(
                    "Por categoría",
                    systemImage: selectedListMode == .groupedByCategory ? "checkmark.circle.fill" : "folder"
                )
            }

            Button {
                withAnimation {
                    modelNotas.notas = NotasModel().getFavNotas()
                }
            } label: {
                Label("Notas favoritas", systemImage: "text.magnifyingglass.rtl")
            }

            Button {
                withAnimation {
                    selectedSortOption = .creationDate
                }
            } label: {
                Label(
                    "Por fecha de creación",
                    systemImage: selectedSortOption == .creationDate ? "checkmark.circle.fill" : "calendar.badge.clock"
                )
            }

            Button {
                withAnimation {
                    selectedSortOption = .modificationDate
                }
            } label: {
                Label(
                    "Por fecha de modificación",
                    systemImage: selectedSortOption == .modificationDate ? "checkmark.circle.fill" : "calendar"
                )
            }

            Button {
                showAlertSearch = true
            } label: {
                Label("Buscar en notas", systemImage: "text.magnifyingglass.rtl")
            }

            Divider()

            Button {
                toggleSelectionMode()
            } label: {
                Label(selectionMode ? "Cancelar selección" : "Seleccionar", systemImage: "checklist")
            }

            exportNotasPDFMenu()
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
        }
    }

    @ViewBuilder
    private var addNotaButton: some View {
        Button {
            guard !selectionMode else { return }
            #if os(macOS)
            showWindow(for: AddNotasView(),
                       environmentObjects: [self.modelNotas],
                       title: "Crear Nota",
                       size: AppCons.windows_size_content,
                       isModal: false
            )
            #else
            showAddNoteView = true
            #endif
        } label: {
            Image(systemName: "plus")
        }
    }

    private func toggleSelectionMode() {
        withAnimation {
            selectionMode.toggle()
            if !selectionMode {
                selectedNotaIDs.removeAll()
            }
        }
    }

    //Actualiza una nota
    func updateYorj(nota : Notas){
        
        if  self.modelNotas.updateNota(
            NotaID: nota.id ?? "",
            newTitle: nota.title ?? "",
            newNota: nota.nota ?? "",
            isfav: nota.isfav,
            direccionMapa: nota.value(forKey: "direccionMapa") as? String ?? "",
            categoria: categoryValue(for: nota)
        ) {
            self.modelNotas.getAllNotasToModel()
        }
        
        
    }

    @ViewBuilder
    func bulkActionsBar() -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Seleccionadas: \(selectedNotaIDs.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(selectedNotaIDs.count == filtered.count && !filtered.isEmpty ? "Quitar sel." : "Sel. todas") {
                        withAnimation {
                            toggleSelectAllFiltered()
                        }
                    }
                    .foregroundStyle(.black).bold()
                    .tint(.gray)
                    .buttonStyle(.bordered)

                    Button {
                        showConfirmBulkDelete = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Eliminar")
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(selectedNotaIDs.isEmpty)

                    Button("Frases") {
                        requestBulkActionConfirmation(.passToFrases)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(selectedNotaIDs.isEmpty)

                    Button("Calma") {
                        requestBulkActionConfirmation(.passToCalm)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(selectedNotaIDs.isEmpty)

                    Menu("Categoría") {
                        Button("Sin categoría") {
                            requestBulkActionConfirmation(.setCategory(""))
                        }
                        ForEach(existingCategories, id: \.self) { category in
                            Button(category) {
                                requestBulkActionConfirmation(.setCategory(category))
                            }
                        }
                        Button("Otra...") {
                            bulkCategoryDraft = ""
                            showBulkCategoryAlert = true
                        }
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .disabled(selectedNotaIDs.isEmpty)

                    Button("Migrar") {
                        requestBulkActionConfirmation(.exportMigration)
                    }
                    .foregroundStyle(.black).bold()
                    .buttonStyle(.bordered)
                    .disabled(selectedNotaIDs.isEmpty)
                }
                .fixedSize()
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func notesBulkConfirmationActions() -> some View {
        if let action = pendingBulkAction {
            Button(action.confirmTitle) {
                performConfirmedBulkAction(action)
                pendingBulkAction = nil
            }
        }
        Button("Cancelar", role: .cancel) {
            pendingBulkAction = nil
        }
    }

    private func notesBulkConfirmationMessage() -> Text {
        Text(pendingBulkAction?.message(count: selectedNotaIDs.count) ?? "")
    }

    private func requestBulkActionConfirmation(_ action: NotesBulkAction) {
        guard !selectedNotaIDs.isEmpty else { return }
        DispatchQueue.main.async {
            pendingBulkAction = action
            showBulkActionConfirmation = true
        }
    }

    private func performConfirmedBulkAction(_ action: NotesBulkAction) {
        switch action {
        case .passToFrases:
            applyPassToFrases()
        case .passToCalm:
            applyPassToCalm()
        case .setCategory(let category):
            applyCategoryToSelected(category)
        case .exportMigration:
            authenticateBeforeMigrationExport()
        }
    }

    private func authenticateBeforeMigrationExport() {
        UtilFuncs.authenticateDeviceOwner(reason: L10n.exact("Autentícate para exportar las notas seleccionadas.")) { success, errorMessage in
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

    private func handleNotasMigrationExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            alertMessage = L10n.format("notes.migration.success", fallback: "Archivo de migración exportado correctamente: {0} nota(s).", String(migrationExportCount))
            selectedNotaIDs.removeAll()
            selectionMode = false
        case .failure(let error):
            alertMessage = L10n.format("migration.save.error", fallback: "No se pudo guardar el archivo de migración: {0}", error.localizedDescription)
        }
        migrationPassword = ""
        migrationPasswordConfirmation = ""
        migrationDocument = nil
        showAlert = true
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

    private func toggleSelection(for nota: Notas) {
        guard selectionMode, let id = nota.id else { return }
        if selectedNotaIDs.contains(id) {
            selectedNotaIDs.remove(id)
        } else {
            selectedNotaIDs.insert(id)
        }
    }

    private func toggleCategoryCollapse(_ category: String) {
        withAnimation {
            if collapsedCategoryNames.contains(category) {
                collapsedCategoryNames.remove(category)
            } else {
                collapsedCategoryNames.insert(category)
            }
        }
    }

    private func renameCategory(_ oldCategory: String, to newCategory: String) {
        let trimmedCategory = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard oldCategory != (trimmedCategory.isEmpty ? uncategorizedCategoryTitle : trimmedCategory) else { return }

        var updatedCount = 0
        for nota in modelNotas.notas where categoryName(for: nota) == oldCategory {
            if modelNotas.updateNota(
                NotaID: nota.id ?? "",
                newTitle: nota.title ?? "",
                newNota: nota.nota ?? "",
                isfav: nota.isfav,
                direccionMapa: nota.value(forKey: "direccionMapa") as? String ?? "",
                categoria: trimmedCategory
            ) {
                updatedCount += 1
            }
        }

        if collapsedCategoryNames.remove(oldCategory) != nil {
            collapsedCategoryNames.insert(trimmedCategory.isEmpty ? uncategorizedCategoryTitle : trimmedCategory)
        }

        modelNotas.getAllNotasToModel()
        alertMessage = L10n.format("notes.updated.count", fallback: "{0} nota(s) actualizada(s).", String(updatedCount))
        showAlert = true
    }

    private func deleteCategory(_ category: String) {
        let toDelete = modelNotas.notas.filter { categoryName(for: $0) == category }
        for nota in toDelete {
            modelNotas.deleteNota(nota: nota)
        }
        collapsedCategoryNames.remove(category)
        selectedNotaIDs.subtract(toDelete.compactMap { $0.id })
        modelNotas.getAllNotasToModel()
        alertMessage = L10n.format("notes.deleted.count", fallback: "{0} nota(s) eliminada(s).", String(toDelete.count))
        showAlert = true
    }

    private func toggleSelectAllFiltered() {
        let allFilteredIDs = Set(orderedFiltered.compactMap { $0.id })
        if !allFilteredIDs.isEmpty && selectedNotaIDs.isSuperset(of: allFilteredIDs) {
            selectedNotaIDs.subtract(allFilteredIDs)
        } else {
            selectedNotaIDs.formUnion(allFilteredIDs)
        }
    }

    private func applyDeleteToSelected() {
        let toDelete = selectedNotas
        for nota in toDelete {
            modelNotas.deleteNota(nota: nota)
        }
        selectedNotaIDs.removeAll()
        selectionMode = false
        modelNotas.getAllNotasToModel()
        alertMessage = L10n.format("notes.deleted.count", fallback: "{0} nota(s) eliminada(s).", String(toDelete.count))
        showAlert = true
    }

    private func applyPassToFrases() {
        var inserted = 0
        for nota in selectedNotas {
            let text = nota.noteDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            if FrasesModel.shared.AddFrase(frase: text, autor: "personal") {
                inserted += 1
            }
        }
        selectedNotaIDs.removeAll()
        selectionMode = false
        alertMessage = L10n.format("notes.personal_phrases.count", fallback: "{0} nota(s) pasada(s) a Frases personales.", String(inserted))
        showAlert = true
    }

    private func applyPassToCalm() {
        let context = CoreDataController.shared.context
        guard let model = context.persistentStoreCoordinator?.managedObjectModel,
              model.entitiesByName["CalmUserPhrase"] != nil,
              let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else {
            alertMessage = L10n.exact("No se encontró la entidad de frases de Espacio Calma.")
            showAlert = true
            return
        }

        var inserted = 0
        for nota in selectedNotas {
            let text = nota.noteDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(UUID(), forKey: "id")
            object.setValue(text, forKey: "phrase")
            object.setValue(Date(), forKey: "createdAt")
            inserted += 1
        }

        do {
            try context.save()
            selectedNotaIDs.removeAll()
            selectionMode = false
            alertMessage = L10n.format("notes.calm.count", fallback: "{0} nota(s) pasada(s) a Espacio Calma.", String(inserted))
        } catch {
            context.rollback()
            alertMessage = L10n.exact("No se pudo guardar en Espacio Calma.")
        }
        showAlert = true
    }

    private func applyCategoryToSelected(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = 0
        for nota in selectedNotas {
            if updateNotaCategory(nota, to: trimmedCategory) {
                updated += 1
            }
        }
        selectedNotaIDs.removeAll()
        selectionMode = false
        modelNotas.getAllNotasToModel()
        alertMessage = L10n.format("notes.updated.count", fallback: "{0} nota(s) actualizada(s).", String(updated))
        showAlert = true
    }

    private func updateNotaCategory(_ nota: Notas, to category: String) -> Bool {
        modelNotas.updateNota(
            NotaID: nota.id ?? "",
            newTitle: nota.title ?? "",
            newNota: nota.nota ?? "",
            isfav: nota.isfav,
            direccionMapa: nota.value(forKey: "direccionMapa") as? String ?? "",
            categoria: category
        )
    }

    private func exportSelectedNotasToMigration() {
        guard migrationPassword == migrationPasswordConfirmation, !migrationPassword.isEmpty else {
            alertMessage = L10n.exact("La contraseña de exportación está vacía o no coincide.")
            showAlert = true
            return
        }

        let notes = selectedNotas
        guard !notes.isEmpty else {
            alertMessage = L10n.exact("Selecciona al menos una nota para exportar.")
            showAlert = true
            return
        }

        do {
            let bridge = CoreDataCanonicalMigrationBridge()
            let records = try bridge.exportRecords(notes: notes)
            let result = try MyAppMigrationService().export(records: records, password: migrationPassword)
            migrationDocument = MigrationDataDocument(data: result.bytes)
            migrationExportCount = notes.count
            migrationExportFileName = "neville-notas-\(notes.count).ypgexp"
            showMigrationPasswordSheet = false
            showMigrationExporter = true
        } catch {
            alertMessage = L10n.format("migration.prepare.error", fallback: "No se pudo preparar el archivo de migración: {0}", error.localizedDescription)
            showAlert = true
        }
    }

    @ViewBuilder
    private func exportNotasPDFMenu() -> some View {
        Menu {
            Text("Exportar a PDF")
                .font(.caption)
            Button("Manual (seleccionadas)") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                if !selectionMode {
                    withAnimation {
                        selectionMode = true
                    }
                    alertMessage = L10n.exact("Selecciona las notas y vuelve a pulsar 'Manual (seleccionadas)' para exportar.")
                    showAlert = true
                    return
                }
                exportNotasToPDF(selectedNotas, scopeName: "Manual")
            }
            Button("Semana actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                exportNotasToPDF(notasCurrentWeek(), scopeName: "Semana")
            }
            Button("Mes actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
                    showAlert = true
                    return
                }
                exportNotasToPDF(notasCurrentMonth(), scopeName: "Mes")
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

    private func notasCurrentWeek() -> [Notas] {
        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let end = calendar.date(byAdding: .day, value: 7, to: start) else {
            return []
        }
        return notasInRange(from: start, to: end)
    }

    private func notasCurrentMonth() -> [Notas] {
        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.dateInterval(of: .month, for: now)?.start,
              let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return []
        }
        return notasInRange(from: start, to: end)
    }

    private func notasInRange(from start: Date, to end: Date) -> [Notas] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDayExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)) ?? end
        return modelNotas.notas.filter { nota in
            guard let date = notasReferenceDate(nota) else { return false }
            return date >= startDay && date < endDayExclusive
        }
    }

    private func exportNotasRangeToPDF(from start: Date, to end: Date) {
        let items = notasInRange(from: start, to: end)
        exportNotasToPDF(items, scopeName: "Rango")
    }

    private func notasReferenceDate(_ nota: Notas) -> Date? {
        (nota.value(forKey: "fechaCreacion") as? Date) ?? (nota.value(forKey: "fechaModificacion") as? Date)
    }

    private func creationDate(for nota: Notas) -> Date {
        (nota.value(forKey: "fechaCreacion") as? Date)
        ?? (nota.value(forKey: "fechaModificacion") as? Date)
        ?? .distantPast
    }

    private func modificationDate(for nota: Notas) -> Date {
        (nota.value(forKey: "fechaModificacion") as? Date)
        ?? (nota.value(forKey: "fechaCreacion") as? Date)
        ?? .distantPast
    }

    private var uncategorizedCategoryTitle: String {
        L10n.exact("Sin categoría")
    }

    private func categoryValue(for nota: Notas) -> String {
        nota.value(forKey: "categoria") as? String ?? ""
    }

    private func categoryName(for nota: Notas) -> String {
        let value = categoryValue(for: nota).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? uncategorizedCategoryTitle : value
    }

    private var existingCategories: [String] {
        Array(Set(modelNotas.notas.compactMap { nota in
            let value = categoryValue(for: nota).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func exportNotasToPDF(_ notas: [Notas], scopeName: String) {
        guard hasPremiumPDFAccess else {
            alertMessage = L10n.exact("La exportación a PDF está disponible en la Versión Extendida.")
            showAlert = true
            return
        }
        guard !notas.isEmpty else {
            alertMessage = L10n.format("notes.pdf.empty", fallback: "No hay notas para exportar en {0}.", L10n.exact(scopeName).lowercased())
            showAlert = true
            return
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notas) { nota in
            let day = notasReferenceDate(nota) ?? Date.distantPast
            return calendar.startOfDay(for: day)
        }

        let sections: [PDFExportSection] = grouped.keys.sorted().map { day in
            let dayNotas = (grouped[day] ?? []).sorted {
                (notasReferenceDate($0) ?? .distantPast) < (notasReferenceDate($1) ?? .distantPast)
            }
            let lines: [PDFExportLine] = dayNotas.map { nota in
                let title = (nota.title ?? "").isEmpty ? "Sin título" : (nota.title ?? "Sin título")
                let detail = nota.noteDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
                let category = categoryValue(for: nota).trimmingCharacters(in: .whitespacesAndNewlines)
                let detailParts = [
                    category.isEmpty ? nil : "Categoría: \(category)",
                    detail.isEmpty ? nil : detail
                ].compactMap { $0 }
                return PDFExportLine(title: title, detail: detailParts.isEmpty ? nil : detailParts.joined(separator: "\n\n"))
            }
            return PDFExportSection(title: day.formatted(date: .complete, time: .omitted), lines: lines)
        }

        let descriptor = PDFExportDocumentDescriptor(
            title: "Notas - \(scopeName)",
            subtitle: "Generado el \(Date().formatted(date: .abbreviated, time: .shortened))",
            sections: sections
        )

        do {
            let data = try PDFExportModule.render(descriptor)
            exportedPDFDocument = ExportedPDFDocument(data: data)
            let dateLabel = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
            exportedPDFFileName = "Notas-\(scopeName)-\(dateLabel)"
            showPDFExporter = true
        } catch {
            alertMessage = L10n.exact("No se pudo generar el PDF.")
            showAlert = true
        }
    }
    

    
    @ViewBuilder // View Extract
    func autenticationView()-> some View {
        VStack(alignment: .center,  spacing: 20) {
             
             Text("Se ha habilitado la protección de las Notas")
                 .foregroundStyle(.orange.opacity(0.7))
                 .font(.system(size: 18))
                 .bold()
            
            //Chequeando si existe biometría en el dispositivo
            if BiometryCheckerSupport.checkBiometricSupport() == .available{
                Button{
                    UtilFuncs.autent(HabilitarContenido: self.$canOpenNotas) //Lanzando el chequeo biométrico
                }label: {
                    Image(systemName: "key.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.orange.opacity(0.7))
                        .symbolEffect(.pulse, isActive: true)
                }
                Text("Toque la imagen de arriba para abrir las Notas")
                
                //Permitir acceder también por contraseña. Si existe una contraseña guardada
                if KeychainHelper.shared.getPassword() != nil{
                    VStack{
                        NavigationLink("Acceder por contraseña"){
                            LogginView(ente: .Notas)
                           
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                    }.padding(.vertical, 25)
                }
                
                
            }else{ // Si no existe biometría en el dispositivo
                
                //Determinamos que haya una contraseña Guardada:
                if KeychainHelper.shared.getPassword() != nil{ //Hay contraseña en el llavero
                    VStack{
                        Text("Parece que su dispositivo no admite biometría. Utilice el botón debajo para entrar por contraseña.")
                        NavigationLink("Acceder por contraseña"){
                            LogginView(ente: .Notas)
                           
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .padding()
                        
                        Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                            .font(.footnote)
                    }
                }else{ //No existe una contrasela en el llavero. Permitir crear una
                    VStack{
                        Text("Parece que su dispositivo no admite biometría. Establezca una contraseña para tener acceso seguro a las Notas Protegidas")
                        NavigationLink("Crear una contraseña"){
                         CreatePasswordView()
                           
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .padding()
                        
                        Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                            .font(.footnote)
                    }
                }
                
                
            }
            
             
         }
    }

}

private struct NotesCategorySectionView: View {
    let category: String
    let notas: [Notas]
    let isCollapsed: Bool
    let selectionMode: Bool
    let selectedNotaIDs: Set<String>
    let onCollapseToggle: () -> Void
    let onRenameCategory: (String) -> Void
    let onDeleteCategory: () -> Void
    let onSelectionToggle: (Notas) -> Void

    @EnvironmentObject private var modelNotas: NotasModel
    @State private var showRenameAlert = false
    @State private var categoryDraft = ""
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
                    Text(category)
                        .font(.headline)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Menu {
                    Text("- Categoría -")
                    Button {
                        categoryDraft = category == "Sin categoría" ? "" : category
                        showRenameAlert = true
                    } label: {
                        Label("Cambiar texto", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Eliminar notas", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.7))
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)

                Spacer()
                Text("\(notas.count)")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if !isCollapsed {
                ForEach(notas) { nota in
                    cardNotas(
                        nota: nota,
                        selectionMode: selectionMode,
                        isSelected: selectedNotaIDs.contains(nota.id ?? ""),
                        onSelectionToggle: { onSelectionToggle(nota) }
                    )
                    .environmentObject(modelNotas)
                }
            }
        }
        .alert("Renombrar categoría", isPresented: $showRenameAlert) {
            TextField("Categoría", text: $categoryDraft, axis: .vertical)
            Button("Cancelar", role: .cancel) {}
            Button("Actualizar") {
                onRenameCategory(categoryDraft)
            }
        } message: {
            Text("Se actualizarán las notas de esta categoría.")
        }
        .confirmationDialog("¿Eliminar todas las notas de esta categoría?", isPresented: $showDeleteConfirmation) {
            Button("Eliminar \(notas.count) nota(s)", role: .destructive) {
                onDeleteCategory()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }
}

//Card notas:
struct cardNotas: View{
    let nota : Notas?
    let selectionMode: Bool
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    @EnvironmentObject var modelNotas : NotasModel
    @State private var expandText = false
    @State private var isfav = false
    @State private var expandNota = false
    
    //Opciones:
    @State private var showConfirmDialogDeleteNota = false
    @State private var showUpdateNoteView = false
    @State private var showCalmAlert = false
    @State private var calmAlertMessage = ""
    @State private var showMapsAlert = false
    @State private var mapsAlertMessage = ""
    @State private var showCategoryAlert = false
    @State private var categoryDraft = ""
    
    @AppStorage(AppCons.UD_setting_fontListaSize)  var fontSizeLista : Int = 20

    private static let metadataDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func formattedMetadata(for nota: Notas?) -> String {
        guard let nota else { return "" }
        let createdRaw = nota.value(forKey: "fechaCreacion") as? Date
        let modifiedRaw = nota.value(forKey: "fechaModificacion") as? Date
        let category = (nota.value(forKey: "categoria") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let created = createdRaw ?? modifiedRaw
        let modified = modifiedRaw ?? createdRaw

        if created == nil, modified == nil, category.isEmpty {
            return ""
        }

        var parts: [String] = []
        if !category.isEmpty {
            parts.append(L10n.format("notes.metadata.category", fallback: "Categoría: {0}", category))
        }
        if let created {
            parts.append(L10n.format("notes.metadata.created", fallback: "Creada: {0}", Self.metadataDateFormatter.string(from: created)))
        }
        if let modified {
            parts.append(L10n.format("notes.metadata.modified", fallback: "Modificada: {0}", Self.metadataDateFormatter.string(from: modified)))
        }
        return parts.joined(separator: " · ")
    }

    private var existingCategories: [String] {
        Array(Set(modelNotas.notas.compactMap { nota in
            let value = (nota.value(forKey: "categoria") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var currentCategory: String {
        (nota?.value(forKey: "categoria") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var noteActionText: String {
        nota?.noteDisplayText ?? ""
    }

    private var availableCategoriesForCurrentNote: [String] {
        existingCategories.filter {
            $0.localizedCaseInsensitiveCompare(currentCategory) != .orderedSame
        }
    }

    
    var body: some View{
        VStack(){
            HStack{
                if selectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(.black)
                        .font(.title3)
                        .padding(.leading, 4)
                }

                Text(nota?.title ?? "")
                    .bold()
                    .fontDesign(.serif)
                    .font(.system(size: CGFloat(self.fontSizeLista)))
                    .foregroundStyle(.black)
                    
                    .bold()
                    .padding(8)
                    .onTapGesture(count: 2) {
                        guard !selectionMode else { return }
                        withAnimation {
                            showUpdateNoteView = true
                        }
                        
                    }
                    .onTapGesture {
                        guard !selectionMode else {
                            onSelectionToggle()
                            return
                        }
                        withAnimation {
                            expandNota.toggle()
                        }
                            
                    }
                Spacer()
                if isfav {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(LinearGradient(colors: [.orange, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .onTapGesture {
                            _ = NotasModel().updateFav(NotaID: nota?.id ?? "", favState: false)
                            withAnimation {
                                isfav = nota?.isfav ?? false ? true : false
                            }
                        }
                }

                if !selectionMode {
                Menu{
                        Text("< \(nota?.title ?? "") >")
                    #if os(macOS)
                    Button{
                        if self.nota?.id != nil {
                            showWindow(for: UpdateNotasView(
                                NotaId: nota!.id!,
                                title: nota!.title!,
                                categoria: nota?.value(forKey: "categoria") as? String ?? "",
                                nota: nota!.nota!,
                                direccionMapa: nota?.value(forKey: "direccionMapa") as? String ?? "",
                                isChecklist: nota?.isChecklistNote ?? false,
                                checklistItems: nota?.checklistItems ?? []
                            ),
                                       environmentObjects: [self.modelNotas],
                                       title: "Editar Nota",
                                       size: AppCons.windows_size_content_small,
                                       isModal: true
                            )
                        }
                    }
                        label:{
                        Label("Editar...", systemImage: "highlighter.badge.ellipsis")
                    }
                    #else
                    
                    NavigationLink{
                        if self.nota?.id != nil {
                            UpdateNotasView(
                                NotaId: nota!.id!,
                                title: nota!.title!,
                                categoria: nota?.value(forKey: "categoria") as? String ?? "",
                                nota: nota!.nota!,
                                direccionMapa: nota?.value(forKey: "direccionMapa") as? String ?? "",
                                isChecklist: nota?.isChecklistNote ?? false,
                                checklistItems: nota?.checklistItems ?? []
                            )
                                .environmentObject(self.modelNotas)
                        }
                          
                    }
                        label:{
                        Label("Editar...", systemImage: "highlighter.badge.ellipsis")
                    }
                    
                    #endif

                    Menu {
                        if !currentCategory.isEmpty {
                            Button("Sin categoría") {
                                updateCurrentNoteCategory("")
                            }
                        }
                        ForEach(availableCategoriesForCurrentNote, id: \.self) { category in
                            Button(category) {
                                updateCurrentNoteCategory(category)
                            }
                        }
                        Button("Otra...") {
                            categoryDraft = nota?.value(forKey: "categoria") as? String ?? ""
                            showCategoryAlert = true
                        }
                    } label: {
                        Label("Cambiar categoría", systemImage: "folder")
                    }

                    Button {
                        convertCurrentNoteType()
                    } label: {
                        Label(
                            nota?.isChecklistNote == true ? "Convertir a texto" : "Convertir a checklist",
                            systemImage: nota?.isChecklistNote == true ? "text.alignleft" : "checklist"
                        )
                    }
                    
                    
                    
                    
                        Button{
                        if nota!.isfav {
                            _ = NotasModel().updateFav(NotaID: nota!.id ?? "", favState: false)
                        }else{
                            _ = NotasModel().updateFav(NotaID: nota!.id ?? "", favState: true)
                        }
                            withAnimation {
                                isfav = nota!.isfav ? true : false
                            }
                        
                        }label:{
                            Label(nota!.isfav ? "Quitar Favorito" : "Hacer Favorito", systemImage: nota!.isfav ? "heart.slash" : "heart")
                    }
                    NavigationLink{
                        let isfav = nota!.isfav
                        let categoria = nota?.value(forKey: "categoria") as? String ?? ""
                        let texto = "\(AppCons.zspNota)\(nota!.title ?? "")::\(noteActionText)::\(isfav == true  ? "si" : "no")::\(categoria)"
                            GenerateQRView(footer: texto, showImage: true)
                    }label:{
                        Label("Generar QR...", systemImage: "qrcode")
                    }

                    Button {
                        self.addCurrentNoteToCalmList()
                    } label: {
                        Label("Añadir a Espacio Calma", systemImage: "leaf")
                    }
                    .buttonStyle(.bordered)

                    if let direccion = nota?.value(forKey: "direccionMapa") as? String,
                       !direccion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            openInMaps(address: direccion)
                        } label: {
                            Label("Abrir en Mapas", systemImage: "map")
                        }
                    }

                    #if os(macOS)
                    Button {
                        let draft = AgendaInterchangeService.makeAgendaDraft(
                            title: nota?.title ?? "",
                            content: noteActionText
                        )
                        showWindow(
                            for: AgendaEditorView(baseItem: draft) { items in
                                AgendaInterchangeService.saveAgendaItems(items)
                            },
                            environmentObjects: [],
                            title: "Exportar a Agenda",
                            size: .percentage(width: 0.38, height: 0.52),
                            isModal: false
                        )
                    } label: {
                        Label("Exportar a Agenda", systemImage: "calendar.badge.plus")
                    }
                    #else
                    NavigationLink {
                        let draft = AgendaInterchangeService.makeAgendaDraft(
                            title: nota?.title ?? "",
                            content: noteActionText
                        )
                        AgendaEditorView(baseItem: draft) { items in
                            AgendaInterchangeService.saveAgendaItems(items)
                        }
                    } label: {
                        Label("Exportar a Agenda", systemImage: "calendar.badge.plus")
                    }
                    #endif
                    
                    #if os(macOS)
                    Button{
                        showWindow(for: LienzoMain(texto: noteActionText, imagenPrimariaACargar: nil),
                                   environmentObjects: [],
                                   title: "Lienzo",
                                   size: .absolute(CGSize(width: 650, height: 750)),
                                   isModal: false
                        )
                        
                    }label:{
                        Label("Lienzo", systemImage: "heart.text.square")
                    }
                    
                    #else
                    NavigationLink{
                        LienzoMain(texto: noteActionText, imagenPrimariaACargar: nil)
                    }label:{
                        Label("Lienzo", systemImage: "heart.text.square")
                    }
                    #endif
                    
                    
                    #if os(macOS)
                    
                    Button{
                        showWindow(for: ReminderEditorView(reminderAEditar: nil, titleAImportar: self.nota?.title, textoAImportar: noteActionText, onSave: {}),
                                   environmentObjects: [],
                                   title: "Lienzo",
                                   size: .absolute(CGSize(width: 650, height: 750)),
                                   isModal: false)
                    }label:{
                        Label("Recordatorios", systemImage: "heart.text.square")
                    }
                    
                    #else
                    
                    NavigationLink{
                        ReminderEditorView(reminderAEditar: nil, titleAImportar: self.nota?.title, textoAImportar: noteActionText, onSave: {})
                    }label:{
                        Label("Recordatorios", systemImage: "heart.text.square")
                    }
                    
                    #endif
                    
                    
                    
                    Button{
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(noteActionText, forType: .string)
                        #else
                        UIPasteboard.general.string = noteActionText
                        #endif
                        
                    }label:{
                        Label("Copiar Nota...", systemImage: "square.fill.on.square.fill")
                    }
                    
                    
                    ShareLink(item: "\(nota!.title ?? "")\n \(noteActionText)")
                    
                    //Funciones de inteligencia: IA
                    if #available(iOS 26.0, macOS 26.0, *) {
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            #if os(macOS)
                            Button{
                                let temp = noteActionText
                                if !temp.isEmpty {
                                    showWindow(for: RespondView(nameConference: "", texto: temp, tipoSalida: .interpretar, autorRespuesta: "nev" ),
                                    environmentObjects: [],
                                               title: "Interpretar Nota",
                                               size: AppCons.windows_size_content,
                                               isModal: true
                                    )
                                    
                                }
                                

                            }label:{
                                Label("Interpretar", systemImage: "sparkles")
                            }
                            .tint(.purple)
                            
                            Button{
                                let temp = noteActionText
                                if !temp.isEmpty {
                                    showWindow(for: RespondView(nameConference: "", texto: temp, tipoSalida: .practicaConcreta, autorRespuesta: "nev"),
                                    environmentObjects: [],
                                               title: "Aplicación Práctica - Nota",
                                               size: AppCons.windows_size_content,
                                               isModal: true
                                    )
                                    
                                }
                                
                            }label:{
                                Label("Aplicación Práctica", systemImage: "sparkles")
                            }
                            .tint(.purple)
                    
                    Button{
                        let temp = noteActionText
                        if !temp.isEmpty {
                            showWindow(for:   ChatView(textoACargar: temp),
                            environmentObjects: [],
                                       title: "Charlar - Notas",
                                       size: AppCons.windows_size_content,
                                       isModal: false
                            )
                        }
                    }label: {
                        Label("Charlar con IA", systemImage: "sparkles")
                    }
                    .tint(.purple)
                            
                            #else
                            Menu{
                                NavigationLink{
                                    let temp = noteActionText
                                    if !temp.isEmpty {
                                        RespondView(nameConference: "", texto: temp, tipoSalida: .interpretar, autorRespuesta: "nev" )
                                    }
                                    
                                    
                                }label:{
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    let temp = noteActionText
                                    if !temp.isEmpty {
                                        RespondView(nameConference: "", texto: temp, tipoSalida: .practicaConcreta, autorRespuesta: "nev")
                                    }
                                    
                                }label:{
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    ChatView(textoACargar: noteActionText)
                                }label: {
                                    Label("Charlar con IA", systemImage: "sparkles")
                                }
                                .tint(.purple)
                            }label:{
                                Label("Funciones IA", systemImage: "sparkles")
                            }
                           
                    #endif
 
                        }
                    }
                    
                    Button{
                        showConfirmDialogDeleteNota = true
                    }label:{
                        Label("Eliminar nota...", systemImage: "trash")
                    }
                    .tint(.red)
   
                }label: {
                    Image(systemName: "ellipsis")
                        .tint(.black)
                        .padding(15)
                }
                }

            }
            if !formattedMetadata(for: nota).isEmpty {
                HStack {
                    Text(formattedMetadata(for: nota))
                        .font(.caption2)
                        .foregroundStyle(.black.opacity(0.75))
                        .padding(.horizontal, 8)
                    Spacer()
                }
            }
            if expandNota {
                VStack(alignment: .leading, spacing: 0) {
                    if nota?.isChecklistNote == true {
                        checklistPreview
                    } else {
                        #if os(macOS)
                        Text(noteActionText)
                            .font(.system(size: 20))
                            .fontDesign(.serif)
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 5)
                            .background {
                                LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            }
                        #else
                        SelectableText(text: noteActionText)
                            .font(.system(size: 20))
                            .fontDesign(.serif)
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 5)
                            .background {
                                LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            }
                        #endif
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !selectionMode else {
                onSelectionToggle()
                return
            }
            withAnimation {
                expandNota.toggle()
            }
            
        }
        .onAppear{
            isfav = nota!.isfav
        }
        //Dialogo de confirmación para elimnar una nota
        .confirmationDialog("Esta seguro?", isPresented: $showConfirmDialogDeleteNota){
            Button("Eliminar Nota", role: .destructive){
                
                withAnimation {
                    modelNotas.deleteNota(nota: nota!)
                    self.modelNotas.getAllNotasToModel()
                }

            }
        } message: {
            Text("La nota será removida!!!")
        }
        .alert("Espacio Calma", isPresented: $showCalmAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(calmAlertMessage)
        }
        .alert("Mapas", isPresented: $showMapsAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(mapsAlertMessage)
        }
        .alert("Cambiar categoría", isPresented: $showCategoryAlert) {
            TextField("Categoría", text: $categoryDraft, axis: .vertical)
            Button("Cancelar", role: .cancel) {}
            Button("Actualizar") {
                updateCurrentNoteCategory(categoryDraft)
            }
        } message: {
            Text("Se actualizará esta nota.")
        }
        .frame(maxWidth: .infinity)
        //.background(.ultraThinMaterial)
        .background(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var checklistPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(nota?.checklistItems ?? []) { item in
                Button {
                    toggleChecklistItem(item)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.isChecked ? .green : .black.opacity(0.7))
                        Text(item.text)
                            .font(.system(size: 20))
                            .fontDesign(.serif)
                            .foregroundStyle(.black)
                            .strikethrough(item.isChecked, color: .black.opacity(0.45))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        }
    }

    private func toggleChecklistItem(_ item: NotaChecklistItem) {
        guard let nota, let id = nota.id else { return }
        var items = nota.checklistItems
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isChecked.toggle()
        let noteText = NotaChecklistItem.renderPlainText(items)
        nota.nota = noteText
        if modelNotas.updateChecklistItems(NotaID: id, checklistItems: items) {
            modelNotas.getAllNotasToModel()
        }
    }

    private func convertCurrentNoteType() {
        guard let nota, let id = nota.id else { return }
        let isCurrentlyChecklist = nota.isChecklistNote
        let items = isCurrentlyChecklist ? [] : NotaChecklistItem.fromText(noteActionText)
        let convertedText = isCurrentlyChecklist
            ? noteActionText
            : NotaChecklistItem.renderPlainText(items)

        if modelNotas.updateNota(
            NotaID: id,
            newTitle: nota.title ?? "",
            newNota: convertedText,
            isfav: nota.isfav,
            direccionMapa: nota.value(forKey: "direccionMapa") as? String ?? "",
            categoria: nota.value(forKey: "categoria") as? String ?? "",
            isChecklist: !isCurrentlyChecklist,
            checklistItems: items
        ) {
            modelNotas.getAllNotasToModel()
            withAnimation {
                expandNota = true
            }
        } else {
            mapsAlertMessage = L10n.exact("No se pudo convertir la nota.")
            showMapsAlert = true
        }
    }

    private func updateCurrentNoteCategory(_ category: String) {
        guard let nota else { return }
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        if modelNotas.updateNota(
            NotaID: nota.id ?? "",
            newTitle: nota.title ?? "",
            newNota: nota.nota ?? "",
            isfav: nota.isfav,
            direccionMapa: nota.value(forKey: "direccionMapa") as? String ?? "",
            categoria: trimmedCategory
        ) {
            modelNotas.getAllNotasToModel()
        } else {
            mapsAlertMessage = L10n.exact("No se pudo cambiar la categoría.")
            showMapsAlert = true
        }
    }

    private func addCurrentNoteToCalmList() {
        let text = noteActionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            self.calmAlertMessage = L10n.exact("La nota está vacía.")
            self.showCalmAlert = true
            return
        }

        let context = CoreDataController.shared.context
        guard let model = context.persistentStoreCoordinator?.managedObjectModel,
              model.entitiesByName["CalmUserPhrase"] != nil,
              let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else {
            self.calmAlertMessage = L10n.exact("No se encontró la entidad de frases de Espacio Calma.")
            self.showCalmAlert = true
            return
        }

        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(text, forKey: "phrase")
        object.setValue(Date(), forKey: "createdAt")

        do {
            try context.save()
            self.calmAlertMessage = L10n.exact("Frase agregada a Espacio Calma.")
        } catch {
            context.rollback()
            self.calmAlertMessage = L10n.exact("No se pudo guardar la frase en Espacio Calma.")
        }

        self.showCalmAlert = true
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
}

private struct ListNotasPreviewHost: View {
    var body: some View {
        ListNotasViews()
    }
}

#Preview("Notas") {
    ListNotasPreviewHost()
}
