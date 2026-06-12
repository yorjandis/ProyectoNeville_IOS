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

    @Environment(\.dismiss) var dimiss
    
    @StateObject private var modelNotas = NotasModel()
    
    @State private var showAddNoteView = false
    //@State private var list : [Notas]  = []
    //Buscar en notas
    @State var showAlertSearch = false
    @State var textField = ""
    //Buscar en titulos de notas
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
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    
    
    
    private var filtered : [Notas] {
        if self.textFieldTitle.isEmpty {return self.modelNotas.notas}
        return self.modelNotas.notas.filter{$0.title?.localizedCaseInsensitiveContains(self.textFieldTitle) ?? false}
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
 
    var body: some View {
        NavigationStack {
            ZStack{
                
                
                
                LinearGradient(colors: GradientesPreselect.G_natural_3.getColors,
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack{
                    if ( canOpenNotas == true  ||   UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false) {
                        ScrollView(.vertical){
                            
                            ForEach (self.orderedFiltered){ nota in
                                cardNotas(
                                    nota: nota,
                                    selectionMode: self.selectionMode,
                                    isSelected: self.selectedNotaIDs.contains(nota.id ?? ""),
                                    onSelectionToggle: { toggleSelection(for: nota) }
                                )
                                    .environmentObject(self.modelNotas)
                            }
                            #if os(macOS)
                            .searchable(text: $textFieldTitle, prompt: "Buscar")
                            #else
                            .searchable(text: $textFieldTitle, placement: .navigationBarDrawer(displayMode: .always)  , prompt:"Buscar")
                            #endif
                            
                            .task {
                                self.modelNotas.getAllNotasToModel()
                            }
                        }
                    }else{
                       
                            Spacer()
                                   autenticationView()
                    }
                        

                            Spacer()
                            if selectionMode && canAccessNotasContent {
                                bulkActionsBar()
                            }
                           
                            Divider()
                            HStack(spacing: 30){
                                Spacer()
                                #if os(iOS)
                                Button("Volver"){
                                    dimiss()
                                }
                                .foregroundStyle(.black)
                                .buttonStyle(.bordered)
                                .padding(.trailing, 20)
                                #endif
                            }
                        
                            .padding(.bottom, 20)
                }
                
                
            }
                .navigationTitle("Notas")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar{
                    
                    //Chequea si esta habilitado la protección de las notas
                    if UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false { //No esta habilitada la protección
                       
                        ToolbarItem {
                            Menu{
                                Button{
                                    withAnimation {
                                        self.modelNotas.getAllNotasToModel()
                                    }
                                }label:{
                                    Label("Todas las notas", systemImage: "text.magnifyingglass.rtl")
                                }
                                
                                Button{
                                    withAnimation {
                                        modelNotas.notas = NotasModel().getFavNotas()
                                    }
                                    
                                }label:{
                                    Label("Notas Favoritas", systemImage: "text.magnifyingglass.rtl")
                                }

                                Button {
                                    withAnimation {
                                        selectedSortOption = .creationDate
                                    }
                                } label: {
                                    Label(
                                        "Por fecha de Creación",
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
                                
                                Button{
                                    showAlertSearch = true
                                }label:{
                                    Label("Buscar en Notas", systemImage: "text.magnifyingglass.rtl")
                                }

                            }label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }
                        
                        if #available(iOS 26.0, macOS 26.0, *) {
                            ToolbarSpacer(.fixed)
                        }
                        
                        ToolbarItem {
                            exportNotasPDFToolbarMenu()
                        }
                        
                        if #available(iOS 26.0, macOS 26.0, *) {
                            ToolbarSpacer(.fixed)
                        }
                        
                        ToolbarItem {
                            Button{
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
                                
                            }label: {
                                Image(systemName: "plus")
                            }
                        }

                        if #available(iOS 26.0, macOS 26.0, *) {
                            ToolbarSpacer(.fixed)
                        }
                        
                        ToolbarItem {
                            
                            Menu{
                                Button(selectionMode ? "Cancelar" : "Seleccionar") {
                                    withAnimation {
                                        selectionMode.toggle()
                                        if !selectionMode {
                                            selectedNotaIDs.removeAll()
                                        }
                                    }
                                }
                            }label: {
                                Image(systemName: "list.dash")
                            }
                            
                            
                        }
                        
                        
                    }else{ //Si esta habilitada la protección de las notas
                        
                        //Chequear si se tiene acceso al contenido
                        if self.canOpenNotas {
                            
                            ToolbarItem {
                                Menu{
                                    Button("Todas las notas"){
                                        withAnimation {
                                            self.modelNotas.getAllNotasToModel()
                                        }
                                    }
                                    Button("Notas Favoritas"){
                                        withAnimation {
                                            
                                            self.modelNotas.notas = self.modelNotas.getFavNotas()
                                        }
                                        
                                    }
                                    Button {
                                        withAnimation {
                                            selectedSortOption = .creationDate
                                        }
                                    } label: {
                                        Label(
                                            "Por fecha de Creación",
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
                                    Button("Buscar en Notas"){
                                        showAlertSearch = true
                                    }
                                    
                                }label: {
                                    Image(systemName: "line.3.horizontal.decrease")
                                }
                            }
                            
                            if #available(iOS 26.0, macOS 26.0, *) {
                                ToolbarSpacer(.fixed)
                            }
                            
                            ToolbarItem {
                                exportNotasPDFToolbarMenu()
                            }

                            ToolbarItem {
                                Button{
                                    guard !selectionMode else { return }
                                    #if os(macOS)
                                    
                                    showWindow(for: AddNotasView(),
                                               environmentObjects: [self.modelNotas],
                                               title: "Crear Nota",
                                               size: AppCons.windows_size_content_small,
                                               isModal: false
                                    )
                                    
                                    #else
                                    showAddNoteView = true
                                    #endif
                                }label: {
                                    Image(systemName: "plus")
                                }
                            }

                            ToolbarItem {
                                Button(selectionMode ? "Cancelar" : "Seleccionar") {
                                    withAnimation {
                                        selectionMode.toggle()
                                        if !selectionMode {
                                            selectedNotaIDs.removeAll()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    
                    
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
                .confirmationDialog("¿Eliminar notas seleccionadas?", isPresented: $showConfirmBulkDelete) {
                    Button("Eliminar \(selectedNotaIDs.count) nota(s)", role: .destructive) {
                        applyDeleteToSelected()
                    }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Esta acción no se puede deshacer.")
                }
                
            
        }
        

    }
    
   
    //Actualiza una nota
    func updateYorj(nota : Notas){
        
        if  self.modelNotas.updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
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
                Button(selectedNotaIDs.count == filtered.count && !filtered.isEmpty ? "Deseleccionar Todas" : "Seleccionar Todas") {
                    withAnimation {
                        toggleSelectAllFiltered()
                    }
                }
                .foregroundStyle(.black).bold()
                .tint(.gray)
                .buttonStyle(.bordered)
            }

            HStack(spacing: 8) {
                Button("Eliminar") {
                    showConfirmBulkDelete = true
                }
                .foregroundStyle(.black).bold()
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(selectedNotaIDs.isEmpty)

                Button("A Frases") {
                    applyPassToFrases()
                }
                .foregroundStyle(.black).bold()
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(selectedNotaIDs.isEmpty)

                Button("A Espacio Calma") {
                    applyPassToCalm()
                }
                .foregroundStyle(.black).bold()
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(selectedNotaIDs.isEmpty)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private func toggleSelection(for nota: Notas) {
        guard selectionMode, let id = nota.id else { return }
        if selectedNotaIDs.contains(id) {
            selectedNotaIDs.remove(id)
        } else {
            selectedNotaIDs.insert(id)
        }
    }

    private func toggleSelectAllFiltered() {
        let allFilteredIDs = Set(filtered.compactMap { $0.id })
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
        alertMessage = "\(toDelete.count) nota(s) eliminada(s)."
        showAlert = true
    }

    private func applyPassToFrases() {
        var inserted = 0
        for nota in selectedNotas {
            let text = (nota.nota ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            if FrasesModel.shared.AddFrase(frase: text, autor: "personal") {
                inserted += 1
            }
        }
        selectedNotaIDs.removeAll()
        selectionMode = false
        alertMessage = "\(inserted) nota(s) pasada(s) a Frases personales."
        showAlert = true
    }

    private func applyPassToCalm() {
        let context = CoreDataController.shared.context
        guard let model = context.persistentStoreCoordinator?.managedObjectModel,
              model.entitiesByName["CalmUserPhrase"] != nil,
              let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else {
            alertMessage = "No se encontró la entidad de frases de Espacio Calma."
            showAlert = true
            return
        }

        var inserted = 0
        for nota in selectedNotas {
            let text = (nota.nota ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
            alertMessage = "\(inserted) nota(s) pasada(s) a Espacio Calma."
        } catch {
            context.rollback()
            alertMessage = "No se pudo guardar en Espacio Calma."
        }
        showAlert = true
    }

    @ViewBuilder
    private func exportNotasPDFMenu() -> some View {
        Menu {
            Text("Exportar a PDF")
                .font(.caption)
            Button("Manual (seleccionadas)") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                if !selectionMode {
                    withAnimation {
                        selectionMode = true
                    }
                    alertMessage = "Selecciona las notas y vuelve a pulsar 'Manual (seleccionadas)' para exportar."
                    showAlert = true
                    return
                }
                exportNotasToPDF(selectedNotas, scopeName: "Manual")
            }
            Button("Semana actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                exportNotasToPDF(notasCurrentWeek(), scopeName: "Semana")
            }
            Button("Mes actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                exportNotasToPDF(notasCurrentMonth(), scopeName: "Mes")
            }
            Button("Rango de fechas") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                showExportRangeSheet = true
            }
        } label: {
            Label("Exportar PDF", systemImage: "doc.richtext")
        }
    }

    @ViewBuilder
    private func exportNotasPDFToolbarMenu() -> some View {
        exportNotasPDFMenu()
            .labelStyle(.iconOnly)
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

    private func exportNotasToPDF(_ notas: [Notas], scopeName: String) {
        guard hasPremiumPDFAccess else {
            alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
            showAlert = true
            return
        }
        guard !notas.isEmpty else {
            alertMessage = "No hay notas para exportar en \(scopeName.lowercased())."
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
                let detail = (nota.nota ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return PDFExportLine(title: title, detail: detail.isEmpty ? nil : detail)
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
            alertMessage = "No se pudo generar el PDF."
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
    
    @AppStorage(AppCons.UD_setting_fontListaSize)  var fontSizeLista : Int = 20

    private static let metadataDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func formattedMetadata(for nota: Notas?) -> String {
        guard let nota else { return "" }
        let createdRaw = nota.value(forKey: "fechaCreacion") as? Date
        let modifiedRaw = nota.value(forKey: "fechaModificacion") as? Date
        let created = createdRaw ?? modifiedRaw
        let modified = modifiedRaw ?? createdRaw

        if created == nil, modified == nil {
            return ""
        }

        var parts: [String] = []
        if let created {
            parts.append("Creada: \(Self.metadataDateFormatter.string(from: created))")
        }
        if let modified {
            parts.append("Modificada: \(Self.metadataDateFormatter.string(from: modified))")
        }
        return parts.joined(separator: " · ")
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
                                nota: nota!.nota!,
                                direccionMapa: nota?.value(forKey: "direccionMapa") as? String ?? ""
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
                                nota: nota!.nota!,
                                direccionMapa: nota?.value(forKey: "direccionMapa") as? String ?? ""
                            )
                                .environmentObject(self.modelNotas)
                        }
                          
                    }
                        label:{
                        Label("Editar...", systemImage: "highlighter.badge.ellipsis")
                    }
                    
                    #endif
                    
                    
                    
                    
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
                        let texto = "\(AppCons.zspNota)\(nota!.title ?? "")::\(nota!.nota ?? "")::\(isfav == true  ? "si" : "no")"
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
                            content: nota?.nota ?? ""
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
                            content: nota?.nota ?? ""
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
                        showWindow(for: LienzoMain(texto: nota?.nota ?? "", imagenPrimariaACargar: nil),
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
                        LienzoMain(texto: nota?.nota ?? "", imagenPrimariaACargar: nil)
                    }label:{
                        Label("Lienzo", systemImage: "heart.text.square")
                    }
                    #endif
                    
                    
                    #if os(macOS)
                    
                    Button{
                        showWindow(for: ReminderEditorView(reminderAEditar: nil, titleAImportar: self.nota?.title, textoAImportar: self.nota?.nota, onSave: {}),
                                   environmentObjects: [],
                                   title: "Lienzo",
                                   size: .absolute(CGSize(width: 650, height: 750)),
                                   isModal: false)
                    }label:{
                        Label("Recordatorios", systemImage: "heart.text.square")
                    }
                    
                    #else
                    
                    NavigationLink{
                        ReminderEditorView(reminderAEditar: nil, titleAImportar: self.nota?.title, textoAImportar: nota?.nota, onSave: {})
                    }label:{
                        Label("Recordatorios", systemImage: "heart.text.square")
                    }
                    
                    #endif
                    
                    
                    
                    Button{
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(nota?.nota ?? "", forType: .string)
                        #else
                        UIPasteboard.general.string = nota?.nota ?? ""
                        #endif
                        
                    }label:{
                        Label("Copiar Nota...", systemImage: "square.fill.on.square.fill")
                    }
                    
                    
                    ShareLink(item: "\(nota!.title ?? "")\n \(nota!.nota ?? "")")
                    
                    //Funciones de inteligencia: IA
                    if #available(iOS 26.0, macOS 26.0, *) {
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            #if os(macOS)
                            Button{
                                if let  temp = nota!.nota{
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
                                if let  temp = nota!.nota{
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
                        if let  temp = nota!.nota{
                            showWindow(for:   ChatView(textoACargar: nota!.nota),
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
                                    if let  temp = nota!.nota{
                                        RespondView(nameConference: "", texto: temp, tipoSalida: .interpretar, autorRespuesta: "nev" )
                                    }
                                    
                                    
                                }label:{
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    if let  temp = nota!.nota{
                                        RespondView(nameConference: "", texto: temp, tipoSalida: .practicaConcreta, autorRespuesta: "nev")
                                    }
                                    
                                }label:{
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    ChatView(textoACargar: nota!.nota)
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
                    #if os(macOS)
                    Text(nota!.nota ?? "")
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
                    SelectableText(text: nota!.nota ?? "")
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
        .frame(maxWidth: .infinity)
        //.background(.ultraThinMaterial)
        .background(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func addCurrentNoteToCalmList() {
        guard let text = nota?.nota?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            self.calmAlertMessage = "La nota está vacía."
            self.showCalmAlert = true
            return
        }

        let context = CoreDataController.shared.context
        guard let model = context.persistentStoreCoordinator?.managedObjectModel,
              model.entitiesByName["CalmUserPhrase"] != nil,
              let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else {
            self.calmAlertMessage = "No se encontró la entidad de frases de Espacio Calma."
            self.showCalmAlert = true
            return
        }

        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(text, forKey: "phrase")
        object.setValue(Date(), forKey: "createdAt")

        do {
            try context.save()
            self.calmAlertMessage = "Frase agregada a Espacio Calma."
        } catch {
            context.rollback()
            self.calmAlertMessage = "No se pudo guardar la frase en Espacio Calma."
        }

        self.showCalmAlert = true
    }

    private func openInMaps(address: String) {
        let cleaned = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            mapsAlertMessage = "La ubicación está vacía."
            showMapsAlert = true
            return
        }

        Task { @MainActor in
            let didOpen = await LocationMapOpener.open(cleaned)
            if !didOpen {
                mapsAlertMessage = "No se pudo abrir Mapas para esta ubicación."
                showMapsAlert = true
            }
        }
    }
}
