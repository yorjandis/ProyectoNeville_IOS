import SwiftUI
import AVFoundation
import QuartzCore
import CoreData

#if canImport(UIKit)
import UIKit
#if canImport(MediaPlayer)
@preconcurrency import MediaPlayer
#endif
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#endif

private struct CalmBubble: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    let radius: CGFloat
    let phrase: String
    let tint: Color
    let bornAtMs: Int64
}

private struct CalmParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let vx: CGFloat
    var vy: CGFloat
    let radius: CGFloat
    let lifeMs: Int64
    let bornAtMs: Int64
    let color: Color
}

private struct CalmFirefly: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    let radius: CGFloat
    let driftSeed: CGFloat
    let twinkleSeed: CGFloat
    let phrase: String
}

private struct CalmPhraseReveal: Identifiable {
    let id: Int
    let phrase: String
    let x: CGFloat
    let y: CGFloat
    let bornAtMs: Int64
    let revealDelayMs: Int64
}

private struct CalmFireflyFlash: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let bornAtMs: Int64
    let lifeMs: Int64
    let maxRadius: CGFloat
}

private struct BubbleDeformation {
    let angleRad: CGFloat
    let strength: CGFloat
    let bornAtMs: Int64
}

private struct CalmAsset: Identifiable, Equatable {
    let name: String
    let url: URL
    let isUserProvided: Bool

    init(name: String, url: URL, isUserProvided: Bool = false) {
        self.name = name
        self.url = url
        self.isUserProvided = isUserProvided
    }

    var id: String { name }
}

private enum CalmAssetKind {
    case background
    case music
}

private enum CalmParticleMode: String, CaseIterable {
    case spheres
    case fireflies
    case both

    var label: String {
        switch self {
        case .spheres: return "Esferas"
        case .fireflies: return "Luciérnagas"
        case .both: return "Ambas"
        }
    }

    var includesSpheres: Bool {
        self == .spheres || self == .both
    }

    var includesFireflies: Bool {
        self == .fireflies || self == .both
    }
}

private enum CalmInteractiveParticle {
    case bubble(Int)
    case firefly(Int)
}

private enum CalmPhraseSource: String, CaseIterable {
    case inbuilt
    case user
    case both

    var label: String {
        switch self {
        case .inbuilt: return "Inbuilt"
        case .user: return "Usuario"
        case .both: return "Ambas"
        }
    }
}

private struct CalmUserPhraseItem: Identifiable {
    let objectID: NSManagedObjectID
    let phrase: String
    let createdAt: Date

    var id: NSManagedObjectID { objectID }
}

// Ajuste de desarrollador:
private enum CalmConstants {
    static let minBubbles = 1
    static let maxBubbles = 16
    static let bubbleRadiusMin: CGFloat = 34
    static let bubbleRadiusMax: CGFloat = 58
    static let developerBubbleSizeScale: CGFloat = 0.52
    static let phraseLifetimeMs: Int64 = 3000
    static let phraseRevealDelayMs: Int64 = 450
    static let bubbleAppearMs: Int64 = 520
    static let deformationMs: Int64 = 360
    static let defaultNominalBubbleSpeed: CGFloat = 22
    static let nominalSpeedRange: ClosedRange<CGFloat> = 10...42
    static let wallRestitution: CGFloat = 0.94
    static let bubbleRestitution: CGFloat = 0.90
    static let backgroundTransitionDuration: Double = 1.35
    static let minFireflies = 8
    static let maxFireflies = 34
    static let defaultFireflyCount = 16
    static let fireflyRadiusRange: ClosedRange<CGFloat> = 1.8...4.2
    // Intensidad visual del destello de fusión de luciérnagas. 1.0 = base.
    static let fireflyMergeFlashIntensity: CGFloat = 1.15
    // Fusión entre luciérnagas: parámetros de suavidad.
    static let fireflyMergeAttractionDistance: CGFloat = 86
    static let fireflyMergeAttractionStrength: CGFloat = 15//26
    static let fireflyMergeSoftCaptureFactor: CGFloat = 0.18
    static let fireflyMergeRelativeSpeedThreshold: CGFloat = 16
    // Intensidad del estado de molestia tras arrastrar/soltar. 1.0 = base.
    static let fireflyAgitationIntensity: CGFloat = 3.10
    static let fireflyAgitationDurationMs: Int64 = 1250
    static let fireflyAgitationSpeedMultiplier: CGFloat = 2.15
}

private enum CalmPrefsKeys {
    static let bubbleCount = "calm_spheres"
    static let useFixedBackground = "calm_use_fixed_background"
    static let fixedBackgroundName = "calm_fixed_background_name"
    static let useFixedMusic = "calm_use_fixed_music"
    static let fixedMusicName = "calm_fixed_music_name"
    static let lastBackgroundName = "calm_last_background_name"
    static let nominalBubbleSpeed = "calm_nominal_bubble_speed"
    static let burstSoundEnabled = "calm_burst_sound_enabled"
    static let keepMusicWithScreenLocked = "calm_keep_music_locked_screen"
    static let keepScreenAwake = "calm_keep_screen_awake"
    static let particleMode = "calm_particle_mode"
    static let phraseSource = "calm_phrase_source"
}

private final class CalmAudioController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var backgroundPlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []
    private var keepMusicWithScreenLocked: Bool = false
    private var nowPlayingTitle: String = "Espacio Calma"

    override init() {
        super.init()
        configureRemoteCommandsIfNeeded()
    }

    func setKeepMusicWithScreenLocked(_ enabled: Bool) {
        keepMusicWithScreenLocked = enabled
        applyAudioSessionConfig()
    }

    func playBackground(url: URL?, title: String?) {
        stopBackground(resetNowPlaying: false)
        guard let url else {
            clearNowPlayingInfoIfNeeded()
            return
        }

        do {
            applyAudioSessionConfig()
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.38
            player.prepareToPlay()
            player.play()
            backgroundPlayer = player
            nowPlayingTitle = title.flatMap { $0.isEmpty ? nil : $0 } ?? "Espacio Calma"
            updateNowPlayingInfoIfNeeded()
        } catch {
            msg("Error reproduciendo música de calma:", error)
        }
    }

    func pauseBackground() {
        backgroundPlayer?.pause()
        updateNowPlayingInfoIfNeeded()
    }

    func resumeBackground() {
        backgroundPlayer?.play()
        updateNowPlayingInfoIfNeeded()
    }

    func stopBackground(resetNowPlaying: Bool = true) {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
        if resetNowPlaying {
            clearNowPlayingInfoIfNeeded()
        }
    }

    func playBurst(url: URL?) {
        guard let url else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = 0.30
            player.delegate = self
            player.prepareToPlay()
            effectPlayers.append(player)
            player.play()
        } catch {
            msg("Error reproduciendo efecto de burbuja:", error)
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        effectPlayers.removeAll { $0 === player }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error {
            msg("Error decodificando efecto de burbuja:", error)
        }
        effectPlayers.removeAll { $0 === player }
    }

    func stopAll() {
        stopBackground()
        effectPlayers.forEach { $0.stop() }
        effectPlayers.removeAll()
    }

    private func applyAudioSessionConfig() {
        #if canImport(UIKit)
        let session = AVAudioSession.sharedInstance()
        do {
            if keepMusicWithScreenLocked {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            } else {
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            }
            try session.setActive(true, options: [])
        } catch {
            msg("Error configurando sesión de audio:", error)
        }
        #endif
    }

    #if canImport(UIKit) && canImport(MediaPlayer)
    private func configureRemoteCommandsIfNeeded() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.resumeBackground()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.pauseBackground()
            return .success
        }

        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.stopBackground()
            return .success
        }
    }

    private func updateNowPlayingInfoIfNeeded() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlayingTitle,
            MPMediaItemPropertyArtist: "Espacio Calma",
            MPNowPlayingInfoPropertyPlaybackRate: backgroundPlayer?.isPlaying == true ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: backgroundPlayer?.currentTime ?? 0
        ]

        if let duration = backgroundPlayer?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlayingInfoIfNeeded() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    #else
    private func configureRemoteCommandsIfNeeded() {}
    private func updateNowPlayingInfoIfNeeded() {}
    private func clearNowPlayingInfoIfNeeded() {}
    #endif
}

struct EspacioCalmaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var targetBubbleCount: Int = 10
    @State private var targetFireflyCount: Int = CalmConstants.defaultFireflyCount
    @State private var nominalBubbleSpeed: Double = Double(CalmConstants.defaultNominalBubbleSpeed)
    @State private var particleMode: CalmParticleMode = .both
    @State private var phraseSource: CalmPhraseSource = .both
    @State private var burstSoundEnabled: Bool = true
    @State private var keepMusicWithScreenLocked: Bool = false
    @State private var keepScreenAwake: Bool = true
    @State private var originalIdleTimerDisabled: Bool?
    @State private var useFixedBackground: Bool = false
    @State private var fixedBackgroundName: String?
    @State private var useFixedMusic: Bool = true
    @State private var fixedMusicName: String?

    @State private var backgroundAssets: [CalmAsset] = []
    @State private var musicAssets: [CalmAsset] = []
    @State private var builtInPhrases: [String] = []
    @State private var userPhraseItems: [CalmUserPhraseItem] = []

    @State private var selectedBackground: CalmAsset?
    @State private var selectedMusic: CalmAsset?
    @State private var burstEffectURL: URL?
    @State private var backgroundUIImage: PlatformImage?
    @State private var previousBackgroundUIImage: PlatformImage?
    @State private var backgroundTransitionProgress: Double = 1.0

    @State private var bubbles: [CalmBubble] = []
    @State private var fireflies: [CalmFirefly] = []
    @State private var fireflyFlashes: [CalmFireflyFlash] = []
    @State private var fireflyAgitatedUntil: [Int: Int64] = [:]
    @State private var fireflyAgitationSeed: [Int: CGFloat] = [:]
    @State private var fireflyAgitationCenter: [Int: CGPoint] = [:]
    @State private var particles: [CalmParticle] = []
    @State private var phraseReveals: [CalmPhraseReveal] = []
    @State private var deformations: [Int: BubbleDeformation] = [:]
    @State private var phraseShuffleQueue: [String] = []

    @State private var nextBubbleID: Int = 1
    @State private var nextFireflyID: Int = 1
    @State private var nextFXID: Int = 1
    @State private var viewportSize: CGSize = .zero
    @State private var nowMs: Int64 = Self.currentTimeMs()

    @State private var showSettings: Bool = false
    @State private var showCloseConfirmation: Bool = false
    @State private var showBackgroundSelector: Bool = false
    @State private var showMusicSelector: Bool = false
    @State private var isPreviewingBackground: Bool = false
    @State private var backgroundShuffleQueue: [String] = []
    @State private var pendingBurstParticleKeys: Set<String> = []
    @State private var draggedParticle: CalmInteractiveParticle?

    @State private var simulationTask: Task<Void, Never>?

    @StateObject private var audioController = CalmAudioController()
    private var showsSpheres: Bool { particleMode.includesSpheres }
    private var showsFireflies: Bool { particleMode.includesFireflies }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                backgroundLayer
                Color.black.opacity(0.16).ignoresSafeArea()

                Canvas { context, _ in
                    if showsSpheres {
                        drawBubbles(context: context)
                    }
                    if showsFireflies {
                        drawFireflies(context: context)
                        drawFireflyFlashes(context: context)
                    }
                    drawParticles(context: context)
                }
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(value)
                        }
                        .onEnded { value in
                            handleDragEnded(value)
                        }
                )

                phraseRevealLayer

                floatingCloseButton(in: proxy)
                floatingSettingsButton(in: proxy)
                if showSettings {
                    settingsOverlay(in: proxy)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        handleBackgroundDoubleTap()
                    }
            )
            .onAppear {
                viewportSize = proxy.size
                loadInitialState()
                #if canImport(UIKit)
                originalIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
                #endif
                audioController.setKeepMusicWithScreenLocked(keepMusicWithScreenLocked)
                applyScreenAwakePreference()
                ensureParticleTargets()
                startSimulation()
            }
            .onDisappear {
                simulationTask?.cancel()
                audioController.stopAll()
                restoreIdleTimerPreference()
            }
            .onChange(of: proxy.size) { _, newValue in
                viewportSize = newValue
                ensureParticleTargets()
            }
            .onChange(of: targetBubbleCount) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: CalmPrefsKeys.bubbleCount)
                targetFireflyCount = newValue
                ensureParticleTargets()
            }
            .onChange(of: particleMode) { _, newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: CalmPrefsKeys.particleMode)
                ensureParticleTargets()
            }
            .onChange(of: phraseSource) { _, newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: CalmPrefsKeys.phraseSource)
                phraseShuffleQueue.removeAll()
            }
            .onChange(of: nominalBubbleSpeed) { _, newValue in
                let clamped = newValue.clamped(
                    to: Double(CalmConstants.nominalSpeedRange.lowerBound)...Double(CalmConstants.nominalSpeedRange.upperBound)
                )
                if clamped != newValue {
                    nominalBubbleSpeed = clamped
                }
                UserDefaults.standard.set(clamped, forKey: CalmPrefsKeys.nominalBubbleSpeed)
                rebalanceBubbleSpeeds()
                rebalanceFireflySpeeds()
            }
            .onChange(of: burstSoundEnabled) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: CalmPrefsKeys.burstSoundEnabled)
            }
            .onChange(of: keepMusicWithScreenLocked) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: CalmPrefsKeys.keepMusicWithScreenLocked)
                audioController.setKeepMusicWithScreenLocked(newValue)
            }
            .onChange(of: keepScreenAwake) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: CalmPrefsKeys.keepScreenAwake)
                applyScreenAwakePreference()
            }
            .onChange(of: useFixedBackground) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: CalmPrefsKeys.useFixedBackground)
                refreshBackgroundSelection(forceRandomWhenNotFixed: true)
            }
            .onChange(of: useFixedMusic) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: CalmPrefsKeys.useFixedMusic)
                refreshMusicSelection(forceRandomWhenNotFixed: true)
            }
            .onChange(of: selectedBackground?.id) {
                UserDefaults.standard.set(selectedBackground?.name, forKey: CalmPrefsKeys.lastBackgroundName)
                updateBackgroundImage()
            }
            .onChange(of: selectedMusic?.id) {
                audioController.playBackground(url: selectedMusic?.url, title: selectedMusic?.name)
            }
            .sheet(isPresented: $showBackgroundSelector) {
                assetSelectorSheet(
                    title: "Fondos",
                    assets: backgroundAssets,
                    selectedName: selectedBackground?.name,
                    showThumbnails: true
                ) { asset in
                    fixedBackgroundName = asset.name
                    UserDefaults.standard.set(asset.name, forKey: CalmPrefsKeys.fixedBackgroundName)
                    UserDefaults.standard.set(asset.name, forKey: CalmPrefsKeys.lastBackgroundName)
                    useFixedBackground = true
                    selectedBackground = asset
                }
            }
            .sheet(isPresented: $showMusicSelector) {
                assetSelectorSheet(
                    title: "Música",
                    assets: musicAssets,
                    selectedName: selectedMusic?.name,
                    showThumbnails: false
                ) { asset in
                    fixedMusicName = asset.name
                    UserDefaults.standard.set(asset.name, forKey: CalmPrefsKeys.fixedMusicName)
                    useFixedMusic = true
                    selectedMusic = asset
                }
            }
            .confirmationDialog(
                "Cerrar Espacio Calma",
                isPresented: $showCloseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Cerrar Espacio Calma", role: .destructive) {
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Seguro que deseas salir de Espacio Calma?")
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showSettings)
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
    }
}

private extension EspacioCalmaView {
    static func currentTimeMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.49, green: 0.65, blue: 0.72), Color(red: 0.70, green: 0.83, blue: 0.78), Color(red: 0.80, green: 0.90, blue: 0.91)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let previousBackgroundUIImage {
                platformImageView(previousBackgroundUIImage)
                    .opacity(1.0 - backgroundTransitionProgress)
            }

            if let backgroundUIImage {
                platformImageView(backgroundUIImage)
                    .opacity(backgroundTransitionProgress)
            }
        }
    }

    @ViewBuilder
    func platformImageView(_ image: PlatformImage) -> some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
        #endif
    }

    var phraseRevealLayer: some View {
        let reveals: [CalmPhraseReveal] = phraseReveals

        return ZStack(alignment: .topLeading) {
            ForEach(reveals, id: \.id) { (reveal: CalmPhraseReveal) in
                let age = nowMs - reveal.bornAtMs
                if age >= reveal.revealDelayMs {
                    let delayedAge = age - reveal.revealDelayMs
                    let progress = max(0.0, min(1.0, Double(delayedAge) / Double(CalmConstants.phraseLifetimeMs)))
                    let alpha = progress < 0.20
                        ? (progress / 0.20)
                        : (progress > 0.75 ? ((1.0 - progress) / 0.25) : 1.0)

                    let formattedPhrase = twoWordsPerLine(reveal.phrase)
                    let cardSize = phraseCardSize(for: formattedPhrase)
                    let rawX = reveal.x - cardSize.width / 2.0
                    let safeX = max(16.0, min(rawX, max(16.0, viewportSize.width - cardSize.width - 16.0)))
                    let topMargin = 24.0
                    let bottomMargin = 28.0
                    // La tarjeta nace desde el centro de la explosión.
                    let preferredY = reveal.y - (cardSize.height / 2.0)
                    let safeY = max(topMargin, min(preferredY, max(topMargin, viewportSize.height - cardSize.height - bottomMargin)))

                    VStack {
                        Text(formattedPhrase)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: cardSize.width)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.50 * alpha), Color.black.opacity(0.90 * alpha)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.03 * alpha))
                    }
                    .offset(x: safeX, y: safeY)
                    .opacity(alpha)
                }
            }
        }
        .allowsHitTesting(false)
    }

    func settingsOverlay(in proxy: GeometryProxy) -> some View {
        let maxWidth = min(proxy.size.width - 28, 560)
        //let maxHeight = min(proxy.size.height * 0.78, 680)

        return ZStack {
            Color.white.opacity(0.02)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPreviewingBackground {
                                isPreviewingBackground = true
                            }
                        }
                        .onEnded { _ in
                            isPreviewingBackground = false
                        }
                )

            if !isPreviewingBackground {
                ScrollView {
                    settingsPanelContent
                }
                .frame(maxWidth: maxWidth, maxHeight: 360)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.018), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
                .transition(.opacity)
            }
        }
        .zIndex(450)
    }

    var settingsPanelContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Espacio de calma")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("🔸Toca una partícula para liberar su frase.\n🔸Doble toque en el fondo para cambiarlo.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.90))

                Text("Tipo de partícula")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Picker("Tipo de partícula", selection: $particleMode) {
                    ForEach(CalmParticleMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("Partículas: \(targetBubbleCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Slider(
                    value: Binding(
                        get: { Double(targetBubbleCount) },
                        set: { targetBubbleCount = Int($0) }
                    ),
                    in: Double(CalmConstants.minBubbles)...Double(CalmConstants.maxBubbles),
                    step: 1
                )

                Text("Velocidad nominal: \(Int(nominalBubbleSpeed.rounded()))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Slider(
                    value: $nominalBubbleSpeed,
                    in: Double(CalmConstants.nominalSpeedRange.lowerBound)...Double(CalmConstants.nominalSpeedRange.upperBound),
                    step: 1
                )

                Text("Fuente de frases")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Picker("Fuente de frases", selection: $phraseSource) {
                    ForEach(CalmPhraseSource.allCases, id: \.self) { source in
                        Text(source.label).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Fondo fijo", isOn: $useFixedBackground)
                    .foregroundStyle(.white)
                    .tint(.mint)

                HStack(spacing: 8) {
                    Button {
                        showBackgroundSelector = true
                    } label: {
                        Text(selectedBackground?.name ?? "Sin fondo")
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button("Aleatorio") {
                        guard let picked = backgroundAssets.randomElement() else { return }
                        fixedBackgroundName = picked.name
                        UserDefaults.standard.set(picked.name, forKey: CalmPrefsKeys.fixedBackgroundName)
                        UserDefaults.standard.set(picked.name, forKey: CalmPrefsKeys.lastBackgroundName)
                        useFixedBackground = true
                        selectedBackground = picked
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 10))
                }

                Toggle("Música fija", isOn: $useFixedMusic)
                    .foregroundStyle(.white)
                    .tint(.mint)

                HStack(spacing: 8) {
                    Button {
                        showMusicSelector = true
                    } label: {
                        Text(selectedMusic?.name ?? "Sin música")
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button("Aleatoria") {
                        guard let picked = musicAssets.randomElement() else { return }
                        fixedMusicName = picked.name
                        UserDefaults.standard.set(picked.name, forKey: CalmPrefsKeys.fixedMusicName)
                        useFixedMusic = true
                        selectedMusic = picked
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 10))
                }

                Toggle("Sonido de efecto", isOn: $burstSoundEnabled)
                    .foregroundStyle(.white)
                    .tint(.mint)

                Toggle("Mantener música con pantalla bloqueada", isOn: $keepMusicWithScreenLocked)
                    .foregroundStyle(.white)
                    .tint(.mint)

                Toggle("Evitar apagado de pantalla", isOn: $keepScreenAwake)
                    .foregroundStyle(.white)
                    .tint(.mint)

                
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func assetSelectorSheet(
        title: String,
        assets: [CalmAsset],
        selectedName: String?,
        showThumbnails: Bool,
        onSelect: @escaping (CalmAsset) -> Void
    ) -> some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(assets) { asset in
                        Button {
                            onSelect(asset)
                            if title == "Fondos" {
                                showBackgroundSelector = false
                            } else {
                                showMusicSelector = false
                            }
                        } label: {
                            HStack {
                                if showThumbnails {
                                    backgroundThumbnail(for: asset)
                                }
                                Text(asset.name)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                if asset.name == selectedName {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.mint)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .background(.ultraThinMaterial)
            .navigationTitle(title)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        if title == "Fondos" {
                            showBackgroundSelector = false
                        } else {
                            showMusicSelector = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    @ViewBuilder
    func backgroundThumbnail(for asset: CalmAsset) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(contentsOfFile: asset.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.7)
                )
        } else {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.06))
                .frame(width: 52, height: 36)
        }
        #elseif canImport(AppKit)
        if let image = NSImage(contentsOfFile: asset.url.path) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.7)
                )
        } else {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.06))
                .frame(width: 52, height: 36)
        }
        #endif
    }

    func floatingCloseButton(in proxy: GeometryProxy) -> some View {
        let safeBottom = max(proxy.safeAreaInsets.bottom, 12)
        let safeLeading = max(proxy.safeAreaInsets.leading, 12)
        let buttonSize: CGFloat = 44
        let x = safeLeading + (buttonSize / 2) + 10
        let y = proxy.size.height - safeBottom - (buttonSize / 2) - 10

        return Button {
            showCloseConfirmation = true
        } label: {
            Image(systemName: "circlebadge")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.01))
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white.opacity(0.01), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0))
            
        }
        .position(x: max(buttonSize / 2 + 8, x), y: max(buttonSize / 2 + 8, y))
        .zIndex(500)
    }

    func floatingSettingsButton(in proxy: GeometryProxy) -> some View {
        let safeBottom = max(proxy.safeAreaInsets.bottom, 12)
        let safeTrailing = max(proxy.safeAreaInsets.trailing, 12)
        let buttonSize: CGFloat = 44
        let x = proxy.size.width - safeTrailing - (buttonSize / 2) - 10
        let y = proxy.size.height - safeBottom - (buttonSize / 2) - 10

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showSettings.toggle()
            }
        } label: {
            Image(systemName: "circlebadge")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.01))
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white.opacity(0.01), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0))
        }
        .position(x: max(buttonSize / 2 + 8, x), y: max(buttonSize / 2 + 8, y))
        .zIndex(500)
    }

    func applyScreenAwakePreference() {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
        #endif
    }

    func restoreIdleTimerPreference() {
        #if canImport(UIKit)
        if let originalIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = originalIdleTimerDisabled
        }
        originalIdleTimerDisabled = nil
        #endif
    }

    func loadInitialState() {
        let defaults = UserDefaults.standard

        let storedCount = defaults.integer(forKey: CalmPrefsKeys.bubbleCount)
        targetBubbleCount = (storedCount == 0 ? 10 : storedCount).clamped(to: CalmConstants.minBubbles...CalmConstants.maxBubbles)
        targetFireflyCount = targetBubbleCount

        let storedNominalSpeed = defaults.object(forKey: CalmPrefsKeys.nominalBubbleSpeed) as? Double
            ?? Double(CalmConstants.defaultNominalBubbleSpeed)
        nominalBubbleSpeed = storedNominalSpeed.clamped(
            to: Double(CalmConstants.nominalSpeedRange.lowerBound)...Double(CalmConstants.nominalSpeedRange.upperBound)
        )
        burstSoundEnabled = defaults.object(forKey: CalmPrefsKeys.burstSoundEnabled) as? Bool ?? true
        keepMusicWithScreenLocked = defaults.object(forKey: CalmPrefsKeys.keepMusicWithScreenLocked) as? Bool ?? false
        keepScreenAwake = defaults.object(forKey: CalmPrefsKeys.keepScreenAwake) as? Bool ?? true

        useFixedBackground = defaults.object(forKey: CalmPrefsKeys.useFixedBackground) as? Bool ?? false
        fixedBackgroundName = defaults.string(forKey: CalmPrefsKeys.fixedBackgroundName)
        let lastBackgroundName = defaults.string(forKey: CalmPrefsKeys.lastBackgroundName)
        useFixedMusic = defaults.object(forKey: CalmPrefsKeys.useFixedMusic) as? Bool ?? true
        fixedMusicName = defaults.string(forKey: CalmPrefsKeys.fixedMusicName) ?? "calma_musica_3.mp3"
        if let storedMode = defaults.string(forKey: CalmPrefsKeys.particleMode),
           let mode = CalmParticleMode(rawValue: storedMode) {
            particleMode = mode
        } else {
            particleMode = .both
        }
        if let storedSource = defaults.string(forKey: CalmPrefsKeys.phraseSource),
           let source = CalmPhraseSource(rawValue: storedSource) {
            phraseSource = source
        } else {
            phraseSource = .both
        }

        ensureCustomDirectories()
        reloadCalmAssets()
        builtInPhrases = loadPhrases()
        reloadUserPhrases()
        phraseShuffleQueue.removeAll()

        selectedBackground = resolveBackgroundAsset(
            allAssets: backgroundAssets,
            useFixed: useFixedBackground,
            fixedName: fixedBackgroundName,
            lastName: lastBackgroundName
        )
        selectedMusic = resolveAsset(
            allAssets: musicAssets,
            useFixed: useFixedMusic,
            fixedName: fixedMusicName
        )

        burstEffectURL = firstBundleFile(named: "efecto-burbuja.mp3")
        updateBackgroundImage(animated: false)
        audioController.setKeepMusicWithScreenLocked(keepMusicWithScreenLocked)
        audioController.playBackground(url: selectedMusic?.url, title: selectedMusic?.name)
        ensureParticleTargets()
    }

    func refreshBackgroundSelection(forceRandomWhenNotFixed: Bool) {
        if useFixedBackground, let fixedBackgroundName, let item = backgroundAssets.first(where: { $0.name == fixedBackgroundName }) {
            selectedBackground = item
            return
        }

        if forceRandomWhenNotFixed {
            selectedBackground = backgroundAssets.randomElement()
        }
    }

    func handleBackgroundDoubleTap() {
        guard !backgroundAssets.isEmpty else { return }

        let currentName = selectedBackground?.name

        if backgroundShuffleQueue.isEmpty {
            backgroundShuffleQueue = backgroundAssets
                .map(\.name)
                .filter { $0 != currentName }
                .shuffled()
        }

        if let currentName {
            backgroundShuffleQueue.removeAll { $0 == currentName }
        }

        if backgroundShuffleQueue.isEmpty {
            backgroundShuffleQueue = backgroundAssets
                .map(\.name)
                .filter { $0 != currentName }
                .shuffled()
        }

        guard let nextName = backgroundShuffleQueue.first else { return }
        backgroundShuffleQueue.removeFirst()

        guard let nextBackground = backgroundAssets.first(where: { $0.name == nextName }) else { return }
        UserDefaults.standard.set(nextBackground.name, forKey: CalmPrefsKeys.lastBackgroundName)
        if useFixedBackground {
            fixedBackgroundName = nextBackground.name
            UserDefaults.standard.set(nextBackground.name, forKey: CalmPrefsKeys.fixedBackgroundName)
        }
        selectedBackground = nextBackground
    }

    func refreshMusicSelection(forceRandomWhenNotFixed: Bool) {
        if useFixedMusic, let fixedMusicName, let item = musicAssets.first(where: { $0.name == fixedMusicName }) {
            selectedMusic = item
            return
        }

        if forceRandomWhenNotFixed {
            selectedMusic = musicAssets.randomElement()
        }
    }

    func updateBackgroundImage(animated: Bool = true) {
        let nextImage: PlatformImage?
        if let selectedBackground {
            #if canImport(UIKit)
            nextImage = UIImage(contentsOfFile: selectedBackground.url.path)
            #elseif canImport(AppKit)
            nextImage = NSImage(contentsOfFile: selectedBackground.url.path)
            #else
            nextImage = nil
            #endif
        } else {
            nextImage = nil
        }

        guard animated else {
            previousBackgroundUIImage = nil
            backgroundUIImage = nextImage
            backgroundTransitionProgress = 1.0
            return
        }

        previousBackgroundUIImage = backgroundUIImage
        backgroundUIImage = nextImage
        backgroundTransitionProgress = 0.0

        withAnimation(.easeInOut(duration: CalmConstants.backgroundTransitionDuration)) {
            backgroundTransitionProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + CalmConstants.backgroundTransitionDuration + 0.05) {
            if self.backgroundTransitionProgress >= 1.0 {
                self.previousBackgroundUIImage = nil
            }
        }
    }

    func listAssets(kind: CalmAssetKind, regex: NSRegularExpression?) -> [CalmAsset] {
        guard let regex else { return [] }

        let bundleAssets = bundleFilesRecursively()
            .filter { url in
                let name = url.lastPathComponent.lowercased()
                let range = NSRange(location: 0, length: name.utf16.count)
                return regex.firstMatch(in: name, options: [], range: range) != nil
            }
            .map { CalmAsset(name: $0.lastPathComponent, url: $0, isUserProvided: false) }

        let customAssets = listCustomAssets(kind: kind)
        return (bundleAssets + customAssets).sorted { lhs, rhs in
            if (kind == .background || kind == .music), lhs.isUserProvided != rhs.isUserProvided {
                return lhs.isUserProvided && !rhs.isUserProvided
            }
            let left = extractOrder(lhs.name)
            let right = extractOrder(rhs.name)
            if left == right {
                return lhs.name < rhs.name
            }
            return left < right
        }
    }

    func listCustomAssets(kind: CalmAssetKind) -> [CalmAsset] {
        guard let directory = customAssetsDirectory(for: kind) else { return [] }
        let allowedExtensions: Set<String>
        switch kind {
        case .background:
            allowedExtensions = ["jpg", "jpeg", "png", "webp", "heic", "heif"]
        case .music:
            allowedExtensions = ["mp3", "m4a", "wav", "aif", "aiff", "caf", "aac"]
        }

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return files
            .filter { url in
                let ext = url.pathExtension.lowercased()
                return allowedExtensions.contains(ext)
            }
            .map { CalmAsset(name: $0.lastPathComponent, url: $0, isUserProvided: true) }
    }

    func reloadCalmAssets() {
        backgroundAssets = listAssets(
            kind: .background,
            regex: try? NSRegularExpression(
                pattern: "calma_fondo_(\\d+)\\.(jpg|jpeg|png|webp)",
                options: [.caseInsensitive]
            )
        )
        backgroundShuffleQueue.removeAll()
        musicAssets = listAssets(
            kind: .music,
            regex: try? NSRegularExpression(
                pattern: "calma_musica_(\\d+)\\.(mp3|ogg|wav|m4a)",
                options: [.caseInsensitive]
            )
        )

        refreshBackgroundSelection(forceRandomWhenNotFixed: false)
        refreshMusicSelection(forceRandomWhenNotFixed: false)
    }

    func customRootDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("EspacioCalma", isDirectory: true)
    }

    func customAssetsDirectory(for kind: CalmAssetKind) -> URL? {
        guard let root = customRootDirectory() else { return nil }
        switch kind {
        case .background:
            return root.appendingPathComponent("Fondos", isDirectory: true)
        case .music:
            return root.appendingPathComponent("Musica", isDirectory: true)
        }
    }

    func ensureCustomDirectories() {
        let manager = FileManager.default
        [CalmAssetKind.background, .music].forEach { kind in
            guard let url = customAssetsDirectory(for: kind) else { return }
            if !manager.fileExists(atPath: url.path) {
                try? manager.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
    }

    func importUserResource(from sourceURL: URL, kind: CalmAssetKind) {
        guard let destinationDir = customAssetsDirectory(for: kind) else { return }
        ensureCustomDirectories()

        let started = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if started {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let ext = sourceURL.pathExtension.isEmpty ? (kind == .background ? "jpg" : "m4a") : sourceURL.pathExtension.lowercased()
        let prefix = (kind == .background) ? "user_fondo" : "user_musica"
        let fileName = "\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6)).\(ext)"
        let destinationURL = destinationDir.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            reloadCalmAssets()
        } catch {
            msg("Error importando recurso personalizado:", error)
        }
    }

    func deleteUserAsset(_ asset: CalmAsset, kind: CalmAssetKind) {
        guard asset.isUserProvided else { return }

        do {
            try FileManager.default.removeItem(at: asset.url)

            if kind == .background, fixedBackgroundName == asset.name {
                fixedBackgroundName = nil
                UserDefaults.standard.removeObject(forKey: CalmPrefsKeys.fixedBackgroundName)
            }

            if kind == .music, fixedMusicName == asset.name {
                fixedMusicName = nil
                UserDefaults.standard.removeObject(forKey: CalmPrefsKeys.fixedMusicName)
            }

            reloadCalmAssets()
        } catch {
            msg("Error eliminando recurso personalizado:", error)
        }
    }

    func extractOrder(_ name: String) -> Int {
        let pattern = #"(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: name, range: NSRange(location: 0, length: name.utf16.count)),
              let range = Range(match.range(at: 1), in: name),
              let value = Int(name[range])
        else {
            return Int.max
        }
        return value
    }

    func bundleFilesRecursively() -> [URL] {
        guard let resourceURL = Bundle.main.resourceURL else { return [] }
        guard let enumerator = FileManager.default.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        while let next = enumerator.nextObject() as? URL {
            let isRegular = (try? next.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            if isRegular {
                files.append(next)
            }
        }
        return files
    }

    func firstBundleFile(named fileName: String) -> URL? {
        let lookup = fileName.lowercased()
        return bundleFilesRecursively().first { $0.lastPathComponent.lowercased() == lookup }
    }

    func loadPhrases() -> [String] {
        guard let url = firstBundleFile(named: "frases_esferas.json") else {
            return defaultPhrases
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String].self, from: data)
            let cleaned = decoded.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return cleaned.isEmpty ? defaultPhrases : cleaned
        } catch {
            msg("Error cargando frases de calma:", error)
            return defaultPhrases
        }
    }

    func reloadUserPhrases() {
        guard hasCalmUserPhraseEntity() else {
            userPhraseItems = []
            return
        }
        let request = NSFetchRequest<NSManagedObject>(entityName: "CalmUserPhrase")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let objects = try CoreDataController.shared.context.fetch(request)
            userPhraseItems = objects.compactMap { object in
                guard let phrase = (object.value(forKey: "phrase") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                      !phrase.isEmpty else {
                    return nil
                }
                let createdAt = (object.value(forKey: "createdAt") as? Date) ?? .distantPast
                return CalmUserPhraseItem(objectID: object.objectID, phrase: phrase, createdAt: createdAt)
            }
        } catch {
            msg("Error cargando frases de usuario para Espacio Calma:", error)
            userPhraseItems = []
        }
    }

    func hasCalmUserPhraseEntity() -> Bool {
        let model = CoreDataController.shared.context.persistentStoreCoordinator?.managedObjectModel
        return model?.entitiesByName["CalmUserPhrase"] != nil
    }

    var defaultPhrases: [String] {
        [
            "Respira suave, todo está bien.",
            "Tu paz interior guía cada paso.",
            "Mente serena, corazón fuerte.",
            "Hoy eliges calma y claridad.",
            "Suelta tensión, abraza presencia.",
            "Cada respiración te renueva.",
            "Estás a salvo en este momento.",
            "La quietud también transforma.",
            "Tu enfoque crea equilibrio.",
            "Con calma, todo fluye mejor.",
            "Confía en tu ritmo natural.",
            "Tu energía vuelve a su centro.",
            "Respira, observa, suelta y continúa.",
            "Dentro de ti hay serenidad.",
            "Eres más grande que el ruido.",
            "Lo simple trae paz profunda.",
            "Tu atención crea bienestar.",
            "Calma por dentro, fuerza por fuera.",
            "Un instante presente lo cambia todo.",
            "La paz que buscas ya está aquí."
        ]
    }

    func startSimulation() {
        simulationTask?.cancel()
        simulationTask = Task { @MainActor in
            var lastTick = CACurrentMediaTime()
            while !Task.isCancelled {
                let nowTick = CACurrentMediaTime()
                let dt = CGFloat((nowTick - lastTick).clamped(to: 0.008...0.030))
                lastTick = nowTick
                nowMs = Self.currentTimeMs()

                stepSimulation(deltaTime: dt)

                try? await Task.sleep(nanoseconds: 16_666_667)
            }
        }
    }

    func ensureParticleTargets() {
        ensureBubbleTarget()
        ensureFireflyTarget()
    }

    func ensureBubbleTarget() {
        guard showsSpheres else {
            bubbles.removeAll()
            deformations.removeAll()
            phraseReveals.removeAll()
            pendingBurstParticleKeys = pendingBurstParticleKeys.filter { !$0.hasPrefix("bubble_") }
            return
        }
        guard viewportSize.width > 0, viewportSize.height > 0 else { return }

        while bubbles.count < targetBubbleCount {
            bubbles.append(spawnBubble())
        }

        while bubbles.count > targetBubbleCount {
            _ = bubbles.popLast()
        }
    }

    func ensureFireflyTarget() {
        guard showsFireflies else {
            fireflies.removeAll()
            fireflyAgitatedUntil.removeAll()
            fireflyAgitationSeed.removeAll()
            fireflyAgitationCenter.removeAll()
            fireflyFlashes.removeAll()
            pendingBurstParticleKeys = pendingBurstParticleKeys.filter { !$0.hasPrefix("firefly_") }
            return
        }
        guard viewportSize.width > 0, viewportSize.height > 0 else { return }

        while fireflies.count < targetFireflyCount {
            fireflies.append(spawnFirefly())
        }

        while fireflies.count > targetFireflyCount {
            _ = fireflies.popLast()
        }
    }

    func spawnBubble() -> CalmBubble {
        let baseRadius = CGFloat.random(in: CalmConstants.bubbleRadiusMin...CalmConstants.bubbleRadiusMax)
        let radius = max(14, baseRadius * CalmConstants.developerBubbleSizeScale)
        let x = CGFloat.random(in: 0.05...0.95) * max(viewportSize.width, radius * 2)
        let y = CGFloat.random(in: 0.10...0.90) * max(viewportSize.height, radius * 2)
        let speed = randomizedSpawnSpeed()
        let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        let phrase = nextPhraseForBubble()
        let hue = Double.random(in: 170...350) / 360.0
        let saturation = Double.random(in: 0.20...0.44)

        let bubble = CalmBubble(
            id: nextBubbleID,
            x: x,
            y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            radius: radius,
            phrase: phrase,
            tint: Color(hue: hue, saturation: saturation, brightness: 1.0, opacity: 0.42),
            bornAtMs: nowMs
        )

        nextBubbleID += 1
        return bubble
    }

    func spawnFirefly() -> CalmFirefly {
        spawnFirefly(at: nil)
    }

    func spawnFirefly(at position: CGPoint?) -> CalmFirefly {
        let radius = CGFloat.random(in: CalmConstants.fireflyRadiusRange)
        let x: CGFloat
        let y: CGFloat
        if let position {
            x = position.x.clamped(to: radius...(max(viewportSize.width - radius, radius)))
            y = position.y.clamped(to: radius...(max(viewportSize.height - radius, radius)))
        } else {
            x = CGFloat.random(in: radius...(max(viewportSize.width - radius, radius)))
            y = CGFloat.random(in: radius...(max(viewportSize.height - radius, radius)))
        }
        let speed = CGFloat.random(in: fireflySpeedRange)
        let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        let firefly = CalmFirefly(
            id: nextFireflyID,
            x: x,
            y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            radius: radius,
            driftSeed: CGFloat.random(in: 0...1000),
            twinkleSeed: CGFloat.random(in: 0...1000),
            phrase: nextPhraseForBubble()
        )
        nextFireflyID += 1
        return firefly
    }

    func stepSimulation(deltaTime dt: CGFloat) {
        guard viewportSize.width > 0, viewportSize.height > 0 else { return }

        if showsSpheres {
        for index in bubbles.indices {
            var bubble = bubbles[index]
            var nx = bubble.x + bubble.vx * dt
            var ny = bubble.y + bubble.vy * dt
            var nvx = bubble.vx
            var nvy = bubble.vy
            var wallImpactAngle: CGFloat?
            var wallImpactSpeed: CGFloat = 0

            if nx - bubble.radius < 0 {
                wallImpactSpeed = max(wallImpactSpeed, abs(nvx))
                wallImpactAngle = .pi * 0.5
                nx = bubble.radius
                nvx = abs(nvx) * CalmConstants.wallRestitution
            } else if nx + bubble.radius > viewportSize.width {
                wallImpactSpeed = max(wallImpactSpeed, abs(nvx))
                wallImpactAngle = .pi * 0.5
                nx = viewportSize.width - bubble.radius
                nvx = -abs(nvx) * CalmConstants.wallRestitution
            }

            if ny - bubble.radius < 0 {
                wallImpactSpeed = max(wallImpactSpeed, abs(nvy))
                wallImpactAngle = 0
                ny = bubble.radius
                nvy = abs(nvy) * CalmConstants.wallRestitution
            } else if ny + bubble.radius > viewportSize.height {
                wallImpactSpeed = max(wallImpactSpeed, abs(nvy))
                wallImpactAngle = 0
                ny = viewportSize.height - bubble.radius
                nvy = -abs(nvy) * CalmConstants.wallRestitution
            }

            let corrected = enforceMinimumSpeed(vx: nvx, vy: nvy)
            bubble.x = nx
            bubble.y = ny
            bubble.vx = corrected.0
            bubble.vy = corrected.1
            bubbles[index] = bubble

            if let wallImpactAngle, wallImpactSpeed > 18 {
                let strength = min(max(wallImpactSpeed / 300.0, 0.02), 0.08)
                deformations[bubble.id] = BubbleDeformation(
                    angleRad: wallImpactAngle,
                    strength: strength,
                    bornAtMs: nowMs
                )
            }
        }

        if bubbles.count > 1 {
            for i in 0..<(bubbles.count - 1) {
                for j in (i + 1)..<bubbles.count {
                    var a = bubbles[i]
                    var b = bubbles[j]

                    let dx = b.x - a.x
                    let dy = b.y - a.y
                    let distance = sqrt(dx * dx + dy * dy)
                    let minDistance = a.radius + b.radius
                    if distance <= 0.001 || distance >= minDistance { continue }

                    let nx = dx / distance
                    let ny = dy / distance
                    let tx = -ny
                    let ty = nx

                    let m1 = a.radius * a.radius
                    let m2 = b.radius * b.radius

                    let v1n = a.vx * nx + a.vy * ny
                    let v1t = a.vx * tx + a.vy * ty
                    let v2n = b.vx * nx + b.vy * ny
                    let v2t = b.vx * tx + b.vy * ty
                    let impactSpeed = abs(v1n - v2n)

                    let v1nAfter = ((v1n * (m1 - m2)) + (2 * m2 * v2n)) / (m1 + m2)
                    let v2nAfter = ((v2n * (m2 - m1)) + (2 * m1 * v1n)) / (m1 + m2)

                    let correctedV1n = v1nAfter * CalmConstants.bubbleRestitution
                    let correctedV2n = v2nAfter * CalmConstants.bubbleRestitution

                    let avx = correctedV1n * nx + v1t * tx
                    let avy = correctedV1n * ny + v1t * ty
                    let bvx = correctedV2n * nx + v2t * tx
                    let bvy = correctedV2n * ny + v2t * ty

                    let overlap = max(minDistance - distance, 0)
                    let totalMass = m1 + m2
                    let shiftA = overlap * (m2 / totalMass)
                    let shiftB = overlap * (m1 / totalMass)

                    let adjustedA = enforceMinimumSpeed(vx: avx, vy: avy)
                    a.x = (a.x - nx * shiftA).clamped(to: a.radius...(viewportSize.width - a.radius))
                    a.y = (a.y - ny * shiftA).clamped(to: a.radius...(viewportSize.height - a.radius))
                    a.vx = adjustedA.0
                    a.vy = adjustedA.1

                    let adjustedB = enforceMinimumSpeed(vx: bvx, vy: bvy)
                    b.x = (b.x + nx * shiftB).clamped(to: b.radius...(viewportSize.width - b.radius))
                    b.y = (b.y + ny * shiftB).clamped(to: b.radius...(viewportSize.height - b.radius))
                    b.vx = adjustedB.0
                    b.vy = adjustedB.1

                    bubbles[i] = a
                    bubbles[j] = b

                    if impactSpeed > 26 {
                        let stretchAngle = atan2(ny, nx) + (.pi * 0.5)
                        let strength = min(max(impactSpeed / 360.0, 0.03), 0.10)

                        deformations[a.id] = BubbleDeformation(
                            angleRad: stretchAngle,
                            strength: strength,
                            bornAtMs: nowMs
                        )

                        deformations[b.id] = BubbleDeformation(
                            angleRad: stretchAngle,
                            strength: strength,
                            bornAtMs: nowMs
                        )
                    }
                }
            }
        }
        } else {
            bubbles.removeAll()
            deformations.removeAll()
        }

        if showsFireflies {
            stepFireflies(deltaTime: dt)
        } else {
            fireflies.removeAll()
        }

        if !particles.isEmpty {
            let currentTime = nowMs
            particles = particles.compactMap { particle in
                let age = currentTime - particle.bornAtMs
                if age >= particle.lifeMs { return nil }

                var updated = particle
                let gravity: CGFloat = 45
                updated.x += updated.vx * dt
                updated.y += updated.vy * dt
                updated.vy += gravity * dt
                return updated
            }
        }

        if !phraseReveals.isEmpty {
            phraseReveals.removeAll { reveal in
                let age = nowMs - reveal.bornAtMs
                return age > (reveal.revealDelayMs + CalmConstants.phraseLifetimeMs)
            }
        }

        if !deformations.isEmpty {
            let expiredIDs = deformations
                .filter { nowMs - $0.value.bornAtMs > CalmConstants.deformationMs }
                .map { $0.key }

            for id in expiredIDs {
                deformations.removeValue(forKey: id)
            }
        }

        if !fireflyFlashes.isEmpty {
            fireflyFlashes.removeAll { flash in
                (nowMs - flash.bornAtMs) > flash.lifeMs
            }
        }

        if !fireflyAgitatedUntil.isEmpty {
            let validIDs = Set(fireflies.map(\.id))
            fireflyAgitatedUntil = fireflyAgitatedUntil.filter { id, until in
                validIDs.contains(id) && until > nowMs
            }
            fireflyAgitationSeed = fireflyAgitationSeed.filter { validIDs.contains($0.key) }
            fireflyAgitationCenter = fireflyAgitationCenter.filter { validIDs.contains($0.key) }
        }
    }

    func stepFireflies(deltaTime dt: CGFloat) {
        guard !fireflies.isEmpty else { return }
        let t = CGFloat(nowMs) / 1000.0
        let speedRange = fireflySpeedRange
        let minX: CGFloat = 0
        let minY: CGFloat = 0
        let maxX: CGFloat = viewportSize.width
        let maxY: CGFloat = viewportSize.height

        var updated = fireflies

        for index in updated.indices {
            var firefly = updated[index]
            let isAgitated = (fireflyAgitatedUntil[firefly.id] ?? 0) > nowMs
            let driftX = sin((t * 0.7) + firefly.driftSeed) * 18.0
            let driftY = cos((t * 0.55) + firefly.driftSeed * 0.77) * 18.0
            firefly.vx += driftX * dt
            firefly.vy += driftY * dt
            firefly.vx *= 0.982
            firefly.vy *= 0.982

            if let agitatedUntil = fireflyAgitatedUntil[firefly.id], agitatedUntil > nowMs {
                let seed = fireflyAgitationSeed[firefly.id] ?? firefly.driftSeed
                let center = fireflyAgitationCenter[firefly.id] ?? CGPoint(x: firefly.x, y: firefly.y)
                let remaining = CGFloat(agitatedUntil - nowMs) / CGFloat(CalmConstants.fireflyAgitationDurationMs)
                let agitation = remaining.clamped(to: 0...1)
                let agitationIntensity = CalmConstants.fireflyAgitationIntensity

                // Giro orgánico: mezcla de órbita base + wobble angular + cambios de radio/fase.
                let basePhase = (t * (14.0 + (seed * 0.03))) + seed
                let phaseWobble = sin((t * 8.7) + seed * 0.83) * 0.95 + cos((t * 5.2) + seed * 1.37) * 0.42
                let phase = basePhase + phaseWobble
                let orbitRadius = (2.8 + (5.6 * agitation)
                    + (sin((t * 6.4) + seed * 1.9) * 1.8)
                    + (cos((t * 11.3) + seed * 0.57) * 1.1)) * agitationIntensity
                let targetX = center.x + cos(phase) * orbitRadius
                let targetY = center.y + sin(phase * 1.17) * orbitRadius
                let steerGain = 9.0 + agitation * (23.0 * agitationIntensity)
                var steerX = (targetX - firefly.x) * steerGain
                var steerY = (targetY - firefly.y) * steerGain

                // Vibración irregular con trayectorias muy cortas tipo abeja.
                let jitterX = (sin((t * 44.0) + seed * 2.4) + cos((t * 29.0) + seed * 0.9)) * (8.8 * agitation * agitationIntensity)
                let jitterY = (cos((t * 39.0) + seed * 1.7) - sin((t * 35.0) + seed * 1.3)) * (8.8 * agitation * agitationIntensity)

                // Añade par de giro variable para incrementar cambios de dirección.
                let lateralSign = sin((t * 13.0) + seed * 0.41) + sin((t * 7.0) + seed * 1.71)
                let lateral = (5.6 * agitationIntensity * agitation) * lateralSign
                let norm = max(0.001, sqrt((steerX * steerX) + (steerY * steerY)))
                let tx = -steerY / norm
                let ty = steerX / norm
                steerX += tx * lateral
                steerY += ty * lateral

                firefly.vx += (steerX + jitterX) * dt
                firefly.vy += (steerY + jitterY) * dt
                firefly.vx *= 0.81
                firefly.vy *= 0.81
            }

            let speed = sqrt((firefly.vx * firefly.vx) + (firefly.vy * firefly.vy))
            let speedUpperBound = isAgitated ? (speedRange.upperBound * CalmConstants.fireflyAgitationSpeedMultiplier) : speedRange.upperBound
            let speedLowerBound = isAgitated ? (speedRange.lowerBound * 0.85) : speedRange.lowerBound
            if speed > speedUpperBound {
                let scale = speedUpperBound / speed
                firefly.vx *= scale
                firefly.vy *= scale
            } else if speed < speedLowerBound {
                let angle = atan2(firefly.vy, firefly.vx)
                firefly.vx = cos(angle) * speedLowerBound
                firefly.vy = sin(angle) * speedLowerBound
            }
            updated[index] = firefly
        }

        // Atracción y fusión suave entre luciérnagas cercanas.
        let attractionDistance = CalmConstants.fireflyMergeAttractionDistance
        let attractionStrength = CalmConstants.fireflyMergeAttractionStrength
        let softCapture = CalmConstants.fireflyMergeSoftCaptureFactor
        let mergeRelativeSpeedThreshold = CalmConstants.fireflyMergeRelativeSpeedThreshold
        var idsToRemove: Set<Int> = []
        var mergePoints: [CGPoint] = []

        if updated.count > 1 {
            for i in 0..<(updated.count - 1) {
                if idsToRemove.contains(updated[i].id) { continue }
                for j in (i + 1)..<updated.count {
                    if idsToRemove.contains(updated[j].id) { continue }

                    let dx = updated[j].x - updated[i].x
                    let dy = updated[j].y - updated[i].y
                    let distance = sqrt((dx * dx) + (dy * dy))
                    guard distance > 0.001 else { continue }

                    let nx = dx / distance
                    let ny = dy / distance

                    if distance < attractionDistance {
                        let pull = ((attractionDistance - distance) / attractionDistance) * attractionStrength * dt
                        updated[i].vx += nx * pull
                        updated[i].vy += ny * pull
                        updated[j].vx -= nx * pull
                        updated[j].vy -= ny * pull
                    }

                    let sumRadius = updated[i].radius + updated[j].radius
                    let softMergeDistance = max(sumRadius * 1.9, 10)
                    if distance <= softMergeDistance {
                        let midpoint = CGPoint(
                            x: (updated[i].x + updated[j].x) * 0.5,
                            y: (updated[i].y + updated[j].y) * 0.5
                        )
                        let phase = ((softMergeDistance - distance) / softMergeDistance).clamped(to: 0...1)
                        let settle = softCapture * phase
                        updated[i].x += (midpoint.x - updated[i].x) * settle
                        updated[i].y += (midpoint.y - updated[i].y) * settle
                        updated[j].x += (midpoint.x - updated[j].x) * settle
                        updated[j].y += (midpoint.y - updated[j].y) * settle
                        updated[i].vx *= (1 - (0.18 * phase))
                        updated[i].vy *= (1 - (0.18 * phase))
                        updated[j].vx *= (1 - (0.18 * phase))
                        updated[j].vy *= (1 - (0.18 * phase))
                    }

                    let mergeDistance = max(sumRadius * 1.16, 7.5)
                    let relativeSpeed = sqrt(
                        pow(updated[i].vx - updated[j].vx, 2) + pow(updated[i].vy - updated[j].vy, 2)
                    )
                    if distance <= mergeDistance && relativeSpeed <= mergeRelativeSpeedThreshold {
                        idsToRemove.insert(updated[i].id)
                        idsToRemove.insert(updated[j].id)
                        mergePoints.append(
                            CGPoint(
                                x: (updated[i].x + updated[j].x) * 0.5,
                                y: (updated[i].y + updated[j].y) * 0.5
                            )
                        )
                        break
                    }
                }
            }
        }

        for index in updated.indices {
            if idsToRemove.contains(updated[index].id) { continue }
            var firefly = updated[index]
            let isAgitated = (fireflyAgitatedUntil[firefly.id] ?? 0) > nowMs

            let speed = sqrt((firefly.vx * firefly.vx) + (firefly.vy * firefly.vy))
            let speedUpperBound = isAgitated ? (speedRange.upperBound * CalmConstants.fireflyAgitationSpeedMultiplier) : speedRange.upperBound
            let speedLowerBound = isAgitated ? (speedRange.lowerBound * 0.85) : speedRange.lowerBound
            if speed > speedUpperBound {
                let scale = speedUpperBound / speed
                firefly.vx *= scale
                firefly.vy *= scale
            } else if speed < speedLowerBound {
                let angle = atan2(firefly.vy, firefly.vx)
                firefly.vx = cos(angle) * speedLowerBound
                firefly.vy = sin(angle) * speedLowerBound
            }

            firefly.x += firefly.vx * dt
            firefly.y += firefly.vy * dt

            if firefly.x < minX {
                firefly.x = minX
                firefly.vx = abs(firefly.vx)
            } else if firefly.x > maxX {
                firefly.x = maxX
                firefly.vx = -abs(firefly.vx)
            }

            if firefly.y < minY {
                firefly.y = minY
                firefly.vy = abs(firefly.vy)
            } else if firefly.y > maxY {
                firefly.y = maxY
                firefly.vy = -abs(firefly.vy)
            }

            updated[index] = firefly
        }

        if !idsToRemove.isEmpty {
            fireflyAgitatedUntil = fireflyAgitatedUntil.filter { !idsToRemove.contains($0.key) }
            fireflyAgitationSeed = fireflyAgitationSeed.filter { !idsToRemove.contains($0.key) }
            fireflyAgitationCenter = fireflyAgitationCenter.filter { !idsToRemove.contains($0.key) }
            for id in idsToRemove {
                pendingBurstParticleKeys.remove("firefly_\(id)")
            }
        }

        fireflies = updated.filter { !idsToRemove.contains($0.id) }

        if !mergePoints.isEmpty {
            for mergePoint in mergePoints {
                registerFireflyMerge(at: mergePoint)
                fireflies.append(spawnFirefly(at: mergePoint))
            }
        }

        // Mantiene siempre el conteo configurado en Ajustes.
        while fireflies.count < targetFireflyCount {
            fireflies.append(spawnFirefly())
        }
        while fireflies.count > targetFireflyCount {
            _ = fireflies.popLast()
        }
    }

    func particleKey(_ particle: CalmInteractiveParticle) -> String {
        switch particle {
        case .bubble(let id): return "bubble_\(id)"
        case .firefly(let id): return "firefly_\(id)"
        }
    }

    func particleHit(at location: CGPoint) -> CalmInteractiveParticle? {
        if showsSpheres,
           let bubble = bubbles.reversed().first(where: { bubble in
               let dx = bubble.x - location.x
               let dy = bubble.y - location.y
               return dx * dx + dy * dy <= bubble.radius * bubble.radius
           }) {
            return .bubble(bubble.id)
        }

        if showsFireflies,
           let firefly = fireflies.reversed().first(where: { firefly in
               let dx = firefly.x - location.x
               let dy = firefly.y - location.y
               let hitRadius = max(firefly.radius * 2.8, 14)
               return dx * dx + dy * dy <= hitRadius * hitRadius
           }) {
            return .firefly(firefly.id)
        }

        return nil
    }

    func handleDragChanged(_ value: DragGesture.Value) {
        if draggedParticle == nil {
            guard let hit = particleHit(at: value.startLocation) else { return }
            draggedParticle = hit
        }

        guard let draggedParticle else { return }

        switch draggedParticle {
        case .bubble(let bubbleID):
            guard let index = bubbles.firstIndex(where: { $0.id == bubbleID }) else { return }
            var bubble = bubbles[index]
            let minX = bubble.radius
            let maxX = max(bubble.radius, viewportSize.width - bubble.radius)
            let minY = bubble.radius
            let maxY = max(bubble.radius, viewportSize.height - bubble.radius)

            let targetX = value.location.x.clamped(to: minX...maxX)
            let targetY = value.location.y.clamped(to: minY...maxY)

            // Seguimiento mínimo y suave del toque: la esfera apenas se ajusta al dedo.
            let followFactor: CGFloat = 0.10
            bubble.x += (targetX - bubble.x) * followFactor
            bubble.y += (targetY - bubble.y) * followFactor

            // Atenúa la inercia durante el arrastre sin anularla por completo.
            bubble.vx *= 0.70
            bubble.vy *= 0.70
            bubbles[index] = bubble

            let dx = value.translation.width
            let dy = value.translation.height
            if abs(dx) + abs(dy) > 0.8 {
                let distance = sqrt(dx * dx + dy * dy)
                let stretchAngle = atan2(dy, dx) + (.pi * 0.5)
                let strength = min(max(distance / 180.0, 0.05), 0.16)
                deformations[bubble.id] = BubbleDeformation(
                    angleRad: stretchAngle,
                    strength: strength,
                    bornAtMs: nowMs
                )
            }
        case .firefly(let fireflyID):
            guard let index = fireflies.firstIndex(where: { $0.id == fireflyID }) else { return }
            var firefly = fireflies[index]
            let minX = firefly.radius
            let maxX = max(firefly.radius, viewportSize.width - firefly.radius)
            let minY = firefly.radius
            let maxY = max(firefly.radius, viewportSize.height - firefly.radius)

            let targetX = value.location.x.clamped(to: minX...maxX)
            let targetY = value.location.y.clamped(to: minY...maxY)
            let followFactor: CGFloat = 0.10
            firefly.x += (targetX - firefly.x) * followFactor
            firefly.y += (targetY - firefly.y) * followFactor
            firefly.vx *= 0.72
            firefly.vy *= 0.72
            fireflies[index] = firefly
        }
    }

    func handleDragEnded(_ value: DragGesture.Value) {
        guard let draggedParticle else { return }
        defer { self.draggedParticle = nil }

        let translation = value.translation
        let dragDistance = sqrt(translation.width * translation.width + translation.height * translation.height)

        if dragDistance < 14 {
            handleTap(at: value.location)
            return
        }

        let predictedDx = value.predictedEndLocation.x - value.location.x
        let predictedDy = value.predictedEndLocation.y - value.location.y
        let launchDx = translation.width + (predictedDx * 0.18)
        let launchDy = translation.height + (predictedDy * 0.18)
        let launchVectorLength = sqrt(launchDx * launchDx + launchDy * launchDy)

        guard launchVectorLength > 0.001 else { return }

        let nx = launchDx / launchVectorLength
        let ny = launchDy / launchVectorLength
        let predictedDistance = sqrt(predictedDx * predictedDx + predictedDy * predictedDy)

        switch draggedParticle {
        case .bubble(let bubbleID):
            guard let index = bubbles.firstIndex(where: { $0.id == bubbleID }) else { return }
            // Impulso de lanzamiento mucho más contenido para mantener el efecto de calma.
            let impulse = min(max((dragDistance * 1.15) + (predictedDistance * 0.35), 24), 95)
            let adjusted = enforceMinimumSpeed(vx: nx * impulse, vy: ny * impulse)
            bubbles[index].vx = adjusted.0
            bubbles[index].vy = adjusted.1
            deformations[bubbleID] = BubbleDeformation(
                angleRad: atan2(ny, nx) + (.pi * 0.5),
                strength: min(max(impulse / 700.0, 0.05), 0.14),
                bornAtMs: nowMs
            )
        case .firefly(let fireflyID):
            guard let index = fireflies.firstIndex(where: { $0.id == fireflyID }) else { return }
            let fireflyImpulse = min(max((dragDistance * 0.65) + (predictedDistance * 0.18), 8), 32)
            fireflies[index].vx = nx * fireflyImpulse
            fireflies[index].vy = ny * fireflyImpulse
            fireflyAgitatedUntil[fireflyID] = nowMs + CalmConstants.fireflyAgitationDurationMs
            fireflyAgitationSeed[fireflyID] = CGFloat.random(in: 0...1000)
            fireflyAgitationCenter[fireflyID] = CGPoint(x: fireflies[index].x, y: fireflies[index].y)
        }
    }

    func handleTap(at location: CGPoint) {
        guard let hit = particleHit(at: location) else { return }
        let key = particleKey(hit)
        if pendingBurstParticleKeys.contains(key) { return }
        pendingBurstParticleKeys.insert(key)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 110_000_000)

            switch hit {
            case .bubble(let bubbleID):
                guard let bubbleToBurst = bubbles.first(where: { $0.id == bubbleID }) else {
                    pendingBurstParticleKeys.remove(key)
                    return
                }
                let dx = location.x - bubbleToBurst.x
                let dy = location.y - bubbleToBurst.y
                let stretchAngle = atan2(dy, dx) + (.pi * 0.5)
                deformations[bubbleID] = BubbleDeformation(
                    angleRad: stretchAngle,
                    strength: 0.13,
                    bornAtMs: nowMs
                )
                explodeBubble(bubbleToBurst)
            case .firefly(let fireflyID):
                guard let fireflyToBurst = fireflies.first(where: { $0.id == fireflyID }) else {
                    pendingBurstParticleKeys.remove(key)
                    return
                }
                explodeFirefly(fireflyToBurst)
            }
            pendingBurstParticleKeys.remove(key)
        }
    }

    func explodeBubble(_ hit: CalmBubble) {
        bubbles.removeAll { $0.id == hit.id }

        phraseReveals.append(
            CalmPhraseReveal(
                id: nextFXID,
                phrase: hit.phrase,
                x: hit.x,
                y: hit.y,
                bornAtMs: nowMs,
                revealDelayMs: CalmConstants.phraseRevealDelayMs
            )
        )
        nextFXID += 1

        // Configuración del campo de explosión de partículas cuando estalla una esfera.
        for _ in 0..<10 {
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let speed = CGFloat.random(in: 32...110)
            particles.append(
                CalmParticle(
                    id: nextFXID,
                    x: hit.x,
                    y: hit.y,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    radius: CGFloat.random(in: 1.8...4.6),
                    lifeMs: Int64.random(in: 380...800),
                    bornAtMs: nowMs,
                    color: hit.tint.opacity(0.6)
                )
            )
            nextFXID += 1
        }

        if burstSoundEnabled {
            audioController.playBurst(url: burstEffectURL)
        }

        if viewportSize.width > 0, viewportSize.height > 0 {
            bubbles.append(spawnBubble())
        }
    }

    func explodeFirefly(_ hit: CalmFirefly) {
        fireflies.removeAll { $0.id == hit.id }

        phraseReveals.append(
            CalmPhraseReveal(
                id: nextFXID,
                phrase: hit.phrase,
                x: hit.x,
                y: hit.y,
                bornAtMs: nowMs,
                revealDelayMs: CalmConstants.phraseRevealDelayMs
            )
        )
        nextFXID += 1

        for _ in 0..<7 {
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let speed = CGFloat.random(in: 20...72)
            particles.append(
                CalmParticle(
                    id: nextFXID,
                    x: hit.x,
                    y: hit.y,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    radius: CGFloat.random(in: 1.4...3.2),
                    lifeMs: Int64.random(in: 320...700),
                    bornAtMs: nowMs,
                    color: Color(red: 1.0, green: 0.86, blue: 0.42, opacity: 0.65)
                )
            )
            nextFXID += 1
        }

        if burstSoundEnabled {
            audioController.playBurst(url: burstEffectURL)
        }

        if viewportSize.width > 0, viewportSize.height > 0 {
            fireflies.append(spawnFirefly())
        }
    }

    func registerFireflyMerge(at point: CGPoint) {
        let flashIntensity = CalmConstants.fireflyMergeFlashIntensity
        fireflyFlashes.append(
            CalmFireflyFlash(
                id: nextFXID,
                x: point.x,
                y: point.y,
                bornAtMs: nowMs,
                lifeMs: 560,
                maxRadius: 30 * (0.9 + (flashIntensity * 0.22))
            )
        )
        nextFXID += 1
    }

    func drawBubbles(context: GraphicsContext) {
        for bubble in bubbles {
            let age = CGFloat(nowMs - bubble.bornAtMs)
            let appearProgress = (age / CGFloat(CalmConstants.bubbleAppearMs)).clamped(to: 0...1)
            let easedAppear = appearProgress * appearProgress * (3 - 2 * appearProgress)
            let radius = bubble.radius * max(easedAppear, 0.02)

            let deformation = deformations[bubble.id]
            let elapsed = deformation.map { CGFloat(nowMs - $0.bornAtMs) } ?? 0
            let deformProgress = (elapsed / CGFloat(CalmConstants.deformationMs)).clamped(to: 0...1)
            let deformEnvelope = sin(deformProgress * .pi).clamped(to: 0...1)
            let deformStrength = (deformation?.strength ?? 0) * deformEnvelope
            let scaleMajor = 1 + deformStrength * 0.65
            let scaleMinor = max(1 - deformStrength * 0.35, 0.86)
            let rotation = Angle(radians: Double(deformation?.angleRad ?? 0))

            var bubbleContext = context
            bubbleContext.translateBy(x: bubble.x, y: bubble.y)
            if deformStrength > 0.001 {
                bubbleContext.rotate(by: rotation)
                bubbleContext.scaleBy(x: scaleMajor, y: scaleMinor)
            }

            let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
            let circlePath = Path(ellipseIn: rect)

            bubbleContext.fill(
                circlePath,
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.58), bubble.tint, bubble.tint.opacity(0.24)]),
                    center: .zero,
                    startRadius: radius * 0.05,
                    endRadius: radius * 1.2
                )
            )

            bubbleContext.stroke(
                circlePath,
                with: .color(Color.white.opacity(0.45)),
                lineWidth: 1.6
            )

        }
    }

    func drawFireflies(context: GraphicsContext) {
        let t = CGFloat(nowMs) / 1000.0
        for firefly in fireflies {
            let agitationMs = max(0, (fireflyAgitatedUntil[firefly.id] ?? 0) - nowMs)
            let agitationProgress = CGFloat(agitationMs) / CGFloat(CalmConstants.fireflyAgitationDurationMs)
            let drawX = firefly.x
            let drawY = firefly.y

            let twinkle = (sin((t * 1.8) + firefly.twinkleSeed) + 1) * 0.5
            let alpha = 0.20 + (twinkle * 0.55) + (agitationProgress * 0.15)
            let glowRadius = firefly.radius * (2.2 + (twinkle * 1.3))

            let glowRect = CGRect(
                x: drawX - glowRadius,
                y: drawY - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            )
            context.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 1.0, green: 0.97, blue: 0.70, opacity: alpha),
                        Color(red: 1.0, green: 0.82, blue: 0.35, opacity: alpha * 0.42),
                        Color(red: 1.0, green: 0.82, blue: 0.35, opacity: 0.0)
                    ]),
                    center: CGPoint(x: drawX, y: drawY),
                    startRadius: firefly.radius * 0.2,
                    endRadius: glowRadius
                )
            )

            let coreRect = CGRect(
                x: drawX - firefly.radius,
                y: drawY - firefly.radius,
                width: firefly.radius * 2,
                height: firefly.radius * 2
            )
            context.fill(
                Path(ellipseIn: coreRect),
                with: .color(Color(red: 1.0, green: 0.95, blue: 0.68, opacity: 0.45 + (twinkle * 0.4)))
            )
        }
    }

    func drawFireflyFlashes(context: GraphicsContext) {
        guard !fireflyFlashes.isEmpty else { return }

        let flashIntensity = CalmConstants.fireflyMergeFlashIntensity
        for flash in fireflyFlashes {
            let age = nowMs - flash.bornAtMs
            let progress = (CGFloat(age) / CGFloat(flash.lifeMs)).clamped(to: 0...1)
            let pulse = sin(progress * .pi).clamped(to: 0...1)
            let smoothPulse = pulse * pulse * (3 - 2 * pulse)
            let radius = flash.maxRadius * (0.82 + (0.22 * smoothPulse))
            let alpha = (0.26 * smoothPulse * flashIntensity).clamped(to: 0...0.52)

            let rect = CGRect(
                x: flash.x - radius,
                y: flash.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.62 * alpha),
                        Color(red: 1.0, green: 0.95, blue: 0.72, opacity: 0.46 * alpha),
                        Color(red: 1.0, green: 0.90, blue: 0.52, opacity: 0.0)
                    ]),
                    center: CGPoint(x: flash.x, y: flash.y),
                    startRadius: radius * 0.04,
                    endRadius: radius
                )
            )
        }
    }

    func drawParticles(context: GraphicsContext) {
        guard !particles.isEmpty else { return }

        for particle in particles {
            let alpha = (1 - CGFloat(nowMs - particle.bornAtMs) / CGFloat(particle.lifeMs)).clamped(to: 0...1)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: particle.x - particle.radius,
                    y: particle.y - particle.radius,
                    width: particle.radius * 2,
                    height: particle.radius * 2
                )),
                with: .color(particle.color.opacity(alpha))
            )
        }
    }

    func resolveAsset(allAssets: [CalmAsset], useFixed: Bool, fixedName: String?) -> CalmAsset? {
        guard !allAssets.isEmpty else { return nil }
        if useFixed,
           let fixedName,
           let fixedAsset = allAssets.first(where: { $0.name == fixedName }) {
            return fixedAsset
        }
        return allAssets.randomElement()
    }

    func resolveBackgroundAsset(
        allAssets: [CalmAsset],
        useFixed: Bool,
        fixedName: String?,
        lastName: String?
    ) -> CalmAsset? {
        guard !allAssets.isEmpty else { return nil }

        if useFixed,
           let fixedName,
           let fixedAsset = allAssets.first(where: { $0.name == fixedName }) {
            return fixedAsset
        }

        if let lastName,
           let lastAsset = allAssets.first(where: { $0.name == lastName }) {
            return lastAsset
        }

        return allAssets.first
    }

    func nextPhraseForBubble() -> String {
        let inbuilt = builtInPhrases.isEmpty ? defaultPhrases : builtInPhrases
        let user = userPhraseItems.map(\.phrase)
        let source: [String]
        switch phraseSource {
        case .inbuilt:
            source = inbuilt
        case .user:
            source = user
        case .both:
            source = inbuilt + user
        }
        guard !source.isEmpty else { return "Respira" }

        if phraseShuffleQueue.isEmpty {
            phraseShuffleQueue = source.shuffled()
        }

        let phrase = phraseShuffleQueue.removeFirst()
        return phrase
    }

    func twoWordsPerLine(_ phrase: String) -> String {
        let words = phrase
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        guard words.count > 2 else {
            return words.joined(separator: " ")
        }

        var lines: [String] = []
        var index = 0
        while index < words.count {
            let next = min(index + 2, words.count)
            lines.append(words[index..<next].joined(separator: " "))
            index = next
        }

        return lines.joined(separator: "\n")
    }

    func phraseCardSize(for formattedPhrase: String) -> CGSize {
        let lines = formattedPhrase.split(separator: "\n").map(String.init)
        let longestLineCount = lines.map(\.count).max() ?? 1
        let lineCount = max(lines.count, 1)

        // Estimación para mantener un cuadro contenido y discreto según texto.
        let estimatedTextWidth = CGFloat(longestLineCount) * 9.0
        let width = min(max(estimatedTextWidth + 32.0, 112.0), min(280.0, viewportSize.width * 0.74))

        let estimatedTextHeight = CGFloat(lineCount) * 24.0
        let height = min(max(estimatedTextHeight + 24.0, 56.0), 220.0)

        return CGSize(width: width, height: height)
    }

    func randomizedSpawnSpeed() -> CGFloat {
        let target = CGFloat(nominalBubbleSpeed)
        let spread = max(target * 0.35, 2)
        let minValue = max(CalmConstants.nominalSpeedRange.lowerBound, target - spread)
        let maxValue = min(CalmConstants.nominalSpeedRange.upperBound, target + spread)
        return CGFloat.random(in: minValue...maxValue)
    }

    var fireflySpeedRange: ClosedRange<CGFloat> {
        let sharedTarget = CGFloat(nominalBubbleSpeed) * 0.35
        let target = sharedTarget.clamped(to: 3.5...15.0)
        let lower = max(2.5, target * 0.58)
        let upper = min(20.0, target * 1.55)
        return lower...max(lower + 0.2, upper)
    }

    func rebalanceBubbleSpeeds() {
        guard !bubbles.isEmpty else { return }

        let target = CGFloat(nominalBubbleSpeed)
        let minValue = max(CalmConstants.nominalSpeedRange.lowerBound, target * 0.85)
        let maxValue = min(CalmConstants.nominalSpeedRange.upperBound, target * 1.15)

        for index in bubbles.indices {
            var bubble = bubbles[index]
            let currentSpeed = sqrt(bubble.vx * bubble.vx + bubble.vy * bubble.vy)
            let angle = currentSpeed > 0.001
                ? atan2(bubble.vy, bubble.vx)
                : CGFloat.random(in: 0...(CGFloat.pi * 2))
            let adjustedSpeed = CGFloat.random(in: minValue...maxValue)
            bubble.vx = cos(angle) * adjustedSpeed
            bubble.vy = sin(angle) * adjustedSpeed
            bubbles[index] = bubble
        }
    }

    func rebalanceFireflySpeeds() {
        guard !fireflies.isEmpty else { return }
        let range = fireflySpeedRange
        for index in fireflies.indices {
            var firefly = fireflies[index]
            let currentSpeed = sqrt((firefly.vx * firefly.vx) + (firefly.vy * firefly.vy))
            let angle = currentSpeed > 0.001
                ? atan2(firefly.vy, firefly.vx)
                : CGFloat.random(in: 0...(CGFloat.pi * 2))
            let adjustedSpeed = CGFloat.random(in: range)
            firefly.vx = cos(angle) * adjustedSpeed
            firefly.vy = sin(angle) * adjustedSpeed
            fireflies[index] = firefly
        }
    }

    func enforceMinimumSpeed(vx: CGFloat, vy: CGFloat) -> (CGFloat, CGFloat) {
        let minimumSpeed = max(4, CGFloat(nominalBubbleSpeed) * 0.42)
        let speed = sqrt(vx * vx + vy * vy)
        if speed >= minimumSpeed {
            return (vx, vy)
        }

        let angle: CGFloat
        if speed > 0.001 {
            angle = atan2(vy, vx)
        } else {
            angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        }

        return (cos(angle) * minimumSpeed, sin(angle) * minimumSpeed)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    EspacioCalmaView()
}
