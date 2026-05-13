import SwiftUI

struct AgendaEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let baseItem: AgendaItemData
    let onSave: (AgendaItemData) -> Void

    @State private var titulo: String
    @State private var fechaActividad: Date
    @State private var hora: Date
    @State private var nota: String
    @State private var lugar: String
    @State private var contenido: String
    @State private var prioridad: AgendaPriority
    @State private var colorHex: String
    @State private var completada: Bool?
    @State private var recordatorioActivo: Bool

    init(baseItem: AgendaItemData, onSave: @escaping (AgendaItemData) -> Void) {
        self.baseItem = baseItem
        self.onSave = onSave
        _titulo = State(initialValue: baseItem.titulo)
        _fechaActividad = State(initialValue: baseItem.fechaActividad)
        _hora = State(initialValue: baseItem.hora)
        _nota = State(initialValue: baseItem.nota)
        _lugar = State(initialValue: baseItem.lugar)
        _contenido = State(initialValue: baseItem.contenido)
        _prioridad = State(initialValue: baseItem.prioridad)
        _colorHex = State(initialValue: baseItem.colorHex)
        _completada = State(initialValue: baseItem.completada)
        _recordatorioActivo = State(initialValue: baseItem.recordatorioActivo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    TextField("Título", text: $titulo)
                    DatePicker("Fecha", selection: $fechaActividad, displayedComponents: .date)
                    DatePicker("Hora", selection: $hora, displayedComponents: .hourAndMinute)
                    TextField("Lugar", text: $lugar)
                }

                Section("Detalles") {
                    TextField("Nota", text: $nota, axis: .vertical)
                    TextField("Contenido", text: $contenido, axis: .vertical)
                }

                Section("Estilo") {
                    Picker("Prioridad", selection: $prioridad) {
                        ForEach(AgendaPriority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                    Picker("Estado", selection: $completada) {
                        Text("No aplicar").tag(Optional<Bool>.none)
                        Text("Activa").tag(Optional(false))
                        Text("Completada").tag(Optional(true))
                    }
                    Toggle("Activar recordatorio", isOn: $recordatorioActivo)
                }
            }
            .navigationTitle(baseItem.titulo.isEmpty ? "Nueva actividad" : "Editar actividad")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let now = Date()
        let item = AgendaItemData(
            id: baseItem.id,
            titulo: titulo,
            fechaCreacion: baseItem.fechaCreacion,
            fechaModificacion: now,
            nota: nota,
            fechaActividad: fechaActividad,
            hora: hora,
            lugar: lugar,
            contenido: contenido,
            prioridad: prioridad,
            colorHex: colorHex,
            completada: completada,
            recordatorioActivo: recordatorioActivo,
            reminderID: baseItem.reminderID
        )
        onSave(item)
        dismiss()
    }
}
