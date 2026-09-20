import CloudKit
import CoreData
import SwiftUI

private struct AppStorageUsageCategory: Identifiable, Sendable {
    let id: String
    let title: String
    let systemImage: String
    let bytes: Int64
    let recordCount: Int
}

private struct AppStorageUsageReport: Sendable {
    let categories: [AppStorageUsageCategory]
    let coreDataDiskBytes: Int64
    let estimatedSyncedBytes: Int64
    let iCloudStatus: String
    let measuredAt: Date

    static let empty = AppStorageUsageReport(
        categories: [],
        coreDataDiskBytes: 0,
        estimatedSyncedBytes: 0,
        iCloudStatus: "Comprobando…",
        measuredAt: .now
    )
}

struct AppStorageUsageView: View {
    @State private var report = AppStorageUsageReport.empty
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            summary

            ForEach(report.categories) { category in
                categoryRow(category)
            }

            Button {
                Task {
                    await reload()
                }
            } label: {
                Label("Actualizar medición", systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)

            Text("El uso local de Core Data es una medición del archivo de base de datos y sus archivos auxiliares. El valor de iCloud es una estimación del contenido local sincronizable; Apple no permite consultar el consumo remoto exacto del contenedor privado.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await reload()
        }
    }

    private var summary: some View {
        VStack(spacing: 8) {
            storageValueRow(
                title: "Core Data en este dispositivo",
                value: formattedBytes(report.coreDataDiskBytes),
                systemImage: "internaldrive"
            )
            storageValueRow(
                title: "Contenido estimado en iCloud",
                value: formattedBytes(report.estimatedSyncedBytes),
                systemImage: "icloud"
            )
            storageValueRow(
                title: "Estado de iCloud",
                value: report.iCloudStatus,
                systemImage: "checkmark.icloud"
            )

            if isLoading {
                ProgressView("Midiendo almacenamiento…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Actualizado (report.measuredAt, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func categoryRow(_ category: AppStorageUsageCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .frame(width: 24)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                Text("(category.recordCount) registros")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedBytes(category.bytes))
                .font(.callout.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }

    private func storageValueRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    @MainActor
    private func reload() async {
        isLoading = true
        let localReport = AppStorageUsageCalculator.measure()
        let iCloudStatus = await AppStorageUsageCalculator.iCloudStatus()
        report = AppStorageUsageReport(
            categories: localReport.categories,
            coreDataDiskBytes: localReport.coreDataDiskBytes,
            estimatedSyncedBytes: localReport.estimatedSyncedBytes,
            iCloudStatus: iCloudStatus,
            measuredAt: .now
        )
        isLoading = false
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

@MainActor
private enum AppStorageUsageCalculator {
    private struct CategoryDefinition {
        let id: String
        let title: String
        let systemImage: String
        let entityNames: [String]
    }

    private static let categories = [
        CategoryDefinition(
            id: "diary",
            title: "Diario y anexos",
            systemImage: "book.closed",
            entityNames: ["Diario", "DiarioAttachment"]
        ),
        CategoryDefinition(
            id: "notes",
            title: "Notas",
            systemImage: "note.text",
            entityNames: ["Notas"]
        ),
        CategoryDefinition(
            id: "goals",
            title: "Metas y revisiones",
            systemImage: "target",
            entityNames: [
                "GoalEntity", "UnitEntity", "ArchivedGoalEntity",
                "ArchivedUnitEntity", "GoalStatsEventEntity", "WeeklyReviewEntity"
            ]
        ),
        CategoryDefinition(
            id: "agenda",
            title: "Agenda",
            systemImage: "calendar",
            entityNames: ["AgendaItemEntity"]
        ),
        CategoryDefinition(
            id: "wellbeing",
            title: "Presencia, rituales y coherencia",
            systemImage: "heart.text.square",
            entityNames: [
                "PresenciaEventEntity", "RitualSessionEntity",
                "coherencia", "CalmUserPhrase"
            ]
        ),
        CategoryDefinition(
            id: "personalContent",
            title: "Frases y contenido personal",
            systemImage: "text.book.closed",
            entityNames: [
                "Frases", "Contexto", "ContextTranslation",
                "PhraseTranslation", "Reflex", "TxtCont"
            ]
        )
    ]

    static func measure() -> AppStorageUsageReport {
        let controller = CoreDataController.shared
        let context = controller.context
        var measuredCategories: [AppStorageUsageCategory] = []

        for definition in categories {
            var bytes: Int64 = 0
            var count = 0

            for entityName in definition.entityNames {
                let measurement = measureEntity(
                    named: entityName,
                    context: context
                )
                bytes += measurement.bytes
                count += measurement.count
            }

            if count > 0 || definition.id == "diary" || definition.id == "notes" || definition.id == "goals" {
                measuredCategories.append(
                    AppStorageUsageCategory(
                        id: definition.id,
                        title: definition.title,
                        systemImage: definition.systemImage,
                        bytes: bytes,
                        recordCount: count
                    )
                )
            }
        }

        return AppStorageUsageReport(
            categories: measuredCategories,
            coreDataDiskBytes: coreDataDiskUsage(controller: controller),
            estimatedSyncedBytes: measuredCategories.reduce(0) { $0 + $1.bytes },
            iCloudStatus: "Comprobando…",
            measuredAt: .now
        )
    }

    static func iCloudStatus() async -> String {
        await withCheckedContinuation { continuation in
            CKContainer(identifier: "iCloud.com.ypg.nev.app.icloud")
                .accountStatus { status, error in
                    guard error == nil else {
                        continuation.resume(returning: "No disponible")
                        return
                    }

                    let description: String
                    switch status {
                    case .available:
                        description = "Disponible"
                    case .noAccount:
                        description = "Sin cuenta"
                    case .restricted:
                        description = "Restringido"
                    case .temporarilyUnavailable:
                        description = "Temporalmente no disponible"
                    case .couldNotDetermine:
                        description = "No determinado"
                    @unknown default:
                        description = "No determinado"
                    }
                    continuation.resume(returning: description)
                }
        }
    }

    private static func measureEntity(
        named entityName: String,
        context: NSManagedObjectContext
    ) -> (bytes: Int64, count: Int) {
        guard let entity = NSEntityDescription.entity(
            forEntityName: entityName,
            in: context
        ) else {
            return (0, 0)
        }

        let attributeNames = entity.attributesByName.values
            .filter { $0.attributeType != .binaryDataAttributeType }
            .map(\.name)

        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = attributeNames
        request.includesPendingChanges = true

        guard let rows = try? context.fetch(request) else {
            return (0, 0)
        }

        var bytes = Int64(rows.count * 128)
        for row in rows {
            for value in row.allValues {
                bytes += estimatedSize(of: value)
            }

            if entityName == "DiarioAttachment",
               let fileSize = row["fileSize"] as? NSNumber {
                bytes += max(0, fileSize.int64Value)
            }
        }

        return (bytes, rows.count)
    }

    private static func estimatedSize(of value: Any) -> Int64 {
        switch value {
        case let string as String:
            return Int64(string.lengthOfBytes(using: .utf8))
        case let data as Data:
            return Int64(data.count)
        case is Date:
            return 8
        case is UUID:
            return 16
        case is NSNumber:
            return 8
        case let url as URL:
            return Int64(url.absoluteString.lengthOfBytes(using: .utf8))
        default:
            return 16
        }
    }

    private static func coreDataDiskUsage(
        controller: CoreDataController
    ) -> Int64 {
        guard let storeURL = controller.persistentContainer
            .persistentStoreCoordinator
            .persistentStores
            .first?
            .url else {
            return 0
        }

        let fileManager = FileManager.default
        let parentURL = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent

        guard let contents = try? fileManager.contentsOfDirectory(
            at: parentURL,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey
            ]
        ) else {
            return 0
        }

        return contents
            .filter { $0.lastPathComponent.hasPrefix(storeName) }
            .reduce(0) { $0 + allocatedSize(of: $1, fileManager: fileManager) }
    }

    private static func allocatedSize(
        of url: URL,
        fileManager: FileManager
    ) -> Int64 {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return 0
        }

        if values.isDirectory == true {
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles]
            ) else {
                return 0
            }

            var total: Int64 = 0
            for case let childURL as URL in enumerator {
                guard let childValues = try? childURL.resourceValues(forKeys: keys),
                      childValues.isDirectory != true else {
                    continue
                }
                total += Int64(
                    childValues.totalFileAllocatedSize
                        ?? childValues.fileAllocatedSize
                        ?? 0
                )
            }
            return total
        }

        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }
}
