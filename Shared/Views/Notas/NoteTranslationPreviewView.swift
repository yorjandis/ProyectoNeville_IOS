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
    @State private var targetLanguage: NoteTranslationLanguage
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
        category: String,
        initialTarget: NoteTranslationLanguage
    ) {
        self.noteID = noteID
        self.noteTitle = noteTitle
        self.originalText = originalText
        self.isFavorite = isFavorite
        self.address = address
        self.category = category
        self._translatedText = State(initialValue: originalText)
        self._targetLanguage = State(initialValue: initialTarget)
        self._pendingTranslationText = State(initialValue: originalText)
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

                TextEditor(text: $translatedText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding()
                    .padding(.bottom, 70)
                    .disabled(isTranslating)

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
            .task {
                requestTranslation(to: targetLanguage, sourceText: originalText)
            }
            .translationTask(translationConfiguration) { session in
                let textToTranslate = pendingTranslationText
                Task { @MainActor in
                    do {
                        translatedText = try await session.translate(textToTranslate).targetText
                    } catch {
                        presentStatus("No se pudo traducir el texto.")
                    }
                    isTranslating = false
                }
            }
        }
        .frame(minWidth: 420, minHeight: 520)
    }

    private var actionsFAB: some View {
        Menu {
            Menu {
                ForEach(NoteTranslationLanguage.allCases) { language in
                    Button {
                        requestTranslation(to: language, sourceText: translatedText)
                    } label: {
                        Text(language.displayName)
                    }
                }
            } label: {
                Label("Traducir", systemImage: "globe")
            }

            Button {
                replaceCurrentNote()
            } label: {
                Label("Reemplazar", systemImage: "arrow.triangle.2.circlepath")
            }

            Menu {
                Button("Nota nueva", systemImage: "note.text.badge.plus") {
                    importAsNewNote()
                }
                Button("Diario", systemImage: "book.closed") {
                    importToDiary()
                }
                Button("Agenda", systemImage: "calendar.badge.plus") {
                    importToAgenda()
                }
                Button("Frase", systemImage: "quote.bubble") {
                    importToPhrases()
                }
            } label: {
                Label("Importar", systemImage: "square.and.arrow.down")
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

        targetLanguage = language
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

    private func importAsNewNote() {
        presentImportResult(
            notesModel.addNote(nota: translatedText, title: noteTitle),
            destination: "Notas"
        )
    }

    private func importToDiary() {
        presentImportResult(
            DiarioModel.shared.addItem(
                title: noteTitle,
                emocion: .neutral,
                content: translatedText
            ),
            destination: "Diario"
        )
    }

    private func importToAgenda() {
        let draft = AgendaInterchangeService.makeAgendaDraft(
            title: noteTitle,
            content: translatedText
        )
        AgendaInterchangeService.saveAgendaItems([draft])
        presentImportResult(true, destination: "Agenda")
    }

    private func importToPhrases() {
        presentImportResult(
            FrasesModel.shared.AddFrase(frase: translatedText, autor: "personal"),
            destination: "Frases"
        )
    }

    private func presentImportResult(_ success: Bool, destination: String) {
        if success {
            presentStatus("Contenido importado en \(destination).")
        } else {
            presentStatus("No se pudo importar el contenido.")
        }
    }

    private func presentStatus(_ message: String) {
        statusMessage = message
        showStatus = true
    }
}
#endif
