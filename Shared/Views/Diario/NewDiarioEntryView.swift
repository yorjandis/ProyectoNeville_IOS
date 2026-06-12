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
    @State private var isCapturingLocation = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var title: String
    @State private var content: String
    @State private var direccionMapa: String
    @State private var emocion: Emociones
    @State private var fechaCreacion: Date

    var onSave: (Date) -> Void

    init(
        title: String = "",
        content: String = "",
        direccionMapa: String = "",
        emocion: Emociones = .neutral,
        fechaCreacion: Date = Date.now,
        onSave: @escaping (Date) -> Void = { _ in }
    ) {
        _title = State(initialValue: title)
        _content = State(initialValue: content)
        _direccionMapa = State(initialValue: direccionMapa)
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
                                        Text(value.rawValue.capitalized)
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
                                    alertMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        } label: {
                            Label("Coordenadas actuales", systemImage: "location.fill")
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
                        let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalTitle = safeTitle.isEmpty ? "Título" : safeTitle
                        let finalContent = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nuevo Contenido!" : content
                        let normalizedDate = Calendar.current.startOfDay(for: fechaCreacion)

                        let didSave = diarioModel.addItem(
                            title: finalTitle,
                            emocion: emocion,
                            content: finalContent,
                            fechaCreacion: normalizedDate,
                            direccionMapa: direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines)
                        )

                        if didSave {
                            onSave(normalizedDate)
                            closeEditorView()
                        }
                    }
                }
            }
            .alert("Ubicación", isPresented: $showAlert) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
}
