import SwiftUI
import CoreLocation
import Combine
import MapKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AgendaEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let baseItem: AgendaItemData
    let onSave: ([AgendaItemData]) -> Void
    private let forceDarkTheme: Bool

    @State private var titulo: String
    @State private var fechaActividad: Date
    @State private var hora: Date
    @State private var nota: String
    @State private var lugar: String
    @State private var contenido: String
    @State private var prioridad: AgendaPriority
    @State private var colorHex: String
    @State private var completada: Bool?
    @State private var recordatorioActivo: Bool

    @State private var recurrenceMode: AgendaRecurrenceMode = .none
    @State private var recurrenceFrequency: AgendaRecurrenceFrequency = .weekly
    @State private var recurrenceEndDate: Date
    @State private var selectedWeekdays: Set<Int> = []
    @State private var specificDateDraft: Date
    @State private var specificDates: [Date] = []
    @StateObject private var locationCapture = AgendaLocationCapture()
    @State private var showLocationAlert = false
    @State private var locationAlertMessage = ""
    @State private var isCapturingLocation = false

    init(baseItem: AgendaItemData, forceDarkTheme: Bool = false, onSave: @escaping ([AgendaItemData]) -> Void) {
        self.baseItem = baseItem
        self.forceDarkTheme = forceDarkTheme
        self.onSave = onSave
        _titulo = State(initialValue: baseItem.titulo)
        _fechaActividad = State(initialValue: baseItem.fechaActividad)
        _hora = State(initialValue: baseItem.hora)
        _nota = State(initialValue: baseItem.nota)
        _lugar = State(initialValue: baseItem.lugar)
        _contenido = State(initialValue: baseItem.contenido)
        _prioridad = State(initialValue: baseItem.prioridad)
        _colorHex = State(initialValue: baseItem.colorHex)
        _completada = State(initialValue: baseItem.completada)
        _recordatorioActivo = State(initialValue: baseItem.recordatorioActivo)

        let today = baseItem.fechaActividad
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: today) ?? today
        _recurrenceEndDate = State(initialValue: endDate)
        _specificDateDraft = State(initialValue: today)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    TextField("Título", text: $titulo)
                        .font(.system(size: 22))
                        .foregroundStyle(editorTextColor)
                    DatePicker("Fecha", selection: $fechaActividad, displayedComponents: .date)
                    DatePicker("Hora", selection: $hora, displayedComponents: .hourAndMinute)
                    Toggle("Activar recordatorio", isOn: $recordatorioActivo)
                    HStack {
                        if isCapturingLocation {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            TextField("Coordenadas", text: $lugar, axis: .vertical)
                                .foregroundStyle(editorTextColor)
                        }
                        Button("Coordenadas actuales") {
                            captureCurrentAddress()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCapturingLocation)
                    }
                    .frame(width: 350)
                }

                Section("Detalles") {
#if os(macOS)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contenido")
                            .font(.body)
                            .foregroundStyle(.white)
                        TextEditor(text: $contenido)
                            .font(.system(size: 22))
                            .foregroundStyle(editorTextColor)
                            .frame(minHeight: 50)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nota")
                            .font(.body)
                            .foregroundStyle(.white)
                        TextEditor(text: $nota)
                            .font(.system(size: 22))
                            .foregroundStyle(editorTextColor)
                            .frame(minHeight: 50)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }
#else
                    TextField("Contenido", text: $contenido, axis: .vertical)
                        .foregroundStyle(editorTextColor)
                        .frame(height: 50)
                    TextField("Nota", text: $nota, axis: .vertical)
                        .foregroundStyle(editorTextColor)
#endif
                }

                Section("Estilo") {
                    Picker("Prioridad", selection: $prioridad) {
                        ForEach(AgendaPriority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                    Picker("Estado", selection: $completada) {
                        Text("No aplicar").tag(Optional<Bool>.none)
                        Text("Activa").tag(Optional(false))
                        Text("Completada").tag(Optional(true))
                    }
                    
                }

                recurrenceSection
            }
            .foregroundStyle(forceDarkTheme ? Color.white : Color.primary)
            .tint(forceDarkTheme ? .white : .accentColor)
#if os(macOS)
            .padding(14)
#endif
            .navigationTitle(baseItem.titulo.isEmpty ? "Nueva actividad" : "Editar actividad")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(forceDarkTheme ? .white : .primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .foregroundStyle(forceDarkTheme ? .white : .primary)
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(forceDarkTheme ? .dark : nil)
        .background(forceDarkTheme ? Color.black : Color.clear)
        .alert("Ubicación", isPresented: $showLocationAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(locationAlertMessage)
        }
    }

    private var editorTextColor: Color {
        (forceDarkTheme || colorScheme == .dark) ? .white : .black
    }

    private func captureCurrentAddress() {
        isCapturingLocation = true
        locationCapture.captureCurrentAddress { result in
            isCapturingLocation = false
            switch result {
            case .success(let coordinates):
                lugar = coordinates
            case .failure(let error):
                locationAlertMessage = error.localizedDescription
                showLocationAlert = true
            }
        }
    }

    private var recurrenceSection: some View {
        Section("Repetición") {
            Text("Configura si esta actividad se repite por días de la semana, por fechas concretas (máximo 50) o por frecuencia semanal, mensual o anual.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker("Modo", selection: $recurrenceMode) {
                ForEach(AgendaRecurrenceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            switch recurrenceMode {
            case .none:
                EmptyView()

            case .weekdays:
                weekdaySelector
                DatePicker("Repetir hasta", selection: $recurrenceEndDate, in: fechaActividad..., displayedComponents: .date)

            case .specificDates:
                DatePicker("Fecha", selection: $specificDateDraft, displayedComponents: .date)
                Button("Añadir fecha") {
                    addSpecificDate(specificDateDraft)
                }
                .disabled(specificDates.count >= 50)

                if !specificDates.isEmpty {
                    ForEach(specificDates, id: \.self) { date in
                        HStack {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Button(role: .destructive) {
                                removeSpecificDate(date)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("\(specificDates.count)/50 fechas")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            case .frequency:
                Picker("Frecuencia", selection: $recurrenceFrequency) {
                    ForEach(AgendaRecurrenceFrequency.allCases) { frequency in
                        Text(frequency.title).tag(frequency)
                    }
                }
                DatePicker("Repetir hasta", selection: $recurrenceEndDate, in: fechaActividad..., displayedComponents: .date)
            }
        }
    }

    private var weekdaySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Días")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let symbols = weekdaySymbolsOrderedByCalendar
            let orderedWeekdays = orderedWeekdayNumbers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
                ForEach(Array(orderedWeekdays.enumerated()), id: \.element) { index, weekday in
                    Button {
                        toggleWeekday(weekday)
                    } label: {
                        Text(symbols[index])
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedWeekdays.contains(weekday) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var canSave: Bool {
        let hasTitle = !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasTitle else { return false }

        switch recurrenceMode {
        case .none:
            return true
        case .weekdays:
            return !selectedWeekdays.isEmpty
        case .specificDates:
            return !specificDates.isEmpty && specificDates.count <= 50
        case .frequency:
            return recurrenceEndDate >= fechaActividad
        }
    }

    private var orderedWeekdayNumbers: [Int] {
        let calendar = Calendar.current
        let all = [1, 2, 3, 4, 5, 6, 7]
        let first = calendar.firstWeekday
        let pivot = max(0, min(all.count - 1, first - 1))
        return Array(all[pivot...]) + Array(all[..<pivot])
    }

    private var weekdaySymbolsOrderedByCalendar: [String] {
        let calendar = Calendar.current
        let base = calendar.shortWeekdaySymbols
        let first = max(0, min(base.count - 1, calendar.firstWeekday - 1))
        return Array(base[first...]) + Array(base[..<first])
    }

    private func toggleWeekday(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    private func addSpecificDate(_ date: Date) {
        guard specificDates.count < 50 else { return }
        let normalized = Calendar.current.startOfDay(for: date)
        if !specificDates.contains(normalized) {
            specificDates.append(normalized)
            specificDates.sort()
        }
    }

    private func removeSpecificDate(_ date: Date) {
        specificDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
    }

    private func mergedDate(_ day: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components) ?? day
    }

    private func buildItemsToSave(now: Date) -> [AgendaItemData] {
        let seriesID: UUID? = recurrenceMode == .none ? baseItem.seriesID : (baseItem.seriesID ?? UUID())
        let dates = generatedActivityDates()
        let calendar = Calendar.current

        return dates.map { activityDate in
            let reuseBaseID = recurrenceMode == .none || calendar.isDate(activityDate, inSameDayAs: baseItem.fechaActividad)
            return AgendaItemData(
                id: reuseBaseID ? baseItem.id : UUID(),
                titulo: titulo.trimmingCharacters(in: .whitespacesAndNewlines),
                fechaCreacion: reuseBaseID ? baseItem.fechaCreacion : now,
                fechaModificacion: now,
                nota: nota,
                fechaActividad: activityDate,
                hora: hora,
                lugar: lugar,
                contenido: contenido,
                prioridad: prioridad,
                colorHex: colorHex,
                completada: completada,
                recordatorioActivo: recordatorioActivo,
                reminderID: reuseBaseID ? baseItem.reminderID : nil,
                seriesID: seriesID
            )
        }
    }

    private func generatedActivityDates() -> [Date] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: fechaActividad)
        let endDay = calendar.startOfDay(for: recurrenceEndDate)

        switch recurrenceMode {
        case .none:
            return [startDay]

        case .specificDates:
            let filtered = specificDates
                .filter { $0 >= startDay }
                .sorted()
            return Array(filtered.prefix(50))

        case .weekdays:
            guard !selectedWeekdays.isEmpty else {
                return [startDay]
            }
            var dates: [Date] = []
            var cursor = startDay
            while cursor <= endDay {
                let weekday = calendar.component(.weekday, from: cursor)
                if selectedWeekdays.contains(weekday) {
                    dates.append(cursor)
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                    break
                }
                cursor = next
            }
            return dates.isEmpty ? [startDay] : dates

        case .frequency:
            return frequencyDates(startDay: startDay, endDay: endDay)
        }
    }

    private func frequencyDates(startDay: Date, endDay: Date) -> [Date] {
        let calendar = Calendar.current
        var result: [Date] = []

        let anchorDay = calendar.component(.day, from: startDay)
        let anchorMonth = calendar.component(.month, from: startDay)

        var offset = 0
        while true {
            let candidate: Date?
            switch recurrenceFrequency {
            case .weekly:
                candidate = calendar.date(byAdding: .weekOfYear, value: offset, to: startDay)

            case .monthly:
                guard let monthBase = calendar.date(byAdding: .month, value: offset, to: startDay) else {
                    return result
                }
                let monthYear = calendar.dateComponents([.year, .month], from: monthBase)
                var components = DateComponents()
                components.year = monthYear.year
                components.month = monthYear.month
                components.day = anchorDay
                candidate = calendar.date(from: components)

            case .yearly:
                guard let yearBase = calendar.date(byAdding: .year, value: offset, to: startDay) else {
                    return result
                }
                let year = calendar.component(.year, from: yearBase)
                var components = DateComponents()
                components.year = year
                components.month = anchorMonth
                components.day = anchorDay
                candidate = calendar.date(from: components)
            }

            if let candidate {
                if candidate > endDay {
                    break
                }
                if candidate >= startDay {
                    result.append(candidate)
                }
            }

            offset += 1
            if offset > 5000 { break }
        }

        return result.isEmpty ? [startDay] : result
    }

    private func save() {
        let now = Date()
        var items = buildItemsToSave(now: now)
        var seenDays = Set<Date>()
        items = items
            .sorted { $0.fechaActividad < $1.fechaActividad }
            .filter { item in
                let day = Calendar.current.startOfDay(for: item.fechaActividad)
                if seenDays.contains(day) {
                    return false
                }
                seenDays.insert(day)
                return true
            }

        if items.isEmpty {
            return
        }

        onSave(items)
        dismiss()
    }
}

@MainActor
final class AgendaLocationCapture: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<String, Error>) -> Void)?
    private var bestLocation: CLLocation?
    private var timeoutTask: Task<Void, Never>?
    private let targetHorizontalAccuracy: CLLocationAccuracy = 25
    private let maximumCaptureSeconds: UInt64 = 6

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func captureCurrentAddress(completion: @escaping (Result<String, Error>) -> Void) {
        cancelPendingCapture()
        bestLocation = nil
        self.completion = completion
        guard CLLocationManager.locationServicesEnabled() else {
            finish(.failure(NSError(
                domain: "AgendaLocationCapture",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Los servicios de ubicación están desactivados en el sistema."]
            )))
            return
        }
#if os(macOS)
        switch manager.authorizationStatus {
        case .authorizedAlways:
            startPrecisionCapture()
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            finish(.failure(NSError(domain: "AgendaLocationCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "No hay permisos de ubicación. Actívalos en Ajustes."])))
        @unknown default:
            finish(.failure(NSError(domain: "AgendaLocationCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Estado de ubicación no soportado."])))
        }
#else
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startPrecisionCapture()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finish(.failure(NSError(domain: "AgendaLocationCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "No hay permisos de ubicación. Actívalos en Ajustes."])))
        @unknown default:
            finish(.failure(NSError(domain: "AgendaLocationCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Estado de ubicación no soportado."])))
        }
#endif
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.handleAuthorizationChange(status)
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        if isAuthorized(status) {
            startPrecisionCapture()
        } else if status == .denied || status == .restricted {
            finish(.failure(NSError(domain: "AgendaLocationCapture", code: 3, userInfo: [NSLocalizedDescriptionKey: "Permiso de ubicación denegado."])))
        }
    }

    private func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
#if os(macOS)
        return status == .authorizedAlways
#else
        return status == .authorizedWhenInUse || status == .authorizedAlways
#endif
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.handleLocationUpdate(locations)
        }
    }

    private func handleLocationUpdate(_ locations: [CLLocation]) {
        let freshLocations = locations.filter { location in
            location.horizontalAccuracy >= 0 && abs(location.timestamp.timeIntervalSinceNow) <= 15
        }

        guard let location = freshLocations.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) else {
            return
        }

        if bestLocation == nil || location.horizontalAccuracy < (bestLocation?.horizontalAccuracy ?? .greatestFiniteMagnitude) {
            bestLocation = location
        }

        if location.horizontalAccuracy <= targetHorizontalAccuracy {
            finish(.success(LocationCoordinateFormatter.string(from: location.coordinate)))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.finish(.failure(error))
        }
    }

    private func finish(_ result: Result<String, Error>) {
        cancelPendingCapture()
        completion?(result)
        completion = nil
    }

    private func startPrecisionCapture() {
        manager.startUpdatingLocation()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: (self?.maximumCaptureSeconds ?? 6) * 1_000_000_000)
            await MainActor.run {
                guard let self, self.completion != nil else { return }
                if let bestLocation = self.bestLocation {
                    self.finish(.success(LocationCoordinateFormatter.string(from: bestLocation.coordinate)))
                } else {
                    self.finish(.failure(NSError(domain: "AgendaLocationCapture", code: 4, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la ubicación actual."])))
                }
            }
        }
    }

    private func cancelPendingCapture() {
        timeoutTask?.cancel()
        timeoutTask = nil
        manager.stopUpdatingLocation()
    }
}

enum LocationMapApp: String, CaseIterable, Identifiable {
    case appleMaps
    case googleMaps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleMaps:
            return "Mapas"
        case .googleMaps:
            return "Google Maps"
        }
    }
}

enum LocationCoordinateFormatter {
    static func string(from coordinate: CLLocationCoordinate2D) -> String {
        String(
            format: "%.6f,%.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            coordinate.latitude,
            coordinate.longitude
        )
    }

    static func coordinate(from value: String) -> CLLocationCoordinate2D? {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 2,
              let latitude = Double(parts[0]),
              let longitude = Double(parts[1]),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
enum LocationMapOpener {
    static func open(_ storedLocation: String) async -> Bool {
        let cleaned = storedLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }

        if let coordinate = LocationCoordinateFormatter.coordinate(from: cleaned) {
            return await open(coordinate: coordinate)
        }

        return await openAddressFallback(cleaned)
    }

    private static func open(coordinate: CLLocationCoordinate2D) async -> Bool {
        let preference = LocationMapApp(rawValue: UserDefaults.standard.string(forKey: AppCons.UD_setting_preferredMapApp) ?? "") ?? .appleMaps

        switch preference {
        case .appleMaps:
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = "Ubicación"
#if os(macOS)
            return await mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
#else
            return mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
#endif
        case .googleMaps:
            let coordinateText = LocationCoordinateFormatter.string(from: coordinate)
            guard let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(coordinateText)") else {
                return false
            }
#if os(iOS)
            return await UIApplication.shared.open(url)
#elseif os(macOS)
            NSWorkspace.shared.open(url)
            return true
#else
            return false
#endif
        }
    }

    private static func openAddressFallback(_ address: String) async -> Bool {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let destination = response.mapItems.first else { return false }
            destination.name = address
#if os(macOS)
            return await destination.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
#else
            return destination.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
#endif
        } catch {
            return false
        }
    }
}
