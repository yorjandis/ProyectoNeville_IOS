#if os(iOS) || os(macOS)
import SwiftUI
@preconcurrency import Translation

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

@available(iOS 18.0, macOS 15.0, *)
struct NoteTranslationPreviewView: View {
    let noteID: String
    let noteTitle: String
    let originalText: String
    let isFavorite: Bool
    let address: String
    let category: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notesModel: NotasModel

    @State private var translatedText: String
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var pendingTranslationText: String
    @State private var isTranslating = false
    @State private var statusMessage = ""
    @State private var showStatus = false

    init(
        noteID: String,
        noteTitle: String,
        originalText: String,
        isFavorite: Bool,
        address: String,
        category: String
    ) {
        let textToTranslate = originalText.trimmingCharacters(in: .whitespacesAndNewlines)

        self.noteID = noteID
        self.noteTitle = noteTitle
        self.originalText = originalText
        self.isFavorite = isFavorite
        self.address = address
        self.category = category
        self._translatedText = State(initialValue: originalText)
        self._translationConfiguration = State(initialValue: nil)
        self._pendingTranslationText = State(initialValue: textToTranslate)
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
                    translatedText = try await session.translate(textToTranslate).targetText
                } catch is CancellationError {
                    // SwiftUI cancels the session when the configuration or view changes.
                } catch {
                    if !Task.isCancelled {
                        presentStatus("No se pudo traducir el texto.")
                    }
                }
                isTranslating = false
            }
        }
        .frame(minWidth: 420, minHeight: 520)
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
                translatedText = originalText
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
        isTranslating = true

        if translationConfiguration?.target == language.localeLanguage {
            translationConfiguration?.invalidate()
        } else {
            translationConfiguration = TranslationSession.Configuration(
                source: nil,
                target: language.localeLanguage
            )
        }
    }

    private func replaceCurrentNote() {
        let success = notesModel.updateNota(
            NotaID: noteID,
            newTitle: noteTitle,
            newNota: translatedText,
            isfav: isFavorite,
            direccionMapa: address,
            categoria: category,
            isChecklist: false,
            checklistItems: []
        )
        if success {
            notesModel.getAllNotasToModel()
            dismiss()
        } else {
            presentStatus("No se pudo reemplazar la nota.")
        }
    }

    private func exportAsNewNote() {
        presentExportResult(
            notesModel.addNote(nota: translatedText, title: noteTitle),
            destination: "Notas"
        )
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
