import Foundation

struct TransformationProtocolConfiguration: Codable, Equatable, Sendable {
    var patternName: String
    var trigger: String
    var automaticThought: String
    var emotion: String
    var oldBehavior: String
    var consequence: String
    var alternativeBehavior: String
    var toleratedEmotion: String
    var identity: String
    var startedAt: Date
    var remindersEnabled: Bool
    var morningMinuteOfDay: Int
    var pauseMinuteOfDay: Int
    var eveningMinuteOfDay: Int

    var patternFormula: String {
        L10n.format(
            "transformation.pattern.formula",
            fallback: "Cuando ocurre {0}, suelo pensar {1}, siento {2} y termino {3}, lo que produce {4}.",
            trigger,
            automaticThought,
            emotion,
            oldBehavior,
            consequence
        )
    }

    var alternativeFormula: String {
        L10n.format(
            "transformation.alternative.formula",
            fallback: "Cuando ocurra {0}, haré {1}, aunque sienta {2}.",
            trigger,
            alternativeBehavior,
            toleratedEmotion
        )
    }
}

struct TransformationProtocolScore: Codable, Equatable, Sendable {
    var awareness = 0
    var pause = 0
    var regulation = 0
    var alternativeBehavior = 0
    var recovery = 0

    var total: Int {
        awareness + pause + regulation + alternativeBehavior + recovery
    }
}

struct TransformationProtocolJournal: Codable, Equatable, Sendable {
    var situation = ""
    var thought = ""
    var emotionAndBody = ""
    var impulse = ""
    var response = ""
    var learning = ""
    var maximumIntensity = 0
    var recoveryMinutes = 0

    var hasContent: Bool {
        !situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !learning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct TransformationProtocolDayEntry: Codable, Identifiable, Equatable, Sendable {
    var id: Int { day }
    let day: Int
    var updatedAt = Date()
    var commitment = ""
    var exerciseNotes = ""
    var morningCompleted = false
    var actionCompleted = false
    var eveningCompleted = false
    var journal = TransformationProtocolJournal()
    var score = TransformationProtocolScore()
    var evidences: [String] = []

    var isCompleted: Bool {
        morningCompleted && actionCompleted && eveningCompleted
    }
}

struct TransformationProtocolPARAEvent: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    var perceivedSignal: String
    var emotion: String
    var alternativeAction: String
    var pauseSeconds: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        perceivedSignal: String,
        emotion: String,
        alternativeAction: String,
        pauseSeconds: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.perceivedSignal = perceivedSignal
        self.emotion = emotion
        self.alternativeAction = alternativeAction
        self.pauseSeconds = pauseSeconds
    }
}

struct TransformationProtocolState: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var configuration: TransformationProtocolConfiguration?
    var entries: [TransformationProtocolDayEntry] = []
    var paraEvents: [TransformationProtocolPARAEvent] = []
    var completedAt: Date?

    static let empty = TransformationProtocolState()
}
