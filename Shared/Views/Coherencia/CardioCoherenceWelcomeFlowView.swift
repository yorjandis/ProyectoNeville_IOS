import SwiftUI

struct CardioCoherenceWelcomeFlowView: View {
    @StateObject private var musicPlayer = CardioCoherenceMusicPlayer()
    @State private var showMainView = false
    @State private var visibleTextIndex = -1
    @State private var isBackgroundMusicEnabled = true
    @State private var didSkip = false

    init() {
        let persistedMusic = UserDefaults.standard.object(forKey: CardioCoherenceConstants.Audio.backgroundMusicEnabledKey) as? Bool
        _isBackgroundMusicEnabled = State(initialValue: persistedMusic ?? true)
    }

    var body: some View {
        ZStack {
            if showMainView {
                CardioCoherenceMainView()
                    .transition(.opacity)
            } else {
                welcomeContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showMainView)
        .task {
            await runWelcomeSequence()
        }
    }

    private var welcomeContent: some View {
        ZStack {
            CardioCoherenceBackgroundView(assetURL: welcomeBackgroundURL)
                .ignoresSafeArea()

            Color.black.opacity(0.28)
                .ignoresSafeArea()

            ZStack {
                ForEach(Array(CardioCoherenceConstants.Welcome.texts.enumerated()), id: \.offset) { index, text in
                    Text(text)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.60, green: 0.90, blue: 1.00),
                                    Color(red: 0.82, green: 0.66, blue: 1.00),
                                    Color(red: 0.66, green: 1.00, blue: 0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.35))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.70),
                                                    Color(red: 0.70, green: 0.55, blue: 1.00).opacity(0.85),
                                                    Color(red: 0.60, green: 0.95, blue: 0.92).opacity(0.80)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                                .shadow(color: Color(red: 0.60, green: 0.80, blue: 1.00).opacity(0.28), radius: 14, x: 0, y: 8)
                        )
                        .opacity(visibleTextIndex == index ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6), value: visibleTextIndex)
                }
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 20)

        }
        .overlay(alignment: .bottomTrailing) {
            Button("Saltar") {
                skipWelcome()
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .foregroundStyle(.black)
            .padding(.trailing, 16)
            .padding(.bottom, 18)
        }
        .ignoresSafeArea()
    }

    private var welcomeBackgroundURL: URL? {
        let bundle = Bundle.main
        if let url = bundle.url(
            forResource: CardioCoherenceConstants.Welcome.backgroundImageName,
            withExtension: CardioCoherenceConstants.Welcome.backgroundImageExtension,
            subdirectory: CardioCoherenceBackgroundResolver.bundleSubdirectory
        ) {
            return url
        }
        return bundle.url(
            forResource: CardioCoherenceConstants.Welcome.backgroundImageName,
            withExtension: CardioCoherenceConstants.Welcome.backgroundImageExtension
        )
    }

    private func skipWelcome() {
        guard !showMainView else { return }
        didSkip = true
        musicPlayer.stop()
        withAnimation(.easeInOut(duration: 0.45)) {
            showMainView = true
        }
    }

    private func runWelcomeSequence() async {
        musicPlayer.playIfEnabled(isBackgroundMusicEnabled, startAt: 0, loopFrom: nil)

        let total = CardioCoherenceConstants.Welcome.durationSeconds
        let initialDelay = CardioCoherenceConstants.Welcome.initialTextDelaySeconds
        let fadeDuration = CardioCoherenceConstants.Welcome.audioFadeOutSeconds
        if isBackgroundMusicEnabled {
            Task {
                let fadeStart = max(0, total - fadeDuration)
                try? await Task.sleep(nanoseconds: UInt64(fadeStart * 1_000_000_000))
                await MainActor.run {
                    guard !didSkip else { return }
                    musicPlayer.fadeOutAndStop(duration: fadeDuration)
                }
            }
        }

        let texts = CardioCoherenceConstants.Welcome.texts
        let durations = CardioCoherenceConstants.Welcome.textDurationsSeconds
        let textCount = min(texts.count, durations.count)

        try? await Task.sleep(nanoseconds: UInt64(max(0, initialDelay) * 1_000_000_000))

        for index in 0..<textCount {
            if didSkip { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.9)) {
                    visibleTextIndex = index
                }
            }
            let currentDuration = max(0.001, durations[index])
            try? await Task.sleep(nanoseconds: UInt64(currentDuration * 1_000_000_000))
        }

        guard !didSkip else { return }
        await MainActor.run {
            withAnimation(.easeInOut(duration: 1.0)) {
                showMainView = true
            }
        }
    }
}
