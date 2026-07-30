import Combine
import SwiftUI

struct TransformationProtocolMorningPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    @State private var minimumMode = false
    @State private var currentStep = 0
    @State private var remainingSeconds = 180
    @State private var isRunning = false
    @State private var didFinish = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var routine: [(title: String, minutes: Int, detail: String)] {
        minimumMode
            ? TransformationProtocolCatalog.minimumRoutine
            : TransformationProtocolCatalog.morningRoutine
    }

    private var current: (title: String, minutes: Int, detail: String) {
        routine[min(currentStep, routine.count - 1)]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Toggle("Versión mínima · 10 minutos", isOn: $minimumMode)
                    .tint(TransformationProtocolTheme.violet)
                    .disabled(isRunning || currentStep > 0)

                Spacer()

                ZStack {
                Circle()
                        .stroke(.white.opacity(0.20), lineWidth: 15)
                    Circle()
                        .trim(from: 0, to: elapsedProgress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    TransformationProtocolTheme.violet,
                                    TransformationProtocolTheme.blue,
                                    TransformationProtocolTheme.mint
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 5) {
                        Text(timeText)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Paso \(currentStep + 1) de \(routine.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
                .frame(width: 230, height: 230)

                VStack(spacing: 8) {
                    Text(L10n.exact(current.title))
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(L10n.exact(current.detail))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.84))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        isRunning.toggle()
                    } label: {
                        Label(
                            L10n.exact(isRunning ? "Pausar" : "Continuar"),
                            systemImage: isRunning ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TransformationProtocolTheme.violet)

                    Button("Siguiente") {
                        advance()
                    }
                    .buttonStyle(.bordered)
                    .padding(.vertical, 6)
                }
            }
            .padding(22)
            .foregroundStyle(.white)
            .background(TransformationProtocolTheme.background.ignoresSafeArea())
            .navigationTitle("Práctica guiada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onChange(of: minimumMode) {
                currentStep = 0
                remainingSeconds = routine[0].minutes * 60
            }
            .onReceive(timer) { _ in
                guard isRunning, !didFinish else { return }
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                } else {
                    advance()
                }
            }
            .alert("Práctica completada", isPresented: $didFinish) {
                Button("Cerrar") {
                    onComplete()
                    dismiss()
                }
            } message: {
                Text("Has entrenado la respuesta nueva. Cuenta la práctica, no la perfección.")
            }
        }
    }

    private var timeText: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private var elapsedProgress: Double {
        let total = max(1, current.minutes * 60)
        return 1 - Double(remainingSeconds) / Double(total)
    }

    private func advance() {
        if currentStep + 1 < routine.count {
            currentStep += 1
            remainingSeconds = routine[currentStep].minutes * 60
        } else {
            isRunning = false
            didFinish = true
        }
    }
}

struct TransformationProtocolPARAView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TransformationProtocolStore

    @State private var perceivedSignal = ""
    @State private var emotion = ""
    @State private var alternativeAction = ""
    @State private var pauseSeconds = 30
    @State private var remainingSeconds = 30
    @State private var timerIsRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    paraStep(
                        letter: "P",
                        title: "Percibe",
                        detail: "Reconoce la primera señal sin juzgarla.",
                        color: TransformationProtocolTheme.violet
                    ) {
                        TransformationProtocolField(
                            title: "Señal detectada",
                            prompt: "Tensión, urgencia, pensamiento repetitivo…",
                            text: $perceivedSignal
                        )
                    }

                    paraStep(
                        letter: "A",
                        title: "Aplaza",
                        detail: "No decidas todavía. Crea espacio.",
                        color: TransformationProtocolTheme.blue
                    ) {
                        VStack(spacing: 12) {
                            Picker("Duración", selection: $pauseSeconds) {
                                Text("30 s").tag(30)
                                Text("60 s").tag(60)
                                Text("90 s").tag(90)
                                Text("2 min").tag(120)
                                Text("5 min").tag(300)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: pauseSeconds) {
                                guard !timerIsRunning else { return }
                                remainingSeconds = pauseSeconds
                            }

                            Button {
                                timerIsRunning.toggle()
                            } label: {
                                Label(
                                    timerIsRunning ? formatTime(remainingSeconds) : "Iniciar pausa",
                                    systemImage: timerIsRunning ? "pause.fill" : "timer"
                                )
                                .font(.headline.monospacedDigit())
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(TransformationProtocolTheme.blue)
                        }
                    }

                    paraStep(
                        letter: "R",
                        title: "Regula",
                        detail: "Haz de tres a seis respiraciones lentas y nombra la emoción.",
                        color: TransformationProtocolTheme.mint
                    ) {
                        TransformationProtocolField(
                            title: "Hay…",
                            prompt: "Miedo, frustración, urgencia…",
                            text: $emotion
                        )
                    }

                    paraStep(
                        letter: "A",
                        title: "Actúa",
                        detail: "Sigue la conducta definida; no improvises bajo activación.",
                        color: TransformationProtocolTheme.warm
                    ) {
                        TransformationProtocolField(
                            title: "Ahora voy a…",
                            prompt: store.configuration?.alternativeBehavior ?? "Conducta alternativa",
                            text: $alternativeAction
                        )
                    }

                    Button(action: save) {
                        Label("Registrar esta pausa", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TransformationProtocolTheme.violet)
                    .disabled(
                        perceivedSignal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || alternativeAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(TransformationProtocolTheme.background.ignoresSafeArea())
            .navigationTitle("P.A.R.A.")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                alternativeAction = store.configuration?.alternativeBehavior ?? ""
            }
            .onReceive(timer) { _ in
                guard timerIsRunning else { return }
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    timerIsRunning = false
                }
            }
        }
    }

    private func paraStep<Content: View>(
        letter: String,
        title: String,
        detail: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        TransformationProtocolCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    Text(letter)
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(color)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.exact(title))
                            .font(.headline)
                        Text(L10n.exact(detail))
                            .font(.caption)
                            .foregroundStyle(TransformationProtocolTheme.secondaryInk)
                    }
                }
                content()
            }
        }
    }

    private func save() {
        store.recordPARA(
            perceivedSignal: perceivedSignal,
            emotion: emotion,
            alternativeAction: alternativeAction,
            pauseSeconds: pauseSeconds - remainingSeconds
        )
        dismiss()
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
