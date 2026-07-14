import SwiftUI

struct HealingGuidedSessionView: View {
    let situation: HealingSituation
    let healingProtocol: HealingProtocol

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentIndex = 0
    @State private var remainingSeconds: Int
    @State private var isPaused = false
    @State private var sessionFinished = false
    @State private var feedback: SessionFeedback?
    @State private var showEmergencyResources = false

    init(situation: HealingSituation, healingProtocol: HealingProtocol) {
        self.situation = situation
        self.healingProtocol = healingProtocol
        _remainingSeconds = State(initialValue: healingProtocol.steps.first?.durationSeconds ?? 0)
    }

    private var currentStep: HealingProtocolStep? {
        guard healingProtocol.steps.indices.contains(currentIndex) else { return nil }
        return healingProtocol.steps[currentIndex]
    }

    private var taskID: String {
        "\(currentIndex)-\(isPaused)-\(sessionFinished)"
    }

    var body: some View {
        ZStack {
            HealingCenterVisualStyle.background.ignoresSafeArea()

            if sessionFinished {
                completionView
            } else if let currentStep {
                sessionView(step: currentStep)
            }
        }
        .navigationTitle(healingProtocol.title)
        .healingInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPaused = true
                    showEmergencyResources = true
                } label: {
                    Image(systemName: "sos.circle")
                }
                .accessibilityLabel("Abrir ayuda urgente")
            }
        }
        .task(id: taskID) {
            await runCurrentStepTimer()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                isPaused = true
            }
        }
        .sheet(isPresented: $showEmergencyResources) {
            NavigationStack { HealingEmergencyResourcesView() }
        }
    }

    private func sessionView(step: HealingProtocolStep) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 9) {
                HStack {
                    Text("Paso \(currentIndex + 1) de \(healingProtocol.steps.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    Text(timeLabel(remainingSeconds))
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.white)
                }

                ProgressView(value: progressValue)
                    .tint(.mint)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer(minLength: 8)
            HealingGuidanceOrb(step: step, isPaused: isPaused)

            VStack(spacing: 10) {
                Text(step.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(step.instruction)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 18)

            HStack(spacing: 14) {
                Button(action: previousStep) {
                    Image(systemName: "backward.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(currentIndex == 0)

                Button {
                    isPaused.toggle()
                } label: {
                    Label(isPaused ? "Continuar" : "Pausa", systemImage: isPaused ? "play.fill" : "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)

                Button(action: advanceStep) {
                    Image(systemName: "forward.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Siguiente paso")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)

            Text(HealingSafetyCopy.stopInstruction)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.52))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 13)
                .padding(.bottom, 18)
        }
    }

    private var completionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 35)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 74))
                    .foregroundStyle(.mint)
                    .shadow(color: .mint.opacity(0.35), radius: 18)

                Text("Guía completada")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Respira con normalidad y observa el momento sin exigir un resultado concreto.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.76))
                    .multilineTextAlignment(.center)

                HealingGlassCard {
                    Text("¿Cómo te ha resultado?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("La respuesta no se guarda. Solo te ayuda a decidir el siguiente paso.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .padding(.top, 2)

                    HStack(spacing: 8) {
                        feedbackButton(.helped)
                        feedbackButton(.somewhat)
                        feedbackButton(.notHelped)
                    }
                    .padding(.top, 9)
                }

                if feedback == .notHelped {
                    Text("Prueba una técnica de otra familia o busca apoyo humano. No es necesario repetir un ejercicio que no te ayuda.")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                } else if feedback == .helped || feedback == .somewhat {
                    Text("Puedes volver a esta técnica desde tus favoritos cuando la necesites.")
                        .font(.subheadline)
                        .foregroundStyle(.mint)
                        .multilineTextAlignment(.center)
                }

                Button {
                    dismiss()
                } label: {
                    Label("Salir de la guía", systemImage: "arrow.left")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button {
                    showEmergencyResources = true
                } label: {
                    Label("Necesito ayuda urgente", systemImage: "sos.circle")
                }
                .foregroundStyle(.red)
            }
            .padding(22)
        }
    }

    private func feedbackButton(_ value: SessionFeedback) -> some View {
        Button {
            feedback = value
        } label: {
            VStack(spacing: 5) {
                Image(systemName: value.symbol)
                    .font(.title3)
                Text(value.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(feedback == value ? Color.white : Color.white.opacity(0.72))
            .background(
                feedback == value ? Color.indigo.opacity(0.72) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var progressValue: Double {
        guard let step = currentStep, !healingProtocol.steps.isEmpty else { return 0 }
        let elapsed = max(step.durationSeconds - remainingSeconds, 0)
        let stepProgress = Double(elapsed) / Double(max(step.durationSeconds, 1))
        return (Double(currentIndex) + stepProgress) / Double(healingProtocol.steps.count)
    }

    private func runCurrentStepTimer() async {
        guard !isPaused, !sessionFinished, currentStep != nil else { return }

        while remainingSeconds > 0 {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled, !isPaused, !sessionFinished else { return }
            if remainingSeconds > 1 {
                remainingSeconds -= 1
            } else {
                advanceStep()
                return
            }
        }
    }

    private func advanceStep() {
        if currentIndex + 1 < healingProtocol.steps.count {
            currentIndex += 1
            remainingSeconds = healingProtocol.steps[currentIndex].durationSeconds
        } else {
            sessionFinished = true
            isPaused = true
        }
    }

    private func previousStep() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        remainingSeconds = healingProtocol.steps[currentIndex].durationSeconds
    }

    private func timeLabel(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private enum SessionFeedback: String {
    case helped
    case somewhat
    case notHelped

    var title: String {
        switch self {
        case .helped: return "Me ayudó"
        case .somewhat: return "Algo"
        case .notHelped: return "No"
        }
    }

    var symbol: String {
        switch self {
        case .helped: return "hand.thumbsup.fill"
        case .somewhat: return "minus.circle.fill"
        case .notHelped: return "hand.thumbsdown.fill"
        }
    }
}
