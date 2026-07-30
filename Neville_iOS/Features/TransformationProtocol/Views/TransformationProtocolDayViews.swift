import SwiftUI

struct TransformationProtocolDayDetailView: View {
    @ObservedObject var store: TransformationProtocolStore
    let day: Int

    @State private var entry: TransformationProtocolDayEntry
    @State private var showsMorningPractice = false
    @State private var showsEveningJournal = false
    @State private var showsSavedConfirmation = false

    private let plan: TransformationProtocolDayPlan

    init(store: TransformationProtocolStore, day: Int) {
        self.store = store
        self.day = day
        plan = TransformationProtocolCatalog.days[day - 1]
        _entry = State(initialValue: store.entry(for: day))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                exercise
                commitment
                dailyChecklist
                scoreSummary
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("Día \(day)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") {
                    save()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showsMorningPractice) {
            TransformationProtocolMorningPracticeView {
                entry.morningCompleted = true
                save()
            }
        }
        .sheet(isPresented: $showsEveningJournal, onDismiss: reload) {
            TransformationProtocolEveningJournalView(store: store, day: day)
        }
        .overlay(alignment: .bottom) {
            if showsSavedConfirmation {
                Label("Progreso guardado", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.exact(plan.phase).uppercased(with: AppLanguage.current.locale))
                    .font(.caption.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(TransformationProtocolTheme.violet)
                Text(L10n.exact(plan.title))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.ink)
                Text(L10n.exact(plan.objective))
                    .font(.headline)
                    .foregroundStyle(TransformationProtocolTheme.blue)
                if let principle = plan.principle {
                    Text(L10n.exact(principle))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var exercise: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 14) {
                TransformationProtocolSectionTitle("Ejercicio principal")
                Text(L10n.exact(plan.exercise))
                    .font(.body)
                    .foregroundStyle(TransformationProtocolTheme.ink)

                ForEach(plan.prompts, id: \.self) { prompt in
                    Label {
                        Text(L10n.exact(prompt))
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(TransformationProtocolTheme.blue)
                    }
                }

                Text("Tus notas")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 3)

                TextEditor(text: $entry.exerciseNotes)
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(TransformationProtocolTheme.violet.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
    }

    private var commitment: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 12) {
                TransformationProtocolSectionTitle(
                    "Acción del día",
                    subtitle: L10n.exact(plan.action)
                )
                TransformationProtocolField(
                    title: "Hoy demostraré mi nueva identidad haciendo…",
                    prompt: "Una acción observable",
                    text: $entry.commitment
                )

                Toggle(isOn: $entry.actionCompleted) {
                    Label(
                        L10n.exact(
                            entry.actionCompleted ? "Acción realizada" : "Marcar cuando la realices"
                        ),
                        systemImage: entry.actionCompleted ? "checkmark.seal.fill" : "circle"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .tint(TransformationProtocolTheme.mint)
            }
        }
    }

    private var dailyChecklist: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 12) {
                TransformationProtocolSectionTitle("Rutina base")

                Button {
                    showsMorningPractice = true
                } label: {
                    checklistRow(
                        "Práctica guiada de mañana",
                        subtitle: "21 minutos · versión mínima de 10",
                        done: entry.morningCompleted,
                        icon: "sun.max.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showsEveningJournal = true
                } label: {
                    checklistRow(
                        "Diario nocturno",
                        subtitle: "Seis columnas · medición 0–10",
                        done: entry.eveningCompleted,
                        icon: "moon.stars.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var scoreSummary: some View {
        TransformationProtocolCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Puntuación de proceso")
                        .font(.headline)
                    Text("Conciencia, pausa, regulación, alternativa y recuperación.")
                        .font(.caption)
                        .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                }
                Spacer()
                Text("\(entry.score.total)/10")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.violet)
            }
        }
    }

    private func checklistRow(
        _ title: String,
        subtitle: String,
        done: Bool,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 34, height: 34)
                .foregroundStyle(done ? TransformationProtocolTheme.mint : TransformationProtocolTheme.violet)
                .background(
                    (done ? TransformationProtocolTheme.mint : TransformationProtocolTheme.violet)
                        .opacity(0.10)
                )
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TransformationProtocolTheme.ink)
                Text(L10n.exact(subtitle))
                    .font(.caption)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(
                    done ? TransformationProtocolTheme.mint : Color.gray.opacity(0.55)
                )
        }
        .contentShape(Rectangle())
        .padding(.vertical, 3)
    }

    private func save() {
        store.update(entry)
        withAnimation {
            showsSavedConfirmation = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation {
                showsSavedConfirmation = false
            }
        }
    }

    private func reload() {
        entry = store.entry(for: day)
    }
}

struct TransformationProtocolEveningJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TransformationProtocolStore
    let day: Int

    @State private var entry: TransformationProtocolDayEntry

    init(store: TransformationProtocolStore, day: Int) {
        self.store = store
        self.day = day
        _entry = State(initialValue: store.entry(for: day))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TransformationProtocolCard {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("No busques una puntuación perfecta.")
                                .font(.headline)
                                .foregroundStyle(TransformationProtocolTheme.ink)
                            Text("Registra el episodio más relevante y usa los números para detectar tendencias.")
                                .font(.subheadline)
                                .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                        }
                    }

                    journalFields
                    measurements

                    Button(action: save) {
                        Label("Guardar cierre del día", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TransformationProtocolTheme.violet)
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(TransformationProtocolTheme.background.ignoresSafeArea())
            .navigationTitle("Diario · Día \(day)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private var journalFields: some View {
        TransformationProtocolCard {
            VStack(spacing: 14) {
                TransformationProtocolField(
                    title: "1. Situación",
                    prompt: "¿Qué ocurrió?",
                    text: $entry.journal.situation
                )
                TransformationProtocolField(
                    title: "2. Pensamiento",
                    prompt: "¿Qué interpretación apareció?",
                    text: $entry.journal.thought
                )
                TransformationProtocolField(
                    title: "3. Emoción y cuerpo",
                    prompt: "¿Qué sentiste y dónde?",
                    text: $entry.journal.emotionAndBody
                )
                TransformationProtocolField(
                    title: "4. Impulso",
                    prompt: "¿Qué querías hacer?",
                    text: $entry.journal.impulse
                )
                TransformationProtocolField(
                    title: "5. Respuesta",
                    prompt: "¿Qué hiciste realmente?",
                    text: $entry.journal.response
                )
                TransformationProtocolField(
                    title: "6. Aprendizaje",
                    prompt: "¿Qué prepararás para la próxima vez?",
                    text: $entry.journal.learning
                )

                Stepper(
                    "Intensidad máxima: \(entry.journal.maximumIntensity)/10",
                    value: $entry.journal.maximumIntensity,
                    in: 0...10
                )
                Stepper(
                    "Recuperación: \(entry.journal.recoveryMinutes) min",
                    value: $entry.journal.recoveryMinutes,
                    in: 0...720,
                    step: 5
                )
            }
        }
    }

    private var measurements: some View {
        TransformationProtocolCard {
            VStack(spacing: 17) {
                TransformationProtocolSectionTitle(
                    "Calidad del proceso",
                    subtitle: "Cada dimensión aporta hasta 2 puntos."
                )
                TransformationProtocolMetricPicker(
                    title: "Conciencia",
                    zero: "No detecté el patrón.",
                    one: "Lo detecté después de actuar.",
                    two: "Lo detecté antes o durante el impulso.",
                    value: $entry.score.awareness
                )
                TransformationProtocolMetricPicker(
                    title: "Pausa",
                    zero: "Reaccioné inmediatamente.",
                    one: "Hice una pausa breve.",
                    two: "Completé el protocolo de pausa.",
                    value: $entry.score.pause
                )
                TransformationProtocolMetricPicker(
                    title: "Regulación",
                    zero: "La emoción dominó la conducta.",
                    one: "Reduje parcialmente la activación.",
                    two: "Toleré la emoción sin obedecerla.",
                    value: $entry.score.regulation
                )
                TransformationProtocolMetricPicker(
                    title: "Conducta alternativa",
                    zero: "Repetí la conducta antigua.",
                    one: "Realicé parcialmente la nueva.",
                    two: "Ejecuté la respuesta prevista.",
                    value: $entry.score.alternativeBehavior
                )
                TransformationProtocolMetricPicker(
                    title: "Recuperación",
                    zero: "El episodio afectó gran parte del día.",
                    one: "Me recuperé con dificultad.",
                    two: "Reparé y regresé al proceso.",
                    value: $entry.score.recovery
                )

                Text("Total: \(entry.score.total)/10")
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.violet)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func save() {
        entry.eveningCompleted = true
        store.update(entry)
        dismiss()
    }
}
