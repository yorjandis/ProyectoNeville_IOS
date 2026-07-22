//
//  ModifyGoal.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI
import CoreData

struct ModifyGoal: View {
    @Environment(\.dismiss) private var dismiss
    
    let goal : GoalEntity
    
    @State private var title : String = ""
    @State private var description: String = ""
    @State private var unitLabel: String = ""
    @State private var dayPeriod: GoalDayPeriod = .anytime
    @State private var usesWeeklyTime = false
    @State private var weeklyTime = GoalWeeklyTime.date(minutes: GoalWeeklyTime.defaultMinutes) ?? Date()
    
    @State private var showAlert: Bool = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case description
        case unitLabel
    }

    private var cleanTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var editedExecutionTarget: String {
        let value = goal.executionValueNumber
        let number = value.rounded() == value
            ? String(Int(value))
            : value.formatted(.number.precision(.fractionLength(0...2)))
        return GoalsL10n.executionTarget(
            value: value,
            number: number,
            label: unitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var editedSchedule: String {
        let cadence: String
        switch goal.goalScheduleType {
        case .interval:
            cadence = GoalsL10n.intervalCadence(frequency: goal.frequencyValue, unit: goal.timeUnit)
        case .weekly:
            let weekly = GoalsL10n.weeklyCadence(days: goal.weeklyDaysValue)
            let selectedDays = goal.selectedWeeklyDays
            cadence = selectedDays.isEmpty
                ? weekly
                : "\(weekly) · \(GoalWeeklySchedule.summary(for: selectedDays))"
        case .specificDates:
            cadence = GoalsL10n.specificDatesCadence(count: Int(goal.totalUnits))
        }
        if goal.goalScheduleType == .weekly, usesWeeklyTime {
            return GoalsL10n.addingWeeklyTime(
                cadence,
                minutes: GoalWeeklyTime.minutes(from: weeklyTime)
            )
        }
        return GoalsL10n.addingPeriod(cadence, period: dayPeriod)
    }

    private var completionSummary: String {
        switch goal.goalCompletionBasis {
        case .executions:
            return GoalsL10n.executionCount(Int(goal.totalUnits))
        case .duration:
            return GoalsL10n.duration(value: goal.durationValueNumber, unit: goal.goalDurationUnit)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título de la meta", text: $title, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .focused($focusedField, equals: .title)
                } header: {
                    Label("Qué quieres lograr", systemImage: "target")
                } footer: {
                    if cleanTitle.isEmpty {
                        Label("El título es obligatorio.", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    TextField("Ej. minutos, páginas, km, vasos", text: $unitLabel)
                        .focused($focusedField, equals: .unitLabel)

                    if goal.goalScheduleType == .weekly {
                        Toggle(
                            "Fijar una hora",
                            isOn: Binding(
                                get: { usesWeeklyTime },
                                set: { isEnabled in
                                    usesWeeklyTime = isEnabled
                                    if isEnabled {
                                        dayPeriod = .anytime
                                    }
                                }
                            )
                        )

                        if usesWeeklyTime {
                            DatePicker(
                                "Hora de ejecución",
                                selection: $weeklyTime,
                                displayedComponents: .hourAndMinute
                            )
                            Label(
                                "La ejecución se podrá marcar durante una hora desde el horario elegido.",
                                systemImage: "clock.badge.checkmark"
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        } else {
                            Picker("Momento del día", selection: $dayPeriod) {
                                ForEach(GoalDayPeriod.allCases, id: \.self) { period in
                                    Text(period.label).tag(period)
                                }
                            }
                        }
                    } else {
                        Picker("Momento del día", selection: $dayPeriod) {
                            ForEach(GoalDayPeriod.allCases, id: \.self) { period in
                                Text(period.label).tag(period)
                            }
                        }
                    }
                } header: {
                    Label("Cómo se registra", systemImage: "calendar.badge.clock")
                } footer: {
                    if goal.goalScheduleType == .weekly, usesWeeklyTime {
                        Text("La hora fija sustituye al Momento del día. El cambio reprogramará las ejecuciones pendientes sin modificar el progreso ya registrado.")
                    } else {
                        Text("Estos cambios se aplicarán también a las ejecuciones pendientes.")
                    }
                }

                Section {
                    TextField("Añade contexto, motivación o instrucciones…", text: $description, axis: .vertical)
                        .lineLimit(3...7)
                        .focused($focusedField, equals: .description)
                } header: {
                    Label("Detalles opcionales", systemImage: "text.alignleft")
                }

                Section {
                    GoalFormSummaryCard(
                        title: title,
                        target: editedExecutionTarget,
                        schedule: editedSchedule,
                        completion: completionSummary,
                        estimatedExecutions: goal.goalCompletionBasis == .duration ? Int(goal.totalUnits) : nil
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Label("Resumen actualizado", systemImage: "checklist")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Editar meta")
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
                        saveChanges()
                    }
                    .disabled(cleanTitle.isEmpty)
                }

#if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        focusedField = nil
                    }
                }
#endif
            }
        }
        .onAppear{
            self.title = self.goal.title ?? ""
            self.description = self.goal.descriptionText ?? ""
            self.unitLabel = self.goal.customUnitLabel ?? ""
            self.dayPeriod = self.goal.goalDayPeriod
            if let minutes = self.goal.weeklyTimeMinutesValue,
               let date = GoalWeeklyTime.date(minutes: minutes) {
                self.usesWeeklyTime = true
                self.weeklyTime = date
                self.dayPeriod = .anytime
            } else {
                self.usesWeeklyTime = false
            }
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("La Ley - Metas"), message: Text("No se ha podido actualizar la meta. Inténtalo de nuevo."))
        }
    }

    private func saveChanges() {
        guard !cleanTitle.isEmpty else { return }
        do {
            goal.updateSchedulingMetadata(
                unitLabel: unitLabel,
                dayPeriod: dayPeriod,
                weeklyTimeMinutes: usesWeeklyTime ? GoalWeeklyTime.minutes(from: weeklyTime) : nil
            )
            try goal.update(title: cleanTitle, description: description.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
        } catch {
            showAlert = true
        }
    }
    
}
