//
//  NewDiarioEntryView.swift
//  Neville_iOS
//
//  Created by Codex on 19/5/26.
//

import SwiftUI

struct NewDiarioEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diarioModel = DiarioModel.shared
    @StateObject private var locationCapture = AgendaLocationCapture()
    @AppStorage(AppCons.UD_setting_DiarioAttachmentImageQuality)
    private var imageQuality = 0.82
    @State private var isCapturingLocation = false
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertTitle = "Ubicación"
    @State private var alertMessage = ""
    @State private var pendingAttachments: [PendingDiaryAttachment] = []
    @State private var savedEntry: Diario?

    @State private var title: String
    @State private var content: String
    @State private var direccionMapa: String
    @State private var capitulo: String
    @State private var emocion: Emociones
    @State private var fechaCreacion: Date

    var onSave: (Date) -> Void

    init(
        title: String = "",
        content: String = "",
        direccionMapa: String = "",
        capitulo: String = "",
        emocion: Emociones = .neutral,
        fechaCreacion: Date = Date.now,
        onSave: @escaping (Date) -> Void = { _ in }
    ) {
        _title = State(initialValue: title)
        _content = State(initialValue: content)
        _direccionMapa = State(initialValue: direccionMapa)
        _capitulo = State(initialValue: capitulo)
        _emocion = State(initialValue: emocion)
        _fechaCreacion = State(initialValue: Calendar.current.startOfDay(for: fechaCreacion))
        self.onSave = onSave
    }

    private func closeEditorView() {
#if os(macOS)
        if let window = NSApp.keyWindow {
            closeWindow(window)
            return
        }
#endif
        dismiss()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Título") {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(Emociones.allCases, id: \.self) { value in
                                Button {
                                    emocion = value
                                } label: {
                                    HStack {
                                        Text(value.localizedTitle)
                                        Text(value.emoji)
                                    }
                                }
                            }
                        } label: {
                            Text(emocion.emoji)
                                .font(.system(size: 36))
                        }
                        .menuStyle(.borderlessButton)
                        .buttonStyle(.plain)

                        TextField("Escribe un título", text: $title, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Contenido") {
                    contentEditor
                }

                attachmentsSection

                Section("Capítulo") {
                    HStack {
                        TextField("Sin capítulo", text: $capitulo, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Menu {
                            Button("Sin capítulo") {
                                capitulo = ""
                            }
                            ForEach(existingChapters, id: \.self) { chapter in
                                Button(chapter) {
                                    capitulo = chapter
                                }
                            }
                        } label: {
                            Image(systemName: "book.closed")
                        }
                        .disabled(existingChapters.isEmpty)
                    }
                }

                Section("Fecha") {
                    DatePicker("Fecha de creación", selection: $fechaCreacion, displayedComponents: [.date])
                }

                Section("Coordenadas (Mapas)") {
                    HStack(spacing: 8) {
                        if isCapturingLocation {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            TextField("Ej: 40.416775,-3.703790", text: $direccionMapa, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button {
                            isCapturingLocation = true
                            locationCapture.captureCurrentAddress { result in
                                isCapturingLocation = false
                                switch result {
                                case .success(let coordinates):
                                    direccionMapa = coordinates
                                case .failure(let error):
                                    alertTitle = "Ubicación"
                                    alertMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        } label: {
                            Label {
                                Text("Coordenadas actuales")
                            } icon: {
                                Image(systemName: direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "location.fill" : "checkmark.circle.fill")
                                    .foregroundStyle(direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.primary : Color.green)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCapturingLocation)
                    }
                }
            }
            .navigationTitle("Nueva Entrada")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        closeEditorView()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await saveEntry() }
                    }
                    .disabled(isSaving)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var existingChapters: [String] {
        Array(Set(diarioModel.getAllItemGET().compactMap { diario in
            let value = (diario.value(forKey: "capitulo") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var contentEditor: some View {
        TextEditor(text: $content)
            .font(.title3)
            .multilineTextAlignment(.leading)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
            )
            .frame(minHeight: 220)
    }

    private var attachmentsSection: some View {
        Section {
            PendingDiaryAttachmentsPicker(attachments: $pendingAttachments)
        } header: {
            Text("Anexos")
        } footer: {
            Text("Los anexos se cifrarán y guardarán junto con la entrada al pulsar Guardar.")
        }
    }

    @MainActor
    private func saveEntry() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = safeTitle.isEmpty ? "Título" : safeTitle
        let finalContent = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nuevo Contenido!" : content
        let normalizedDate = Calendar.current.startOfDay(for: fechaCreacion)

        if savedEntry == nil {
            savedEntry = diarioModel.addItemAndReturn(
                title: finalTitle,
                emocion: emocion,
                content: finalContent,
                fechaCreacion: normalizedDate,
                direccionMapa: direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines),
                capitulo: capitulo
            )
        }

        guard let savedEntry else {
            alertTitle = "No se pudo guardar"
            alertMessage = "No se pudo crear la entrada del Diario. Inténtalo de nuevo."
            showAlert = true
            return
        }

        do {
            while let attachment = pendingAttachments.first {
                try await DiaryAttachmentStore.shared.importData(
                    attachment.data,
                    fileName: attachment.fileName,
                    contentType: attachment.contentType,
                    into: savedEntry,
                    imageQuality: imageQuality
                )
                pendingAttachments.removeFirst()
            }
            onSave(normalizedDate)
            closeEditorView()
        } catch {
            alertTitle = "No se pudieron guardar los anexos"
            alertMessage = "La entrada se guardó, pero quedan anexos pendientes. \(error.localizedDescription)"
            showAlert = true
        }
    }
}
