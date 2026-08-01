import SwiftUI

struct TransformationProtocolInformationView: View {
    @Environment(\.dismiss) private var dismiss

    let hasActiveCycle: Bool
    let showsPracticalDemo: Bool
    let allowsExampleApplication: Bool
    let showsDetailedReference: Bool
    let onUseExample: (TransformationProtocolExample) -> Void

    @State private var pendingExample: TransformationProtocolExample?
    @State private var confirmsReplacement = false

    init(
        hasActiveCycle: Bool,
        showsPracticalDemo: Bool = true,
        allowsExampleApplication: Bool = true,
        showsDetailedReference: Bool = true,
        onUseExample: @escaping (TransformationProtocolExample) -> Void
    ) {
        self.hasActiveCycle = hasActiveCycle
        self.showsPracticalDemo = showsPracticalDemo
        self.allowsExampleApplication = allowsExampleApplication
        self.showsDetailedReference = showsDetailedReference
        self.onUseExample = onUseExample
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    objectiveCard
                    cycleCard
                    dailyUseCard
                    measurementCard
                    if showsPracticalDemo {
                        if allowsExampleApplication {
                            exampleCard
                        }
                        
                    }
                    if showsDetailedReference {
                        detailedInformationCard
                    }
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

    private var detailedInformationCard: some View {
        NavigationLink {
            TransformationProtocolDetailedInformationView()
        } label: {
            TransformationProtocolCard {
                HStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(TransformationProtocolTheme.blue)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Documento de referencia")
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(0.7)
                            .foregroundStyle(TransformationProtocolTheme.blue)

                        Text("Explicación detallada del protocolo")
                            .font(.headline)
                            .foregroundStyle(TransformationProtocolTheme.ink)

                        Text("Consulta los fundamentos, reglas, fases, prácticas diarias y criterios de seguridad que dieron forma a esta herramienta.")
                            .font(.caption)
                            .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TransformationProtocolTheme.tertiaryInk)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre la explicación completa en la que se basa la herramienta")
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

private struct TransformationProtocolDetailedInformationView: View {
    private static let resourceName = "info_protocolo_de_transformacion"
    @State private var blocks: [TransformationProtocolDocumentBlock]

    init() {
        _blocks = State(
            initialValue: TransformationProtocolDocumentParser.blocks(
                from: L10n.textResource(named: Self.resourceName)
            )
        )
    }

    var body: some View {
        ScrollView {
            if blocks.isEmpty {
                ContentUnavailableView(
                    "Contenido no disponible",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("No se pudo cargar la explicación detallada del protocolo.")
                )
                .foregroundStyle(TransformationProtocolTheme.ink)
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.97))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(16)
            } else {
                LazyVStack(alignment: .leading, spacing: 13) {
                    ForEach(blocks) { block in
                        blockView(block)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.97))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 30)
                .textSelection(.enabled)
            }
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("Protocolo detallado")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task(id: AppLanguage.current) {
            blocks = TransformationProtocolDocumentParser.blocks(
                from: L10n.textResource(named: Self.resourceName)
            )
        }
    }

    @ViewBuilder
    private func blockView(_ block: TransformationProtocolDocumentBlock) -> some View {
        switch block.kind {
        case let .heading(level, text):
            inlineText(text)
                .font(headingFont(level: level))
                .foregroundStyle(level == 1 ? TransformationProtocolTheme.violet : TransformationProtocolTheme.ink)
                .padding(.top, level == 1 ? 16 : 8)

        case let .paragraph(text):
            inlineText(text)
                .font(.body)
                .foregroundStyle(TransformationProtocolTheme.ink)
                .lineSpacing(4)

        case let .bullet(text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Circle()
                    .fill(TransformationProtocolTheme.violet)
                    .frame(width: 6, height: 6)
                inlineText(text)
                    .font(.body)
                    .foregroundStyle(TransformationProtocolTheme.ink)
            }

        case let .numbered(number, text):
            HStack(alignment: .top, spacing: 10) {
                Text("\(number).")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.blue)
                    .frame(minWidth: 24, alignment: .trailing)
                inlineText(text)
                    .font(.body)
                    .foregroundStyle(TransformationProtocolTheme.ink)
            }

        case let .quote(text):
            inlineText(text)
                .font(.body.weight(.medium))
                .italic()
                .foregroundStyle(TransformationProtocolTheme.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TransformationProtocolTheme.violet.opacity(0.08))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(TransformationProtocolTheme.violet)
                        .frame(width: 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        case let .callout(text):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(TransformationProtocolTheme.warm)
                inlineText(text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TransformationProtocolTheme.ink)
            }

        case .divider:
            Divider()
                .overlay(TransformationProtocolTheme.violet.opacity(0.25))
                .padding(.vertical, 6)
        }
    }

    private func inlineText(_ source: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return Text(attributed)
        }
        return Text(source)
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1:
            return .title2.weight(.bold)
        case 2:
            return .title3.weight(.bold)
        default:
            return .headline
        }
    }
}

private struct TransformationProtocolDocumentBlock: Identifiable {
    enum Kind {
        case heading(level: Int, text: String)
        case paragraph(String)
        case bullet(String)
        case numbered(number: Int, text: String)
        case quote(String)
        case callout(String)
        case divider
    }

    let id: Int
    let kind: Kind
}

private enum TransformationProtocolDocumentParser {
    static func blocks(from source: String) -> [TransformationProtocolDocumentBlock] {
        source
            .components(separatedBy: .newlines)
            .compactMap { rawLine -> TransformationProtocolDocumentBlock.Kind? in
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { return nil }

                if line == "---" {
                    return .divider
                }

                if line.hasPrefix("#") {
                    let level = min(line.prefix(while: { $0 == "#" }).count, 3)
                    let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
                    return .heading(level: level, text: text)
                }

                if line.hasPrefix("🟠 ") {
                    return .heading(level: 2, text: String(line.dropFirst(2)))
                }

                if line.hasPrefix("🔸 ") {
                    return .callout(String(line.dropFirst(2)))
                }

                if line.hasPrefix("> ") {
                    return .quote(String(line.dropFirst(2)))
                }

                if line.hasPrefix("- ") {
                    return .bullet(String(line.dropFirst(2)))
                }

                if let numbered = numberedItem(from: line) {
                    return .numbered(number: numbered.number, text: numbered.text)
                }

                return .paragraph(line)
            }
            .enumerated()
            .map { TransformationProtocolDocumentBlock(id: $0.offset, kind: $0.element) }
    }

    private static func numberedItem(from line: String) -> (number: Int, text: String)? {
        guard let separator = line.firstIndex(of: ".") else { return nil }
        let numberText = line[..<separator]
        guard let number = Int(numberText) else { return nil }
        let textStart = line.index(after: separator)
        let text = line[textStart...].trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return (number, text)
    }
}
