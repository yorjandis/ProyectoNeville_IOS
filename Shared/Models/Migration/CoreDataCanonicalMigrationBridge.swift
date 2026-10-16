import Foundation
import CoreData
import UniformTypeIdentifiers
#if os(iOS)
import AVFoundation
#endif

private enum VoiceNoteMigrationField {
    static let audioData = "voiceAudioData"
    static let audioFileExtension = "voiceAudioFileExtension"
}

@MainActor
final class CoreDataCanonicalMigrationBridge {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataController.shared.context) {
        self.context = context
    }

    func exportRecords() async throws -> [CanonicalMigrationRecord] {
        var records: [CanonicalMigrationRecord] = []
        let notes = try fetchNotes()
#if os(iOS)
        try await normalizeVoiceAudioForWirelessSync(in: notes)
#endif
        records += try notes.map(noteRecord)
        let diaryEntries = try fetchDiary()
        records += try diaryEntries.map(diaryRecord)
        for diary in diaryEntries {
            records += try await diaryAttachmentRecords(for: diary)
        }
        records += try fetchObjects(entityName: "AgendaItemEntity").map(agendaRecord)
        records += try fetchGoals().map(goalRecord)
        records += try fetchArchivedGoals().map(archivedGoalRecord)
        records += try fetchPersonalPhrases().map(personalPhraseRecord)
        records += try fetchPersonalReflections().map(personalReflectionRecord)
        records += try ritualRecords()
        records += try fetchObjects(entityName: "CalmUserPhrase").compactMap(calmPhraseRecord)
        return records
    }

    func exportRecords(notes: [Notas]) throws -> [CanonicalMigrationRecord] {
        try notes.map(noteRecord)
    }

    func exportRecords(diaryEntries: [Diario]) async throws -> [CanonicalMigrationRecord] {
        var records = try diaryEntries.map(diaryRecord)
        for diary in diaryEntries {
            records += try await diaryAttachmentRecords(for: diary)
        }
        return records
    }

    func exportRecords(agendaItems: [AgendaItemData]) throws -> [CanonicalMigrationRecord] {
        try agendaItems.map(agendaRecord)
    }

    func exportRecords(personalPhrases: [Frases]) throws -> [CanonicalMigrationRecord] {
        try personalPhrases.filter(\.isPersonal).map(personalPhraseRecord)
    }

#if os(iOS)
    /// Android records and plays AAC in an MPEG-4 container. iOS text-to-speech
    /// notes were historically stored as PCM CAF, so normalize those assets once
    /// before exporting to guarantee playback on both platforms.
    private func normalizeVoiceAudioForWirelessSync(in notes: [Notas]) async throws {
        for note in notes {
            guard let audioData = note.value(forKey: VoiceNoteMigrationField.audioData) as? Data,
                  !audioData.isEmpty,
                  (note.value(forKey: VoiceNoteMigrationField.audioFileExtension) as? String)?
                    .lowercased() == "caf" else {
                continue
            }

            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("voice-note-sync-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let sourceURL = directory.appendingPathComponent("source.caf")
            let destinationURL = directory.appendingPathComponent("normalized.m4a")
            try audioData.write(to: sourceURL, options: [.atomic])
            let asset = AVURLAsset(url: sourceURL)
            guard let exporter = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                throw MigrationError.validation("No se pudo convertir el audio CAF de la nota de voz")
            }
            try await exporter.export(to: destinationURL, as: .m4a)
            let normalizedData = try Data(contentsOf: destinationURL, options: [.mappedIfSafe])
            guard !normalizedData.isEmpty else {
                throw MigrationError.validation("La conversión de la nota de voz produjo audio vacío")
            }

            note.setValue(normalizedData, forKey: VoiceNoteMigrationField.audioData)
            note.setValue("m4a", forKey: VoiceNoteMigrationField.audioFileExtension)

            if let noteID = note.id, !noteID.isEmpty {
                let localURL = try VoiceNoteAudioStore.recordingURL(for: noteID)
                try normalizedData.write(to: localURL, options: [.atomic])
                if let oldURL = try? VoiceNoteAudioStore.synthesizedURL(for: noteID) {
                    try? FileManager.default.removeItem(at: oldURL)
                }
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }
#endif

    func findConflicts(records: [CanonicalMigrationRecord]) async throws -> [ImportConflict] {
        let existing = try await exportRecords()
        return records.compactMap { incoming in
            guard let match = matchingExistingRecord(for: incoming, in: existing) else {
                return nil
            }
            if recordsEquivalent(match, incoming) {
                return ImportConflict(type: incoming.type, recordId: incoming.id, reason: "Ya existe un elemento idéntico; se omitirá")
            }
            return ImportConflict(type: incoming.type, recordId: incoming.id, reason: "Duplicado por ID estable con contenido distinto")
        }
    }

    func importRecords(_ records: [CanonicalMigrationRecord], policy: ImportPolicy) async throws -> MigrationSummary {
        var summary = MigrationSummary()
        do {
            let diaryRecords = records
                .filter { $0.type == MigrationRecordType.diary }
                .reduce(into: [String: CanonicalMigrationRecord]()) { $0[$1.id] = $1 }
            for record in records where record.type != MigrationRecordType.diaryAttachment {
                summary = summary + (try importOne(record, policy: policy))
            }
            for record in records where record.type == MigrationRecordType.diaryAttachment {
                summary = summary + (try await importDiaryAttachment(
                    record,
                    parentRecord: diaryRecords[MigrationJSON.string(record.payload, "parentDiaryId")],
                    policy: policy
                ))
            }
            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
            throw error
        }
        return summary
    }

    private func importOne(_ record: CanonicalMigrationRecord, policy: ImportPolicy) throws -> MigrationSummary {
        switch record.type {
        case MigrationRecordType.note:
            return try importStableRecord(record, existing: try existingNote(for: record).map(noteRecord), policy: policy) {
                try upsertNote(record)
            }
        case MigrationRecordType.diary:
            return try importStableRecord(record, existing: try existingDiary(for: record).map(diaryRecord), policy: policy) {
                try upsertDiary(record)
            }
        case MigrationRecordType.agenda:
            return try importStableRecord(record, existing: try existingAgenda(for: record).map(agendaRecord), policy: policy) {
                try upsertAgenda(record)
            }
        case MigrationRecordType.goal:
            return try importStableRecord(record, existing: try existingGoal(for: record).map(goalRecord), policy: policy) {
                try upsertGoal(record)
            }
        case MigrationRecordType.archivedGoal:
            return try importStableRecord(record, existing: try existingArchivedGoal(for: record).map(archivedGoalRecord), policy: policy) {
                try upsertArchivedGoal(record)
            }
        case MigrationRecordType.personalPhrase:
            return try importAutoRecord(record, existing: fetchPersonalPhrases().map(personalPhraseRecord)) { insertPersonalPhrase(record) }
        case MigrationRecordType.personalReflection:
            return try importAutoRecord(record, existing: fetchPersonalReflections().map(personalReflectionRecord)) { insertPersonalReflection(record) }
        case MigrationRecordType.dayRitualArchive:
            return try importRitual(record)
        case MigrationRecordType.calmPersonalPhrase:
            return try importAutoRecord(record, existing: fetchObjects(entityName: "CalmUserPhrase").compactMap(calmPhraseRecord)) { try insertCalmPhrase(record) }
        default:
            return MigrationSummary(skipped: 1, errors: 1)
        }
    }

    private func importStableRecord(
        _ record: CanonicalMigrationRecord,
        existing: CanonicalMigrationRecord?,
        policy: ImportPolicy,
        upsert: () throws -> Void
    ) throws -> MigrationSummary {
        guard let existing else {
            try upsert()
            return MigrationSummary(inserted: 1)
        }
        if recordsEquivalent(existing, record) {
            return MigrationSummary(skipped: 1)
        }
        switch policy {
        case .skipExisting:
            return MigrationSummary(conflicts: 1)
        case .overwriteExisting:
            try upsert()
            return MigrationSummary(updated: 1)
        case .newerWins:
            let incomingDate = try MigrationFormat.milliseconds(fromISO8601: record.updatedAt)
            let existingDate = try MigrationFormat.milliseconds(fromISO8601: existing.updatedAt)
            if incomingDate > existingDate {
                try upsert()
                return MigrationSummary(updated: 1)
            }
            return incomingDate < existingDate
                ? MigrationSummary(skipped: 1)
                : MigrationSummary(conflicts: 1)
        case .newerWinsIncomingOnTie:
            let incomingDate = try MigrationFormat.milliseconds(fromISO8601: record.updatedAt)
            let existingDate = try MigrationFormat.milliseconds(fromISO8601: existing.updatedAt)
            guard incomingDate >= existingDate else {
                return MigrationSummary(skipped: 1)
            }
            try upsert()
            return MigrationSummary(updated: 1)
        case .newerWinsExistingOnTie:
            let incomingDate = try MigrationFormat.milliseconds(fromISO8601: record.updatedAt)
            let existingDate = try MigrationFormat.milliseconds(fromISO8601: existing.updatedAt)
            guard incomingDate > existingDate else {
                return MigrationSummary(skipped: 1)
            }
            try upsert()
            return MigrationSummary(updated: 1)
        }
    }

    private func importAutoRecord(
        _ record: CanonicalMigrationRecord,
        existing: [CanonicalMigrationRecord],
        insert: () throws -> Void
    ) throws -> MigrationSummary {
        if let match = matchingExistingRecord(for: record, in: existing) {
            return recordsEquivalent(match, record) ? MigrationSummary(skipped: 1) : MigrationSummary(conflicts: 1)
        }
        try insert()
        return MigrationSummary(inserted: 1)
    }

    private func recordsEquivalent(_ left: CanonicalMigrationRecord, _ right: CanonicalMigrationRecord) -> Bool {
        guard left.type == right.type else { return false }

        if left.type == MigrationRecordType.diaryAttachment {
            return left.id == right.id &&
                MigrationJSON.string(left.payload, "sha256") == MigrationJSON.string(right.payload, "sha256") &&
                MigrationJSON.string(left.payload, "parentDiaryId") == MigrationJSON.string(right.payload, "parentDiaryId") &&
                MigrationJSON.string(left.payload, "fileName") == MigrationJSON.string(right.payload, "fileName") &&
                MigrationJSON.string(left.payload, "mimeType") == MigrationJSON.string(right.payload, "mimeType")
        }

        if left.type == MigrationRecordType.note {
            let sameIdentityAndDates: Bool
            if left.id == right.id {
                sameIdentityAndDates = left.createdAt == right.createdAt &&
                    left.updatedAt == right.updatedAt
            } else {
                sameIdentityAndDates = semanticContentKey(for: left) == semanticContentKey(for: right) &&
                    left.createdAt == right.createdAt
            }
            return sameIdentityAndDates && notePayloadsEquivalent(left.payload, right.payload)
        }

        if left.id == right.id {
            return left.createdAt == right.createdAt &&
            left.updatedAt == right.updatedAt &&
            NSDictionary(dictionary: left.payload).isEqual(to: right.payload)
        }

        if let leftKey = semanticContentKey(for: left),
           let rightKey = semanticContentKey(for: right),
           leftKey == rightKey {
            return left.createdAt == right.createdAt &&
                NSDictionary(dictionary: left.payload).isEqual(to: right.payload)
        }

        return false
    }

    /// Peers predating wireless voice-audio support omit these optional keys.
    /// An omitted key means "audio not supplied", not "remove local audio".
    private func notePayloadsEquivalent(_ left: [String: Any], _ right: [String: Any]) -> Bool {
        let commonFieldsMatch = MigrationJSON.string(left, "title") == MigrationJSON.string(right, "title") &&
            MigrationJSON.string(left, "body") == MigrationJSON.string(right, "body") &&
            MigrationJSON.string(left, "category") == MigrationJSON.string(right, "category") &&
            MigrationJSON.bool(left, "favorite") == MigrationJSON.bool(right, "favorite") &&
            MigrationJSON.bool(left, "isChecklist") == MigrationJSON.bool(right, "isChecklist") &&
            MigrationJSON.string(left, "checklistJson") == MigrationJSON.string(right, "checklistJson")
        guard commonFieldsMatch else { return false }

        let audioMatches = left[VoiceNoteMigrationField.audioData] == nil ||
            right[VoiceNoteMigrationField.audioData] == nil ||
            MigrationJSON.string(left, VoiceNoteMigrationField.audioData) ==
                MigrationJSON.string(right, VoiceNoteMigrationField.audioData)
        let extensionMatches = left[VoiceNoteMigrationField.audioFileExtension] == nil ||
            right[VoiceNoteMigrationField.audioFileExtension] == nil ||
            MigrationJSON.string(left, VoiceNoteMigrationField.audioFileExtension) ==
                MigrationJSON.string(right, VoiceNoteMigrationField.audioFileExtension)
        return audioMatches && extensionMatches
    }

    private func matchingExistingRecord(
        for incoming: CanonicalMigrationRecord,
        in existing: [CanonicalMigrationRecord]
    ) -> CanonicalMigrationRecord? {
        if incoming.type == MigrationRecordType.diaryAttachment {
            return existing.first { $0.type == incoming.type && $0.id == incoming.id }
        }
        let incomingContentKey = semanticContentKey(for: incoming)
        let incomingFingerprint = try? incoming.contentFingerprint()

        return existing.first { local in
            guard local.type == incoming.type else { return false }

            if local.id == incoming.id {
                return true
            }

            if let incomingContentKey,
               let localContentKey = semanticContentKey(for: local),
               localContentKey == incomingContentKey {
                return true
            }

            if let incomingFingerprint,
               (try? local.contentFingerprint()) == incomingFingerprint {
                return true
            }

            return false
        }
    }

    private func semanticContentKey(for record: CanonicalMigrationRecord) -> String? {
        switch record.type {
        case MigrationRecordType.note:
            let title = canonicalText(MigrationJSON.string(record.payload, "title"))
            let body = canonicalText(MigrationJSON.string(record.payload, "body"))
            return "\(record.type)|\(title)|\(body)"
        case MigrationRecordType.diary:
            let title = canonicalText(MigrationJSON.string(record.payload, "title"))
            let body = canonicalText(MigrationJSON.string(record.payload, "body"))
            return "\(record.type)|\(title)|\(body)"
        default:
            return nil
        }
    }

    private func canonicalText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension CoreDataCanonicalMigrationBridge {
    func fetchNotes() throws -> [Notas] {
        let request: NSFetchRequest<Notas> = Notas.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "fechaCreacion", ascending: true)]
        return try context.fetch(request)
    }

    func fetchDiary() throws -> [Diario] {
        let request: NSFetchRequest<Diario> = Diario.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "fecha", ascending: true)]
        return try context.fetch(request)
    }

    func fetchDiaryAttachments(for diary: Diario) throws -> [DiarioAttachment] {
        let request = NSFetchRequest<DiarioAttachment>(entityName: "DiarioAttachment")
        request.predicate = NSPredicate(format: "diario == %@", diary)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }

    func diaryAttachmentRecords(for diary: Diario) async throws -> [CanonicalMigrationRecord] {
        let parent = try diaryRecord(diary)
        var records: [CanonicalMigrationRecord] = []
        for attachment in try fetchDiaryAttachments(for: diary) {
            guard let id = attachment.id,
                  let encryptedData = attachment.fileData,
                  let encapsulatedKey = attachment.encapsulatedKey else {
                throw MigrationError.validation("Un anexo del Diario no contiene todos sus datos")
            }
            let clearData = try await DiaryAttachmentCryptor.shared.decrypt(
                DiaryAttachmentPayload(
                    encryptedData: encryptedData,
                    encapsulatedKey: encapsulatedKey
                ),
                attachmentID: id
            )
            let createdAt = iso(attachment.createdAt)
            let updatedAt = iso(attachment.updatedAt ?? attachment.createdAt)
            let mimeType = attachment.utiString
                .flatMap(UTType.init)
                .flatMap(\.preferredMIMEType) ?? "application/octet-stream"
            records.append(
                CanonicalMigrationRecord(
                    type: MigrationRecordType.diaryAttachment,
                    id: id.uuidString.lowercased(),
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    schemaVersion: MigrationFormat.schemaVersion,
                    payload: [
                        "parentDiaryId": parent.id,
                        "fileName": attachment.fileName ?? "Archivo",
                        "mimeType": mimeType,
                        "fileSize": clearData.count,
                        "sha256": MigrationIds.sha256Hex(clearData),
                        "data": MigrationFormat.encodeBase64(clearData)
                    ]
                )
            )
        }
        return records
    }

    func fetchGoals() throws -> [GoalEntity] {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return try context.fetch(request)
    }

    func fetchArchivedGoals() throws -> [ArchivedGoalEntity] {
        let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "completionDate", ascending: true)]
        return try context.fetch(request)
    }

    func fetchPersonalPhrases() throws -> [Frases] {
        let request: NSFetchRequest<Frases> = Frases.fetchRequest()
        request.predicate = NSPredicate(format: "noinbuilt == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "frase", ascending: true)]
        return try context.fetch(request)
    }

    func fetchPersonalReflections() throws -> [Reflex] {
        let request: NSFetchRequest<Reflex> = Reflex.fetchRequest()
        request.predicate = NSPredicate(format: "isInbuilt == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return try context.fetch(request)
    }

    func fetchObjects(entityName: String) throws -> [NSManagedObject] {
        guard context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName] != nil else {
            return []
        }
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        return try context.fetch(request)
    }

    func date(_ value: Date?) -> Date {
        value ?? Date(timeIntervalSince1970: 0)
    }

    func millis(_ date: Date?) -> Int64 {
        Int64((self.date(date).timeIntervalSince1970 * 1000).rounded())
    }

    func iso(_ date: Date?) -> String {
        MigrationFormat.isoString(fromMilliseconds: millis(date))
    }

    func uuidString(_ uuid: UUID?) -> String {
        (uuid ?? UUID()).uuidString.lowercased()
    }
}

private extension CoreDataCanonicalMigrationBridge {
    func noteRecord(_ note: Notas) throws -> CanonicalMigrationRecord {
        let created = iso(note.fechaCreacion)
        let updated = iso(note.fechaModificacion)
        let title = note.title ?? ""
        let body = note.nota ?? ""
        let category = note.categoria ?? ""
        let storedId = note.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let recordId = storedId.isEmpty
            ? try MigrationIds.stableId(type: MigrationRecordType.note, parts: "ios", created)
            : storedId
        var payload: [String: Any] = [
            "title": title,
            "body": body,
            "tags": category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [category],
            "category": category,
            "favorite": note.isfav,
            "isChecklist": note.value(forKey: "isChecklist") as? Bool ?? false,
            "checklistJson": note.value(forKey: "checklistItemsData") as? String ?? ""
        ]
        if let audioData = note.value(forKey: VoiceNoteMigrationField.audioData) as? Data,
           !audioData.isEmpty {
            payload[VoiceNoteMigrationField.audioData] = audioData.base64EncodedString()
            payload[VoiceNoteMigrationField.audioFileExtension] =
                note.value(forKey: VoiceNoteMigrationField.audioFileExtension) as? String ?? ""
        }
        return CanonicalMigrationRecord(
            type: MigrationRecordType.note,
            id: recordId,
            createdAt: created,
            updatedAt: updated,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: payload
        )
    }

    func diaryRecord(_ diary: Diario) throws -> CanonicalMigrationRecord {
        let created = iso(diary.fecha)
        let updated = iso(diary.fechaM)
        let title = diary.title ?? ""
        let body = diary.content ?? ""
        let recordId: String
        if let id = diary.id {
            recordId = id.uuidString.lowercased()
        } else {
            recordId = try MigrationIds.stableId(type: MigrationRecordType.diary, parts: "ios", created)
        }
        return CanonicalMigrationRecord(
            type: MigrationRecordType.diary,
            id: recordId,
            createdAt: created,
            updatedAt: updated,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "title": title,
                "body": body,
                "emotion": diary.emotion ?? "",
                "chapter": diary.capitulo ?? "",
                "favorite": diary.isFav
            ]
        )
    }

    func agendaRecord(_ object: NSManagedObject) throws -> CanonicalMigrationRecord {
        let created = iso(object.value(forKey: "fechaCreacion") as? Date)
        let updated = iso(object.value(forKey: "fechaModificacion") as? Date)
        let id = uuidString(object.value(forKey: "id") as? UUID)
        return CanonicalMigrationRecord(
            type: MigrationRecordType.agenda,
            id: id,
            createdAt: created,
            updatedAt: updated,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "title": object.value(forKey: "titulo") as? String ?? "",
                "note": object.value(forKey: "nota") as? String ?? "",
                "activityDateMillis": millis(object.value(forKey: "fechaActividad") as? Date),
                "activityTimeMillis": millis(object.value(forKey: "hora") as? Date),
                "place": object.value(forKey: "lugar") as? String ?? "",
                "content": object.value(forKey: "contenido") as? String ?? "",
                "priority": object.value(forKey: "prioridad") as? String ?? "",
                "colorHex": object.value(forKey: "colorHex") as? String ?? "",
                "completed": object.value(forKey: "completada") ?? NSNull(),
                "reminderActive": false,
                "reminderId": NSNull()
            ]
        )
    }

    func agendaRecord(_ item: AgendaItemData) throws -> CanonicalMigrationRecord {
        CanonicalMigrationRecord(
            type: MigrationRecordType.agenda,
            id: item.id.uuidString.lowercased(),
            createdAt: iso(item.fechaCreacion),
            updatedAt: iso(item.fechaModificacion),
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "title": item.titulo,
                "note": item.nota,
                "activityDateMillis": millis(item.fechaActividad),
                "activityTimeMillis": millis(item.hora),
                "place": item.lugar,
                "content": item.contenido,
                "priority": item.prioridad.rawValue,
                "colorHex": item.colorHex,
                "completed": item.completada.map { NSNumber(value: $0) } ?? NSNull(),
                "reminderActive": false,
                "reminderId": NSNull()
            ]
        )
    }

    func goalRecord(_ goal: GoalEntity) throws -> CanonicalMigrationRecord {
        let units = goal.unitsArray
        let createdMillis = millis(goal.startDate)
        let updatedMillis = units.compactMap { unit in
            [unit.completedDate, unit.endDate, unit.startDate].compactMap { $0 }.max()
        }.max().map(millis) ?? createdMillis
        return CanonicalMigrationRecord(
            type: MigrationRecordType.goal,
            id: uuidString(goal.id),
            createdAt: MigrationFormat.isoString(fromMilliseconds: createdMillis),
            updatedAt: MigrationFormat.isoString(fromMilliseconds: updatedMillis),
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "title": goal.title ?? "",
                "descriptionText": goal.descriptionText ?? "",
                "totalUnits": Int(goal.totalUnits),
                "unitType": goal.unitType ?? "",
                "frequency": Int(goal.frequency),
                "scheduleType": goal.scheduleType ?? GoalScheduleType.interval.rawValue,
                "weeklyDaysPerWeek": Int(goal.weeklyDaysPerWeek),
                "weeklyDaysMask": Int(goal.weeklyDaysMask),
                "weeklyTimeMinutes": goal.weeklyTimeMinutesValue ?? GoalWeeklyTime.disabledMinutes,
                "dayPeriod": goal.goalDayPeriod.rawValue,
                "customUnitLabel": goal.customUnitLabel ?? "",
                "executionTargetValue": goal.executionTargetValue,
                "completionBasis": goal.completionBasis ?? GoalCompletionBasis.executions.rawValue,
                "durationValue": Int(goal.durationValue),
                "durationUnit": goal.durationUnit ?? TimeUnit.dias.rawValue,
                "isStarted": goal.isStarted,
                "startDate": goal.startDate.map(millis) ?? NSNull(),
                "notifyOnUnitAvailable": false,
                "lastNotifiedUnitIndex": 0,
                "status": units.isEmpty || units.contains { $0.status != "completed" } ? "active" : "completed",
                "units": units.map(unitPayload)
            ]
        )
    }

    func archivedGoalRecord(_ goal: ArchivedGoalEntity) throws -> CanonicalMigrationRecord {
        let created = iso(goal.completionDate)
        let units = (goal.units as? Set<ArchivedUnitEntity> ?? []).sorted { $0.index < $1.index }
        return CanonicalMigrationRecord(
            type: MigrationRecordType.archivedGoal,
            id: uuidString(goal.id),
            createdAt: created,
            updatedAt: created,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "title": goal.title ?? "",
                "descriptionText": goal.descriptionText ?? "",
                "totalUnits": Int(goal.totalUnits),
                "unitType": goal.unitType ?? "",
                "frequency": Int(goal.frequency),
                "scheduleType": goal.scheduleType ?? GoalScheduleType.interval.rawValue,
                "weeklyDaysPerWeek": Int(goal.weeklyDaysPerWeek),
                "weeklyDaysMask": Int(goal.weeklyDaysMask),
                "weeklyTimeMinutes": Int(goal.weeklyTimeMinutes),
                "dayPeriod": goal.dayPeriod ?? GoalDayPeriod.anytime.rawValue,
                "customUnitLabel": goal.customUnitLabel ?? "",
                "executionTargetValue": goal.executionTargetValue,
                "completionBasis": goal.completionBasis ?? GoalCompletionBasis.executions.rawValue,
                "durationValue": Int(goal.durationValue),
                "durationUnit": goal.durationUnit ?? TimeUnit.dias.rawValue,
                "completionDate": millis(goal.completionDate),
                "status": "archived",
                "units": units.map(archivedUnitPayload)
            ]
        )
    }

    func unitPayload(_ unit: UnitEntity) -> [String: Any] {
        [
            "id": uuidString(unit.id),
            "goalId": uuidString(unit.goal?.id),
            "unitIndex": Int(unit.index),
            "status": unit.status ?? "pending",
            "unitType": unit.unitType ?? unit.goal?.unitType ?? "",
            "name": unit.name ?? "",
            "info": unit.info ?? "",
            "note": unit.note ?? "",
            "startDate": unit.startDate.map(millis) ?? NSNull(),
            "endDate": unit.endDate.map(millis) ?? NSNull(),
            "completedDate": unit.completedDate.map(millis) ?? NSNull()
        ]
    }

    func archivedUnitPayload(_ unit: ArchivedUnitEntity) -> [String: Any] {
        [
            "id": uuidString(unit.id),
            "goalId": uuidString(unit.goal?.id),
            "unitIndex": Int(unit.index),
            "status": unit.status ?? "completed",
            "name": unit.name ?? "",
            "info": unit.info ?? "",
            "note": unit.note ?? "",
            "startDate": unit.startDate.map(millis) ?? NSNull(),
            "endDate": unit.endDate.map(millis) ?? NSNull(),
            "completedDate": unit.completedDate.map(millis) ?? NSNull()
        ]
    }

    func personalPhraseRecord(_ phrase: Frases) throws -> CanonicalMigrationRecord {
        let created = MigrationFormat.isoString(fromMilliseconds: 0)
        let text = phrase.frase ?? ""
        let author = phrase.autor ?? ""
        return CanonicalMigrationRecord(
            type: MigrationRecordType.personalPhrase,
            id: try MigrationIds.stableId(type: MigrationRecordType.personalPhrase, parts: text, author),
            createdAt: created,
            updatedAt: created,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "phrase": text,
                "author": author,
                "source": phrase.fuente ?? "",
                "favorite": phrase.isfav,
                "note": phrase.nota ?? "",
                "category": "OTROS"
            ]
        )
    }

    func personalReflectionRecord(_ reflex: Reflex) throws -> CanonicalMigrationRecord {
        let created = MigrationFormat.isoString(fromMilliseconds: 0)
        let title = reflex.title ?? ""
        let content = reflex.texto ?? ""
        return CanonicalMigrationRecord(
            type: MigrationRecordType.personalReflection,
            id: try MigrationIds.stableId(type: MigrationRecordType.personalReflection, parts: created, title, content),
            createdAt: created,
            updatedAt: created,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "title": title,
                "content": content,
                "favorite": reflex.isfav,
                "note": "",
                "author": reflex.autor ?? ""
            ]
        )
    }

    func calmPhraseRecord(_ object: NSManagedObject) throws -> CanonicalMigrationRecord? {
        guard let phrase = (object.value(forKey: "phrase") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !phrase.isEmpty else {
            return nil
        }
        let created = iso(object.value(forKey: "createdAt") as? Date)
        return CanonicalMigrationRecord(
            type: MigrationRecordType.calmPersonalPhrase,
            id: try MigrationIds.stableId(type: MigrationRecordType.calmPersonalPhrase, parts: phrase, created),
            createdAt: created,
            updatedAt: created,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: ["phrase": phrase]
        )
    }
}

private extension CoreDataCanonicalMigrationBridge {
    struct RitualSession: Codable {
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

    func ritualRecords() throws -> [CanonicalMigrationRecord] {
        try loadRitualSessions().map { session in
            let created = MigrationFormat.isoString(fromMilliseconds: session.completedAtEpochMillis)
            let sessionId = try MigrationIds.stableLongId(type: MigrationRecordType.dayRitualArchive, parts: session.id.uuidString, session.completedAtEpochMillis)
            return CanonicalMigrationRecord(
                type: MigrationRecordType.dayRitualArchive,
                id: try MigrationIds.stableId(type: MigrationRecordType.dayRitualArchive, parts: session.id.uuidString, session.completedAtEpochMillis),
                createdAt: created,
                updatedAt: created,
                schemaVersion: MigrationFormat.schemaVersion,
                payload: [
                    "sessionId": sessionId,
                    "diarioId": 0,
                    "createdAtMillis": session.completedAtEpochMillis,
                    "iosSessionId": session.id.uuidString,
                    "sessionDateEpochDay": session.sessionDateEpochDay,
                    "completed": session.completed,
                    "noteText": session.noteText
                ]
            )
        }
    }

    func importRitual(_ record: CanonicalMigrationRecord) throws -> MigrationSummary {
        var sessions = loadRitualSessions()
        let completedAt = MigrationJSON.int64(record.payload, "createdAtMillis", default: try MigrationFormat.milliseconds(fromISO8601: record.createdAt))
        let id = UUID(uuidString: MigrationJSON.string(record.payload, "iosSessionId")) ?? MigrationIds.deterministicUUID(from: record.id)
        if let existing = sessions.first(where: { $0.id == id || $0.completedAtEpochMillis == completedAt }) {
            let existingRecord = try ritualRecord(from: existing)
            return recordsEquivalent(existingRecord, record) ? MigrationSummary(skipped: 1) : MigrationSummary(conflicts: 1)
        }

        let session = RitualSession(
            id: id,
            sessionDateEpochDay: MigrationJSON.int(record.payload, "sessionDateEpochDay", default: Int(completedAt / 86_400_000)),
            completedAtEpochMillis: completedAt,
            goals: [],
            identity: "",
            emotions: [],
            anticipatedSituations: [],
            consciousResponses: [],
            noteText: MigrationJSON.string(record.payload, "noteText"),
            completed: MigrationJSON.bool(record.payload, "completed", default: true)
        )
        sessions.append(session)
        try saveRitualSessions(sessions)
        return MigrationSummary(inserted: 1)
    }

    func ritualRecord(from session: RitualSession) throws -> CanonicalMigrationRecord {
        let created = MigrationFormat.isoString(fromMilliseconds: session.completedAtEpochMillis)
        return CanonicalMigrationRecord(
            type: MigrationRecordType.dayRitualArchive,
            id: try MigrationIds.stableId(type: MigrationRecordType.dayRitualArchive, parts: session.id.uuidString, session.completedAtEpochMillis),
            createdAt: created,
            updatedAt: created,
            schemaVersion: MigrationFormat.schemaVersion,
            payload: [
                "sessionId": try MigrationIds.stableLongId(type: MigrationRecordType.dayRitualArchive, parts: session.id.uuidString, session.completedAtEpochMillis),
                "diarioId": 0,
                "createdAtMillis": session.completedAtEpochMillis,
                "iosSessionId": session.id.uuidString,
                "sessionDateEpochDay": session.sessionDateEpochDay,
                "completed": session.completed,
                "noteText": session.noteText
            ]
        )
    }

    func loadRitualSessions() -> [RitualSession] {
        let keys = ["morning_ritual_sessions"]
        let stores = [UserDefaults(suiteName: AppCons.AppGroupName), .standard].compactMap { $0 }
        for store in stores {
            for key in keys {
                if let data = store.data(forKey: key),
                   let decoded = try? JSONDecoder().decode([RitualSession].self, from: data) {
                    return decoded
                }
            }
        }
        return []
    }

    func saveRitualSessions(_ sessions: [RitualSession]) throws {
        let sorted = sessions.sorted { $0.completedAtEpochMillis > $1.completedAtEpochMillis }
        let data = try JSONEncoder().encode(sorted)
        UserDefaults(suiteName: AppCons.AppGroupName)?.set(data, forKey: "morning_ritual_sessions")
        UserDefaults.standard.set(data, forKey: "morning_ritual_sessions")
    }
}

private extension CoreDataCanonicalMigrationBridge {
    func upsertNote(_ record: CanonicalMigrationRecord) throws {
        let note = try existingNote(for: record) ?? Notas(context: context)
        note.id = record.id
        note.title = MigrationJSON.string(record.payload, "title")
        note.nota = MigrationJSON.string(record.payload, "body")
        note.isfav = MigrationJSON.bool(record.payload, "favorite")
        note.setValue(MigrationJSON.string(record.payload, "category"), forKey: "categoria")
        note.setValue(MigrationJSON.bool(record.payload, "isChecklist"), forKey: "isChecklist")
        note.setValue(MigrationJSON.string(record.payload, "checklistJson"), forKey: "checklistItemsData")
        if record.payload[VoiceNoteMigrationField.audioData] != nil {
            let encodedAudio = MigrationJSON.string(record.payload, VoiceNoteMigrationField.audioData)
            if encodedAudio.isEmpty {
                note.setValue(nil, forKey: VoiceNoteMigrationField.audioData)
            } else {
                guard let audioData = Data(base64Encoded: encodedAudio), !audioData.isEmpty else {
                    throw MigrationError.validation("El audio de la nota de voz no es Base64 válido")
                }
                note.setValue(audioData, forKey: VoiceNoteMigrationField.audioData)
            }
        }
        if record.payload[VoiceNoteMigrationField.audioFileExtension] != nil {
            let fileExtension = MigrationJSON.string(
                record.payload,
                VoiceNoteMigrationField.audioFileExtension
            )
            note.setValue(fileExtension.isEmpty ? nil : fileExtension, forKey: VoiceNoteMigrationField.audioFileExtension)
        } else if record.payload[VoiceNoteMigrationField.audioData] != nil,
                  note.value(forKey: VoiceNoteMigrationField.audioFileExtension) == nil {
            note.setValue("m4a", forKey: VoiceNoteMigrationField.audioFileExtension)
        }
        note.fechaCreacion = try MigrationFormat.date(fromISO8601: record.createdAt)
        note.fechaModificacion = try MigrationFormat.date(fromISO8601: record.updatedAt)
    }

    func upsertDiary(_ record: CanonicalMigrationRecord) throws {
        let diary = try existingDiary(for: record) ?? Diario(context: context)
        diary.id = MigrationIds.deterministicUUID(from: record.id)
        diary.title = MigrationJSON.string(record.payload, "title")
        diary.content = MigrationJSON.string(record.payload, "body")
        diary.emotion = MigrationJSON.string(record.payload, "emotion", default: "neutral")
        diary.capitulo = MigrationJSON.string(record.payload, "chapter")
        diary.isFav = MigrationJSON.bool(record.payload, "favorite")
        diary.fecha = try MigrationFormat.date(fromISO8601: record.createdAt)
        diary.fechaM = try MigrationFormat.date(fromISO8601: record.updatedAt)
    }

    func importDiaryAttachment(
        _ record: CanonicalMigrationRecord,
        parentRecord: CanonicalMigrationRecord?,
        policy: ImportPolicy
    ) async throws -> MigrationSummary {
        guard let parentRecord,
              let diary = try existingDiary(for: parentRecord) else {
            throw MigrationError.validation("El anexo no tiene una entrada del Diario asociada")
        }

        let encodedData = MigrationJSON.string(record.payload, "data")
        let clearData = try MigrationFormat.decodeBase64(encodedData)
        let declaredSize = MigrationJSON.int(record.payload, "fileSize", default: -1)
        guard declaredSize == clearData.count else {
            throw MigrationError.validation("El tamaño declarado del anexo no coincide")
        }
        let incomingDigest = MigrationJSON.string(record.payload, "sha256").lowercased()
        guard !incomingDigest.isEmpty,
              MigrationIds.sha256Hex(clearData) == incomingDigest else {
            throw MigrationError.validation("La huella del anexo no coincide con su contenido")
        }

        let attachmentID = MigrationIds.deterministicUUID(from: record.id)
        let existing = try existingDiaryAttachment(id: attachmentID)
        if let existing {
            let localData = try await decryptedData(for: existing)
            let localDigest = MigrationIds.sha256Hex(localData)
            let existingMimeType = existing.utiString
                .flatMap { UTType($0)?.preferredMIMEType } ?? "application/octet-stream"
            let isEquivalent = localDigest == incomingDigest &&
                existing.fileName == MigrationJSON.string(record.payload, "fileName") &&
                existingMimeType == MigrationJSON.string(record.payload, "mimeType") &&
                existing.diario == diary
            if isEquivalent {
                return MigrationSummary(skipped: 1)
            }

            switch policy {
            case .skipExisting:
                return MigrationSummary(conflicts: 1)
            case .overwriteExisting:
                try await applyAttachment(record, clearData: clearData, id: attachmentID, diary: diary, existing: existing)
                return MigrationSummary(updated: 1)
            case .newerWins:
                let localUpdatedAt = millis(existing.updatedAt ?? existing.createdAt)
                let incomingUpdatedAt = try MigrationFormat.milliseconds(fromISO8601: record.updatedAt)
                guard incomingUpdatedAt != localUpdatedAt else {
                    return MigrationSummary(conflicts: 1)
                }
                if incomingUpdatedAt > localUpdatedAt {
                    try await applyAttachment(record, clearData: clearData, id: attachmentID, diary: diary, existing: existing)
                    return MigrationSummary(updated: 1)
                }
                return MigrationSummary(skipped: 1)
            case .newerWinsIncomingOnTie:
                let localUpdatedAt = millis(existing.updatedAt ?? existing.createdAt)
                let incomingUpdatedAt = try MigrationFormat.milliseconds(fromISO8601: record.updatedAt)
                guard incomingUpdatedAt >= localUpdatedAt else {
                    return MigrationSummary(skipped: 1)
                }
                try await applyAttachment(record, clearData: clearData, id: attachmentID, diary: diary, existing: existing)
                return MigrationSummary(updated: 1)
            case .newerWinsExistingOnTie:
                let localUpdatedAt = millis(existing.updatedAt ?? existing.createdAt)
                let incomingUpdatedAt = try MigrationFormat.milliseconds(fromISO8601: record.updatedAt)
                guard incomingUpdatedAt > localUpdatedAt else {
                    return MigrationSummary(skipped: 1)
                }
                try await applyAttachment(record, clearData: clearData, id: attachmentID, diary: diary, existing: existing)
                return MigrationSummary(updated: 1)
            }
        }

        try await applyAttachment(record, clearData: clearData, id: attachmentID, diary: diary, existing: nil)
        return MigrationSummary(inserted: 1)
    }

    func applyAttachment(
        _ record: CanonicalMigrationRecord,
        clearData: Data,
        id: UUID,
        diary: Diario,
        existing: DiarioAttachment?
    ) async throws {
        let encrypted = try await DiaryAttachmentCryptor.shared.encrypt(clearData, attachmentID: id)
        let attachment = existing ?? DiarioAttachment(context: context)
        let mimeType = MigrationJSON.string(record.payload, "mimeType", default: "application/octet-stream")
        let fileName = MigrationJSON.string(record.payload, "fileName", default: "Archivo")

        attachment.id = id
        attachment.fileName = fileName
        attachment.fileNameEncrip = "\(id.uuidString).nevenc"
        attachment.utiString = UTType(mimeType: mimeType)?.identifier ??
            UTType(filenameExtension: (fileName as NSString).pathExtension)?.identifier ??
            UTType.data.identifier
        attachment.fileSize = Int64(clearData.count)
        attachment.createdAt = try MigrationFormat.date(fromISO8601: record.createdAt)
        attachment.updatedAt = try MigrationFormat.date(fromISO8601: record.updatedAt)
        attachment.cryptoVersion = 1
        attachment.fileData = encrypted.encryptedData
        attachment.encapsulatedKey = encrypted.encapsulatedKey
        attachment.diario = diary

        let incomingUpdatedAt = try MigrationFormat.date(fromISO8601: record.updatedAt)
        if diary.fechaM == nil || diary.fechaM! < incomingUpdatedAt {
            diary.fechaM = incomingUpdatedAt
        }
    }

    func decryptedData(for attachment: DiarioAttachment) async throws -> Data {
        guard let id = attachment.id,
              let encryptedData = attachment.fileData,
              let encapsulatedKey = attachment.encapsulatedKey else {
            throw MigrationError.validation("El anexo local está incompleto")
        }
        return try await DiaryAttachmentCryptor.shared.decrypt(
            DiaryAttachmentPayload(encryptedData: encryptedData, encapsulatedKey: encapsulatedKey),
            attachmentID: id
        )
    }

    func upsertAgenda(_ record: CanonicalMigrationRecord) throws {
        let object = try existingAgenda(for: record) ?? newObject(entityName: "AgendaItemEntity")
        object.setValue(MigrationIds.deterministicUUID(from: record.id), forKey: "id")
        object.setValue(MigrationJSON.string(record.payload, "title"), forKey: "titulo")
        object.setValue(try MigrationFormat.date(fromISO8601: record.createdAt), forKey: "fechaCreacion")
        object.setValue(try MigrationFormat.date(fromISO8601: record.updatedAt), forKey: "fechaModificacion")
        object.setValue(MigrationJSON.string(record.payload, "note"), forKey: "nota")
        object.setValue(Date(timeIntervalSince1970: TimeInterval(MigrationJSON.int64(record.payload, "activityDateMillis")) / 1000), forKey: "fechaActividad")
        object.setValue(Date(timeIntervalSince1970: TimeInterval(MigrationJSON.int64(record.payload, "activityTimeMillis")) / 1000), forKey: "hora")
        object.setValue(MigrationJSON.string(record.payload, "place"), forKey: "lugar")
        object.setValue(MigrationJSON.string(record.payload, "content"), forKey: "contenido")
        object.setValue(MigrationJSON.string(record.payload, "priority"), forKey: "prioridad")
        object.setValue(MigrationJSON.string(record.payload, "colorHex"), forKey: "colorHex")
        object.setValue(record.payload["completed"] is NSNull ? nil : MigrationJSON.bool(record.payload, "completed") as NSNumber, forKey: "completada")
        object.setValue(false, forKey: "recordatorioActivo")
        object.setValue(nil, forKey: "reminderID")
    }

    func upsertGoal(_ record: CanonicalMigrationRecord) throws {
        let goal = try existingGoal(for: record) ?? GoalEntity(context: context)
        goal.id = MigrationIds.deterministicUUID(from: record.id)
        goal.title = MigrationJSON.string(record.payload, "title")
        goal.descriptionText = MigrationJSON.string(record.payload, "descriptionText")
        goal.totalUnits = Int32(MigrationJSON.int(record.payload, "totalUnits"))
        goal.unitType = MigrationJSON.string(record.payload, "unitType")
        goal.frequency = Int32(MigrationJSON.int(record.payload, "frequency", default: 1))
        goal.scheduleType = MigrationJSON.string(record.payload, "scheduleType", default: GoalScheduleType.interval.rawValue)
        goal.weeklyDaysPerWeek = Int16(MigrationJSON.int(record.payload, "weeklyDaysPerWeek", default: 3))
        goal.weeklyDaysMask = Int16(MigrationJSON.int(record.payload, "weeklyDaysMask"))
        goal.weeklyTimeMinutes = Int32(MigrationJSON.int(record.payload, "weeklyTimeMinutes", default: GoalWeeklyTime.disabledMinutes))
        let importedPeriod = GoalDayPeriod(
            rawValue: MigrationJSON.string(record.payload, "dayPeriod", default: GoalDayPeriod.anytime.rawValue)
        ) ?? .anytime
        goal.dayPeriod = GoalSchedulingRules.normalizedDayPeriod(
            scheduleType: goal.goalScheduleType,
            intervalUnit: goal.timeUnit,
            requestedPeriod: importedPeriod,
            weeklyTimeMinutes: goal.weeklyTimeMinutesValue
        ).rawValue
        goal.customUnitLabel = MigrationJSON.string(record.payload, "customUnitLabel")
        goal.executionTargetValue = MigrationJSON.double(record.payload, "executionTargetValue", default: 1)
        goal.completionBasis = MigrationJSON.string(record.payload, "completionBasis", default: GoalCompletionBasis.executions.rawValue)
        goal.durationValue = Int32(MigrationJSON.int(record.payload, "durationValue"))
        goal.durationUnit = MigrationJSON.string(record.payload, "durationUnit", default: TimeUnit.dias.rawValue)
        goal.isStarted = MigrationJSON.bool(record.payload, "isStarted")
        goal.startDate = MigrationJSON.optionalInt64(record.payload, "startDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }

        for unit in goal.unitsArray {
            context.delete(unit)
        }
        for item in record.payload["units"] as? [[String: Any]] ?? [] {
            let unit = UnitEntity(context: context)
            unit.id = MigrationIds.deterministicUUID(from: MigrationJSON.string(item, "id", default: UUID().uuidString))
            unit.index = Int32(MigrationJSON.int(item, "unitIndex"))
            unit.status = MigrationJSON.string(item, "status", default: "pending")
            unit.unitType = MigrationJSON.string(item, "unitType", default: goal.unitType ?? "")
            unit.name = MigrationJSON.string(item, "name")
            unit.info = MigrationJSON.string(item, "info")
            unit.note = MigrationJSON.string(item, "note")
            unit.startDate = MigrationJSON.optionalInt64(item, "startDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            unit.endDate = MigrationJSON.optionalInt64(item, "endDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            unit.completedDate = MigrationJSON.optionalInt64(item, "completedDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            unit.goal = goal
        }
    }

    func upsertArchivedGoal(_ record: CanonicalMigrationRecord) throws {
        let goal = try existingArchivedGoal(for: record) ?? ArchivedGoalEntity(context: context)
        goal.id = MigrationIds.deterministicUUID(from: record.id)
        goal.title = MigrationJSON.string(record.payload, "title")
        goal.descriptionText = MigrationJSON.string(record.payload, "descriptionText")
        goal.totalUnits = Int32(MigrationJSON.int(record.payload, "totalUnits"))
        goal.unitType = MigrationJSON.string(record.payload, "unitType")
        goal.frequency = Int32(MigrationJSON.int(record.payload, "frequency"))
        goal.scheduleType = MigrationJSON.string(record.payload, "scheduleType", default: GoalScheduleType.interval.rawValue)
        goal.weeklyDaysPerWeek = Int16(MigrationJSON.int(record.payload, "weeklyDaysPerWeek", default: 3))
        goal.weeklyDaysMask = Int16(MigrationJSON.int(record.payload, "weeklyDaysMask"))
        goal.weeklyTimeMinutes = Int32(MigrationJSON.int(record.payload, "weeklyTimeMinutes", default: GoalWeeklyTime.disabledMinutes))
        let archivedSchedule = GoalScheduleType(rawValue: goal.scheduleType ?? "") ?? .interval
        let archivedUnit = TimeUnit(rawValue: goal.unitType ?? "") ?? .dias
        let archivedTime = archivedSchedule == .weekly
            ? GoalWeeklyTime.normalized(Int(goal.weeklyTimeMinutes))
            : nil
        let importedArchivedPeriod = GoalDayPeriod(
            rawValue: MigrationJSON.string(record.payload, "dayPeriod", default: GoalDayPeriod.anytime.rawValue)
        ) ?? .anytime
        goal.dayPeriod = GoalSchedulingRules.normalizedDayPeriod(
            scheduleType: archivedSchedule,
            intervalUnit: archivedUnit,
            requestedPeriod: importedArchivedPeriod,
            weeklyTimeMinutes: archivedTime
        ).rawValue
        goal.customUnitLabel = MigrationJSON.string(record.payload, "customUnitLabel")
        goal.executionTargetValue = MigrationJSON.double(record.payload, "executionTargetValue", default: 1)
        goal.completionBasis = MigrationJSON.string(record.payload, "completionBasis", default: GoalCompletionBasis.executions.rawValue)
        goal.durationValue = Int32(MigrationJSON.int(record.payload, "durationValue"))
        goal.durationUnit = MigrationJSON.string(record.payload, "durationUnit", default: TimeUnit.dias.rawValue)
        goal.completionDate = Date(timeIntervalSince1970: TimeInterval(MigrationJSON.int64(record.payload, "completionDate", default: try MigrationFormat.milliseconds(fromISO8601: record.updatedAt))) / 1000)

        for unit in (goal.units as? Set<ArchivedUnitEntity> ?? []) {
            context.delete(unit)
        }
        for item in record.payload["units"] as? [[String: Any]] ?? [] {
            let unit = ArchivedUnitEntity(context: context)
            unit.id = MigrationIds.deterministicUUID(from: MigrationJSON.string(item, "id", default: UUID().uuidString))
            unit.index = Int32(MigrationJSON.int(item, "unitIndex"))
            unit.status = MigrationJSON.string(item, "status", default: "completed")
            unit.name = MigrationJSON.string(item, "name")
            unit.info = MigrationJSON.string(item, "info")
            unit.note = MigrationJSON.string(item, "note")
            unit.startDate = MigrationJSON.optionalInt64(item, "startDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            unit.endDate = MigrationJSON.optionalInt64(item, "endDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            unit.completedDate = MigrationJSON.optionalInt64(item, "completedDate").map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            unit.goal = goal
        }
    }

    func insertPersonalPhrase(_ record: CanonicalMigrationRecord) {
        let phrase = Frases(context: context)
        phrase.id = record.id
        phrase.frase = MigrationJSON.string(record.payload, "phrase")
        phrase.autor = MigrationJSON.string(record.payload, "author")
        phrase.fuente = MigrationJSON.string(record.payload, "source")
        phrase.isfav = MigrationJSON.bool(record.payload, "favorite")
        phrase.nota = MigrationJSON.string(record.payload, "note")
        phrase.noinbuilt = true
        phrase.isnew = true
    }

    func insertPersonalReflection(_ record: CanonicalMigrationRecord) {
        let reflex = Reflex(context: context)
        reflex.id = record.id
        reflex.title = MigrationJSON.string(record.payload, "title")
        reflex.texto = MigrationJSON.string(record.payload, "content")
        reflex.isfav = MigrationJSON.bool(record.payload, "favorite")
        reflex.autor = MigrationJSON.string(record.payload, "author", default: MigrationJSON.string(record.payload, "note"))
        reflex.isInbuilt = false
        reflex.isnew = true
    }

    func insertCalmPhrase(_ record: CanonicalMigrationRecord) throws {
        let object = try newObject(entityName: "CalmUserPhrase")
        object.setValue(MigrationIds.deterministicUUID(from: record.id), forKey: "id")
        object.setValue(MigrationJSON.string(record.payload, "phrase"), forKey: "phrase")
        object.setValue(try MigrationFormat.date(fromISO8601: record.createdAt), forKey: "createdAt")
    }

    func existingAgenda(for record: CanonicalMigrationRecord) throws -> NSManagedObject? {
        try firstObject(entityName: "AgendaItemEntity", uuidKey: "id", uuid: MigrationIds.deterministicUUID(from: record.id))
    }

    func existingNote(for record: CanonicalMigrationRecord) throws -> Notas? {
        for note in try fetchNotes() {
            if try noteRecord(note).id == record.id {
                return note
            }
        }
        return nil
    }

    func existingDiary(for record: CanonicalMigrationRecord) throws -> Diario? {
        let request: NSFetchRequest<Diario> = Diario.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@",
            MigrationIds.deterministicUUID(from: record.id) as CVarArg
        )
        request.fetchLimit = 1
        if let exactMatch = try context.fetch(request).first {
            return exactMatch
        }

        let incomingTitle = canonicalText(MigrationJSON.string(record.payload, "title"))
        let incomingBody = canonicalText(MigrationJSON.string(record.payload, "body"))
        return try fetchDiary().first { diary in
            canonicalText(diary.title ?? "") == incomingTitle &&
                canonicalText(diary.content ?? "") == incomingBody
        }
    }

    func existingDiaryAttachment(id: UUID) throws -> DiarioAttachment? {
        let request = NSFetchRequest<DiarioAttachment>(entityName: "DiarioAttachment")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }

    func existingGoal(for record: CanonicalMigrationRecord) throws -> GoalEntity? {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", MigrationIds.deterministicUUID(from: record.id) as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func existingArchivedGoal(for record: CanonicalMigrationRecord) throws -> ArchivedGoalEntity? {
        let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", MigrationIds.deterministicUUID(from: record.id) as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func firstObject(entityName: String, uuidKey: String, uuid: UUID) throws -> NSManagedObject? {
        guard context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName] != nil else {
            return nil
        }
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", uuidKey, uuid as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func newObject(entityName: String) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw MigrationError.validation("Entidad Core Data no disponible: \(entityName)")
        }
        return NSManagedObject(entity: entity, insertInto: context)
    }
}
