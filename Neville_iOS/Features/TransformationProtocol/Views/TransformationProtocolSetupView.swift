import SwiftUI

struct TransformationProtocolSetupView: View {
    @ObservedObject var store: TransformationProtocolStore
    let exampleSelection: TransformationProtocolExampleSelection?
    let onExampleApplied: () -> Void

    @State private var patternName = ""
    @State private var trigger = ""
    @State private var thought = ""
    @State private var emotion = ""
    @State private var oldBehavior = ""
    @State private var consequence = ""
    @State private var alternativeBehavior = ""
    @State private var toleratedEmotion = ""
    @State private var identity = ""
    @State private var remindersEnabled = true
    @State private var morningTime = Date.transformationProtocolTime(minuteOfDay: 8 * 60)
    @State private var pauseTime = Date.transformationProtocolTime(minuteOfDay: 14 * 60)
    @State private var eveningTime = Date.transformationProtocolTime(minuteOfDay: 21 * 60)

    private var canStart: Bool {
        [patternName, trigger, oldBehavior, consequence, alternativeBehavior, identity]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                patternSection
                alternativeSection
                reminderSection
                safetySection

                Button(action: start) {
                    Label("Comenzar mis 21 días", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint( TransformationProtocolTheme.violet)
                .disabled(!canStart)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("Transformación")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            applyExampleIfNeeded()
        }
        .onChange(of: exampleSelection) {
            applyExampleIfNeeded()
        }
    }

    private var hero: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(TransformationProtocolTheme.violet)

                Text("Un patrón. Una respuesta nueva. 21 días.")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.ink)

                Text("Observar → interrumpir → sustituir → repetir → evaluar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TransformationProtocolTheme.blue)

                Text("Elige un comportamiento concreto y observable. La herramienta te acompañará con práctica guiada, P.A.R.A., diario y medición.")
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
        }
    }

    private var patternSection: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 15) {
                TransformationProtocolSectionTitle(
                    "Cartografía el patrón",
                    eyebrow: "Paso 1",
                    subtitle: "Trabaja con un solo automatismo durante el ciclo."
                )
                TransformationProtocolField(
                    title: "Nombre breve",
                    prompt: "Ej. urgencia, evitación, reacción defensiva…",
                    text: $patternName
                )
                TransformationProtocolField(
                    title: "Cuando ocurre…",
                    prompt: "Describe el desencadenante",
                    text: $trigger
                )
                TransformationProtocolField(
                    title: "Suelo pensar…",
                    prompt: "La interpretación automática",
                    text: $thought
                )
                TransformationProtocolField(
                    title: "Siento…",
                    prompt: "Emoción y señal corporal",
                    text: $emotion
                )
                TransformationProtocolField(
                    title: "Y termino haciendo…",
                    prompt: "La conducta observable",
                    text: $oldBehavior
                )
                TransformationProtocolField(
                    title: "Lo que produce…",
                    prompt: "Consecuencia inmediata y posterior",
                    text: $consequence
                )
            }
        }
    }

    private var alternativeSection: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 15) {
                TransformationProtocolSectionTitle(
                    "Diseña la alternativa",
                    eyebrow: "Paso 2",
                    subtitle: "Debe poder ejecutarse incluso con emoción presente."
                )
                TransformationProtocolField(
                    title: "Cuando aparezca, haré…",
                    prompt: "Una respuesta concreta y verificable",
                    text: $alternativeBehavior
                )
                TransformationProtocolField(
                    title: "Aunque sienta…",
                    prompt: "La emoción que estás dispuesto a tolerar",
                    text: $toleratedEmotion
                )
                TransformationProtocolField(
                    title: "Estoy entrenando para ser una persona que…",
                    prompt: "Una identidad basada en proceso",
                    text: $identity
                )
            }
        }
    }

    private var reminderSection: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $remindersEnabled) {
                    Label("Acompañamiento diario", systemImage: "bell.badge")
                        .font(.headline)
                }
                .tint(TransformationProtocolTheme.violet)

                if remindersEnabled {
                    DatePicker("Práctica de mañana", selection: $morningTime, displayedComponents: .hourAndMinute)
                    DatePicker("Pausa P.A.R.A.", selection: $pauseTime, displayedComponents: .hourAndMinute)
                    DatePicker("Diario nocturno", selection: $eveningTime, displayedComponents: .hourAndMinute)
                }
            }
        }
    }

    private var safetySection: some View {
        TransformationProtocolCard {
            Label {
                Text("Practica con dificultad manejable. Si aparecen pánico intenso, recuerdos traumáticos intrusivos, desconexión persistente o empeoramiento significativo, detén el ejercicio y busca acompañamiento profesional.")
                    .font(.footnote)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            } icon: {
                Image(systemName: "heart.text.clipboard")
                    .foregroundStyle(TransformationProtocolTheme.warm)
            }
        }
    }

    private func start() {
        let configuration = TransformationProtocolConfiguration(
            patternName: patternName.trimmingCharacters(in: .whitespacesAndNewlines),
            trigger: trigger.trimmingCharacters(in: .whitespacesAndNewlines),
            automaticThought: thought.trimmingCharacters(in: .whitespacesAndNewlines),
            emotion: emotion.trimmingCharacters(in: .whitespacesAndNewlines),
            oldBehavior: oldBehavior.trimmingCharacters(in: .whitespacesAndNewlines),
            consequence: consequence.trimmingCharacters(in: .whitespacesAndNewlines),
            alternativeBehavior: alternativeBehavior.trimmingCharacters(in: .whitespacesAndNewlines),
            toleratedEmotion: toleratedEmotion.trimmingCharacters(in: .whitespacesAndNewlines),
            identity: identity.trimmingCharacters(in: .whitespacesAndNewlines),
            startedAt: Date(),
            remindersEnabled: remindersEnabled,
            morningMinuteOfDay: morningTime.transformationProtocolMinuteOfDay,
            pauseMinuteOfDay: pauseTime.transformationProtocolMinuteOfDay,
            eveningMinuteOfDay: eveningTime.transformationProtocolMinuteOfDay
        )
        store.start(configuration)
    }

    private func applyExampleIfNeeded() {
        guard let example = exampleSelection?.example else { return }
        patternName = L10n.exact(example.patternName)
        trigger = L10n.exact(example.trigger)
        thought = L10n.exact(example.automaticThought)
        emotion = L10n.exact(example.emotion)
        oldBehavior = L10n.exact(example.oldBehavior)
        consequence = L10n.exact(example.consequence)
        alternativeBehavior = L10n.exact(example.alternativeBehavior)
        toleratedEmotion = L10n.exact(example.toleratedEmotion)
        identity = L10n.exact(example.identity)
        onExampleApplied()
    }
}
