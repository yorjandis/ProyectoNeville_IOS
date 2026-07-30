import SwiftUI

struct TransformationProtocolInformationView: View {
    @Environment(\.dismiss) private var dismiss

    let hasActiveCycle: Bool
    let onUseExample: (TransformationProtocolExample) -> Void

    @State private var pendingExample: TransformationProtocolExample?
    @State private var confirmsReplacement = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    objectiveCard
                    cycleCard
                    dailyUseCard
                    measurementCard
                    exampleCard
                }
                .padding(16)
                .padding(.bottom, 26)
            }
            .background(TransformationProtocolTheme.background.ignoresSafeArea())
            .navigationTitle("Cómo funciona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .confirmationDialog(
            "¿Sustituir el ciclo actual?",
            isPresented: $confirmsReplacement,
            titleVisibility: .visible
        ) {
            Button("Sustituir y cargar el ejemplo", role: .destructive) {
                applyPendingExample()
            }
            Button("Conservar mi ciclo", role: .cancel) {
                pendingExample = nil
            }
        } message: {
            Text("Se borrarán la configuración, las prácticas y los diarios del ciclo actual antes de completar los campos de prueba.")
        }
    }

    private var objectiveCard: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(TransformationProtocolTheme.violet)

                TransformationProtocolSectionTitle(
                    "¿Cuál es el objetivo?",
                    eyebrow: "Transformación personal"
                )

                Text("Entrenar durante 21 días una respuesta más útil ante un patrón automático concreto.")
                    .font(.headline)
                    .foregroundStyle(TransformationProtocolTheme.ink)

                Text("La herramienta no intenta cambiar toda tu personalidad ni eliminar las emociones. Te ayuda a reconocer antes un automatismo, crear una pausa y ejecutar una conducta elegida aunque todavía exista incomodidad.")
                    .font(.subheadline)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
        }
    }

    private var cycleCard: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 14) {
                TransformationProtocolSectionTitle(
                    "El ciclo de aprendizaje",
                    subtitle: "La repetición convierte una intención en experiencia."
                )

                flowStep("1", title: "Observar", detail: "Detecta el desencadenante, pensamiento, emoción, cuerpo e impulso.", color: TransformationProtocolTheme.blue)
                flowStep("2", title: "Interrumpir", detail: "Crea espacio antes de decidir con una pausa deliberada.", color: TransformationProtocolTheme.violet)
                flowStep("3", title: "Sustituir", detail: "Ejecuta la respuesta concreta que definiste al comenzar.", color: TransformationProtocolTheme.warm)
                flowStep("4", title: "Repetir", detail: "Practica primero con situaciones pequeñas y manejables.", color: TransformationProtocolTheme.mint)
                flowStep("5", title: "Evaluar", detail: "Registra hechos y ajusta el sistema sin convertir un desliz en identidad.", color: TransformationProtocolTheme.blue)
            }
        }
    }

    private var dailyUseCard: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 13) {
                TransformationProtocolSectionTitle("Cómo se utiliza cada día")

                useRow(
                    icon: "sun.max.fill",
                    title: "Mañana",
                    detail: "Regula el cuerpo, observa el patrón, ensaya la dificultad y define una acción observable."
                )
                useRow(
                    icon: "pause.circle.fill",
                    title: "Durante el día · P.A.R.A.",
                    detail: "Percibe la señal, aplaza la decisión, regula la activación y actúa según tu protocolo."
                )
                useRow(
                    icon: "moon.stars.fill",
                    title: "Noche",
                    detail: "Registra el episodio principal, lo que hiciste y lo que prepararás para la próxima ocasión."
                )
                useRow(
                    icon: "calendar",
                    title: "Una práctica distinta cada jornada",
                    detail: "Los 21 días avanzan desde observar el patrón hasta consolidar una identidad basada en conducta."
                )
            }
        }
    }

    private var measurementCard: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 12) {
                TransformationProtocolSectionTitle(
                    "Qué se mide",
                    subtitle: "El progreso se evalúa por acciones, no por inspiración."
                )

                HStack(spacing: 8) {
                    metric("Conciencia", icon: "eye.fill")
                    metric("Pausa", icon: "pause.fill")
                    metric("Regulación", icon: "waveform.path.ecg")
                }
                HStack(spacing: 8) {
                    metric("Alternativa", icon: "arrow.triangle.branch")
                    metric("Recuperación", icon: "arrow.counterclockwise")
                }

                Text("La emoción no necesita desaparecer. La señal principal de progreso es que tenga cada vez menos autoridad sobre tu comportamiento.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                    .padding(.top, 3)
            }
        }
    }

    private var exampleCard: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 13) {
                TransformationProtocolSectionTitle(
                    "Pruébalo con un caso hipotético",
                    eyebrow: "Demostración práctica",
                    subtitle: "La app elegirá automáticamente una de seis alternativas y completará todos los campos iniciales."
                )

                Text("Los ejemplos incluyen reacción a críticas, procrastinación, teléfono compulsivo, comida por estrés, conversaciones incómodas y abandono prematuro de rutinas.")
                    .font(.subheadline)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)

                if hasActiveCycle {
                    Label(
                        "Para cargar un ejemplo será necesario sustituir el ciclo actual. Te pediremos confirmación.",
                        systemImage: "exclamationmark.shield.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(Color(red: 0.63, green: 0.29, blue: 0.08))
                }

                Button(action: chooseRandomExample) {
                    Label("Completar con un ejemplo al azar", systemImage: "dice.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(TransformationProtocolTheme.violet)
            }
        }
    }

    private func flowStep(
        _ number: String,
        title: String,
        detail: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.subheadline.monospacedDigit().weight(.black))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.bold))
                Text(L10n.exact(detail))
                    .font(.caption)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
        }
    }

    private func useRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(TransformationProtocolTheme.violet)
                .frame(width: 34, height: 34)
                .background(TransformationProtocolTheme.violet.opacity(0.09))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.bold))
                Text(L10n.exact(detail))
                    .font(.caption)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
        }
    }

    private func metric(_ title: String, icon: String) -> some View {
        Label(L10n.exact(title), systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(TransformationProtocolTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(TransformationProtocolTheme.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func chooseRandomExample() {
        guard let example = TransformationProtocolCatalog.examples.randomElement() else {
            return
        }
        pendingExample = example
        if hasActiveCycle {
            confirmsReplacement = true
        } else {
            applyPendingExample()
        }
    }

    private func applyPendingExample() {
        guard let pendingExample else { return }
        onUseExample(pendingExample)
        self.pendingExample = nil
        dismiss()
    }
}
