#if os(iOS) || os(macOS)
import SwiftUI
@preconcurrency import Translation
import NaturalLanguage

enum NoteTranslationLanguage: String, CaseIterable, Identifiable {
    case spanish
    case english
    case simplifiedChinese

    var id: Self { self }

    var displayName: LocalizedStringKey {
        switch self {
        case .spanish: "Español"
        case .english: "Inglés"
        case .simplifiedChinese: "Chino mandarín"
        }
    }

    var localeLanguage: Locale.Language {
        switch self {
        case .spanish: Locale.Language(identifier: "es")
        case .english: Locale.Language(identifier: "en")
        case .simplifiedChinese: Locale.Language(identifier: "zh-Hans")
        }
    }
}

private enum NoteTranslationSourceLanguage: String, CaseIterable, Identifiable {
    case automatic
    case spanish
    case english
    case simplifiedChinese

    var id: Self { self }

    var displayName: LocalizedStringKey {
        switch self {
        case .automatic: "Detectar automáticamente"
        case .spanish: "Español"
        case .english: "Inglés"
        case .simplifiedChinese: "Chino mandarín"
        }
    }

    var localeLanguage: Locale.Language? {
        switch self {
        case .automatic: nil
        case .spanish: Locale.Language(identifier: "es")
        case .english: Locale.Language(identifier: "en")
        case .simplifiedChinese: Locale.Language(identifier: "zh-Hans")
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct NoteTranslationPreviewView: View {
    let noteID: String
    let noteTitle: String
    let originalText: String
    let isFavorite: Bool
    let address: String
    let category: String
    let isChecklist: Bool
    let preservesConvertibleChecklistStructure: Bool
    let originalChecklistItems: [NotaChecklistItem]

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notesModel: NotasModel

    @State private var translatedText: String
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var pendingTranslationText: String
    @State private var pendingChecklistItems: [NotaChecklistItem]
    @State private var translatedChecklistItems: [NotaChecklistItem]
    @State private var selectedSourceLanguage: NoteTranslationSourceLanguage = .automatic
    @State private var isTranslating = false
    @State private var statusMessage = ""
    @State private var showStatus = false

    init(
        noteID: String,
        noteTitle: String,
        originalText: String,
        isFavorite: Bool,
        address: String,
        category: String,
        isChecklist: Bool,
        checklistItems: [NotaChecklistItem]
    ) {
        let preservesConvertibleChecklistStructure = isChecklist
            || !checklistItems.isEmpty
            || NotaChecklistItem.containsConvertibleNoteBlocks(in: originalText)
        let resolvedChecklistItems: [NotaChecklistItem]
        if preservesConvertibleChecklistStructure {
            resolvedChecklistItems = !checklistItems.isEmpty
                ? checklistItems
                : NotaChecklistItem.fromText(originalText)
        } else {
            resolvedChecklistItems = checklistItems
        }
        let sourceText = preservesConvertibleChecklistStructure
            ? NotaChecklistItem.renderPlainText(resolvedChecklistItems)
            : originalText
        let textToTranslate = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)

        self.noteID = noteID
        self.noteTitle = noteTitle
        self.originalText = originalText
        self.isFavorite = isFavorite
        self.address = address
        self.category = category
        self.isChecklist = isChecklist
        self.preservesConvertibleChecklistStructure = preservesConvertibleChecklistStructure
        self.originalChecklistItems = resolvedChecklistItems
        self._translatedText = State(initialValue: sourceText)
        self._translationConfiguration = State(initialValue: nil)
        self._pendingTranslationText = State(initialValue: textToTranslate)
        self._pendingChecklistItems = State(initialValue: resolvedChecklistItems)
        self._translatedChecklistItems = State(initialValue: resolvedChecklistItems)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [.orange.opacity(0.22), .green.opacity(0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    sourceLanguagePicker
                    translationButtons

                    TextEditor(text: $translatedText)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .disabled(isTranslating)
                }
                    .padding()
                    .padding(.bottom, 70)

                actionsFAB
                    .padding(24)
            }
            .navigationTitle("Vista previa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .overlay {
                if isTranslating {
                    ProgressView("Traduciendo…")
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("Traducción", isPresented: $showStatus) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(statusMessage)
            }
            .translationTask(translationConfiguration) { session in
                let textToTranslate = pendingTranslationText
                isTranslating = true
                do {
                    if preservesConvertibleChecklistStructure {
                        var translatedItems: [NotaChecklistItem] = []
                        for item in pendingChecklistItems {
                            var translatedItem = item
                            if !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                translatedItem.text = try await session.translate(item.text).targetText
                            }
                            translatedItems.append(translatedItem)
                        }
                        translatedChecklistItems = translatedItems
                        translatedText = NotaChecklistItem.renderPlainText(translatedItems)
                    } else {
                        translatedText = try await session.translate(textToTranslate).targetText
                    }
                } catch is CancellationError {
                    // SwiftUI cancels the session when the configuration or view changes.
                } catch {
                    if !Task.isCancelled {
                        presentStatus(
                            String(
                                format: String(localized: "No se pudo traducir el texto: %@"),
                                error.localizedDescription
                            )
                        )
                    }
                }
                isTranslating = false
            }
        }
        .frame(minWidth: 420, minHeight: 520)
    }

    private var sourceLanguagePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Idioma de origen")
                    .font(.subheadline)

                Spacer()

                Picker("Idioma de origen", selection: $selectedSourceLanguage) {
                    ForEach(NoteTranslationSourceLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            if selectedSourceLanguage == .automatic {
                Text("Detectado: \(detectedSourceLanguageName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(isTranslating)
    }

    private var detectedSourceLanguageName: String {
        let detectionText = preservesConvertibleChecklistStructure
            ? NotaChecklistItem.updatingTexts(
                in: translatedChecklistItems,
                toMatchPlainText: translatedText
            ).map(\.text).joined(separator: "\n")
            : translatedText
        guard let identifier = detectedSourceLanguageIdentifier(for: detectionText) else {
            return String(localized: "Sin detectar")
        }
        return Locale.current.localizedString(forLanguageCode: identifier) ?? identifier
    }

    private var translationButtons: some View {
        HStack(spacing: 8) {
            ForEach([
                NoteTranslationLanguage.spanish,
                .simplifiedChinese,
                .english
            ]) { language in
                Button {
                    requestTranslation(to: language, sourceText: translatedText)
                } label: {
                    Text(language.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.42, green: 0.68, blue: 0.90))
            }
        }
        .disabled(isTranslating || translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var actionsFAB: some View {
        Menu {
            Button {
                translatedChecklistItems = originalChecklistItems
                translatedText = preservesConvertibleChecklistStructure
                    ? NotaChecklistItem.renderPlainText(originalChecklistItems)
                    : originalText
            } label: {
                Label("Texto original", systemImage: "arrow.uturn.backward")
            }

            Button {
                replaceCurrentNote()
            } label: {
                Label("Reemplazar nota", systemImage: "arrow.triangle.2.circlepath")
            }

            Menu {
                Button("Nota nueva", systemImage: "note.text.badge.plus") {
                    exportAsNewNote()
                }
                Button("Diario", systemImage: "book.closed") {
                    exportToDiary()
                }
                Button("Agenda", systemImage: "calendar.badge.plus") {
                    exportToAgenda()
                }
                Button("Frase", systemImage: "quote.bubble") {
                    exportToPhrases()
                }
            } label: {
                Label("Exportar a", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [.orange, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.28), radius: 8, y: 5)
        }
        .menuStyle(.borderlessButton)
        .disabled(isTranslating || translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityLabel("Acciones de traducción")
    }

    private func requestTranslation(to language: NoteTranslationLanguage, sourceText: String) {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        pendingTranslationText = text
        if preservesConvertibleChecklistStructure {
            pendingChecklistItems = checklistItems(
                from: text,
                preserving: translatedChecklistItems
            )
        }

        let languageDetectionText = preservesConvertibleChecklistStructure
            ? pendingChecklistItems.map(\.text).joined(separator: "\n")
            : text
        let sourceLanguage = selectedSourceLanguage.localeLanguage
            ?? detectedSourceLanguage(for: languageDetectionText)

        if preservesConvertibleChecklistStructure, sourceLanguage == nil {
            presentStatus(
                L10n.exact("No se pudo detectar el idioma de origen. Selecciónalo manualmente e inténtalo de nuevo.")
            )
            return
        }

        if sourceLanguage == language.localeLanguage {
            presentStatus(
                L10n.exact("El idioma de origen y el idioma de destino son el mismo.")
            )
            return
        }

        isTranslating = true

        if translationConfiguration?.source == sourceLanguage,
           translationConfiguration?.target == language.localeLanguage {
            translationConfiguration?.invalidate()
        } else {
            translationConfiguration = TranslationSession.Configuration(
                source: sourceLanguage,
                target: language.localeLanguage
            )
        }
    }

    private func detectedSourceLanguage(for text: String) -> Locale.Language? {
        guard let identifier = detectedSourceLanguageIdentifier(for: text) else {
            return nil
        }
        return Locale.Language(identifier: identifier)
    }

    private func detectedSourceLanguageIdentifier(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage,
              language != .undetermined else {
            return nil
        }
        return language.rawValue
    }

    private func replaceCurrentNote() {
        let checklistItems = translatedChecklistItemsForSaving()
        let noteText = preservesConvertibleChecklistStructure
            ? NotaChecklistItem.renderPlainText(checklistItems)
            : translatedText
        let success = notesModel.updateNota(
            NotaID: noteID,
            newTitle: noteTitle,
            newNota: noteText,
            isfav: isFavorite,
            direccionMapa: address,
            categoria: category,
            isChecklist: isChecklist,
            checklistItems: checklistItems
        )
        if success {
            notesModel.getAllNotasToModel()
            dismiss()
        } else {
            presentStatus("No se pudo reemplazar la nota.")
        }
    }

    private func exportAsNewNote() {
        let checklistItems = translatedChecklistItemsForSaving().map {
            NotaChecklistItem(text: $0.text, isChecked: $0.isChecked, kind: $0.kind)
        }
        let noteText = preservesConvertibleChecklistStructure
            ? NotaChecklistItem.renderPlainText(checklistItems)
            : translatedText
        presentExportResult(
            notesModel.addNote(
                nota: noteText,
                title: noteTitle,
                isFav: isFavorite,
                direccionMapa: address,
                categoria: category,
                isChecklist: isChecklist,
                checklistItems: checklistItems
            ),
            destination: "Notas"
        )
    }

    private func translatedChecklistItemsForSaving() -> [NotaChecklistItem] {
        guard preservesConvertibleChecklistStructure else { return [] }
        return checklistItems(from: translatedText, preserving: translatedChecklistItems)
    }

    private func checklistItems(
        from text: String,
        preserving items: [NotaChecklistItem]
    ) -> [NotaChecklistItem] {
        NotaChecklistItem.updatingTexts(in: items, toMatchPlainText: text)
    }

    private func exportToDiary() {
        presentExportResult(
            DiarioModel.shared.addItem(
                title: noteTitle,
                emocion: .neutral,
                content: translatedText
            ),
            destination: "Diario"
        )
    }

    private func exportToAgenda() {
        let draft = AgendaInterchangeService.makeAgendaDraft(
            title: noteTitle,
            content: translatedText
        )
        AgendaInterchangeService.saveAgendaItems([draft])
        presentExportResult(true, destination: "Agenda")
    }

    private func exportToPhrases() {
        presentExportResult(
            FrasesModel.shared.AddFrase(frase: translatedText, autor: "personal"),
            destination: "Frases"
        )
    }

    private func presentExportResult(
        _ success: Bool,
        destination: LocalizedStringResource
    ) {
        if success {
            let localizedDestination = String(localized: destination)
            presentStatus(String(localized: "Contenido exportado a \(localizedDestination)."))
        } else {
            presentStatus(String(localized: "No se pudo exportar el contenido."))
        }
    }

    private func presentStatus(_ message: String) {
        statusMessage = message
        showStatus = true
    }
}
#endif
