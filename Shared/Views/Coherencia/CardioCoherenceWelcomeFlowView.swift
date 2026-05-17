#if os(iOS)
import SwiftUI

struct CardioCoherenceWelcomeFlowView: View {
    @StateObject private var musicPlayer = CardioCoherenceMusicPlayer()
    @State private var welcomeTexts: [String] = []
    @State private var currentTextIndex: Int = -1
    @State private var showMainView = false
    @State private var flowTask: Task<Void, Never>?
    @State private var isLastTextDisappearing = false

    private let lastTextDisappearDuration: TimeInterval = 1.2

    var body: some View {
        Group {
            if showMainView {
                CardioCoherenceMainView()
            } else {
                welcomeView
            }
        }
        .onAppear {
            startWelcomeFlowIfNeeded()
        }
        .onDisappear {
            flowTask?.cancel()
            flowTask = nil
            musicPlayer.stop()
        }
    }

    private var welcomeView: some View {
        ZStack {
            backgroundImage
            Color.black.opacity(0.42)

            VStack {
                Spacer()
                if currentTextIndex >= 0, currentTextIndex < welcomeTexts.count {
                    let isCurrentLastText = currentTextIndex == welcomeTexts.count - 1
                    Text(welcomeTexts[currentTextIndex])
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.black.opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.72), lineWidth: 0.8)
                                .shadow(color: Color.white.opacity(0.36), radius: 8, x: 0, y: 0)
                                .shadow(color: Color.white.opacity(0.20), radius: 18, x: 0, y: 0)
                        )
                        .opacity(isCurrentLastText && isLastTextDisappearing ? 0 : 1)
                        .scaleEffect(
                            x: isCurrentLastText && isLastTextDisappearing ? 1.07 : 1.0,
                            y: isCurrentLastText && isLastTextDisappearing ? 0.86 : 1.0
                        )
                        .blur(radius: isCurrentLastText && isLastTextDisappearing ? 1.8 : 0)
                        .transition(.opacity)
                        .id(currentTextIndex)
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.6), value: currentTextIndex)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Saltar") {
                        skipWelcome()
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.28), lineWidth: 0.7)
                    )
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let image = UIImage(
            named: CardioCoherenceConstants.Welcome.backgroundImageName,
            in: .main,
            with: nil
        ) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [Color.black, Color(red: 0.12, green: 0.1, blue: 0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func startWelcomeFlowIfNeeded() {
        guard flowTask == nil, !showMainView else { return }
        welcomeTexts = CardioCoherenceConstants.Welcome.texts
        let durations = CardioCoherenceConstants.Welcome.textDurationsSeconds
        guard welcomeTexts.count == durations.count, !welcomeTexts.isEmpty else {
            showMainView = true
            return
        }

        musicPlayer.playIfEnabled(true, startAt: 0, loopFrom: nil, customTrackURL: nil)

        flowTask = Task {
            try? await Task.sleep(
                nanoseconds: UInt64(CardioCoherenceConstants.Welcome.initialTextDelaySeconds * 1_000_000_000)
            )
            guard !Task.isCancelled else { return }

            for index in welcomeTexts.indices {
                await MainActor.run {
                    isLastTextDisappearing = false
                    currentTextIndex = index
                }

                let isLast = index == welcomeTexts.count - 1
                let totalDuration = durations[index]
                if isLast {
                    let preDisappear = max(0, totalDuration - lastTextDisappearDuration)
                    if preDisappear > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(preDisappear * 1_000_000_000))
                        guard !Task.isCancelled else { return }
                    }

                    await MainActor.run {
                        withAnimation(.easeInOut(duration: lastTextDisappearDuration)) {
                            isLastTextDisappearing = true
                        }
                    }
                    try? await Task.sleep(
                        nanoseconds: UInt64(min(totalDuration, lastTextDisappearDuration) * 1_000_000_000)
                    )
                } else {
                    try? await Task.sleep(nanoseconds: UInt64(totalDuration * 1_000_000_000))
                }
                guard !Task.isCancelled else { return }
            }

            await MainActor.run {
                musicPlayer.fadeOutAndStop(duration: CardioCoherenceConstants.Welcome.audioFadeOutSeconds)
                withAnimation(.easeInOut(duration: 0.45)) {
                    showMainView = true
                }
            }
        }
    }

    private func skipWelcome() {
        flowTask?.cancel()
        flowTask = nil
        musicPlayer.fadeOutAndStop(duration: 0.35)
        withAnimation(.easeInOut(duration: 0.25)) {
            showMainView = true
        }
    }
}
#else
import SwiftUI

struct CardioCoherenceWelcomeFlowView: View {
    var body: some View {
        EmptyView()
    }
}
#endif
