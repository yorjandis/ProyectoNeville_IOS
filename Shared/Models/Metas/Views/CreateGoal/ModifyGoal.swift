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
    @State private var selectedWeeklyDays: Set<GoalWeekday> = []
    
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

    private var supportsDayPeriod: Bool {
        GoalSchedulingRules.supportsDayPeriod(
            scheduleType: goal.goalScheduleType,
            intervalUnit: goal.timeUnit
        )
    }

    private var canEditUnitLabel: Bool {
        !goal.isStarted
    }

    private var canEditWeeklyDays: Bool {
        goal.goalScheduleType == .weekly
            && goal.goalCompletionBasis == .executions
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
            let weekly = GoalsL10n.weeklyCadence(days: selectedWeeklyDays.count)
            cadence = selectedWeeklyDays.isEmpty
                ? weekly
                : "\(weekly) · \(GoalWeeklySchedule.summary(for: selectedWeeklyDays))"
        case .specificDates:
            cadence = GoalsL10n.specificDatesCadence(count: Int(goal.totalUnits))
        }
        if goal.goalScheduleType == .weekly, usesWeeklyTime {
            return GoalsL10n.addingWeeklyTime(
                cadence,
                minutes: GoalWeeklyTime.minutes(from: weeklyTime)
            )
        }
        return GoalsL10n.addingPeriod(
            cadence,
            period: GoalSchedulingRules.normalizedDayPeriod(
                scheduleType: goal.goalScheduleType,
                intervalUnit: goal.timeUnit,
                requestedPeriod: dayPeriod,
                weeklyTimeMinutes: nil
            )
        )
    }

    private var completionSummary: String {
        switch goal.goalCompletionBasis {
        case .executions:
            return GoalsL10n.executionCount(Int(goal.totalUnits))
        case .duration:
            return GoalsL10n.duration(value: goal.durationValueNumber, unit: goal.goalDurationUnit)
        }
    }

    private var protectedScheduleType: String {
        switch goal.goalScheduleType {
        case .interval:
            return GoalsL10n.intervalCadence(
                frequency: goal.frequencyValue,
                unit: goal.timeUnit
            )
        case .weekly:
            return goal.goalScheduleType.label
        case .specificDates:
            return GoalsL10n.specificDatesCadence(count: Int(goal.totalUnits))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(
                        goal.isStarted
                            ? "Puedes actualizar la identidad y la planificación futura. El progreso ya registrado no cambiará."
                            : "La meta todavía no ha comenzado, así que también puedes corregir su unidad de medida.",
                        systemImage: "checkmark.shield"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

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
                    if canEditUnitLabel {
                        TextField("Ej. minutos, páginas, km, vasos", text: $unitLabel)
                            .focused($focusedField, equals: .unitLabel)
                    }

                    if goal.goalScheduleType == .weekly {
                        if canEditWeeklyDays {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Días de ejecución")
                                    .font(.subheadline.weight(.semibold))

                                LazyVGrid(
                                    columns: Array(
                                        repeating: GridItem(.flexible(), spacing: 6),
                                        count: 4
                                    ),
                                    spacing: 6
                                ) {
                                    ForEach(GoalWeekday.mondayFirst) { weekday in
                                        weeklyDayButton(weekday)
                                    }
                                }
                            }
                        } else {
                            LabeledContent(
                                "Días de ejecución",
                                value: GoalWeeklySchedule.summary(for: selectedWeeklyDays)
                            )
                        }

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
                    } else if supportsDayPeriod {
                        Picker("Momento del día", selection: $dayPeriod) {
                            ForEach(GoalDayPeriod.allCases, id: \.self) { period in
                                Text(period.label).tag(period)
                            }
                        }
                    } else {
                        Label(
                            "El propio intervalo determina la ventana de cada ejecución.",
                            systemImage: "info.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Planificación futura", systemImage: "calendar.badge.clock")
                } footer: {
                    if goal.goalScheduleType == .weekly, usesWeeklyTime {
                        Text("La hora fija sustituye al Momento del día. Solo se reprogramarán las ejecuciones pendientes.")
                    } else if goal.goalScheduleType == .weekly, !canEditWeeklyDays {
                        Text("En una meta definida por duración se conservan los días para no alterar su fecha de finalización. El horario sí puede cambiarse con seguridad.")
                    } else if goal.goalScheduleType == .interval, !supportsDayPeriod {
                        Text("Momento del día no se combina con este tipo de intervalo, porque produciría ventanas contradictorias o ambiguas.")
                    } else {
                        Text("Estos cambios se aplicarán únicamente a las ejecuciones pendientes.")
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
                    LabeledContent(
                        "Objetivo por ejecución",
                        value: editedExecutionTarget
                    )
                    LabeledContent(
                        "Tipo de programación",
                        value: protectedScheduleType
                    )
                    LabeledContent(
                        "Finalización",
                        value: completionSummary
                    )
                } header: {
                    Label("Configuración protegida", systemImage: "lock")
                } footer: {
                    Text("Estos valores se mantienen para que las unidades completadas, perdidas y pendientes sigan significando lo mismo.")
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
            self.selectedWeeklyDays = self.goal.effectiveWeeklyDays(from: Date())
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
                weeklyTimeMinutes: usesWeeklyTime ? GoalWeeklyTime.minutes(from: weeklyTime) : nil,
                weeklyDays: canEditWeeklyDays ? selectedWeeklyDays : nil
            )
            try goal.update(title: cleanTitle, description: description.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
        } catch {
            showAlert = true
        }
    }

    private func weeklyDayButton(_ weekday: GoalWeekday) -> some View {
        let isSelected = selectedWeeklyDays.contains(weekday)
        return Button {
            if isSelected {
                guard selectedWeeklyDays.count > 1 else { return }
                selectedWeeklyDays.remove(weekday)
            } else {
                selectedWeeklyDays.insert(weekday)
            }
        } label: {
            Text(weekday.shortLabel)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.22))
        )
        .accessibilityLabel(weekday.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
}
