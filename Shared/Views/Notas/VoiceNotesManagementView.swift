#if os(iOS)
import AVFoundation
import Observation
import Speech
import SwiftUI

enum VoiceNoteAudioStore {
    static func audioURL(for noteID: String) throws -> URL {
        let recordedURL = try recordingURL(for: noteID)
        if FileManager.default.fileExists(atPath: recordedURL.path) {
            return recordedURL
        }

        let synthesizedURL = try synthesizedURL(for: noteID)
        if FileManager.default.fileExists(atPath: synthesizedURL.path) {
            return synthesizedURL
        }
        return recordedURL
    }

    static func recordingURL(for noteID: String) throws -> URL {
        try directory(for: noteID).appendingPathComponent("recording.m4a")
    }

    static func synthesizedURL(for noteID: String) throws -> URL {
        try directory(for: noteID).appendingPathComponent("synthesized.caf")
    }

    static func transcriptURL(for noteID: String) throws -> URL {
        try directory(for: noteID).appendingPathComponent("transcript.txt")
    }

    static func hasAudio(for noteID: String) -> Bool {
        guard let url = try? audioURL(for: noteID) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func removeFiles(for noteID: String) {
        guard let directory = try? directory(for: noteID) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    private static func directory(for noteID: String) throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let safeNoteID = noteID.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? noteID
        let directory = baseURL
            .appendingPathComponent("VoiceNotes", isDirectory: true)
            .appendingPathComponent(safeNoteID, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

@MainActor
@Observable
final class VoiceNoteAudioModel: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private(set) var isRecording = false
    private(set) var recordingStartedAt: Date?
    private(set) var isPlaying = false
    private(set) var isTranscribing = false
    private(set) var duration: TimeInterval = 0
    private(set) var transcript = ""
    var errorMessage: String?

    private let noteID: String
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var pendingRecordingURL: URL?

    init(noteID: String) {
        self.noteID = noteID
        super.init()
        reload()
    }

    var hasAudio: Bool {
        VoiceNoteAudioStore.hasAudio(for: noteID)
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }

    func stopRecording() {
        recorder?.stop()
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
            return
        }

        do {
            let url = try VoiceNoteAudioStore.audioURL(for: noteID)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            guard newPlayer.play() else {
                throw VoiceNoteError.playbackCouldNotStart
            }
            player = newPlayer
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func transcribe(locale: Locale) async -> String? {
        guard !isTranscribing, hasAudio else { return nil }
        isTranscribing = true
        defer { isTranscribing = false }

        do {
            let audioURL = try VoiceNoteAudioStore.audioURL(for: noteID)
            let result = try await OnDeviceSpeechTranscriber.transcribe(
                audioAt: audioURL,
                locale: locale
            )
            let transcriptURL = try VoiceNoteAudioStore.transcriptURL(for: noteID)
            try result.write(to: transcriptURL, atomically: true, encoding: .utf8)
            transcript = result
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func updateTranscript(_ value: String) {
        do {
            let url = try VoiceNoteAudioStore.transcriptURL(for: noteID)
            try value.write(to: url, atomically: true, encoding: .utf8)
            transcript = value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAudio() {
        stopPlayback()
        VoiceNoteAudioStore.removeFiles(for: noteID)
        reload()
    }

    private func startRecording() async {
        do {
            guard await AVAudioApplication.requestRecordPermission() else {
                throw VoiceNoteError.microphonePermissionDenied
            }

            stopPlayback()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)

            let finalURL = try VoiceNoteAudioStore.recordingURL(for: noteID)
            let pendingURL = finalURL.deletingLastPathComponent().appendingPathComponent("pending.m4a")
            try? FileManager.default.removeItem(at: pendingURL)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let newRecorder = try AVAudioRecorder(url: pendingURL, settings: settings)
            newRecorder.delegate = self
            guard newRecorder.record() else {
                throw VoiceNoteError.recordingCouldNotStart
            }

            pendingRecordingURL = pendingURL
            recorder = newRecorder
            isRecording = true
            recordingStartedAt = .now
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reload() {
        guard let audioURL = try? VoiceNoteAudioStore.audioURL(for: noteID),
              FileManager.default.fileExists(atPath: audioURL.path) else {
            duration = 0
            transcript = ""
            return
        }

        duration = (try? AVAudioPlayer(contentsOf: audioURL).duration) ?? 0
        if let transcriptURL = try? VoiceNoteAudioStore.transcriptURL(for: noteID) {
            transcript = (try? String(contentsOf: transcriptURL, encoding: .utf8)) ?? ""
        }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.recorder = nil
                self.pendingRecordingURL = nil
                self.isRecording = false
                self.recordingStartedAt = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                self.reload()
            }

            guard flag, let pendingURL = self.pendingRecordingURL else {
                self.errorMessage = VoiceNoteError.recordingCouldNotStart.localizedDescription
                return
            }

            do {
                let finalURL = try VoiceNoteAudioStore.recordingURL(for: self.noteID)
                if FileManager.default.fileExists(atPath: finalURL.path) {
                    _ = try FileManager.default.replaceItemAt(finalURL, withItemAt: pendingURL)
                } else {
                    try FileManager.default.moveItem(at: pendingURL, to: finalURL)
                }
                if let synthesizedURL = try? VoiceNoteAudioStore.synthesizedURL(for: self.noteID) {
                    try? FileManager.default.removeItem(at: synthesizedURL)
                }
                if let transcriptURL = try? VoiceNoteAudioStore.transcriptURL(for: self.noteID) {
                    try? FileManager.default.removeItem(at: transcriptURL)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.player = nil
            self?.isPlaying = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}


private final class OnDeviceSpeechTranscriber: NSObject, SFSpeechRecognitionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, any Error>?
    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?
    private let callbackQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.ypg.nev.voice-note-transcription"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    static func transcribe(audioAt url: URL, locale: Locale) async throws -> String {
        let session = OnDeviceSpeechTranscriber()
        return try await withTaskCancellationHandler {
            try await session.run(audioAt: url, locale: locale)
        } onCancel: {
            session.cancel()
        }
    }

    private func run(audioAt url: URL, locale: Locale) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.continuation = continuation
            lock.unlock()

            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                guard let self else { return }
                guard status == .authorized else {
                    self.finish(with: .failure(VoiceNoteError.speechPermissionDenied))
                    return
                }
                self.startRecognition(audioAt: url, locale: locale)
            }
        }
    }

    private func startRecognition(audioAt url: URL, locale: Locale) {
        guard let recognizer = SFSpeechRecognizer(locale: locale),
              recognizer.supportsOnDeviceRecognition else {
            finish(with: .failure(VoiceNoteError.onDeviceRecognitionUnavailable))
            return
        }

        recognizer.queue = callbackQueue
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        self.recognizer = recognizer
        task = recognizer.recognitionTask(with: request, delegate: self)
    }

    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        finish(with: .success(recognitionResult.bestTranscription.formattedString))
    }

    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishSuccessfully successfully: Bool
    ) {
        guard !successfully else { return }
        finish(with: .failure(task.error ?? VoiceNoteError.transcriptionFailed))
    }

    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        finish(with: .failure(CancellationError()))
    }

    private func cancel() {
        lock.lock()
        let activeTask = task
        lock.unlock()
        activeTask?.cancel()
    }

    private func finish(with result: Result<String, any Error>) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        task = nil
        recognizer = nil
        lock.unlock()
        continuation.resume(with: result)
    }
}

private enum VoiceNoteError: LocalizedError {
    case microphonePermissionDenied
    case speechPermissionDenied
    case onDeviceRecognitionUnavailable
    case recordingCouldNotStart
    case playbackCouldNotStart
    case transcriptionFailed
    case synthesisVoiceUnavailable
    case synthesisFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "Activa el acceso al micrófono en Ajustes para grabar notas de voz."
        case .speechPermissionDenied:
            "Activa el reconocimiento de voz en Ajustes para transcribir el audio."
        case .onDeviceRecognitionUnavailable:
            "La transcripción local no está disponible para el idioma actual en este dispositivo."
        case .recordingCouldNotStart:
            "No se pudo guardar la grabación."
        case .playbackCouldNotStart:
            "No se pudo reproducir la nota de voz."
        case .transcriptionFailed:
            "No se pudo completar la transcripción de la nota de voz."
        case .synthesisVoiceUnavailable:
            "No hay una voz instalada para el idioma seleccionado."
        case .synthesisFailed:
            "No se pudo generar el audio de la nota en el dispositivo."
        }
    }
}

struct AddVoiceNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var modelNotas: NotasModel

    @State private var title = ""
    @State private var noteText = ""
    @State private var category = ""
    @State private var audioModel: VoiceNoteAudioModel
    @State private var validationMessage: String?
    private let noteID: String

    init() {
        let id = UUID().uuidString
        noteID = id
        _audioModel = State(initialValue: VoiceNoteAudioModel(noteID: id))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título de la nota de voz", text: $title, axis: .vertical)
                } header: {
                    Text("Título")
                } footer: {
                    Text("Obligatorio")
                }

                Section("Nota asociada (opcional)") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                }

                Section("Categoría") {
                    HStack {
                        TextField("Sin categoría", text: $category, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        Menu {
                            Button("Sin categoría") {
                                category = ""
                            }

                            ForEach(existingCategories, id: \.self) { existingCategory in
                                Button(existingCategory) {
                                    category = existingCategory
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                        }
                    }
                }

                Section("Grabación") {
                    VoiceNoteRecordingButton(model: audioModel)
                    if audioModel.hasAudio {
                        VoiceNotePlaybackButton(model: audioModel)
                    }
                }
            }
            .navigationTitle("Nueva nota de voz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        VoiceNoteAudioStore.removeFiles(for: noteID)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                }
            }
            .interactiveDismissDisabled(audioModel.isRecording)
            .alert(
                "Nueva nota de voz",
                isPresented: Binding(
                    get: { validationMessage != nil },
                    set: { if !$0 { validationMessage = nil } }
                )
            ) {
                Button("Aceptar", role: .cancel) {
                    validationMessage = nil
                }
            } message: {
                Text(validationMessage ?? "")
            }
            .voiceNoteErrorAlert(model: audioModel)
        }
    }

    private var existingCategories: [String] {
        Array(Set(modelNotas.notas.compactMap { note in
            let value = (note.value(forKey: "categoria") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "El título es obligatorio."
            return
        }
        guard audioModel.hasAudio else {
            validationMessage = "Graba el audio antes de guardar la nota de voz."
            return
        }

        if modelNotas.addVoiceNote(
            id: noteID,
            title: trimmedTitle,
            note: noteText,
            category: category
        ) {
            modelNotas.getAllNotasToModel()
            dismiss()
        }
    }
}

private enum VoiceTranscriptionLanguage: String, CaseIterable, Identifiable {
    case spanish = "es-ES"
    case english = "en-US"
    case mandarinChinese = "zh-CN"

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .spanish:
            "Español"
        case .english:
            "Inglés"
        case .mandarinChinese:
            "Chino mandarín"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    static var current: Self {
        let identifier = Locale.current.identifier.lowercased()
        if identifier.hasPrefix("en") {
            return .english
        }
        if identifier.hasPrefix("zh") {
            return .mandarinChinese
        }
        return .spanish
    }
}

private final class OnDeviceSpeechSynthesizer: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, any Error>?
    private var synthesizer: AVSpeechSynthesizer?
    private var audioFile: AVAudioFile?
    private var pendingURL: URL?
    private var destinationURL: URL?

    static func synthesize(
        text: String,
        language: VoiceTranscriptionLanguage,
        to destinationURL: URL
    ) async throws {
        let session = OnDeviceSpeechSynthesizer()
        try await withTaskCancellationHandler {
            try await session.run(text: text, language: language, destinationURL: destinationURL)
        } onCancel: {
            session.cancel()
        }
    }

    private func run(
        text: String,
        language: VoiceTranscriptionLanguage,
        destinationURL: URL
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.continuation = continuation
            self.destinationURL = destinationURL
            lock.unlock()

            guard let voice = AVSpeechSynthesisVoice(language: language.rawValue) else {
                finish(.failure(VoiceNoteError.synthesisVoiceUnavailable))
                return
            }

            let pendingURL = destinationURL
                .deletingLastPathComponent()
                .appendingPathComponent("synthesis-pending.caf")
            try? FileManager.default.removeItem(at: pendingURL)
            self.pendingURL = pendingURL

            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate

            let synthesizer = AVSpeechSynthesizer()
            self.synthesizer = synthesizer
            synthesizer.write(utterance) { [weak self] buffer in
                self?.receive(buffer)
            }
        }
    }

    private func receive(_ buffer: AVAudioBuffer) {
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
            finish(.failure(VoiceNoteError.synthesisFailed))
            return
        }

        if pcmBuffer.frameLength == 0 {
            do {
                audioFile = nil
                guard let pendingURL, let destinationURL else {
                    throw VoiceNoteError.synthesisFailed
                }
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: pendingURL, to: destinationURL)
                finish(.success(()))
            } catch {
                finish(.failure(error))
            }
            return
        }

        do {
            if audioFile == nil {
                guard let pendingURL else {
                    throw VoiceNoteError.synthesisFailed
                }
                audioFile = try AVAudioFile(
                    forWriting: pendingURL,
                    settings: pcmBuffer.format.settings,
                    commonFormat: pcmBuffer.format.commonFormat,
                    interleaved: pcmBuffer.format.isInterleaved
                )
            }
            try audioFile?.write(from: pcmBuffer)
        } catch {
            finish(.failure(error))
        }
    }

    private func cancel() {
        lock.lock()
        let synthesizer = self.synthesizer
        lock.unlock()
        synthesizer?.stopSpeaking(at: .immediate)
        finish(.failure(CancellationError()))
    }

    private func finish(_ result: Result<Void, any Error>) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        synthesizer = nil
        audioFile = nil
        let pendingURL = self.pendingURL
        self.pendingURL = nil
        destinationURL = nil
        lock.unlock()

        if case .failure = result, let pendingURL {
            try? FileManager.default.removeItem(at: pendingURL)
        }
        continuation.resume(with: result)
    }
}

struct TextToVoiceNoteConversionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var modelNotas: NotasModel

    @State private var language = VoiceTranscriptionLanguage.current
    @State private var isProcessing = false
    @State private var errorMessage: String?

    let noteID: String
    let title: String
    let text: String
    let category: String
    let isFavorite: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Texto que se convertirá") {
                    Text(text)
                        .textSelection(.enabled)
                }

                Section("Idioma de la voz") {
                    Picker("Idioma", selection: $language) {
                        ForEach(VoiceTranscriptionLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                }

                Section {
                    Button {
                        convert()
                    } label: {
                        if isProcessing {
                            HStack {
                                ProgressView()
                                Text("Generando audio en el dispositivo…")
                            }
                        } else {
                            Label("Convertir en nota de voz", systemImage: "waveform.and.mic")
                        }
                    }
                    .disabled(isProcessing)
                } footer: {
                    Text("La voz y el archivo de audio se generan íntegramente en el dispositivo.")
                }
            }
            .navigationTitle("Convertir a nota de voz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Convertir a nota de voz",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("Aceptar", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func convert() {
        let sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceText.isEmpty else {
            errorMessage = "La nota no contiene texto para convertir."
            return
        }

        isProcessing = true
        Task {
            do {
                let destinationURL = try VoiceNoteAudioStore.synthesizedURL(for: noteID)
                try await OnDeviceSpeechSynthesizer.synthesize(
                    text: sourceText,
                    language: language,
                    to: destinationURL
                )
                if let recordedURL = try? VoiceNoteAudioStore.recordingURL(for: noteID) {
                    try? FileManager.default.removeItem(at: recordedURL)
                }

                guard modelNotas.convertPlainTextNoteToVoice(
                    noteID: noteID,
                    title: title,
                    text: text,
                    category: category,
                    isFavorite: isFavorite
                ) else {
                    try? FileManager.default.removeItem(at: destinationURL)
                    throw VoiceNoteError.synthesisFailed
                }

                modelNotas.getAllNotasToModel()
                dismiss()
            } catch is CancellationError {
                // The view is closing; no user-facing error is needed.
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}

struct VoiceNotesManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var modelNotas: NotasModel
    @State private var audioModel: VoiceNoteAudioModel
    @State private var transcriptResult: VoiceNoteTranscription?
    @State private var transcriptDraft = ""
    @State private var titleDraft: String
    @State private var noteTextDraft: String
    @State private var categoryDraft: String
    @State private var transcriptionLanguage = VoiceTranscriptionLanguage.current
    @State private var validationMessage: String?

    private let noteID: String
    private let isFavorite: Bool

    init(
        noteID: String,
        noteTitle: String,
        noteText: String,
        category: String,
        isFavorite: Bool
    ) {
        self.noteID = noteID
        self.isFavorite = isFavorite
        _titleDraft = State(initialValue: noteTitle)
        _noteTextDraft = State(initialValue: noteText)
        _categoryDraft = State(initialValue: category)
        _audioModel = State(initialValue: VoiceNoteAudioModel(noteID: noteID))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título de la nota de voz", text: $titleDraft, axis: .vertical)
                } header: {
                    Text("Título")
                } footer: {
                    Text("Obligatorio")
                }

                Section("Nota asociada (opcional)") {
                    TextEditor(text: $noteTextDraft)
                        .frame(minHeight: 120)
                }

                Section("Categoría") {
                    HStack {
                        TextField("Sin categoría", text: $categoryDraft, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        Menu {
                            Button("Sin categoría") {
                                categoryDraft = ""
                            }

                            ForEach(existingCategories, id: \.self) { category in
                                Button(category) {
                                    categoryDraft = category
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                        }
                    }
                }

                Section("Audio") {
                    VoiceNotePlaybackButton(model: audioModel)
                    VoiceNoteRecordingButton(model: audioModel)
                }

                Section("Transcripción local") {
                    Picker("Idioma del audio", selection: $transcriptionLanguage) {
                        ForEach(VoiceTranscriptionLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }

                    Button {
                        Task {
                            if let text = await audioModel.transcribe(locale: transcriptionLanguage.locale) {
                                transcriptDraft = text
                                transcriptResult = VoiceNoteTranscription(text: text)
                            }
                        }
                    } label: {
                        if audioModel.isTranscribing {
                            HStack {
                                ProgressView()
                                Text("Transcribiendo en el dispositivo…")
                            }
                        } else {
                            Label("Transcribir audio", systemImage: "captions.bubble")
                        }
                    }
                    .disabled(audioModel.isTranscribing || !audioModel.hasAudio)

                    if !audioModel.transcript.isEmpty {
                        Button("Ver transcripción guardada") {
                            transcriptDraft = audioModel.transcript
                            transcriptResult = VoiceNoteTranscription(text: audioModel.transcript)
                        }
                    }
                }
            }
            .navigationTitle(titleDraft.isEmpty ? "Nota de voz" : titleDraft)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveChanges()
                    }
                }
            }
            .sheet(item: $transcriptResult) { result in
                VoiceNoteTranscriptionView(
                    transcript: $transcriptDraft,
                    onReplaceCurrentNote: {
                        replaceCurrentNote(with: transcriptDraft)
                    },
                    onCreateNewNote: {
                        createNewNote(with: transcriptDraft)
                    },
                    onSaveTranscript: {
                        audioModel.updateTranscript(transcriptDraft)
                        transcriptResult = nil
                    }
                )
            }
            .alert(
                "Gestionar nota de voz",
                isPresented: Binding(
                    get: { validationMessage != nil },
                    set: { if !$0 { validationMessage = nil } }
                )
            ) {
                Button("Aceptar", role: .cancel) {
                    validationMessage = nil
                }
            } message: {
                Text(validationMessage ?? "")
            }
            .voiceNoteErrorAlert(model: audioModel)
        }
    }

    private var existingCategories: [String] {
        Array(Set(modelNotas.notas.compactMap { note in
            let value = (note.value(forKey: "categoria") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func saveChanges() {
        let trimmedTitle = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "El título es obligatorio."
            return
        }

        if modelNotas.updateNota(
            NotaID: noteID,
            newTitle: trimmedTitle,
            newNota: noteTextDraft,
            isfav: isFavorite,
            direccionMapa: "",
            categoria: categoryDraft,
            isChecklist: false,
            checklistItems: [],
            preserveVoiceType: true
        ) {
            titleDraft = trimmedTitle
            modelNotas.getAllNotasToModel()
            dismiss()
        }
    }

    private func replaceCurrentNote(with transcription: String) {
        let updated = modelNotas.updateNota(
            NotaID: noteID,
            newTitle: titleDraft,
            newNota: transcription,
            isfav: isFavorite,
            direccionMapa: "",
            categoria: categoryDraft,
            isChecklist: false,
            checklistItems: [],
            preserveVoiceType: false
        )
        if updated {
            VoiceNoteAudioStore.removeFiles(for: noteID)
            modelNotas.getAllNotasToModel()
            transcriptResult = nil
            dismiss()
        }
    }

    private func createNewNote(with transcription: String) {
        let transcriptionTitle = titleDraft.isEmpty
            ? "Transcripción de nota de voz"
            : "\(titleDraft) · Transcripción"
        if modelNotas.addNote(
            nota: transcription,
            title: transcriptionTitle,
            categoria: categoryDraft
        ) {
            modelNotas.getAllNotasToModel()
            transcriptResult = nil
        }
    }
}

struct VoiceNoteCardControls: View {
    @State private var audioModel: VoiceNoteAudioModel
    let onManage: () -> Void

    init(noteID: String, onManage: @escaping () -> Void) {
        _audioModel = State(initialValue: VoiceNoteAudioModel(noteID: noteID))
        self.onManage = onManage
    }

    var body: some View {
        HStack(spacing: 10) {
            VoiceNotePlaybackButton(model: audioModel)
            VoiceNoteRecordingButton(model: audioModel, compact: true)

            Spacer()

            Button(action: onManage) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .accessibilityLabel("Gestionar nota de voz")
        }
        .voiceNoteErrorAlert(model: audioModel)
    }
}

private struct VoiceNoteRecordingButton: View {
    let model: VoiceNoteAudioModel
    var compact = false

    var body: some View {
        Button {
            Task {
                await model.toggleRecording()
            }
        } label: {
            Label(
                model.isRecording
                    ? "Detener grabación"
                    : (model.hasAudio ? "Reemplazar" : "Grabar audio"),
                systemImage: model.isRecording ? "stop.circle.fill" : "mic.circle.fill"
            )
            .frame(maxWidth: compact ? nil : .infinity, alignment: .leading)
        }
        .foregroundStyle(model.isRecording ? .red : .black)

        if let startedAt = model.recordingStartedAt, !compact {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text("Grabando · \(context.date.timeIntervalSince(startedAt), format: .number.precision(.fractionLength(0))) s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct VoiceNotePlaybackButton: View {
    let model: VoiceNoteAudioModel

    var body: some View {
        Button {
            model.togglePlayback()
        } label: {
            Label(
                model.isPlaying ? "Detener audio" : "Reproducir",
                systemImage: model.isPlaying ? "stop.fill" : "play.fill"
            )
        }
        .foregroundStyle(.black)
        .disabled(!model.hasAudio || model.isRecording)
        .accessibilityLabel(model.isPlaying ? "Detener nota de voz" : "Reproducir nota de voz")

        if model.duration > 0 {
            Text(Duration.seconds(model.duration), format: .time(pattern: .minuteSecond))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct VoiceNoteTranscription: Identifiable {
    let id = UUID()
    let text: String
}

private struct VoiceNoteTranscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var transcript: String
    let onReplaceCurrentNote: () -> Void
    let onCreateNewNote: () -> Void
    let onSaveTranscript: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $transcript)
                    .padding()
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .padding()

                VStack(spacing: 10) {
                    Button("Reemplazar nota actual", action: onReplaceCurrentNote)
                        .buttonStyle(.bordered)
                    Button("Crear nueva nota con la transcripción", action: onCreateNewNote)
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Transcripción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar texto", action: onSaveTranscript)
                }
            }
        }
    }
}

private extension View {
    func voiceNoteErrorAlert(model: VoiceNoteAudioModel) -> some View {
        alert(
            "Nota de voz",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
#endif
