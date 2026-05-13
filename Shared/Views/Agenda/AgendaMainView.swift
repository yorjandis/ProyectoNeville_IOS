import SwiftUI

enum AgendaUIConstants {
    static let calendarBackgroundOpacity: Double = 0.5
    static let activityCardBackgroundOpacity: Double = 0.5
    static let priorityBackgroundOpacity: Double = 0.7
}

struct AgendaMainView: View {
    @StateObject private var viewModel = AgendaViewModel()
    @State private var editorItem: AgendaItemData?
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
    @State private var multiSelectionMode = false
    @State private var selectedItemsIDs: Set<UUID> = []

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    var body: some View {
        NavigationStack {
            if purchaseStatus || yorjPremium {
                ZStack {
                    LinearGradient(
                       
                        colors: [
                            /*
                             Color(red: 0.84, green: 0.94, blue: 0.82),
                             Color(red: 0.73, green: 0.88, blue: 0.74)
                             */
                            .blue.opacity(6),
                            .blue.opacity(2),
                            
                             
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 12) {
                        if multiSelectionMode {
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

                        Picker("Filtro", selection: $viewModel.quickFilter) {
                            ForEach(AgendaViewModel.QuickFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color(red: 0.95, green: 0.67, blue: 0.37))
                        .colorScheme(.light)
                        .foregroundStyle(.black)
                        .padding(.top, 4)

                        HStack(spacing: 10) {
                            Spacer()
                            
                            Text("Calendario")
                                .font(.subheadline)
                                .foregroundStyle(.black.opacity(0.75))
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if isCalendarExpanded {
                                        viewModel.quickFilter = .todos
                                    }
                                    isCalendarExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: isCalendarExpanded ? "chevron.up.circle" : "chevron.down.circle")
                                    .font(.title3)
                                    .foregroundStyle(.black.opacity(0.65))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isCalendarExpanded ? "Ocultar calendario" : "Mostrar calendario")
                        }
                        .padding(.horizontal, 4)

                        if isCalendarExpanded {
                            customCalendarView
                                .padding(10)
                                .background(.white.opacity(AgendaUIConstants.calendarBackgroundOpacity), in: RoundedRectangle(cornerRadius: 12))
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        List {
                            if isCalendarExpanded {
                                ForEach(viewModel.itemsForSelectedDay) { item in
                                    agendaCard(item, fixedHeight: true)
                                }
                            } else {
                                ForEach(viewModel.collapsedSectionsForActiveFilter, id: \.date) { section in
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
                        .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal, 10)
                }
                .navigationTitle("Agenda")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.light, for: .navigationBar)
                .tint(.black)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Agenda")
                            .foregroundStyle(.black)
                            .font(.headline)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Recordatorios") {
                            showReminderManager = true
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Eliminar mes actual", role: .destructive) {
                                bulkDeleteItems = itemsInCurrentMonth()
                                showBulkDeleteConfirmation = !bulkDeleteItems.isEmpty
                            }
                            Button("Eliminar semana actual", role: .destructive) {
                                bulkDeleteItems = itemsInCurrentWeek()
                                showBulkDeleteConfirmation = !bulkDeleteItems.isEmpty
                            }
                            Divider()
                            Button(multiSelectionMode ? "Salir selección múltiple" : "Selección múltiple") {
                                multiSelectionMode.toggle()
                                if !multiSelectionMode { selectedItemsIDs.removeAll() }
                            }
                            if multiSelectionMode {
                                Button("Eliminar seleccionadas", role: .destructive) {
                                    bulkDeleteItems = selectedListedItems()
                                    showBulkDeleteConfirmation = !bulkDeleteItems.isEmpty
                                }
                                Button("Marcar seleccionadas completadas") {
                                    markSelectedAsCompleted()
                                }
                                Button("Quitar modo check seleccionadas") {
                                    clearCheckModeForSelected()
                                }
                                Button("Activar recordatorios seleccionadas") {
                                    activateReminderForSelected()
                                }
                                Button("Desactivar recordatorios seleccionadas") {
                                    deactivateReminderForSelected()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            editorItem = viewModel.create(selectedDate: viewModel.selectedDate)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(item: $editorItem) { item in
                    AgendaEditorView(baseItem: item) { updated in
                        viewModel.save(updated)
                        viewModel.updateReminder(for: updated, enabled: updated.recordatorioActivo)
                    }
                }
                .sheet(isPresented: $showReminderManager) {
                    AgendaReminderManagementView(viewModel: viewModel)
                }
                .onAppear {
                    viewModel.load()
                    displayedMonth = monthStart(of: viewModel.selectedDate)
                }
                .alert("Recordatorio", isPresented: $showReminderValidationAlert) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(reminderValidationMessage)
                }
                .confirmationDialog("¿Eliminar actividad?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Eliminar", role: .destructive) {
                        if let itemPendingDelete {
                            viewModel.delete(itemPendingDelete)
                        }
                        itemPendingDelete = nil
                    }
                    Button("Cancelar", role: .cancel) {
                        itemPendingDelete = nil
                    }
                } message: {
                    Text("Esta acción no se puede deshacer.")
                }
                .confirmationDialog("¿Eliminar actividades?", isPresented: $showBulkDeleteConfirmation, titleVisibility: .visible) {
                    Button("Eliminar \(bulkDeleteItems.count) actividad(es)", role: .destructive) {
                        for item in bulkDeleteItems {
                            viewModel.delete(item)
                        }
                        selectedItemsIDs.subtract(bulkDeleteItems.map(\.id))
                        bulkDeleteItems.removeAll()
                    }
                    Button("Cancelar", role: .cancel) {
                        bulkDeleteItems.removeAll()
                    }
                } message: {
                    Text("También se eliminarán sus recordatorios. Esta acción no se puede deshacer.")
                }
                .onChange(of: viewModel.quickFilter) { _, newValue in
                    if newValue == .hoy {
                        let now = Date()
                        viewModel.selectedDate = now
                        displayedMonth = monthStart(of: now)
                    }
                }
            } else {
                PurchaseView()
            }
        }
    }

    private func checkActionTitle(for item: AgendaItemData) -> String {
        switch item.completada {
        case nil:
            return "Activar check"
        case .some(true):
            return "Reactivar"
        case .some(false):
            return "Quitar check"
        }
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
                Circle()
                    .fill(item.prioridad.tint)
                    .frame(width: 10, height: 10)
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
            }
            if let completada = item.completada {
                Text(completada ? "Completada" : "Activa")
                    .font(.body)
                    .foregroundStyle(completada ? .green.opacity(0.85) : .black.opacity(0.65))
            }
            if !item.lugar.isEmpty {
                Text("Lugar: \(item.lugar)")
                    .foregroundStyle(.black.opacity(0.85))
            }
            if !item.contenido.isEmpty || !item.nota.isEmpty {
                Text(cardDetailText(for: item))
                    .font(.body)
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(expandedContentIDs.contains(item.id) ? nil : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            if expandedContentIDs.contains(item.id) {
                                expandedContentIDs.remove(item.id)
                            } else {
                                expandedContentIDs.insert(item.id)
                            }
                        }
                    }
            }
        }
        .frame(minHeight: fixedHeight ? 122 : 0, alignment: .top)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: expandedContentIDs.contains(item.id))
        .contentShape(Rectangle())
        .onTapGesture {
            guard multiSelectionMode else { return }
            if selectedItemsIDs.contains(item.id) {
                selectedItemsIDs.remove(item.id)
            } else {
                selectedItemsIDs.insert(item.id)
            }
        }
        .swipeActions(allowsFullSwipe: false) {
            Button("Eliminar", role: .destructive) {
                itemPendingDelete = item
                showDeleteConfirmation = true
            }
            Button("Editar") {
                editorItem = item
            }
            .tint(.indigo)
            Button(checkActionTitle(for: item)) {
                var updated = item
                switch updated.completada {
                case nil:
                    updated.completada = true
                case .some(true):
                    updated.completada = false
                case .some(false):
                    updated.completada = nil
                }
                updated.fechaModificacion = Date()
                viewModel.save(updated)
            }
            .tint(checkActionTint(for: item))
            Button(item.recordatorioActivo ? "Quitar recordatorio" : "Recordatorio") {
                let shouldEnable = !item.recordatorioActivo
                if shouldEnable, !viewModel.reminderCanBeEnabled(for: item) {
                    reminderValidationMessage = "La hora seleccionada ya pasó. Ajusta la fecha u hora del recordatorio a un momento futuro para poder activarlo."
                    showReminderValidationAlert = true
                } else {
                    viewModel.updateReminder(for: item, enabled: shouldEnable)
                }
            }
            .tint(.green)
        }
        .listRowBackground(backgroundColor(for: item.prioridad))
    }

    private func currentListedItems() -> [AgendaItemData] {
        if isCalendarExpanded {
            return viewModel.itemsForSelectedDay
        }
        return viewModel.collapsedSectionsForActiveFilter.flatMap(\.items)
    }

    private func selectedListedItems() -> [AgendaItemData] {
        let ids = selectedItemsIDs
        return currentListedItems().filter { ids.contains($0.id) }
    }

    private func itemsInCurrentMonth() -> [AgendaItemData] {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
        return viewModel.items.filter { $0.fechaActividad >= start && $0.fechaActividad < end }
    }

    private func itemsInCurrentWeek() -> [AgendaItemData] {
        let calendar = Calendar.current
        let now = Date()
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        guard let interval = weekInterval else { return [] }
        return viewModel.items.filter { $0.fechaActividad >= interval.start && $0.fechaActividad < interval.end }
    }

    private func activateReminderForSelected() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }
        let invalidExists = selected.contains { !viewModel.reminderCanBeEnabled(for: $0) && !$0.recordatorioActivo }
        if invalidExists {
            reminderValidationMessage = "No se activó ningún recordatorio: al menos una actividad seleccionada tiene una hora pasada. Ajusta esas horas a futuro y vuelve a intentarlo."
            showReminderValidationAlert = true
            return
        }
        for item in selected {
            if !item.recordatorioActivo {
                viewModel.updateReminder(for: item, enabled: true)
            }
        }
    }

    private func deactivateReminderForSelected() {
        let selected = selectedListedItems()
        guard !selected.isEmpty else { return }
        for item in selected where item.recordatorioActivo {
            viewModel.updateReminder(for: item, enabled: false)
        }
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
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        let title = formatter.string(from: date).capitalized
        if Calendar.current.isDateInToday(date) {
            return "Hoy · \(title)"
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

            let symbols = Calendar.current.shortWeekdaySymbols
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(symbols.indices, id: \.self) { idx in
                    Text(symbols[idx])
                        .font(.caption2)
                        .foregroundStyle(.black.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }

                ForEach(daysForDisplayedMonth(), id: \.self) { date in
                    if let date {
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
        }
        .buttonStyle(.plain)
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
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date).capitalized
    }
}

struct AgendaReminderManagementView: View {
    @ObservedObject var viewModel: AgendaViewModel

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(.black)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Recordatorios Agenda")
                        .foregroundStyle(.black)
                        .font(.headline)
                }
            }
        }
    }
}
