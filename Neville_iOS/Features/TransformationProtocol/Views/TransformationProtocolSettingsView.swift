import SwiftUI

struct TransformationProtocolSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TransformationProtocolStore

    @State private var configuration: TransformationProtocolConfiguration
    @State private var morningTime: Date
    @State private var pauseTime: Date
    @State private var eveningTime: Date
    @State private var confirmsReset = false

    init(store: TransformationProtocolStore) {
        self.store = store
        let fallback = TransformationProtocolConfiguration(
            patternName: "",
            trigger: "",
            automaticThought: "",
            emotion: "",
            oldBehavior: "",
            consequence: "",
            alternativeBehavior: "",
            toleratedEmotion: "",
            identity: "",
            startedAt: Date(),
            remindersEnabled: false,
            morningMinuteOfDay: 480,
            pauseMinuteOfDay: 840,
            eveningMinuteOfDay: 1260
        )
        let configuration = store.configuration ?? fallback
        _configuration = State(initialValue: configuration)
        _morningTime = State(
            initialValue: .transformationProtocolTime(
                minuteOfDay: configuration.morningMinuteOfDay
            )
        )
        _pauseTime = State(
            initialValue: .transformationProtocolTime(
                minuteOfDay: configuration.pauseMinuteOfDay
            )
        )
        _eveningTime = State(
            initialValue: .transformationProtocolTime(
                minuteOfDay: configuration.eveningMinuteOfDay
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                pattern
                reminders
                principles
                resetSection
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") {
                    save()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .confirmationDialog(
            "¿Reiniciar el protocolo?",
            isPresented: $confirmsReset,
            titleVisibility: .visible
        ) {
            Button("Borrar ciclo y reiniciar", role: .destructive) {
                store.reset()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrarán la configuración, los diarios y todas las mediciones de este ciclo.")
        }
    }

    private var pattern: some View {
        TransformationProtocolCard {
            VStack(spacing: 14) {
                TransformationProtocolSectionTitle("Protocolo personal")
                TransformationProtocolField(
                    title: "Nombre del patrón",
                    prompt: "Nombre breve",
                    text: $configuration.patternName
                )
                TransformationProtocolField(
                    title: "Desencadenante",
                    prompt: "Cuando ocurre…",
                    text: $configuration.trigger
                )
                TransformationProtocolField(
                    title: "Pensamiento automático",
                    prompt: "Suelo pensar…",
                    text: $configuration.automaticThought
                )
                TransformationProtocolField(
                    title: "Emoción y cuerpo",
                    prompt: "Siento…",
                    text: $configuration.emotion
                )
                TransformationProtocolField(
                    title: "Conducta antigua",
                    prompt: "Termino haciendo…",
                    text: $configuration.oldBehavior
                )
                TransformationProtocolField(
                    title: "Consecuencia",
                    prompt: "Lo que produce…",
                    text: $configuration.consequence
                )
                TransformationProtocolField(
                    title: "Conducta alternativa",
                    prompt: "Haré…",
                    text: $configuration.alternativeBehavior
                )
                TransformationProtocolField(
                    title: "Emoción tolerada",
                    prompt: "Aunque sienta…",
                    text: $configuration.toleratedEmotion
                )
                TransformationProtocolField(
                    title: "Identidad en entrenamiento",
                    prompt: "Una persona que…",
                    text: $configuration.identity
                )
            }
        }
    }

    private var reminders: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 13) {
                Toggle(isOn: $configuration.remindersEnabled) {
                    Label("Recordatorios diarios", systemImage: "bell.badge")
                        .font(.headline)
                }
                .tint(TransformationProtocolTheme.violet)

                if configuration.remindersEnabled {
                    DatePicker("Práctica de mañana", selection: $morningTime, displayedComponents: .hourAndMinute)
                    DatePicker("Pausa P.A.R.A.", selection: $pauseTime, displayedComponents: .hourAndMinute)
                    DatePicker("Diario nocturno", selection: $eveningTime, displayedComponents: .hourAndMinute)
                }
            }
        }
    }

    private var principles: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 11) {
                TransformationProtocolSectionTitle("Reglas del ciclo")
                ForEach([
                    "Trabaja con hechos, no solo con intenciones.",
                    "No intentes eliminar emociones: evita convertirlas automáticamente en conducta.",
                    "Practica primero con situaciones pequeñas.",
                    "Un desliz es información, no una identidad.",
                    "Sueño, alimentación, fatiga y estrés también forman parte del sistema."
                ], id: \.self) { principle in
                    Label(L10n.exact(principle), systemImage: "circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(TransformationProtocolTheme.ink)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    private var resetSection: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nuevo ciclo")
                    .font(.headline)
                Text("Reinicia únicamente si deseas abandonar este patrón y empezar un ciclo diferente. Un desliz no requiere reiniciar.")
                    .font(.footnote)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                Button("Reiniciar protocolo", role: .destructive) {
                    confirmsReset = true
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func save() {
        configuration.morningMinuteOfDay = morningTime.transformationProtocolMinuteOfDay
        configuration.pauseMinuteOfDay = pauseTime.transformationProtocolMinuteOfDay
        configuration.eveningMinuteOfDay = eveningTime.transformationProtocolMinuteOfDay
        store.updateConfiguration(configuration)
    }
}
