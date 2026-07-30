import SwiftUI

struct TransformationProtocolView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = TransformationProtocolStore()
    @State private var showsInformation = false
    @State private var exampleSelection: TransformationProtocolExampleSelection?

    var body: some View {
        NavigationStack {
            Group {
                if store.configuration == nil {
                    TransformationProtocolSetupView(
                        store: store,
                        exampleSelection: exampleSelection,
                        onExampleApplied: {
                            exampleSelection = nil
                        }
                    )
                } else {
                    TransformationProtocolDashboardView(store: store)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsInformation = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Información sobre la herramienta")
                }
            }
        }
        .sheet(isPresented: $showsInformation) {
            TransformationProtocolInformationView(
                hasActiveCycle: store.configuration != nil,
                onUseExample: applyExample
            )
        }
        .alert(
            "Transformación en 21 días",
            isPresented: Binding(
                get: { store.presentedError != nil },
                set: { if !$0 { store.presentedError = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) {
                store.presentedError = nil
            }
        } message: {
            Text(store.presentedError ?? "")
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.light)
        .environment(\.locale, AppLanguage.current.locale)
    }

    private func applyExample(_ example: TransformationProtocolExample) {
        if store.configuration != nil {
            store.reset()
        }
        exampleSelection = TransformationProtocolExampleSelection(example: example)
    }
}

private struct TransformationProtocolDashboardView: View {
    @ObservedObject var store: TransformationProtocolStore

    @State private var showsMorningPractice = false
    @State private var showsPARA = false
    @State private var showsEveningJournal = false

    private var day: Int { store.currentDayNumber }
    private var plan: TransformationProtocolDayPlan {
        TransformationProtocolCatalog.days[day - 1]
    }
    private var entry: TransformationProtocolDayEntry {
        store.entry(for: day)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                progressHeader
                todayCard
                quickTools
                protocolCard
                navigationCards
                safetyNote
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("21 días")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    TransformationProtocolSettingsView(store: store)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Ajustes del protocolo")
            }
        }
        .sheet(isPresented: $showsMorningPractice) {
            TransformationProtocolMorningPracticeView {
                store.markMorningCompleted(day: day)
            }
        }
        .sheet(isPresented: $showsPARA) {
            TransformationProtocolPARAView(store: store)
        }
        .sheet(isPresented: $showsEveningJournal) {
            TransformationProtocolEveningJournalView(store: store, day: day)
        }
    }

    private var progressHeader: some View {
        TransformationProtocolCard {
            HStack(spacing: 18) {
                TransformationProtocolProgressRing(
                    progress: store.progress,
                    label: "\(store.completedDays)/21"
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Día \(day) de 21")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TransformationProtocolTheme.ink)
                    Text(store.configuration?.patternName ?? "")
                        .font(.headline)
                        .foregroundStyle(TransformationProtocolTheme.violet)
                    Text("Cada repetición correcta es evidencia, aunque la emoción siga presente.")
                        .font(.footnote)
                        .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                }
            }
        }
    }

    private var todayCard: some View {
        NavigationLink {
            TransformationProtocolDayDetailView(store: store, day: day)
        } label: {
            TransformationProtocolCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(L10n.exact(plan.phase).uppercased(with: AppLanguage.current.locale))
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(TransformationProtocolTheme.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(TransformationProtocolTheme.tertiaryInk)
                    }

                    Text(L10n.exact(plan.title))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TransformationProtocolTheme.ink)
                    Text(L10n.exact(plan.objective))
                        .font(.subheadline)
                        .foregroundStyle(TransformationProtocolTheme.secondaryInk)

                    HStack(spacing: 7) {
                        statusPill("Mañana", done: entry.morningCompleted)
                        statusPill("Acción", done: entry.actionCompleted)
                        statusPill("Cierre", done: entry.eveningCompleted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var quickTools: some View {
        HStack(spacing: 10) {
            quickButton(
                title: "Práctica",
                subtitle: "21 min",
                icon: "timer",
                color: TransformationProtocolTheme.violet
            ) {
                showsMorningPractice = true
            }
            quickButton(
                title: "P.A.R.A.",
                subtitle: "En el momento",
                icon: "pause.circle.fill",
                color: TransformationProtocolTheme.blue
            ) {
                showsPARA = true
            }
            quickButton(
                title: "Diario",
                subtitle: "Cierre",
                icon: "book.closed.fill",
                color: TransformationProtocolTheme.mint
            ) {
                showsEveningJournal = true
            }
        }
    }

    private var protocolCard: some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 13) {
                TransformationProtocolSectionTitle(
                    "Tu respuesta elegida",
                    eyebrow: "Protocolo personal"
                )

                Label(store.configuration?.alternativeFormula ?? "", systemImage: "arrow.triangle.branch")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TransformationProtocolTheme.ink)

                Divider()

                Text("¿Qué haría ahora la versión de mí que estoy entrenando?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TransformationProtocolTheme.violet)
            }
        }
    }

    private var navigationCards: some View {
        HStack(spacing: 10) {
            NavigationLink {
                TransformationProtocolPlanView(store: store)
            } label: {
                navigationCard("Ruta completa", icon: "calendar")
            }
            NavigationLink {
                TransformationProtocolInsightsView(store: store)
            } label: {
                navigationCard("Tendencias", icon: "chart.line.uptrend.xyaxis")
            }
        }
        .buttonStyle(.plain)
    }

    private var safetyNote: some View {
        Label(
            "Versión mínima disponible: reducir la práctica es válido; abandonarla por perfeccionismo no.",
            systemImage: "leaf.fill"
        )
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 4)
    }

    private func statusPill(_ title: String, done: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
            Text(L10n.exact(title))
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(
            done ? TransformationProtocolTheme.mint : TransformationProtocolTheme.tertiaryInk
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            (done ? TransformationProtocolTheme.mint : TransformationProtocolTheme.tertiaryInk)
                .opacity(0.09)
        )
        .clipShape(Capsule())
    }

    private func quickButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(L10n.exact(title))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TransformationProtocolTheme.ink)
                Text(L10n.exact(subtitle))
                    .font(.caption2)
                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func navigationCard(_ title: String, icon: String) -> some View {
        Label(L10n.exact(title), systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TransformationProtocolTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white.opacity(0.70))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TransformationProtocolPlanView: View {
    @ObservedObject var store: TransformationProtocolStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(TransformationProtocolCatalog.days) { plan in
                    NavigationLink {
                        TransformationProtocolDayDetailView(store: store, day: plan.number)
                    } label: {
                        HStack(spacing: 13) {
                            ZStack {
                                Circle()
                                    .fill(color(for: plan.number).opacity(0.14))
                                if store.entry(for: plan.number).isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                } else {
                                    Text("\(plan.number)")
                                        .font(.subheadline.monospacedDigit().weight(.bold))
                                }
                            }
                            .foregroundStyle(color(for: plan.number))
                            .frame(width: 38, height: 38)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(L10n.exact(plan.title))
                                    .font(.headline)
                                    .foregroundStyle(TransformationProtocolTheme.ink)
                                Text(L10n.exact(plan.phase))
                                    .font(.caption)
                                    .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                            }
                            Spacer()
                            if plan.number == store.currentDayNumber {
                                Text("HOY")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(TransformationProtocolTheme.violet)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(TransformationProtocolTheme.tertiaryInk)
                        }
                        .padding(14)
                        .background(.white.opacity(0.74))
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("Ruta de 21 días")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func color(for day: Int) -> Color {
        if day <= 7 { return TransformationProtocolTheme.blue }
        if day <= 14 { return TransformationProtocolTheme.violet }
        return TransformationProtocolTheme.mint
    }
}

private struct TransformationProtocolInsightsView: View {
    @ObservedObject var store: TransformationProtocolStore

    private var recentEntries: [TransformationProtocolDayEntry] {
        Array(store.state.entries.sorted { $0.day < $1.day }.suffix(7))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    stat("\(store.completedDays)", label: "días completos")
                    stat("\(store.totalPARAPauses)", label: "pausas P.A.R.A.")
                    stat(String(format: "%.1f", store.averageScore), label: "media / 10")
                }

                TransformationProtocolCard {
                    VStack(alignment: .leading, spacing: 14) {
                        TransformationProtocolSectionTitle(
                            "Últimos registros",
                            subtitle: "Observa la tendencia; no conviertas el número en perfeccionismo."
                        )

                        if recentEntries.isEmpty {
                            Text("Completa el cierre nocturno para empezar a ver tu tendencia.")
                                .font(.subheadline)
                                .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                                .padding(.vertical, 22)
                        } else {
                            HStack(alignment: .bottom, spacing: 10) {
                                ForEach(recentEntries) { entry in
                                    VStack(spacing: 6) {
                                        Text("\(entry.score.total)")
                                            .font(.caption2.monospacedDigit())
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        TransformationProtocolTheme.violet,
                                                        TransformationProtocolTheme.mint
                                                    ],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                            )
                                            .frame(
                                                height: max(8, CGFloat(entry.score.total) / 10 * 120)
                                            )
                                        Text("D\(entry.day)")
                                            .font(.caption2)
                                            .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 160, alignment: .bottom)
                        }
                    }
                }

                TransformationProtocolCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TransformationProtocolSectionTitle("Señales de progreso real")
                        ForEach([
                            "Detectas antes el patrón.",
                            "La emoción dura menos o gobierna menos tu conducta.",
                            "Realizas pausas con menos esfuerzo.",
                            "Te recuperas antes de un desliz.",
                            "Haces lo correcto incluso sin motivación."
                        ], id: \.self) { signal in
                            Label(L10n.exact(signal), systemImage: "checkmark.seal")
                                .font(.subheadline)
                                .foregroundStyle(TransformationProtocolTheme.ink)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(TransformationProtocolTheme.background.ignoresSafeArea())
        .navigationTitle("Tendencias")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(TransformationProtocolTheme.violet)
            Text(L10n.exact(label))
                .font(.caption2)
                .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
