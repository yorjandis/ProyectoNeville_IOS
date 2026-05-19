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

                        TextField("Escribe un título", text: $title, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Contenido") {
                    TextField("Escribe tu entrada", text: $content, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Fecha") {
                    DatePicker("Fecha de creación", selection: $fechaCreacion, displayedComponents: [.date])
                }

                Section("Dirección (Mapas)") {
                    TextField("Ej: Gran Vía 1, Madrid", text: $direccionMapa, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .navigationTitle("Nueva Entrada")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
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
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
