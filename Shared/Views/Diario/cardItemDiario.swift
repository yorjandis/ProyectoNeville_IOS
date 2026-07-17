//
//  cardItem.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/11/25.
//


import SwiftUI
import CoreData
import MapKit

struct cardItemDiario: View{
    @Environment(\.colorScheme) var theme
    
    @State var diario : Diario //Entrada a mostrar
    var onEntryDeleted: (Date?) -> Void = { _ in }
    var onEntryUpdated: (Date?) -> Void = { _ in }
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onSelectionToggle: () -> Void = {}
    
    @StateObject private var diarioModel = DiarioModel.shared
    
    @State private var expandText = false //Permite expandir/contraer el texto de una entrada
    @State private var isEditing = false
    @State private var textfield = ""
    //Alert: Modificar titulo
    @State private var showAlert = false
    @State private var title = ""
    //Alert Eliminar Entrada
    @State private var showAlertDeleteEntry = false
    @State private var showInterchangeAlert = false
    @State private var interchangeAlertMessage = ""
    @State private var showMapsAlert = false
    @State private var mapsAlertMessage = ""
    @State private var agendaDraftToExport: AgendaItemData?
    @State private var showChapterAlert = false
    @State private var chapterDraft = ""
    //Edit Content
    @State private var showSheet = false
    //favorito
    @State private var isfav : Bool = false
    // El pie de la tarjeta comienza contraído para priorizar el contenido de la entrada.
    @State private var isFooterExpanded = false
    //Animation
    @State private var animValue = 0
    

    var body: some View{
        VStack(spacing: 20){
            diaryHeader
            diaryEntryContent
            if isFooterExpanded {
                diaryFooter
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !isFooterExpanded {
                footerVisibilityButton(isFloating: true)
                    // Compensa el área táctil ampliada para mantener el icono en la misma posición visual.
                    .offset(x: 21, y: 26)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onSelectionToggle()
            }
        }

        .alert("Modificar Título", isPresented: $showAlert){
            TextField("Nuevo título", text: $title)
                .foregroundStyle(theme == .dark ? .white : .black)
            Button("Cancelar"){
                showAlert = false
            }
            Button("Guardar"){
                diarioModel.UpdateTitle(title: title, diario: diario)
                onEntryUpdated(diario.fecha)
            }
            
        }
        .alert("¿Desea eliminar la entrada? \n Esta acción no puede deshacerse", isPresented: $showAlertDeleteEntry, actions: {
            Button("Eliminar", role: .destructive){
                withAnimation {
                    let deletedDate = diario.fecha
                    diarioModel.DeleteItem(diario: diario)
                    onEntryDeleted(deletedDate)
                }
            }
        })
        .alert("Diario", isPresented: $showInterchangeAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(interchangeAlertMessage)
        }
        .alert("Mapas", isPresented: $showMapsAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(mapsAlertMessage)
        }
        .alert("Asignar capítulo", isPresented: $showChapterAlert) {
            TextField("Capítulo", text: $chapterDraft, axis: .vertical)
            Button("Cancelar", role: .cancel) {}
            Button("Actualizar") {
                updateChapter(chapterDraft)
            }
        } message: {
            Text("Se actualizará esta entrada del Diario.")
        }
        .sheet(isPresented: $showSheet){
            diaryEntryEditor
        }
#if os(iOS)
        .sheet(item: $agendaDraftToExport) { draft in
            AgendaEditorView(baseItem: draft, forceDarkTheme: true) { items in
                AgendaInterchangeService.saveAgendaItems(items)
            }
            .preferredColorScheme(.dark)
            .tint(.white)
            .background(Color.black)
        }
#endif
        
    }

    private var diaryHeader: some View {
        HStack {
            if isSelectionMode {
                selectionButton
            }
            emotionMenu
            diaryTitle
            Spacer()
        }
    }

    private var selectionButton: some View {
        Button(action: onSelectionToggle) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 26))
                .foregroundStyle(isSelected ? Color.orange : Color.black.opacity(0.65))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var emotionMenu: some View {
        Menu {
            ForEach(Emociones.allCases, id: \.self) { emotion in
                Button {
                    updateEmotion(emotion)
                } label: {
                    HStack {
                        Text(emotion.localizedTitle)
                        Text(emotion.emoji)
                    }
                }
            }
        } label: {
            Text(Emociones.emoji(from: diario.emotion))
                .font(.system(size: 40))
        }
        .disabled(isSelectionMode)
    }

    private var diaryTitle: some View {
        Text(diario.title ?? "")
            .font(.headline.bold())
            .onTapGesture(count: 2) {
                presentTitleEditor()
            }
    }

    private var diaryFooter: some View {
        VStack {
            Divider()
            HStack {
                diaryMetadata
                Spacer()
                favoriteButton
                entryActionsMenu
                footerVisibilityButton()
                    .padding(.leading, 6)
            }
        }
    }

    private var diaryMetadata: some View {
        VStack {
            if !chapterName.isEmpty {
                HStack {
                    Text("Capítulo:")
                        .font(.system(size: 10))
                    Text(chapterName)
                        .font(.caption2.bold())
                        .lineLimit(1)
                }
            }
            HStack {
                Text("Modificado:")
                    .font(.system(size: 10))
                Text(diario.fechaM ?? Date.now, style: .date)
                    .font(.caption2.bold())
                Text(diario.fechaM ?? Date.now, style: .time)
                    .font(.caption2.bold())
            }
            HStack {
                Text("       Creado:")
                    .font(.system(size: 10))
                Text(diario.fecha ?? Date.now, style: .date)
                    .font(.caption2.bold())
                Text(diario.fecha ?? Date.now, style: .time)
                    .font(.caption2.bold())
            }
        }
    }

    private var favoriteButton: some View {
        Button {
            toggleFavorite()
        } label: {
            Image(systemName: isfav ? "heart.fill" : "heart")
                .foregroundStyle(.black)
                .padding(.trailing, 10)
                .symbolEffect(.bounce, value: animValue)
        }
        .buttonStyle(.plain)
        .disabled(isSelectionMode)
        .onAppear {
            isfav = diario.isFav
        }
    }

    private var entryActionsMenu: some View {
        Menu {
            Button {
                presentDiaryEntryEditor(isModal: true)
            } label: {
                Label("Editar", systemImage: "pencil")
            }

            chapterAssignmentMenu

            Button(role: .destructive) {
                showAlertDeleteEntry = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }

            if !mapAddress.isEmpty {
                Button {
                    openInMaps(address: mapAddress)
                } label: {
                    Label("Abrir en Mapas", systemImage: "map")
                }
            }

            Button {
                exportEntryToAgenda()
            } label: {
                Label("Exportar a Agenda", systemImage: "calendar.badge.plus")
            }
        } label: {
            entryActionsMenuLabel
        }
        .buttonStyle(.plain)
        .disabled(isSelectionMode)
    }

    private var chapterAssignmentMenu: some View {
        Menu {
            Button("Sin capítulo") {
                updateChapter("")
            }
            ForEach(availableChaptersForCurrentEntry, id: \.self) { chapter in
                Button(chapter) {
                    updateChapter(chapter)
                }
            }
            Button("Nuevo...") {
                chapterDraft = ""
                showChapterAlert = true
            }
        } label: {
            Label("Capítulo", systemImage: "book.closed")
        }
    }

    private var mapAddress: String {
        (diario.value(forKey: "direccionMapa") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateEmotion(_ emotion: Emociones) {
        diarioModel.UpdateEmoticono(emoticono: emotion, diario: diario)
        withAnimation {
            diarioModel.getAllItem()
        }
    }

    private func presentTitleEditor() {
        guard !isSelectionMode else { return }
        title = diario.title ?? ""
#if os(macOS)
        showWindow(
            for: titleEditorContent,
            environmentObjects: [diarioModel],
            title: "Editar Entrada Diario",
            size: AppCons.windows_size_content_small,
            isModal: true
        )
#else
        showAlert = true
#endif
    }

#if os(macOS)
    private var titleEditorContent: some View {
        VStack {
            TextField("Nuevo título", text: $title)
                .foregroundStyle(theme == .dark ? .white : .black)
            Button("Cancelar") {
                closeKeyWindow()
            }
            Button("Guardar") {
                diarioModel.UpdateTitle(title: title, diario: diario)
                onEntryUpdated(diario.fecha)
                closeKeyWindow()
            }
        }
        .padding(10)
    }

    private func closeKeyWindow() {
        if let window = NSApp.keyWindow {
            closeWindow(window)
        }
    }
#endif

    private func toggleFavorite() {
        guard !isSelectionMode else { return }
        isfav.toggle()
        diarioModel.UpdateFav(isFav: isfav, diario: diario)
        animValue += 1
#if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
    }

    private func exportEntryToAgenda() {
        let draft = AgendaInterchangeService.makeAgendaDraft(
            title: diario.title ?? "Entrada Diario",
            content: diario.content ?? "",
            activityDate: diario.fecha ?? Date()
        )
#if os(macOS)
        showWindow(
            for: agendaEditor(for: draft),
            environmentObjects: [],
            title: "Exportar a Agenda",
            size: .percentage(width: 0.38, height: 0.52),
            isModal: false
        )
#else
        agendaDraftToExport = draft
#endif
    }

#if os(macOS)
    private func agendaEditor(for draft: AgendaItemData) -> some View {
        AgendaEditorView(baseItem: draft, forceDarkTheme: true) { items in
            AgendaInterchangeService.saveAgendaItems(items)
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .background(Color.black)
    }
#endif

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

    private var chapterName: String {
        (diario.value(forKey: "capitulo") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var diaryEntryContent: some View {
        Text(diario.content ?? "")
            .font(.system(size: 18))
            .foregroundStyle(.black)
            .italic()
            .fontDesign(.serif)
            .fontWeight(.heavy)
            .lineLimit(isContentExpanded ? nil : 1)
            .onTapGesture {
                guard !isSelectionMode else {
                    onSelectionToggle()
                    return
                }
                toggleContentExpansion()
            }
            .onTapGesture(count: 2) {
                guard !isSelectionMode else { return }
                presentDiaryEntryEditor()
            }
    }

    private var diaryEntryEditor: some View {
        let mapAddress = diario.value(forKey: "direccionMapa") as? String ?? ""
        let chapter = diario.value(forKey: "capitulo") as? String ?? ""
        let emotion = diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral")

        return editContent(
            diario: $diario,
            textTitle: diario.title ?? "",
            textContent: diario.content ?? "",
            direccionMapa: mapAddress,
            capitulo: chapter,
            emoticono: emotion,
            onEntryUpdated: onEntryUpdated
        )
    }

    private func presentDiaryEntryEditor(isModal: Bool = false) {
#if os(macOS)
        showWindow(
            for: diaryEntryEditor,
            environmentObjects: [diarioModel],
            title: "Editar entrada Diario",
            size: AppCons.windows_size_content,
            isModal: isModal
        )
#else
        showSheet = true
#endif
    }

    private var entryExpansionIdentifier: String {
        diario.fecha?.formatted() ?? ""
    }

    private var isContentExpanded: Bool {
        diarioModel.expandirEntrada == entryExpansionIdentifier
    }

    private func toggleContentExpansion() {
        withAnimation {
            diarioModel.expandirEntrada = isContentExpanded ? "" : entryExpansionIdentifier
        }
    }

    private func footerVisibilityButton(isFloating: Bool = false) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isFooterExpanded.toggle()
            }
        } label: {
            Image(systemName: isFooterExpanded ? "chevron.up.circle" : "chevron.down.circle")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.45))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .frame(width: isFloating ? 44 : 22, height: isFloating ? 44 : 22)
        .contentShape(Rectangle())
        .disabled(isSelectionMode)
        .accessibilityLabel(isFooterExpanded ? "Ocultar detalles de la entrada" : "Mostrar detalles de la entrada")
        .help(isFooterExpanded ? "Ocultar detalles" : "Mostrar detalles")
    }

    private var entryActionsMenuLabel: some View {
        Image(systemName: "ellipsis")
            .tint(.black)
            .frame(width: 25, height: 25)
            .contentShape(Rectangle())
    }

    private var existingChapters: [String] {
        Array(Set(diarioModel.getAllItemGET().compactMap { item in
            let value = (item.value(forKey: "capitulo") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var availableChaptersForCurrentEntry: [String] {
        existingChapters.filter {
            $0.localizedCaseInsensitiveCompare(chapterName) != .orderedSame
        }
    }

    private func updateChapter(_ chapter: String) {
        guard let id = diario.id else { return }
        diarioModel.UpdateCapitulo(capitulo: chapter, ids: [id])
        diario.setValue(chapter.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "capitulo")
        onEntryUpdated(diario.fecha)
    }
}
