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
    @AppStorage(PresenciaSettings.customMainButtonTitleKey) private var customMainButtonTitle = PresenciaSettings.defaultMainButtonTitle

    private let repository = PresenciaRepository()
    private let celebrationVisibleDuration: TimeInterval = 2.3

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    var body: some View {
        NavigationStack {
            if hasPremiumAccess {
                ZStack {
                    mainContent
                        .scaleEffect(showCelebration ? 0.64 : 1.0)
                        .opacity(showCelebration ? 0.0 : 1.0)
                        .blur(radius: showCelebration ? 8 : 0)
                        .animation(.easeInOut(duration: 0.44), value: showCelebration)

                    if showCelebration {
                        PresenceCelebrationView(phrase: celebrationPhrase, showsContinueButton: false)
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .opacity
                            ))
                            .zIndex(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.56, dampingFraction: 0.72), value: showCelebration)
                .background(
                    LinearGradient.AzulTecnologico()
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
                .toolbar(showCelebration ? .hidden : .visible, for: .navigationBar)
                .sheet(isPresented: $showInfo) {
                    PresenceInfoView()
                }
                .onAppear(perform: reload)
                .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
                    reload()
                }
            } else {
                PremiumFeaturePreviewView(feature: .consciousPresence)
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                mainAction
                moodSection
            }
            .padding()
            .animation(.easeInOut(duration: 0.24), value: showMoodList)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vuelve al Presente")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(L10n.format(
                todayPresentCount == 1 ? "presence.today_return.singular" : "presence.today_return.plural",
                fallback: todayPresentCount == 1 ? "Hoy has vuelto al presente {0} vez" : "Hoy has vuelto al presente {0} veces",
                "\(todayPresentCount)"
            ))
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
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.9)
                registerPresent(mood: nil)
            } label: {
                PresenceHaloButtonContent(title: mainButtonTitle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vuelvo al Presente")
            .padding(.top, 60)
/*
 VStack(spacing: 2) {
     Image(systemName: "arrow.up")
         .font(.headline.weight(.semibold))
     Text(" Volver al presente")
         .font(.subheadline.weight(.medium))
     Text("  con un solo toque")
         .font(.caption)
 }
 .foregroundStyle(.white.opacity(0.88))
 .multilineTextAlignment(.center)
 */
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var moodToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.24)) {
                showMoodList.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showMoodList ? "chevron.up.circle" : "face.smiling")
                Text(L10n.exact(showMoodList ? "Ocultar estado de ánimo" : "Añadir estado de ánimo"))
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
                            Text(mood.localizedTitle)
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
        presentCelebrationAndReturn()
    }

    private func reload() {
        todayPresentCount = repository.todayPresentCount()
    }

    private var celebrationPhrase: String {
        let trimmed = customCelebrationPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let phrase = trimmed.isEmpty ? PresenciaSettings.defaultCelebrationPhrase : trimmed
        return phrase == PresenciaSettings.defaultCelebrationPhrase ? L10n.exact(phrase) : phrase
    }

    private var mainButtonTitle: String {
        let trimmed = customMainButtonTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.isEmpty ? PresenciaSettings.defaultMainButtonTitle : trimmed
        return title == PresenciaSettings.defaultMainButtonTitle ? L10n.exact(title) : title
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

    private func presentCelebrationAndReturn() {
        withAnimation(.spring(response: 0.56, dampingFraction: 0.72)) {
            showCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + celebrationVisibleDuration) {
            withAnimation(.easeInOut(duration: 0.36)) {
                showCelebration = false
            }
        }
    }
}

private struct PresenceHaloButtonContent: View {
    @State private var haloPulse = false
    let title: String

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

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 22)
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

                    Text("Desde Joe Dispenza, el cambio se fortalece cuando el cuerpo empieza a sentir emocionalmente el futuro antes de que ocurra.\nDesde Neville Goddard, la imaginación crea cuando vivimos internamente desde el estado cumplido. Este registro convierte ese retorno en una acción pequeña, repetible y consciente.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("Cada toque es una interrupción amable del viejo hábito y una elección deliberada de identidad.")
                        .font(.headline)
                }
                .padding()
            }
            .navigationTitle("Presencia")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light)
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
    @State private var scale: CGFloat = 0.08
    @State private var auraScale: CGFloat = 0.18
    @State private var contentOpacity: Double = 0
    @State private var symbolRotation: Double = -10
    @State private var glow = false
    let phrase: String
    var showsContinueButton = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.34, green: 0.18, blue: 0.78),
                    Color(red: 0.08, green: 0.48, blue: 0.86),
                    Color(red: 0.18, green: 0.92, blue: 0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 460, height: 460)
                .scaleEffect(auraScale)
                .blur(radius: 18)
                .opacity(glow ? 0.72 : 0.36)

            Circle()
                .stroke(.white.opacity(0.22), lineWidth: 1.4)
                .frame(width: 280, height: 280)
                .scaleEffect(glow ? 1.24 : 0.92)
                .opacity(glow ? 0.14 : 0.62)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(.white.opacity(0.14 - Double(index) * 0.03), lineWidth: 1)
                    .frame(width: CGFloat(180 + index * 72), height: CGFloat(180 + index * 72))
                    .scaleEffect(glow ? 1.08 : 0.9)
                    .opacity(glow ? 0.28 : 0.7)
            }

            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 132, height: 132)
                        .blur(radius: 1)

                    Image(systemName: "camera.macro")
                        .font(.system(size: 82, weight: .light))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(symbolRotation))
                        .shadow(color: .white.opacity(glow ? 0.86 : 0.38), radius: glow ? 24 : 8)
                }

                Text(phrase)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .minimumScaleFactor(0.72)
                    .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
/*
 Text("He vuelto. Lo siento ahora.")
     .font(.headline)
     .foregroundStyle(.white.opacity(0.92))
 
 
                Text("Vivo mi Futuro Ahora")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
 */

                Spacer()

                if showsContinueButton {
                    Button {
                        dismiss()
                    } label: {
                        Text("Continuar")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan.opacity(0.6))
                    .foregroundStyle(.black)
                    .frame(width: 200)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 25)
                }
            }
            .scaleEffect(scale)
            .opacity(contentOpacity)
            .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
            withAnimation(.easeOut(duration: 0.16)) {
                contentOpacity = 1
            }
            withAnimation(.spring(response: 0.58, dampingFraction: 0.58)) {
                scale = 1.0
            }
            withAnimation(.spring(response: 0.72, dampingFraction: 0.68)) {
                auraScale = 1.0
                symbolRotation = 0
            }
            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}
#Preview{
    PresenciaView()
    //PresenceCelebrationView(phrase: "Siento mi futuro Ahora")
}
#endif
