import Foundation
import UserNotifications

actor TransformationProtocolNotificationService {
    static let shared = TransformationProtocolNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let identifiers = [
        "transformation_protocol_morning",
        "transformation_protocol_pause",
        "transformation_protocol_evening"
    ]

    func apply(_ configuration: TransformationProtocolConfiguration) async -> Bool {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        guard configuration.remindersEnabled else { return true }
        guard await requestAuthorizationIfNeeded() else { return false }

        await schedule(
            identifier: identifiers[0],
            minuteOfDay: configuration.morningMinuteOfDay,
            title: L10n.exact("Tu práctica de transformación"),
            body: L10n.exact("Respira, observa el patrón y ensaya hoy tu respuesta elegida.")
        )
        await schedule(
            identifier: identifiers[1],
            minuteOfDay: configuration.pauseMinuteOfDay,
            title: L10n.exact("P.A.R.A."),
            body: L10n.exact("Percibe · Aplaza · Regula · Actúa según tu protocolo.")
        )
        await schedule(
            identifier: identifiers[2],
            minuteOfDay: configuration.eveningMinuteOfDay,
            title: L10n.exact("Cierre del día"),
            body: L10n.exact("Registra un episodio, extrae el aprendizaje y valora el proceso.")
        )
        return true
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func schedule(
        identifier: String,
        minuteOfDay: Int,
        title: String,
        body: String
    ) async {
        var components = DateComponents()
        components.hour = max(0, min(23, minuteOfDay / 60))
        components.minute = max(0, min(59, minuteOfDay % 60))

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["destination": "transformationProtocol"]

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        try? await center.add(request)
    }
}
