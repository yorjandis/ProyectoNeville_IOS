#if os(iOS)
import SwiftUI
import UIKit

struct PresenciaView: View {
    @State private var todayPresentCount = 0
    @State private var showCelebration = false
    @State private var showInfo = false
    @State private var showMilestoneMessage = false

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage(PresenciaSettings.customCelebrationPhraseKey) private var customCelebrationPhrase = PresenciaSettings.defaultCelebrationPhrase

    private let repository = PresenciaRepository()

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    var body: some View {
        NavigationStack {
            if hasPremiumAccess {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        mainAction
                        moodList
                    }
                    .padding()
                }
                .background(
                    LinearGradient(colors: [.indigo.opacity(0.95), .teal.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
                .navigationTitle("Presencia")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("Información")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            PresenciaStatsView(embeddedInNavigation: true)
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                        .accessibilityLabel("Estadísticas")
                    }
                }
                .sheet(isPresented: $showInfo) {
                    PresenceInfoView()
                }
                .fullScreenCover(isPresented: $showCelebration) {
                    PresenceCelebrationView(phrase: celebrationPhrase)
                }
                .onAppear(perform: reload)
                .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
                    reload()
                }
            } else {
                PurchaseView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vuelve al Presente")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Hoy has vuelto al presente \(todayPresentCount) veces.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
            if showMilestoneMessage {
                Text("Racha interior activada: sigue regresando.")
                    .font(.subheadline.bold())
                    .foregroundStyle(.yellow)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showMilestoneMessage)
    }

    private var mainAction: some View {
        Button {
            registerPresent(mood: nil)
        } label: {
            Label("Vuelvo al Presente", systemImage: "sparkles")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 58)
        }
        .buttonStyle(.borderedProminent)
        .tint(.mint)
        .foregroundStyle(.black)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var moodList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estado de ánimo")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVStack(spacing: 10) {
                ForEach(PresenciaMood.common) { mood in
                    Button {
                        registerPresent(mood: mood)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mood.symbolName)
                                .frame(width: 24)
                            Text(mood.title)
                                .font(.body.weight(.medium))
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func registerPresent(mood: PresenciaMood?) {
        let saved: Bool
        if let mood {
            saved = repository.recordPresent(mood: mood, source: "iOS")
        } else {
            saved = repository.recordPresent(source: "iOS")
        }

        reload()
        guard saved else { return }
        triggerMilestoneMessageIfNeeded()
        showCelebration = true
    }

    private func reload() {
        todayPresentCount = repository.todayPresentCount()
    }

    private var celebrationPhrase: String {
        let trimmed = customCelebrationPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? PresenciaSettings.defaultCelebrationPhrase : trimmed
    }

    private func triggerMilestoneMessageIfNeeded() {
        guard todayPresentCount >= 10 else { return }

        showMilestoneMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeInOut(duration: 0.7)) {
                showMilestoneMessage = false
            }
        }
    }
}

private struct PresenceInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("La práctica de Presencia une dos gestos: despertar del piloto automático y encarnar el estado deseado ahora.")
                        .font(.title3.bold())

                    Text("Desde Joe Dispenza, el cambio se fortalece cuando el cuerpo empieza a sentir emocionalmente el futuro antes de que ocurra. Desde Neville Goddard, la imaginación crea cuando vivimos internamente desde el estado cumplido. Este registro convierte ese retorno en una acción pequeña, repetible y consciente.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("Cada toque es una interrupción amable del viejo hábito y una elección deliberada de identidad.")
                        .font(.headline)
                }
                .padding()
            }
            .navigationTitle("Presencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PresenceCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 0.82
    @State private var glow = false
    let phrase: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pink, .orange, .yellow, .mint, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .yellow.opacity(glow ? 0.95 : 0.35), radius: glow ? 26 : 8)

                Text(phrase)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .minimumScaleFactor(0.72)
                    .shadow(color: .black.opacity(0.28), radius: 10, y: 4)

                Text("He vuelto. Lo siento ahora.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.92))

                Button {
                    dismiss()
                } label: {
                    Label("Continuar", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.top, 12)
            }
            .scaleEffect(scale)
            .padding(.vertical, 40)
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}
#endif


#Preview{
    PresenciaView()
}
