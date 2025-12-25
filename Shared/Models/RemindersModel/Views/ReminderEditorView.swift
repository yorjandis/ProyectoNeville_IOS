//
//  ReminderEditorView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

import SwiftUI

// MARK: - UI Mode Enum
enum ReminderEditorMode: String, CaseIterable, Identifiable {
    case interval = "Intervalo"
    case daily = "Diario"
    case date = "Fecha definida"

    var id: String { rawValue }
}

struct ReminderEditorView: View {

    let reminder: StoredReminder? // Si existe, es edición
    let onSave: () -> Void        // Closure al guardar

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var message = ""

    // Modo de edición
    @State private var mode: ReminderEditorMode = .interval

    // Intervalo
    @State private var selectedTime = Time(hour: 0, minute: 5)

    // Diario
    @State private var dailyTime = Date()

    // Fecha definida
    @State private var selectedDate = Date()

    // Alertas
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {

            // Contenido
            Section("Recordatorio") {
                TextField("Título", text: $title, axis: .vertical)
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)
                    .bold()
                    .padding()

                TextField("Contenido", text: $message, axis: .vertical)
                    .font(.system(size: 22))
                    .padding()
                    .frame(minHeight: 100)
            }

            // Frecuencia
            Section("Frecuencia") {
                Picker("Tipo", selection: $mode) {
                    ForEach(ReminderEditorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Selector según modo
            switch mode {

            case .interval:
                intervalSection
                    .contentShape(Rectangle())
                #if os(iOS)
                    .onTapGesture { hideKeyboard() }
                #endif

            case .daily:
                dailySection
                    .contentShape(Rectangle())
                    #if os(iOS)
                    .onTapGesture { hideKeyboard() }
                    #endif

            case .date:
                dateSection
                    .contentShape(Rectangle())
                    #if os(iOS)
                    .onTapGesture { hideKeyboard() }
                    #endif
            }

            // Guardar
            HStack {
                Spacer()
                Button(mode == .date ? "Programar" : "Guardar") {

                    // Cancelar si estamos editando
                    if let reminder {
                        ReminderNotificationManager.shared.cancel(id: reminder.id)
                    }

                    let frequency: ReminderFrequency?

                    switch mode {

                    case .interval:
                        if selectedTime.hour == 0 && selectedTime.minute == 0 {
                            frequency = nil
                        } else {
                            frequency = .interval(
                                hours: selectedTime.hour,
                                minutes: selectedTime.minute
                            )
                        }

                    case .daily:
                        let components = Calendar.current.dateComponents(
                            [.hour, .minute],
                            from: dailyTime
                        )

                        if let h = components.hour, let m = components.minute {
                            frequency = .daily(hour: h, minute: m)
                        } else {
                            frequency = nil
                        }

                    case .date:
                        if selectedDate <= Date() {
                            frequency = nil
                        } else {
                            frequency = .date(selectedDate)
                        }
                    }

                    guard let frequency else {
                        alertMessage = "Debes elegir un tiempo válido para el recordatorio"
                        showAlert = true
                        return
                    }

                    ReminderNotificationManager.shared.scheduleAndStore(
                        title: title,
                        message: message,
                        frequency: frequency
                    )

                    onSave()
                    dismiss()
                }
                .tint(.orange)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle(reminder == nil ? "Nuevo recordatorio" : "Editar")
        .onAppear { loadExisting() }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("La ley"),
                message: Text(alertMessage)
            )
        }
    }

    // Secciones

    private var intervalSection: some View {
        VStack {
            Text("Repetir cada")
                .padding(.bottom, 10)

            TimePickerWheel(time: $selectedTime)
        }
        .frame(maxWidth: .infinity)
    }

    private var dailySection: some View {
        DatePicker(
            "A una hora dada:",
            selection: $dailyTime,
            displayedComponents: .hourAndMinute
        )
    }

    private var dateSection: some View {
        DatePicker(
            "Selecciona fecha y hora",
            selection: $selectedDate,
            in: Date()...,
            displayedComponents: [.date, .hourAndMinute]
        )
    }

    // Cargar edición
    private func loadExisting() {
        guard let reminder else { return }

        title = reminder.title
        message = reminder.message

        switch reminder.frequency {

        case .interval(let h, let m):
            mode = .interval
            selectedTime = Time(hour: h, minute: m)

        case .daily(let h, let m):
            mode = .daily
            dailyTime = Calendar.current.date(
                bySettingHour: h,
                minute: m,
                second: 0,
                of: Date()
            ) ?? Date()

        case .date(let date):
            mode = .date
            selectedDate = date
        }
    }
}

#if os(iOS)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif
