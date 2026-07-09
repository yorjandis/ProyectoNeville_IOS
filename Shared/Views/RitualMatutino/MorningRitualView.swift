import SwiftUI
import Combine
import UserNotifications

private enum MorningRitualConstants {
    static let sessionsKey = "morning_ritual_sessions"
    static let settingsKey = "morning_ritual_settings"
    static let maxItems = 3
    static let maxGoals = 12
}

private struct MorningRitualSession: Codable, Identifiable, Equatable {
    let id: UUID
    let sessionDateEpochDay: Int
    let completedAtEpochMillis: Int64
    let goals: [String]
    let identity: String
    let emotions: [String]
    let anticipatedSituations: [String]
    let consciousResponses: [String]
    var noteText: String
    let completed: Bool

    init(
        id: UUID = UUID(),
        sessionDateEpochDay: Int,
        completedAtEpochMillis: Int64,
        goals: [String],
        identity: String,
        emotions: [String],
        anticipatedSituations: [String],
        consciousResponses: [String],
        noteText: String = "",
        completed: Bool = true
    ) {
        self.id = id
        self.sessionDateEpochDay = sessionDateEpochDay
        self.completedAtEpochMillis = completedAtEpochMillis
        self.goals = goals
        self.identity = identity
        self.emotions = emotions
        self.anticipatedSituations = anticipatedSituations
        self.consciousResponses = consciousResponses
        self.noteText = noteText
        self.completed = completed
    }
}

private struct MorningRitualSettings: Codable, Equatable {
    var enabled: Bool = false
    var hour: Int = 7
    var minute: Int = 30
}

private struct TriggerResponseInput: Equatable {
    var trigger: String = ""
    var response: String = ""
}

private struct MorningRitualDraft: Equatable {
    let goals: [String]
    let identityValues: [String]
    let emotionValues: [String]
    let triggers: [String]
    let responses: [String]
    let noteText: String
    let dayRemindersEnabled: Bool
    let dayReminderTimes: [Int]
}

private struct MorningRitualFlowState {
    var step: Int = 1
    var goals: [String] = [""]
    var identities: [String] = []
    var customIdentity: String = ""
    var emotions: [String] = []
    var customEmotion: String = ""
    var triggerResponses: [TriggerResponseInput] = [TriggerResponseInput()]
    var dayRemindersEnabled: Bool = true
    var dayReminderTimes: [Int] = [10 * 60, 14 * 60, 19 * 60]
    var ritualNote: String = ""
    var validationMessage: String?
    var isCompleted: Bool = false
}

@MainActor
private final class MorningRitualStore: ObservableObject {
    @Published private(set) var sessions: [MorningRitualSession] = []
    @Published private(set) var settings: MorningRitualSettings = .init()

    private let sharedDefaults: UserDefaults?
    private let standardDefaults: UserDefaults

    init() {
        self.sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        self.standardDefaults = .standard
        self.loadAll()
    }

    var todayCompleted: Bool {
        let today = epochDay(for: Date())
        return sessions.contains { $0.completed && $0.sessionDateEpochDay == today }
    }

    func saveSession(_ session: MorningRitualSession) {
        sessions.removeAll { $0.sessionDateEpochDay == session.sessionDateEpochDay }
        sessions.insert(session, at: 0)
        persistSessions()
    }

    func updateNote(sessionId: UUID, noteText: String) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[idx].noteText = noteText
        persistSessions()
    }

    func deleteSession(sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        persistSessions()
    }

    func applySettings(enabled: Bool, hour: Int, minute: Int) {
        settings.enabled = enabled
        settings.hour = max(0, min(23, hour))
        settings.minute = max(0, min(59, minute))
        persistSettings()

        Task {
            await MorningRitualNotificationManager.shared.scheduleDailyReminder(settings: settings)
        }
    }

    func scheduleDayReminders(minutesOfDay: [Int], enabled: Bool) {
        Task {
            await MorningRitualNotificationManager.shared.scheduleDayReminders(
                minutesOfDay: enabled ? minutesOfDay : []
            )
        }
    }

    func reload() {
        loadAll()
    }

    private func loadAll() {
        let sharedSessions = decodeSessions(from: sharedDefaults)
        let standardSessions = decodeSessions(from: standardDefaults)
        sessions = mergeSessions(sharedSessions, standardSessions)

        let sharedSettings = decodeSettings(from: sharedDefaults)
        let standardSettings = decodeSettings(from: standardDefaults)
        settings = sharedSettings ?? standardSettings ?? .init()

        mirrorSessionsAcrossContainers()
        mirrorSettingsAcrossContainers()
    }

    private func persistSessions() {
        sessions.sort { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.sessionsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.sessionsKey)
    }

    private func persistSettings() {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.settingsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.settingsKey)
    }

    private func decodeSessions(from defaults: UserDefaults?) -> [MorningRitualSession] {
        guard let defaults,
              let data = defaults.data(forKey: MorningRitualConstants.sessionsKey),
              let decoded = try? JSONDecoder().decode([MorningRitualSession].self, from: data) else {
            return []
        }
        return decoded
    }

    private func decodeSettings(from defaults: UserDefaults?) -> MorningRitualSettings? {
        guard let defaults,
              let data = defaults.data(forKey: MorningRitualConstants.settingsKey),
              let decoded = try? JSONDecoder().decode(MorningRitualSettings.self, from: data) else {
            return nil
        }
        return decoded
    }

    private func mergeSessions(_ lhs: [MorningRitualSession], _ rhs: [MorningRitualSession]) -> [MorningRitualSession] {
        var bestByDay: [Int: MorningRitualSession] = [:]

        for session in lhs + rhs {
            if let current = bestByDay[session.sessionDateEpochDay] {
                bestByDay[session.sessionDateEpochDay] =
                    session.completedAtEpochMillis >= current.completedAtEpochMillis ? session : current
            } else {
                bestByDay[session.sessionDateEpochDay] = session
            }
        }

        return bestByDay.values.sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
    }

    private func mirrorSessionsAcrossContainers() {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.sessionsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.sessionsKey)
    }

    private func mirrorSettingsAcrossContainers() {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        sharedDefaults?.set(encoded, forKey: MorningRitualConstants.settingsKey)
        standardDefaults.set(encoded, forKey: MorningRitualConstants.settingsKey)
    }

    private func epochDay(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }
}

private actor MorningRitualNotificationManager {
    static let shared = MorningRitualNotificationManager()

    private let center = UNUserNotificationCenter.current()

    func scheduleDailyReminder(settings: MorningRitualSettings) async {
        center.removePendingNotificationRequests(withIdentifiers: ["morning_ritual_daily"])

        guard settings.enabled else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        var date = DateComponents()
        date.hour = settings.hour
        date.minute = settings.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Ritual Matutino"
        content.body = "Diseña tu día con claridad e intención."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "morning_ritual_daily",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func scheduleDayReminders(minutesOfDay: [Int]) async {
        let existing = await center.pendingNotificationRequests()
            .map(\ .identifier)
            .filter { $0.hasPrefix("morning_ritual_day_") }
        center.removePendingNotificationRequests(withIdentifiers: existing)

        guard !minutesOfDay.isEmpty else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let calendar = Calendar.current
        let today = Date()

        for (index, minuteOfDay) in minutesOfDay.sorted().enumerated() {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = minuteOfDay / 60
            components.minute = minuteOfDay % 60
            components.second = 0

            guard let date = calendar.date(from: components), date > today else { continue }

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Ritual Matutino"
            content.body = "Mantén tu intención durante el día."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "morning_ritual_day_\(index)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
            return true
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}

struct MorningRitualMainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = MorningRitualStore()
    @State private var route: MorningRitualRoute?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.50, blue: 0.45),
                        Color(red: 0.66, green: 0.50, blue: 0.80),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack{
                    Text("Ritual Matutino")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.black)
                    ScrollView {
                        VStack(spacing: 14) {
                            ritualCard(title: "Diseña con intención este día", subtitle: "Un ritual breve para estructurar tu día con claridad, intención y presencia.") {
                                Text(store.todayCompleted ? "Hoy ya completaste tu diálogo." : "Aún no has completado tu diálogo de hoy.")
                                    .font(.body)
                                    .foregroundStyle(.black.opacity(0.85))
                                HStack{
                                    Spacer()
                                    Button(store.todayCompleted ? "Repetir diálogo" : "Iniciar diálogo") {
                                        route = .flow
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.black)
                                }
                                
                            }

                            ritualCard(title: "Explorar", subtitle: nil) {
                                HStack{
                                    Button{ route = .settings } label:{
                                        Text("Ajustes")
                                            .foregroundStyle(.black)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.gray)
                                    .frame(width: 100)

                                    Spacer()

                                    Button{ route = .history } label:{
                                        Text("Ver historial")
                                            .foregroundStyle(.black)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.gray)
                                    .frame(width: 150)
                                    
                                    Button { route = .stats } label: {
                                        Text("Resumen")
                                            .foregroundStyle(.black)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.black.opacity(0.25))
                                    .frame(width: 100)
                                    
                                }
                            }
                        }
                        
                    }
                    .padding(16)
                }
                
            }
            //.navigationTitle("Ritual Matutino")
            .onTapGesture {
                dismissKeyboard()
            }
            .onAppear {
                store.reload()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    store.reload()
                }
            }
            .sheet(item: $route) { selected in
                switch selected {
                case .flow:
                    MorningRitualFlowView(store: store)
                case .history:
                    MorningRitualHistoryView(store: store)
                case .settings:
                    MorningRitualSettingsView(store: store)
                        .presentationDetents([.height(320)])
                        .presentationDragIndicator(.visible)
                case .stats:
                    MorningRitualStatsView(store: store)
                }
            }
        }
    }

    @ViewBuilder
    private func ritualCard(title: String, subtitle: String?, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                
            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.black)
        .background(LinearGradient.Amanecer())
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private enum MorningRitualRoute: String, Identifiable {
    case flow
    case history
    case settings
    case stats

    var id: String { rawValue }
}

private extension View {
    func morningRitualTextFieldStyle() -> some View {
        self
            .font(.system(size: 22))
            .padding(10)
            .foregroundStyle(.white)
            .tint(.white)
#if os(macOS)
            .textFieldStyle(.plain)
#endif
            .background(Color.black.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
    }
}

private struct MorningRitualFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore

    private enum FocusedField: Hashable {
        case goal(Int)
    }

    @State private var state = MorningRitualFlowState()
    @State private var showingTimePicker = false
    @State private var showingNoteEditor = false
    @State private var reminderPickerValue = Date()
    @State private var lastSavedDraft: MorningRitualDraft?
    @FocusState private var focusedField: FocusedField?

    private let identitySuggestions = [
        "Enfocado", "Calmado", "Disciplinado", "Valiente", "Presente",
        "Compasivo","Curioso","Reflexivo","Proactivo","Consciente","Observador",
        "Intencional","Constante","Organizado","Persistente","Productivo","Comprometido",
        "Auténtico","Visionario","Autodidacta","Explorador", "Innovador"
    ]

    private let emotionSuggestions = [
        "Calma", "Confianza", "Gratitud", "Claridad", "Energía", "Apertura",
        "Serenidad","Empatía", "Autoestima","Alegría","Paz", "Amor", "Compasión","Esperanza",
        "Entusiasmo","Seguridad","Asombro","Satisfacción", "Fluidez", "Conexión", "Fortaleza",
        "Resiliencia"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [
                    Color(red: 0.20, green: 0.20, blue: 0.30),
                    Color(red: 0.76, green: 0.60, blue: 0.90)],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView(value: Double(state.step), total: 6)
                        .tint(.mint)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            contentForCurrentStep

                            if let message = state.validationMessage {
                                Text(message)
                                    .font(.body)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissKeyboard()
                        }
                    }

                    HStack(spacing: 12) {
#if os(macOS)
                        Button("Cerrar") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .tint(.black)
                        
                        Spacer()
                        
#endif

                        Button("Atrás") {
                            state.validationMessage = nil
                            state.step = max(1, state.step - 1)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .tint(.black)
                        .disabled(state.step == 1)

                        if state.step < 6 {
                            Button("Continuar") {
                                guard validateCurrentStep() == nil else { return }
                                state.step += 1
                                state.validationMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .tint(.black)
                        } else if hasPendingChanges {
                            Button("Guardar Ritual") {
                                completeRitual()
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .tint(.black)
                        }
                    }
                    .padding([.top, .bottom], 6)
                    .padding(.horizontal, 12)

                    if state.isCompleted {
                        Button("Volver al inicio") { dismiss() }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white)
                            .tint(.black)
                            .padding(.bottom, 10)
                    }
                }
            }
            .navigationTitle("Diseña tu día")
            .toolbarTitleDisplayMode(.inline)
            .onTapGesture {
                dismissKeyboard()
            }
            .sheet(isPresented: $showingTimePicker) {
                NavigationStack {
                    VStack(spacing: 14) {
                        DatePicker("Hora", selection: $reminderPickerValue, displayedComponents: .hourAndMinute)
#if os(iOS)
                            .datePickerStyle(.wheel)
#endif
                            .labelsHidden()

                        Button("Añadir hora") {
                            let minuteOfDay = minuteOfDay(from: reminderPickerValue)
                            if !state.dayReminderTimes.contains(minuteOfDay) {
                                state.dayReminderTimes.append(minuteOfDay)
                                state.dayReminderTimes.sort()
                            }
                            showingTimePicker = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingNoteEditor) {
                MorningRitualDraftNoteSheet(
                    noteText: $state.ritualNote
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var contentForCurrentStep: some View {
        switch state.step {
        case 1:
            cardBlock(title: "Antes de empezar, vuelve a ti", body: "Cierra los ojos y respira profundo... Acalla tus pensamientos y solo siente tu respiración. Eres importante, este momento es tuyo.") {
                Text("Hoy no reaccionas por inercia, hoy eliges.")
                    .foregroundStyle(.black.opacity(0.85))
                    .font(.title3)
                HStack{
                    Spacer()
                    Button("Estoy presente") { state.step = 2 }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)
                }
                
            }
        case 2:
            cardBlock(title: "Metas del día", body: "Comienza por el final. Si hoy fuera un buen día para ti, ¿qué habría ocurrido?") {
                HStack {
                    Spacer()
                    Button("Añadir meta") {
                        state.goals.append("")
                        let newIndex = state.goals.count - 1
                        DispatchQueue.main.async {
                            focusedField = .goal(newIndex)
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.black)
                    .tint(.black)
                    .disabled(state.goals.count >= MorningRitualConstants.maxGoals)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(state.goals.enumerated()), id: \.offset) { index, _ in
                            HStack {
                                TextField("Meta \(index + 1)", text: Binding(
                                    get: { state.goals[index] },
                                    set: { state.goals[index] = $0 }
                                ))
                                .morningRitualTextFieldStyle()
                                .focused($focusedField, equals: .goal(index))

                                if state.goals.count > 1 {
                                    Button(role: .destructive) {
                                        state.goals.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 200)
            }
        case 3:
            cardBlock(title: "Identidad", body: "¿Quién decides ser hoy?") {
                chipGrid(items: identitySuggestions, selected: state.identities) { value in
                    toggleValue(value, in: &state.identities)
                }

                TextField("Identidad personalizada", text: $state.customIdentity)
                    .morningRitualTextFieldStyle()
            }
        case 4:
            cardBlock(title: "Emoción", body: "¿Qué emoción quieres sostener hoy?") {
                chipGrid(items: emotionSuggestions, selected: state.emotions) { value in
                    toggleValue(value, in: &state.emotions)
                }

                TextField("Emoción personalizada", text: $state.customEmotion)
                    .morningRitualTextFieldStyle()
            }
        case 5:
            cardBlock(title: "Anticipación (Opcional)", body: "¿Qué podría desafiarte hoy y cómo responderás conscientemente?") {
                ForEach(Array(state.triggerResponses.enumerated()), id: \.offset) { index, _ in
                    VStack(spacing: 6) {
                        TextField("Si sucede x...", text: Binding(
                            get: { state.triggerResponses[index].trigger },
                            set: { state.triggerResponses[index].trigger = $0 }
                        ))
                        .morningRitualTextFieldStyle()

                        TextField("Responderé con y...", text: Binding(
                            get: { state.triggerResponses[index].response },
                            set: { state.triggerResponses[index].response = $0 }
                        ))
                        .morningRitualTextFieldStyle()

                        if state.triggerResponses.count > 1 {
                            Button("Quitar") {
                                state.triggerResponses.remove(at: index)
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.black)
                            .tint(.red)
                        }
                    }
                    .padding(8)
                    .background(.black.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if state.triggerResponses.count < MorningRitualConstants.maxItems {
                    Button("Añadir situación") { state.triggerResponses.append(.init()) }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)
                }
            }
        default:
            cardBlock(title: "Resumen", body: "Hoy eliges tu estado interno y comportamiento. No serás un efecto de tu entorno.") {
                Group {
                    summarySection(title: "Metas", text: compactGoals)
                    summarySection(title: "Identidad", text: compactIdentity)
                    summarySection(title: "Emociones", text: compactEmotions)
                    summarySection(title: "Anticipación", text: compactAnticipation)
                }

                Button(state.ritualNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Añadir una nota (opcional)" : "Editar nota del ritual") {
                    showingNoteEditor = true
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.black)

                if !state.ritualNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    summarySection(title: "Nota", text: state.ritualNote)
                }

                Toggle(
                    "Recordatorios durante el día",
                    isOn: Binding(
                        get: { state.dayRemindersEnabled },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.28)) {
                                state.dayRemindersEnabled = newValue
                            }
                        }
                    )
                )
                .toggleStyle(.switch)
                .foregroundStyle(.black)

                if state.dayRemindersEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(state.dayReminderTimes, id: \.self) { minuteOfDay in
                            HStack {
                                Text(timeString(from: minuteOfDay))
                                    .foregroundStyle(.black)
                                Spacer()
                                Button(role: .destructive) {
                                    state.dayReminderTimes.removeAll { $0 == minuteOfDay }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }

                        Button("Añadir hora") {
                            reminderPickerValue = Date()
                            showingTimePicker = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.black)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    private var compactGoals: String {
        state.goals.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    private var compactIdentity: String {
        let custom = state.customIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = state.identities + (custom.isEmpty ? [] : [custom])
        return values.joined(separator: ", ")
    }

    private var compactEmotions: String {
        let custom = state.customEmotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = state.emotions + (custom.isEmpty ? [] : [custom])
        return values.joined(separator: ", ")
    }

    private var compactAnticipation: String {
        let validPairs = state.triggerResponses
            .map {
                TriggerResponseInput(
                    trigger: $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                    response: $0.response.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.trigger.isEmpty && !$0.response.isEmpty }

        return validPairs
            .map { "\($0.trigger) → \($0.response)" }
            .joined(separator: "\n")
    }

    private func validateCurrentStep() -> String? {
        let message: String?
        switch state.step {
        case 2:
            let valid = state.goals.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            message = valid.isEmpty ? "Añade al menos 1 meta para hoy." : nil
        case 3:
            let hasCustom = !state.customIdentity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            message = (state.identities.isEmpty && !hasCustom) ? "Elige al menos una identidad o añade una personalizada." : nil
        case 4:
            let hasCustom = !state.customEmotion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            message = (state.emotions.isEmpty && !hasCustom) ? "Elige al menos una emoción o añade una personalizada." : nil
        case 5:
            let normalizedPairs = state.triggerResponses.map {
                TriggerResponseInput(
                    trigger: $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                    response: $0.response.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            let hasAnyInput = normalizedPairs.contains { !$0.trigger.isEmpty || !$0.response.isEmpty }
            let hasIncompletePair = normalizedPairs.contains { ($0.trigger.isEmpty && !$0.response.isEmpty) || (!$0.trigger.isEmpty && $0.response.isEmpty) }

            if !hasAnyInput {
                message = nil
            } else if hasIncompletePair {
                message = "Completa situación y respuesta en cada bloque usado, o déjalos vacíos."
            } else {
                message = nil
            }
        case 6:
            message = state.dayRemindersEnabled && state.dayReminderTimes.isEmpty
                ? "Añade al menos una hora o desactiva los recordatorios del día."
                : nil
        default:
            message = nil
        }

        state.validationMessage = message
        return message
    }

    private func completeRitual() {
        guard validateCurrentStep() == nil else { return }

        let nowMillis = Int64(Date().timeIntervalSince1970 * 1_000)
        let todayEpoch = epochDay(for: Date())

        let session = MorningRitualSession(
            sessionDateEpochDay: todayEpoch,
            completedAtEpochMillis: nowMillis,
            goals: currentDraft.goals,
            identity: currentDraft.identityValues.joined(separator: ", "),
            emotions: currentDraft.emotionValues,
            anticipatedSituations: currentDraft.triggers,
            consciousResponses: currentDraft.responses,
            noteText: currentDraft.noteText
        )

        store.saveSession(session)
        store.scheduleDayReminders(minutesOfDay: state.dayReminderTimes, enabled: state.dayRemindersEnabled)
        lastSavedDraft = currentDraft
        state.isCompleted = true
        state.validationMessage = nil
        state.step = 6
    }

    private var hasPendingChanges: Bool {
        lastSavedDraft != currentDraft
    }

    private var currentDraft: MorningRitualDraft {
        let validGoals = state.goals
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let customIdentity = state.customIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        let identityValues = Array(Set(state.identities + (customIdentity.isEmpty ? [] : [customIdentity]))).sorted()

        let customEmotion = state.customEmotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let emotionValues = Array(Set(state.emotions + (customEmotion.isEmpty ? [] : [customEmotion]))).sorted()

        let validPairs = state.triggerResponses
            .map {
                TriggerResponseInput(
                    trigger: $0.trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                    response: $0.response.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.trigger.isEmpty && !$0.response.isEmpty }

        return MorningRitualDraft(
            goals: validGoals,
            identityValues: identityValues,
            emotionValues: emotionValues,
            triggers: validPairs.map(\.trigger),
            responses: validPairs.map(\.response),
            noteText: state.ritualNote.trimmingCharacters(in: .whitespacesAndNewlines),
            dayRemindersEnabled: state.dayRemindersEnabled,
            dayReminderTimes: Array(Set(state.dayReminderTimes)).sorted()
        )
    }

    private func timeString(from minuteOfDay: Int) -> String {
        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func minuteOfDay(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func epochDay(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }

    private func toggleValue(_ value: String, in array: inout [String]) {
        if let idx = array.firstIndex(of: value) {
            array.remove(at: idx)
        } else {
            array.append(value)
        }
    }

    @ViewBuilder
    private func summarySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body).bold()
                .foregroundStyle(.black)
            Text(text.isEmpty ? "-" : text)
                .font(.body)
                .foregroundStyle(.black.opacity(0.85))
        }
    }

    @ViewBuilder
    private func chipGrid(items: [String], selected: [String], onToggle: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                let isOn = selected.contains(item)
                Button {
                    onToggle(item)
                } label: {
                    Text(item)
                        .font(.body)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(isOn ? Color.blue.opacity(0.8) : Color.black.opacity(0.15))
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func cardBlock(title: String, body: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.black)
            Text(body)
                .font(.title3)
                .foregroundStyle(.black.opacity(0.85))
            content()
        }
        .padding(14)
        .background(LinearGradient.Amanecer())
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualDraftNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var noteText: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nota del ritual")
                    .font(.title3.bold())

                TextEditor(text: $noteText)
                    .frame(minHeight: 220)
                    .padding(10)
                    .background(Color.black.opacity(0.001))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    

                HStack {
                    Spacer()
                    Button("Guardar") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .onTapGesture {
                dismissKeyboard()
            }
            .navigationTitle("Añadir nota")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore

    @State private var stats = MorningRitualStatsSnapshot(sessions: [])

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.26),
                        Color(red: 0.11, green: 0.26, blue: 0.44),
                        Color(red: 0.95, green: 0.46, blue: 0.23)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        MorningRitualHeadlineCards(stats: stats)
                        MorningRitualWeeklyBars(stats: stats)
                        MorningRitualTopTagsSection(stats: stats)
                        MorningRitualTrendSection(stats: stats)
                    }
                    .padding()
                }
            }
            .navigationTitle("Resumen de Rituales")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem {
                    Button {
                        reloadStats()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                reloadStats()
            }
        }
    }

    private func reloadStats() {
        stats = MorningRitualStatsSnapshot(sessions: store.sessions)
    }
}

private struct MorningRitualStatsSnapshot {
    struct WeekdayCount: Identifiable {
        var id: String { dayLabel }
        let dayLabel: String
        let count: Int
    }

    struct DayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let count: Int
    }

    struct NamedCount: Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    let totalRituals: Int
    let daysWithRitual: Int
    let currentStreak: Int
    let longestStreak: Int
    let weeklyAverage: Double
    let monthlyAverage: Double
    let avgGoalsPerRitual: Double
    let avgAnticipationsPerRitual: Double
    let weekdayCounts: [WeekdayCount]
    let topIdentities: [NamedCount]
    let topEmotions: [NamedCount]
    let dayPoints: [DayPoint]

    init(sessions: [MorningRitualSession]) {
        let calendar = Calendar.current
        let days = sessions.map { Date(timeIntervalSince1970: TimeInterval($0.sessionDateEpochDay * 86_400)) }
            .map { calendar.startOfDay(for: $0) }
        let uniqueDays = Set(days)

        totalRituals = sessions.count
        daysWithRitual = uniqueDays.count

        let totalGoals = sessions.reduce(0) { $0 + $1.goals.count }
        avgGoalsPerRitual = sessions.isEmpty ? 0 : Double(totalGoals) / Double(sessions.count)

        let totalAnticipations = sessions.reduce(0) { partial, session in
            partial + min(session.anticipatedSituations.count, session.consciousResponses.count)
        }
        avgAnticipationsPerRitual = sessions.isEmpty ? 0 : Double(totalAnticipations) / Double(sessions.count)

        if let firstDate = days.min(), let lastDate = days.max() {
            let dayRange = max((calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0) + 1, 1)
            weeklyAverage = Double(totalRituals) / (Double(dayRange) / 7.0)

            let monthRange = max((calendar.dateComponents([.month], from: firstDate, to: lastDate).month ?? 0) + 1, 1)
            monthlyAverage = Double(totalRituals) / Double(monthRange)
        } else {
            weeklyAverage = 0
            monthlyAverage = 0
        }

        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        let weekdayMap = Dictionary(grouping: days, by: { calendar.component(.weekday, from: $0) })
            .mapValues(\.count)
        weekdayCounts = weekdaySymbols.enumerated().map { index, label in
            let weekday = index + 1
            return WeekdayCount(dayLabel: label, count: weekdayMap[weekday] ?? 0)
        }

        let identityValues = sessions
            .flatMap { $0.identity.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
            .filter { !$0.isEmpty }
        topIdentities = Dictionary(grouping: identityValues, by: { $0 })
            .map { NamedCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }

        let emotionValues = sessions.flatMap { $0.emotions }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        topEmotions = Dictionary(grouping: emotionValues, by: { $0 })
            .map { NamedCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }

        let dailyCounts = Dictionary(grouping: days, by: { $0 }).mapValues(\.count)
        dayPoints = Self.buildDayPoints(days: 30, calendar: calendar, dailyCounts: dailyCounts)

        longestStreak = Self.calculateLongestStreak(from: uniqueDays, calendar: calendar)
        currentStreak = Self.calculateCurrentStreak(from: uniqueDays, calendar: calendar)
    }

    private static func buildDayPoints(days: Int, calendar: Calendar, dailyCounts: [Date: Int]) -> [DayPoint] {
        var points: [DayPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let target = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: target)
            points.append(DayPoint(date: start, count: dailyCounts[start] ?? 0))
        }
        return points
    }

    private static func calculateCurrentStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), days.contains(yesterday) {
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func calculateLongestStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        let sorted = days.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for idx in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[idx - 1], to: sorted[idx]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }

        return best
    }
}

private struct MorningRitualHeadlineCards: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(spacing: 12) {
            Text("Resumen general")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                metricCard(title: "Rituales", value: "\(stats.totalRituals)", subtitle: "Total")
                metricCard(title: "Días activos", value: "\(stats.daysWithRitual)", subtitle: "Con ritual")
            }
            HStack(spacing: 10) {
                metricCard(title: "Racha actual", value: "\(stats.currentStreak)", subtitle: "días")
                metricCard(title: "Mejor racha", value: "\(stats.longestStreak)", subtitle: "días")
            }
            HStack(spacing: 10) {
                metricCard(title: "Prom. semanal", value: String(format: "%.1f", stats.weeklyAverage), subtitle: "rituales")
                metricCard(title: "Metas/ritual", value: String(format: "%.1f", stats.avgGoalsPerRitual), subtitle: "media")
            }
        }
    }

    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MorningRitualWeeklyBars: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distribución semanal")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 10) {
                let maxCount = max(stats.weekdayCounts.map(\ .count).max() ?? 1, 1)
                ForEach(stats.weekdayCounts) { item in
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.85))
                                .frame(height: max(4, geo.size.height * CGFloat(item.count) / CGFloat(maxCount)))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                        .frame(height: 90)

                        Text(item.dayLabel)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MorningRitualTopTagsSection: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Enfoques frecuentes")
                .font(.headline)
                .foregroundStyle(.white)

            sectionRow(title: "Identidades", items: stats.topIdentities)
            sectionRow(title: "Emociones", items: stats.topEmotions)
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionRow(title: String, items: [MorningRitualStatsSnapshot.NamedCount]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.9))

            if items.isEmpty {
                Text("Sin datos")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            Text("\(item.name)  \(item.count)")
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(.white.opacity(0.18))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

private struct MorningRitualTrendSection: View {
    let stats: MorningRitualStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tendencia últimos 30 días")
                .font(.headline)
                .foregroundStyle(.white)

            GeometryReader { geo in
                let points = stats.dayPoints
                let maxCount = max(points.map(\ .count).max() ?? 1, 1)
                let stepX = max(geo.size.width / CGFloat(max(points.count - 1, 1)), 1)

                Path { path in
                    guard !points.isEmpty else { return }
                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height - (CGFloat(point.count) / CGFloat(maxCount) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 90)

            Text("Promedio mensual: \(String(format: "%.1f", stats.monthlyAverage)) rituales")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

//Vista del Hostorial
private struct MorningRitualHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore
    @State private var selectedForNote: MorningRitualSession?
    @State private var expandedSessionId: UUID?
    @State private var searchText: String = ""
    @State private var currentMonth: Date = Date()
    @State private var selectedEpochDay: Int? = nil
    @State private var showCalendar: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.50, blue: 0.45),
                        Color(red: 0.66, green: 0.50, blue: 0.80),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if store.sessions.isEmpty {
                    Text("Aún no hay sesiones guardadas.")
                        .foregroundStyle(.white)
                } else {
                    VStack(spacing: 10) {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showCalendar.toggle()
                                }
                            } label: {
                                Image(systemName: showCalendar ? "calendar.badge.minus" : "calendar")
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                        }

                        TextField("Buscar en metas, identidad, emoción o anticipación", text: $searchText)
                            .morningRitualTextFieldStyle()

                        if showCalendar {
                            MorningRitualHistoryCalendarView(
                                currentMonth: $currentMonth,
                                markedEpochDays: Set(store.sessions.map(\ .sessionDateEpochDay)),
                                selectedEpochDay: $selectedEpochDay
                            )
                        }

                        if let selectedEpochDay {
                            HStack {
                                Text("Filtrando: \(formattedDateFromEpochDay(selectedEpochDay))")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.9))
                                Spacer()
                                Button("Limpiar") {
                                    self.selectedEpochDay = nil
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal, 4)
                        }

                        ScrollView {
                            VStack(spacing: 10) {
                                if filteredSessions.isEmpty {
                                    Text("No hay rituales que coincidan con el filtro.")
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(.top, 10)
                                }

                                ForEach(filteredSessions) { session in
                                    let isExpanded = expandedSessionId == session.id

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(formattedDate(session.completedAtEpochMillis))
                                                .font(.headline)
                                                .foregroundStyle(.white)

                                            Spacer()

                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    expandedSessionId = isExpanded ? nil : session.id
                                                }
                                            } label: {
                                                Label(isExpanded ? "Colapsar" : "Expandir", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                                                    .labelStyle(.iconOnly)
                                                    .foregroundStyle(.white)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        if isExpanded {
                                            detailSection(session)
                                        } else {
                                            Text(summaryText(for: session))
                                                .foregroundStyle(.white.opacity(0.9))
                                                .lineLimit(4)
                                        }

                                        HStack {
                                            Button(session.noteText.isEmpty ? "Crear nota" : "Editar nota") {
                                                selectedForNote = session
                                            }
                                            .buttonStyle(.bordered)

                                            Spacer()

                                            Button("Eliminar", role: .destructive) {
                                                store.deleteSession(sessionId: session.id)
                                                if expandedSessionId == session.id {
                                                    expandedSessionId = nil
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                    .padding(14)
                                    .background(.black.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedSessionId = isExpanded ? nil : session.id
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Historial")
            .toolbar {
                ToolbarItem {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                dismissKeyboard()
            }
            .onChange(of: store.sessions) { _, newSessions in
                if let selectedEpochDay, !newSessions.contains(where: { $0.sessionDateEpochDay == selectedEpochDay }) {
                    self.selectedEpochDay = nil
                }
                if let expandedSessionId, !newSessions.contains(where: { $0.id == expandedSessionId }) {
                    self.expandedSessionId = nil
                }
            }
            .sheet(item: $selectedForNote) { session in
                MorningRitualNoteView(initialText: session.noteText) { note in
                    store.updateNote(sessionId: session.id, noteText: note)
                    selectedForNote = nil
                }
            }
        }
    }

    private var filteredSessions: [MorningRitualSession] {
        let normalizedQuery = normalizedText(searchText)

        return store.sessions.filter { session in
            if let selectedEpochDay, session.sessionDateEpochDay != selectedEpochDay {
                return false
            }

            guard !normalizedQuery.isEmpty else { return true }

            let searchCorpus = [
                session.goals.joined(separator: " "),
                session.identity,
                session.emotions.joined(separator: " "),
                session.anticipatedSituations.joined(separator: " "),
                session.consciousResponses.joined(separator: " ")
            ].joined(separator: " ")

            return normalizedText(searchCorpus).contains(normalizedQuery)
        }
    }

    private func normalizedText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedDateFromEpochDay(_ epochDay: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochDay * 86_400))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func detailSection(_ session: MorningRitualSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            historyItem(title: "Metas", value: session.goals.isEmpty ? "-" : "• " + session.goals.joined(separator: "\n• "))
            historyItem(title: "Identidad", value: session.identity.isEmpty ? "-" : session.identity)
            historyItem(title: "Emociones", value: session.emotions.isEmpty ? "-" : session.emotions.joined(separator: ", "))
            historyItem(title: "Anticipación", value: anticipationText(for: session))
            historyItem(title: "Nota", value: session.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : session.noteText)
        }
    }

    private func historyItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func anticipationText(for session: MorningRitualSession) -> String {
        let count = min(session.anticipatedSituations.count, session.consciousResponses.count)
        guard count > 0 else { return "-" }

        return (0..<count)
            .map { "• \(session.anticipatedSituations[$0]) → \(session.consciousResponses[$0])" }
            .joined(separator: "\n")
    }

    private func summaryText(for session: MorningRitualSession) -> String {
        let goals = session.goals.isEmpty ? "-" : session.goals.joined(separator: " • ")
        let emotions = session.emotions.isEmpty ? "-" : session.emotions.joined(separator: ", ")
        return "Metas: \(goals)\nIdentidad: \(session.identity.isEmpty ? "-" : session.identity)\nEmociones: \(emotions)"
    }

    private func formattedDate(_ millis: Int64) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(millis) / 1_000))
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualHistoryCalendarView: View {
    @Binding var currentMonth: Date
    let markedEpochDays: Set<Int>
    @Binding var selectedEpochDay: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text(monthTitle)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }

                ForEach(daysInMonth.indices, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        let epoch = epochDay(for: date)
                        let isSelected = selectedEpochDay == epoch
                        let hasSession = markedEpochDays.contains(epoch)

                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 18, weight: hasSession ? .bold : .regular, design: .default))
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(hasSession ? Color.white.opacity(0.18) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(hasSession ? .black : .white)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedEpochDay = (selectedEpochDay == epoch) ? nil : epoch
                                }
                            }
                    } else {
                        Color.clear
                            .frame(height: 34)
                    }
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
    }

    private var daysInMonth: [Date?] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        days += range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
        return days
    }

    private func changeMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = next
        }
    }

    private func epochDay(for date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }
}

private struct MorningRitualNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State var initialText: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $initialText)
                    .padding(8)
                    .background(.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Guardar nota") {
                    onSave(initialText)
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .onTapGesture {
                dismissKeyboard()
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.25, blue: 0.35), Color(red: 0.15, green: 0.16, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Nota del ritual")
        }
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

private struct MorningRitualSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MorningRitualStore

    @State private var enabled = false
    @State private var hour = 7
    @State private var minute = 30

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.14, blue: 0.31), Color(red: 0.18, green: 0.32, blue: 0.24)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    Toggle("Activar recordatorio diario", isOn: $enabled)
                        .tint(.green)
                        .foregroundStyle(.white)

                    HStack {
                        Picker("Hora", selection: $hour) {
                            ForEach(0..<24, id: \.self) { value in
                                Text(String(format: "%02d", value)).tag(value)
                            }
                        }
#if os(iOS)
                        .pickerStyle(.wheel)
#endif

                        Picker("Minuto", selection: $minute) {
                            ForEach(0..<60, id: \.self) { value in
                                Text(String(format: "%02d", value)).tag(value)
                            }
                        }
#if os(iOS)
                        .pickerStyle(.wheel)
#endif
                    }
                    .frame(height: 140)

                    Button("Guardar cambios") {
                        store.applySettings(enabled: enabled, hour: hour, minute: minute)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)

                    Spacer()
                }
                .padding(16)
            }
            .onTapGesture {
                dismissKeyboard()
            }
            //.navigationTitle("Ajustes")
            .onAppear {
                enabled = store.settings.enabled
                hour = store.settings.hour
                minute = store.settings.minute
            }
        }
    }

    private func dismissKeyboard() {
#if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}
