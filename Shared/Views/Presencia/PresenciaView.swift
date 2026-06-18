#if os(iOS)
import SwiftUI
import UIKit

struct PresenciaView: View {
    @State private var todayPresentCount = 0
    @State private var showCelebration = false
    @State private var showInfo = false
    @State private var showMilestoneMessage = false
    @State private var showMoodList = false

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
                        moodSection
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.24), value: showMoodList)
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
                Text("Lo estás haciendo genial: sigue regresando.")
                    .font(.body.bold())
                    .foregroundStyle(.black)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 1.5), value: showMilestoneMessage)
    }

    private var mainAction: some View {
        VStack(spacing: 10) {
            Button {
                registerPresent(mood: nil)
            } label: {
                PresenceHaloButtonContent()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vuelvo al Presente")

            VStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.headline.weight(.semibold))
                Text("Volver al presente")
                    .font(.subheadline.weight(.medium))
                Text("con un solo toque")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.88))
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var moodToggleButton: some View {
        Button {
            showMoodList.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showMoodList ? "chevron.up.circle" : "face.smiling")
                Text(showMoodList ? "Ocultar estado de ánimo" : "Añadir estado de ánimo")
                Spacer()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            moodToggleButton

            if showMoodList {
                moodList
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                    .zIndex(-1)
            }
        }
        .clipped()
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

private struct PresenceHaloButtonContent: View {
    @State private var haloPulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 196, height: 196)
                .scaleEffect(haloPulse ? 1.08 : 0.96)
                .opacity(haloPulse ? 0.46 : 0.78)

            Circle()
                .stroke(.white.opacity(0.34), lineWidth: 1.4)
                .frame(width: 174, height: 174)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.78, green: 0.72, blue: 1.0),
                            Color(red: 0.46, green: 0.35, blue: 0.78)
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 96
                    )
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.32), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.58, green: 0.48, blue: 0.94).opacity(0.42), radius: 28, y: 12)
                .frame(width: 154, height: 154)

            VStack(spacing: 9) {
                Image(systemName: "camera.macro")
                    .font(.system(size: 47, weight: .light))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.28), radius: 8)

                Text("Estoy aquí")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 210, height: 210)
        .contentShape(Circle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                haloPulse = true
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
                colors: [.mint.opacity(0.5), .blue, .blue, .mint.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                
                Text("☘️")
                    .font(.system(size: 45))
                /*
                 Image(systemName: "sparkles")
                     .font(.system(size: 56, weight: .bold))
                     .foregroundStyle(.white)
                     .shadow(color: .yellow.opacity(glow ? 0.95 : 0.35), radius: glow ? 26 : 8)
                 */
                

                Text(phrase)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .minimumScaleFactor(0.72)
                    .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
/*
 Text("He vuelto. Lo siento ahora.")
     .font(.headline)
     .foregroundStyle(.white.opacity(0.92))
 */
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Label("Continuar mi día", systemImage: "")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan.opacity(0.6))
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.bottom, 25)
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
    PresenceCelebrationView(phrase: "Siento mi futuro Ahora")
}
