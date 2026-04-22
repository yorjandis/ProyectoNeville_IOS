import SwiftUI
import Combine

private enum MacMorningRitualKeys {
    static let sessionsKey = "morning_ritual_sessions"
}

private struct MacMorningRitualSession: Codable, Identifiable {
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
}

@MainActor
private final class MacMorningRitualStore: ObservableObject {
    @Published private(set) var sessions: [MacMorningRitualSession] = []

    private let defaults: UserDefaults

    init() {
        self.defaults = UserDefaults(suiteName: AppCons.AppGroupName) ?? .standard
        reload()
    }

    var todayCompleted: Bool {
        let today = epochDay(for: Date())
        return sessions.contains { $0.completed && $0.sessionDateEpochDay == today }
    }

    func reload() {
        guard let data = defaults.data(forKey: MacMorningRitualKeys.sessionsKey),
              let decoded = try? JSONDecoder().decode([MacMorningRitualSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = decoded.sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
    }

    func completeToday(goal: String, identity: String, emotion: String, note: String) {
        let cleanGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanIdentity = identity.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmotion = emotion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanGoal.isEmpty, !cleanIdentity.isEmpty, !cleanEmotion.isEmpty else { return }

        let today = epochDay(for: Date())
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)

        let session = MacMorningRitualSession(
            id: UUID(),
            sessionDateEpochDay: today,
            completedAtEpochMillis: nowMillis,
            goals: [cleanGoal],
            identity: cleanIdentity,
            emotions: [cleanEmotion],
            anticipatedSituations: [],
            consciousResponses: [],
            noteText: note,
            completed: true
        )

        sessions.removeAll { $0.sessionDateEpochDay == today }
        sessions.insert(session, at: 0)

        if let encoded = try? JSONEncoder().encode(sessions) {
            defaults.set(encoded, forKey: MacMorningRitualKeys.sessionsKey)
        }
    }

    private func epochDay(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return Int(start.timeIntervalSince1970 / 86_400)
    }
}

struct MacMorningRitualView: View {
    @StateObject private var store = MacMorningRitualStore()

    @State private var goal: String = ""
    @State private var identity: String = ""
    @State private var emotion: String = ""
    @State private var note: String = ""

    private let refreshTimer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ritual Matutino")
                .font(.largeTitle.bold())

            Text("Los datos se guardan en App Group compartido con iOS.")
                .foregroundStyle(.secondary)

            statusCard

            VStack(alignment: .leading, spacing: 10) {
                Text("Completar ritual de hoy")
                    .font(.headline)

                TextField("Meta principal de hoy", text: $goal)
                    .textFieldStyle(.roundedBorder)
                TextField("¿Quién eliges ser hoy?", text: $identity)
                    .textFieldStyle(.roundedBorder)
                TextField("Emoción dominante", text: $emotion)
                    .textFieldStyle(.roundedBorder)

                TextField("Nota opcional", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                HStack {
                    Button("Guardar ritual") {
                        store.completeToday(goal: goal, identity: identity, emotion: emotion, note: note)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Actualizar") {
                        store.reload()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            Text("Historial")
                .font(.headline)

            List(store.sessions.prefix(20)) { session in
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.goals.first ?? "Sin meta")
                        .font(.body.bold())
                    Text("Identidad: \(session.identity)")
                    Text("Emoción: \(session.emotions.first ?? "-")")
                    Text(Date(timeIntervalSince1970: TimeInterval(session.completedAtEpochMillis) / 1000), format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .onAppear {
            store.reload()
        }
        .onReceive(refreshTimer) { _ in
            store.reload()
        }
    }

    private var statusCard: some View {
        HStack {
            Image(systemName: store.todayCompleted ? "checkmark.seal.fill" : "clock.badge.exclamationmark")
                .foregroundStyle(store.todayCompleted ? .green : .orange)
                .font(.title2)
            Text(store.todayCompleted ? "Hoy ya completaste el ritual" : "Ritual de hoy pendiente")
                .font(.headline)
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MacMorningRitualView()
}
