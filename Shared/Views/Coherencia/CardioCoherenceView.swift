#if os(iOS)
import SwiftUI
import Combine
import CoreData
import UIKit
import AVFoundation

private enum CardioCoherenceStage {
    case setup
    case session
    case evaluation
    case summary
}

private enum BreathingRhythmOption: String, CaseIterable, Identifiable {
    case fiveFive = "5s Inhalar / 5s Exhalar"
    case fiveHalfFiveHalf = "5.5s Inhalar / 5.5s Exhalar"
    case sixSix = "6s Inhalar / 6s Exhalar"
    case fourHalfFiveHalf = "4.5s Inhalar / 5.5s Exhalar"

    var id: String { rawValue }

    var inhaleMillis: Int {
        switch self {
        case .fiveFive: return CardioCoherenceConstants.BreathingRhythm.fiveFive.inhaleMillis
        case .fiveHalfFiveHalf: return CardioCoherenceConstants.BreathingRhythm.fiveHalfFiveHalf.inhaleMillis
        case .sixSix: return CardioCoherenceConstants.BreathingRhythm.sixSix.inhaleMillis
        case .fourHalfFiveHalf: return CardioCoherenceConstants.BreathingRhythm.fourHalfFiveHalf.inhaleMillis
        }
    }

    var exhaleMillis: Int {
        switch self {
        case .fiveFive: return CardioCoherenceConstants.BreathingRhythm.fiveFive.exhaleMillis
        case .fiveHalfFiveHalf: return CardioCoherenceConstants.BreathingRhythm.fiveHalfFiveHalf.exhaleMillis
        case .sixSix: return CardioCoherenceConstants.BreathingRhythm.sixSix.exhaleMillis
        case .fourHalfFiveHalf: return CardioCoherenceConstants.BreathingRhythm.fourHalfFiveHalf.exhaleMillis
        }
    }

    var inhaleSeconds: Int { inhaleMillis / 1000 }
    var exhaleSeconds: Int { exhaleMillis / 1000 }
    var displayLabel: String { rawValue }
}

private enum SessionDurationOption: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case fifteen = 15

    var id: Int { rawValue }
    var label: String { "\(rawValue) minutos" }
}

private enum InitialEmotionalState: String, CaseIterable, Identifiable {
    case anxious = "Ansioso"
    case neutral = "Neutral"
    case calm = "Calmado"
    case low = "Bajo de energía"

    var id: String { rawValue }
}

private enum PostSessionEmotion: String, CaseIterable, Identifiable {
    case calm = "Calma"
    case gratitude = "Gratitud"
    case joy = "Alegría"
    case clarity = "Claridad"
    case connection = "Conexión"

    var id: String { rawValue }
}

private enum MeditationPhaseKind: String, Codable {
    case regulation
    case heartConnection
    case emotionalActivation
    case integration
}

private struct MeditationPhase {
    let kind: MeditationPhaseKind
    let durationSeconds: Int
    let title: String
    let cue: String
    let attentionCues: [AttentionCue]
    let emotionPrompt: String?

    struct AttentionCue {
        let startFraction: Double
        let text: String
    }

    func currentGuidanceText(phaseProgress: Double) -> String {
        let valid = attentionCues
            .filter { phaseProgress >= $0.startFraction }
            .max(by: { $0.startFraction < $1.startFraction })
        return valid?.text ?? cue
    }
}

private struct MeditationSession {
    let phases: [MeditationPhase]
    let totalDurationSeconds: Int
}

private struct CardioCoherenceRecord: Codable, Identifiable {
    let id: UUID
    let dateEpochMillis: Int64
    let durationMinutes: Int
    let initialState: String
    let intention: String
    let beforeScore: Int
    let afterScore: Int
    let mentalClarityScore: Int
    let heartConnectionScore: Int
    let predominantEmotion: String
    let closingWord: String
}

private struct CardioCoherenceUiState {
    var stage: CardioCoherenceStage = .setup
    var selectedState: InitialEmotionalState = .neutral
    var durationOption: SessionDurationOption = .ten
    var breathingRhythm: BreathingRhythmOption = .fiveHalfFiveHalf
    var intention: String = ""
    var beforeScore: Int = 5
    var afterScore: Int = 7
    var mentalClarityScore: Int = 7
    var heartConnectionScore: Int = 7
    var predominantEmotion: PostSessionEmotion = .calm
    var closingWord: String = ""
    var records: [CardioCoherenceRecord] = []
    var session: MeditationSession?
    var elapsedSeconds: Int = 0
    var preparationRemainingSeconds: Int = 5
    var currentPhaseIndex: Int = 0
    var isPaused: Bool = false

    var totalSeconds: Int { session?.totalDurationSeconds ?? durationOption.rawValue * 60 }
    var remainingSeconds: Int { max(0, totalSeconds - elapsedSeconds) }
    var isPreparing: Bool { preparationRemainingSeconds > 0 }

    var currentPhase: MeditationPhase? {
        guard let session else { return nil }
        return session.phases.indices.contains(currentPhaseIndex) ? session.phases[currentPhaseIndex] : nil
    }

    var currentPhaseElapsedSeconds: Int {
        guard let session else { return 0 }
        let consumedBefore = session.phases.prefix(currentPhaseIndex).reduce(0) { $0 + $1.durationSeconds }
        return max(0, elapsedSeconds - consumedBefore)
    }

    var currentPhaseRemainingSeconds: Int {
        guard let currentPhase else { return 0 }
        return max(0, currentPhase.durationSeconds - currentPhaseElapsedSeconds)
    }
}

@MainActor
private final class CardioCoherenceStore: ObservableObject {
    @Published var state = CardioCoherenceUiState()

    private let coherenceEntityName = "coherencia"
    private var tickerTask: Task<Void, Never>?

    init() {
        loadRecords()
    }

    func selectInitialState(_ value: InitialEmotionalState) { state.selectedState = value }
    func selectDuration(_ value: SessionDurationOption) { state.durationOption = value }
    func selectBreathingRhythm(_ value: BreathingRhythmOption) { state.breathingRhythm = value }

    func updateIntention(_ value: String) { state.intention = String(value.prefix(180)) }
    func updateBeforeScore(_ value: Int) { state.beforeScore = max(1, min(10, value)) }
    func updateAfterScore(_ value: Int) { state.afterScore = max(1, min(10, value)) }
    func updateMentalClarityScore(_ value: Int) { state.mentalClarityScore = max(1, min(10, value)) }
    func updateHeartConnectionScore(_ value: Int) { state.heartConnectionScore = max(1, min(10, value)) }
    func updatePredominantEmotion(_ value: PostSessionEmotion) { state.predominantEmotion = value }
    func updateClosingWord(_ value: String) { state.closingWord = String(value.prefix(36)) }

    func startSession() {
        let session = buildSession(durationMinutes: state.durationOption.rawValue, rhythm: state.breathingRhythm)
        tickerTask?.cancel()
        state.stage = .session
        state.session = session
        state.elapsedSeconds = 0
        state.preparationRemainingSeconds = 5
        state.currentPhaseIndex = 0
        state.isPaused = false
        startTicker()
    }

    func pause() { state.isPaused = true }
    func resume() { state.isPaused = false }

    func finishSession() {
        tickerTask?.cancel()
        state.stage = .evaluation
        state.isPaused = true
        state.afterScore = state.beforeScore
    }

    func saveEvaluation() {
        let record = CardioCoherenceRecord(
            id: UUID(),
            dateEpochMillis: Int64(Date().timeIntervalSince1970 * 1000),
            durationMinutes: max(1, (state.elapsedSeconds + 59) / 60),
            initialState: state.selectedState.rawValue,
            intention: state.intention.trimmingCharacters(in: .whitespacesAndNewlines),
            beforeScore: state.beforeScore,
            afterScore: state.afterScore,
            mentalClarityScore: state.mentalClarityScore,
            heartConnectionScore: state.heartConnectionScore,
            predominantEmotion: state.predominantEmotion.rawValue,
            closingWord: state.closingWord.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        state.records.insert(record, at: 0)
        persistRecords()
        state.stage = .summary
    }

    func resetFlow() {
        tickerTask?.cancel()
        state.stage = .setup
        state.session = nil
        state.elapsedSeconds = 0
        state.preparationRemainingSeconds = 5
        state.currentPhaseIndex = 0
        state.isPaused = false
        state.beforeScore = state.afterScore
        state.intention = ""
        state.closingWord = ""
    }

    func loadRecords() {
        let context = CoreDataController.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: coherenceEntityName)
        request.sortDescriptors = [NSSortDescriptor(key: "dateEpochMillis", ascending: false)]
        do {
            let rows = try context.fetch(request)
            state.records = rows.map { row in
                CardioCoherenceRecord(
                    id: row.value(forKey: "id") as? UUID ?? UUID(),
                    dateEpochMillis: row.value(forKey: "dateEpochMillis") as? Int64 ?? 0,
                    durationMinutes: Int(row.value(forKey: "durationMinutes") as? Int16 ?? 0),
                    initialState: row.value(forKey: "initialState") as? String ?? "",
                    intention: row.value(forKey: "intention") as? String ?? "",
                    beforeScore: Int(row.value(forKey: "beforeScore") as? Int16 ?? 0),
                    afterScore: Int(row.value(forKey: "afterScore") as? Int16 ?? 0),
                    mentalClarityScore: Int(row.value(forKey: "mentalClarityScore") as? Int16 ?? 0),
                    heartConnectionScore: Int(row.value(forKey: "heartConnectionScore") as? Int16 ?? 0),
                    predominantEmotion: row.value(forKey: "predominantEmotion") as? String ?? "",
                    closingWord: row.value(forKey: "closingWord") as? String ?? ""
                )
            }
        } catch {
            state.records = []
        }
    }

    private func persistRecords() {
        let context = CoreDataController.shared.context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: coherenceEntityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        _ = try? context.execute(deleteRequest)

        for record in state.records {
            guard let entity = NSEntityDescription.entity(forEntityName: coherenceEntityName, in: context) else { continue }
            let row = NSManagedObject(entity: entity, insertInto: context)
            row.setValue(record.id, forKey: "id")
            row.setValue(record.dateEpochMillis, forKey: "dateEpochMillis")
            row.setValue(Int16(record.durationMinutes), forKey: "durationMinutes")
            row.setValue(record.initialState, forKey: "initialState")
            row.setValue(record.intention, forKey: "intention")
            row.setValue(Int16(record.beforeScore), forKey: "beforeScore")
            row.setValue(Int16(record.afterScore), forKey: "afterScore")
            row.setValue(Int16(record.mentalClarityScore), forKey: "mentalClarityScore")
            row.setValue(Int16(record.heartConnectionScore), forKey: "heartConnectionScore")
            row.setValue(record.predominantEmotion, forKey: "predominantEmotion")
            row.setValue(record.closingWord, forKey: "closingWord")
        }
        try? context.save()
    }

    private func startTicker() {
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                if self.state.stage != .session || self.state.isPaused { continue }

                if self.state.preparationRemainingSeconds > 0 {
                    self.state.preparationRemainingSeconds -= 1
                    continue
                }

                guard let session = self.state.session else { return }
                let nextElapsed = min(session.totalDurationSeconds, self.state.elapsedSeconds + 1)
                self.state.elapsedSeconds = nextElapsed
                self.state.currentPhaseIndex = self.phaseIndex(for: session, elapsedSeconds: nextElapsed)

                if nextElapsed >= session.totalDurationSeconds {
                    self.finishSession()
                    return
                }
            }
        }
    }

    private func phaseIndex(for session: MeditationSession, elapsedSeconds: Int) -> Int {
        var acc = 0
        for (index, phase) in session.phases.enumerated() {
            acc += phase.durationSeconds
            if elapsedSeconds < acc { return index }
        }
        return max(0, session.phases.count - 1)
    }

    private func buildSession(durationMinutes: Int, rhythm: BreathingRhythmOption) -> MeditationSession {
        let total = min(30, max(5, durationMinutes)) * 60
        let phaseDurations = distributePhaseDurations(
            totalSeconds: total,
            weights: phaseWeights(for: state.selectedState)
        )

        var phases: [MeditationPhase] = []
        phases.append(.init(
            kind: .regulation,
            durationSeconds: phaseDurations[0],
            title: "Regulación",
            cue: "Respira lento. Permite que el cuerpo baje el ritmo y encuentre estabilidad.",
            attentionCues: [
                .init(startFraction: 0.00, text: "Relaja la mandíbula. Deja que la lengua descanse y que el rostro se suavice."),
                .init(startFraction: 0.20, text: "Baja los hombros. Suelta cualquier esfuerzo innecesario en cuello y espalda."),
                .init(startFraction: 0.40, text: "Siente el peso del cuerpo. Permite que el soporte debajo de ti te sostenga."),
                .init(startFraction: 0.60, text: "Nota el pecho y el esternón. Lleva ahí una atención tranquila, sin forzar."),
                .init(startFraction: 0.80, text: "Suaviza el abdomen. Deja que la respiración se vuelva amplia, lenta y cómoda.")
            ],
            emotionPrompt: nil
        ))
        phases.append(.init(
            kind: .heartConnection,
            durationSeconds: phaseDurations[1],
            title: "Conexión corazón",
            cue: "Lleva la atención al centro del pecho. Imagina que el aire entra y sale desde el corazón.",
            attentionCues: [
                .init(startFraction: 0.0, text: "Lleva la atención al centro del pecho. Imagina que el aire entra y sale desde el corazón.")
            ],
            emotionPrompt: nil
        ))
        phases.append(.init(
            kind: .emotionalActivation,
            durationSeconds: phaseDurations[2],
            title: "Emoción elevada",
            cue: "Evoca una emoción elevada en el corazón y respírala con suavidad.",
            attentionCues: [
                .init(startFraction: 0.0, text: "Evoca una emoción elevada en el corazón y respírala con suavidad.")
            ],
            emotionPrompt: state.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Sostén gratitud, paz o alegría como estado interno."
                : "Siente tu intención como ya cumplida: \(state.intention.trimmingCharacters(in: .whitespacesAndNewlines))"
        ))
        phases.append(.init(
            kind: .integration,
            durationSeconds: phaseDurations[3],
            title: "Integración",
            cue: "Permanece en silencio. Ancla esta coherencia y deja que tu intención quede sentida.",
            attentionCues: [
                .init(startFraction: 0.0, text: "Permanece en silencio. Ancla esta coherencia y deja que tu intención quede sentida.")
            ],
            emotionPrompt: state.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Siente tu intención como si ya fuera parte de ti: \(state.intention.trimmingCharacters(in: .whitespacesAndNewlines))"
        ))

        let realTotal = phases.reduce(0) { $0 + $1.durationSeconds }
        return MeditationSession(phases: phases, totalDurationSeconds: realTotal)
    }

    private func phaseWeights(for initialState: InitialEmotionalState) -> [Float] {
        switch initialState {
        case .anxious:
            return [0.28, 0.36, 0.22, 0.14]
        case .neutral:
            return [0.28, 0.27, 0.28, 0.17]
        case .calm:
            return [0.22, 0.27, 0.33, 0.18]
        case .low:
            return [0.30, 0.26, 0.28, 0.16]
        }
    }

    private func distributePhaseDurations(totalSeconds: Int, weights: [Float]) -> [Int] {
        let minimumSeconds = 45
        let base = Array(repeating: minimumSeconds, count: weights.count)
        let remaining = max(0, totalSeconds - base.reduce(0, +))
        let weighted = weights.map { Int(Float(remaining) * $0) }
        let remainder = totalSeconds - base.reduce(0, +) - weighted.reduce(0, +)
        return base.indices.map { index in
            base[index] + weighted[index] + (index == base.indices.last ? remainder : 0)
        }
    }
}

@MainActor
private final class BreathingHapticEngine: ObservableObject {
    private var task: Task<Void, Never>?
#if canImport(UIKit)
    private let generator = UIImpactFeedbackGenerator(style: .rigid)
#endif

    func start(rhythm: BreathingRhythmOption, anchor: Date) {
        stop()
        task = Task { [weak self] in
            guard let self else { return }
            await prepareHaptics()
            var nextPulseAt = Date.distantPast
            var lastState: BreathingCycleState = .idle
            while !Task.isCancelled {
                let now = Date()
                let snapshot = breathingCycleSnapshot(
                    now: now,
                    anchor: anchor,
                    rhythm: rhythm,
                    preparing: false,
                    paused: false
                )

                if snapshot.state != lastState {
                    // Dispara inmediatamente al entrar en inhalación/exhalación.
                    nextPulseAt = now
                    lastState = snapshot.state
                }

                switch snapshot.state {
                case .inhale, .exhale:
                    if now >= nextPulseAt {
                        let intensity = CardioCoherenceConstants.Haptics.pulseIntensity
                        await emitHaptic(intensity: intensity)
                        let interval = intervalForCurrentPulse(state: snapshot.state, progress: snapshot.progress)
                        nextPulseAt = now.addingTimeInterval(interval)
                    }
                case .inhalePause, .exhalePause, .idle:
                    break
                }

                try? await Task.sleep(nanoseconds: CardioCoherenceConstants.Haptics.schedulerTickNanos)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func prepareHaptics() async {
#if canImport(UIKit)
        await MainActor.run {
            generator.prepare()
        }
#endif
    }

    private func emitHaptic(intensity: CGFloat) async {
#if canImport(UIKit)
        await MainActor.run {
            generator.impactOccurred(intensity: intensity)
        }
#else
        _ = intensity
#endif
    }

    private func intervalForCurrentPulse(state: BreathingCycleState, progress: CGFloat) -> TimeInterval {
        let t = Double(min(max(progress, 0), 1))
        let minInterval = CardioCoherenceConstants.Haptics.minPulseIntervalSeconds
        let maxInterval = CardioCoherenceConstants.Haptics.maxPulseIntervalSeconds

        // Curvas suaves:
        // - Inhalación: comienza denso y termina espaciado.
        // - Exhalación: comienza espaciado y vuelve a denso hacia el cierre.
        let eased: Double
        switch state {
        case .inhale:
            eased = t * t // ease-in para abrir el espaciado de forma progresiva
            return minInterval + ((maxInterval - minInterval) * eased)
        case .exhale:
            let inv = 1.0 - t
            eased = inv * inv // inversa suave para cerrar espaciado
            return minInterval + ((maxInterval - minInterval) * eased)
        case .inhalePause, .exhalePause, .idle:
            return maxInterval
        }
    }
}

@MainActor
final class CardioCoherenceMusicPlayer: ObservableObject {
    private var player: AVAudioPlayer?
    private var loopTask: Task<Void, Never>?
    private var loadedTrackURL: URL?

    func playIfEnabled(
        _ enabled: Bool,
        startAt: TimeInterval = 0,
        loopFrom: TimeInterval? = nil,
        customTrackURL: URL? = nil
    ) {
        guard enabled else {
            stop()
            return
        }

        let targetURL = customTrackURL ?? resolveTrackURL()
        guard let targetURL else { return }

        if player == nil || loadedTrackURL != targetURL {
            preparePlayer(trackURL: targetURL)
        }
        guard let player else { return }

        configure(player: player, startAt: startAt, loopFrom: loopFrom)
        if !player.isPlaying {
            player.play()
        }
    }

    func fadeOutAndStop(duration: TimeInterval) {
        guard let player else { return }
        loopTask?.cancel()
        player.setVolume(0.0, fadeDuration: duration)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, duration) * 1_000_000_000))
            await MainActor.run {
                self?.stop()
            }
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
        player?.stop()
        player = nil
        loadedTrackURL = nil
    }

    private func preparePlayer(trackURL: URL) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: trackURL)
            audioPlayer.prepareToPlay()
            player = audioPlayer
            loadedTrackURL = trackURL
        } catch {
            player = nil
            loadedTrackURL = nil
        }
    }

    private func configure(player: AVAudioPlayer, startAt: TimeInterval, loopFrom: TimeInterval?) {
        loopTask?.cancel()
        loopTask = nil

        player.volume = CardioCoherenceConstants.Audio.backgroundMusicVolume
        let safeStart = max(0, min(startAt, max(0, player.duration - 0.05)))
        if !player.isPlaying {
            player.currentTime = safeStart
        }

        guard let loopFrom else {
            player.numberOfLoops = -1
            return
        }

        let safeLoopFrom = max(0, min(loopFrom, max(0, player.duration - 0.05)))
        player.numberOfLoops = 0

        loopTask = Task { [weak player] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let player else { return }
                if !player.isPlaying { continue }
                if player.currentTime >= max(0, player.duration - 0.04) {
                    player.currentTime = safeLoopFrom
                    player.play()
                }
            }
        }
    }

    private func resolveTrackURL() -> URL? {
        let bundle = Bundle.main
        if let url = bundle.url(
            forResource: CardioCoherenceConstants.Audio.backgroundTrackName,
            withExtension: CardioCoherenceConstants.Audio.backgroundTrackExtension,
            subdirectory: CardioCoherenceConstants.Audio.backgroundTrackSubdirectory
        ) {
            return url
        }
        return bundle.url(
            forResource: CardioCoherenceConstants.Audio.backgroundTrackName,
            withExtension: CardioCoherenceConstants.Audio.backgroundTrackExtension
        )
    }
}

struct CardioCoherenceMainView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = CardioCoherenceStore()
    @StateObject private var hapticEngine = BreathingHapticEngine()
    @StateObject private var musicPlayer = CardioCoherenceMusicPlayer()
    @State private var showStats = false
    @State private var breathingAnchor = Date()
    @State private var backgroundAssets: [URL] = []
    @State private var selectedBackgroundAsset: URL?
    @State private var seenBackgroundAssets: Set<String> = []
    @State private var isBackgroundMusicEnabled = true
    @State private var useCustomMusicInSession = false
    @State private var showEvaluationContent = false

    init() {
        let initial = CardioCoherenceBackgroundResolver.bootstrapBackgroundSelection()
        _backgroundAssets = State(initialValue: initial.assets)
        _selectedBackgroundAsset = State(initialValue: initial.selected)
        _seenBackgroundAssets = State(initialValue: initial.seen)
        let persistedMusic = UserDefaults.standard.object(forKey: CardioCoherenceConstants.Audio.backgroundMusicEnabledKey) as? Bool
        _isBackgroundMusicEnabled = State(initialValue: persistedMusic ?? true)
        let persistedCustomMusic = UserDefaults.standard.bool(forKey: CardioCoherenceConstants.Audio.useCustomMusicInSessionKey)
        _useCustomMusicInSession = State(initialValue: persistedCustomMusic)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    if let selectedBackgroundAsset {
                        CardioCoherenceBackgroundView(assetURL: selectedBackgroundAsset)
                            .id(selectedBackgroundAsset.path)
                            .transition(.opacity)
                    } else {
                        CardioCoherenceBackgroundView(assetURL: nil)
                            .id("cardio-coherence-default-background")
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.85), value: selectedBackgroundAsset?.path)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Cohencia Cardio-Cerebral")
                            .font(.title)
                            .padding(.vertical, 10)
                        switch store.state.stage {
                        case .setup:
                            setupSection
                        case .session:
                            sessionSection
                        case .evaluation:
                            evaluationSection
                                .opacity(showEvaluationContent ? 1 : 0)
                                .offset(y: showEvaluationContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.45), value: showEvaluationContent)
                        case .summary:
                            summarySection
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    selectNextBackground()
                }
            )
            .safeAreaInset(edge: .bottom) {
                if store.state.stage == .setup {
                    Button("Iniciar sesión") {
                        dismissKeyboard()
                        store.startSession()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.60, green: 0.46, blue: 0.92))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.25))
                }
            }
            //.navigationTitle("Coherencia Cardio-Cerebral")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        isBackgroundMusicEnabled.toggle()
                    } label: {
                        Image(systemName: isBackgroundMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.92))

                    Button("Stats") { showStats = true }
                        .foregroundStyle(.white)

                    if store.state.stage == .session {
                        Menu {
                            Button(store.state.isPaused ? "Reanudar" : "Pausar") {
                                store.state.isPaused ? store.resume() : store.pause()
                            }
                            Button("Finalizar", role: .destructive) {
                                store.finishSession()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Ocultar") {
                        dismissKeyboard()
                    }
                }
            }
            .sheet(isPresented: $showStats) {
                CardioCoherenceStatsView(records: store.state.records)
            }
            .onChange(of: store.state.stage) { _, newStage in
                if newStage == .session {
                    breathingAnchor = Date()
                    if !store.state.isPaused, !store.state.isPreparing {
                        hapticEngine.start(rhythm: store.state.breathingRhythm, anchor: breathingAnchor)
                    }
                    playSessionMusicIfNeeded()
                } else {
                    hapticEngine.stop()
                }

                if newStage == .evaluation {
                    showEvaluationContent = false
                    withAnimation(.easeOut(duration: 0.45)) {
                        showEvaluationContent = true
                    }
                } else {
                    showEvaluationContent = false
                }
            }
            .onChange(of: store.state.isPaused) { _, isPaused in
                if store.state.stage == .session, !isPaused, !store.state.isPreparing {
                    if store.state.elapsedSeconds == 0 {
                        breathingAnchor = Date()
                    }
                    hapticEngine.start(rhythm: store.state.breathingRhythm, anchor: breathingAnchor)
                } else {
                    hapticEngine.stop()
                }
            }
            .onChange(of: store.state.preparationRemainingSeconds) { oldValue, newValue in
                if oldValue > 0, newValue == 0, store.state.stage == .session, !store.state.isPaused {
                    breathingAnchor = Date()
                    hapticEngine.start(rhythm: store.state.breathingRhythm, anchor: breathingAnchor)
                }
            }
            .onAppear {
                // Seguridad: por si la vista se inicializa sin assets disponibles.
                if backgroundAssets.isEmpty {
                    loadBackgroundAssets()
                } else {
                    persistBackgroundSelection()
                }
                playSessionMusicIfNeeded()
            }
            .onChange(of: isBackgroundMusicEnabled) { _, enabled in
                UserDefaults.standard.set(enabled, forKey: CardioCoherenceConstants.Audio.backgroundMusicEnabledKey)
                playSessionMusicIfNeeded()
            }
            .onChange(of: useCustomMusicInSession) { _, enabled in
                UserDefaults.standard.set(enabled, forKey: CardioCoherenceConstants.Audio.useCustomMusicInSessionKey)
                playSessionMusicIfNeeded()
            }
            .onDisappear {
                hapticEngine.stop()
                musicPlayer.stop()
            }
        }
    }

    private func loadBackgroundAssets() {
        let assets = CardioCoherenceBackgroundResolver.loadAssetURLs()
        backgroundAssets = assets

        let persisted = UserDefaults.standard.string(forKey: CardioCoherenceBackgroundResolver.lastAssetKey)
        let validPersisted = assets.first { $0.path == persisted }
        let preferred = assets.first { $0.lastPathComponent == CardioCoherenceBackgroundResolver.defaultAssetName }
        selectedBackgroundAsset = validPersisted ?? preferred ?? assets.randomElement()

        let persistedSeen = Set(UserDefaults.standard.stringArray(forKey: CardioCoherenceBackgroundResolver.seenAssetsKey) ?? [])
        seenBackgroundAssets = Set(assets.map(\.path)).intersection(persistedSeen)
        if let selectedPath = selectedBackgroundAsset?.path {
            seenBackgroundAssets.insert(selectedPath)
        }
        persistBackgroundSelection()
    }

    private func selectNextBackground() {
        guard !backgroundAssets.isEmpty else { return }
        let currentPath = selectedBackgroundAsset?.path
        let availableSet = Set(backgroundAssets.map(\.path))
        let unseen = backgroundAssets.filter { !seenBackgroundAssets.contains($0.path) && $0.path != currentPath }
        let candidates = unseen.isEmpty
            ? backgroundAssets.filter { $0.path != currentPath }
            : unseen
        let next = candidates.randomElement() ?? backgroundAssets.randomElement()
        selectedBackgroundAsset = next

        if unseen.isEmpty {
            seenBackgroundAssets = Set([currentPath, next?.path].compactMap { $0 }).intersection(availableSet)
        } else if let nextPath = next?.path {
            seenBackgroundAssets.insert(nextPath)
            seenBackgroundAssets = seenBackgroundAssets.intersection(availableSet)
        }
        persistBackgroundSelection()
    }

    private func persistBackgroundSelection() {
        UserDefaults.standard.set(selectedBackgroundAsset?.path, forKey: CardioCoherenceBackgroundResolver.lastAssetKey)
        UserDefaults.standard.set(Array(seenBackgroundAssets), forKey: CardioCoherenceBackgroundResolver.seenAssetsKey)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var setupSection: some View {
        VStack(spacing: 12) {
            pickerCard(title: "Estado inicial y tiempo") {
                HStack(spacing: 10) {
                    Picker("Estado", selection: Binding(get: { store.state.selectedState }, set: { value in
                        store.selectInitialState(value)
                    })) {
                        ForEach(InitialEmotionalState.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()

                    Picker("Tiempo", selection: Binding(get: { store.state.durationOption }, set: { value in
                        store.selectDuration(value)
                    })) {
                        ForEach(SessionDurationOption.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            pickerCard(title: "Ritmo respiratorio") {
                Picker("Ritmo", selection: Binding(get: { store.state.breathingRhythm }, set: { value in
                    store.selectBreathingRhythm(value)
                })) {
                    ForEach(BreathingRhythmOption.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)
            }

            scoreSlider(title: "Estrés / Calma antes", value: store.state.beforeScore, onChange: store.updateBeforeScore)

            VStack(alignment: .leading, spacing: 8) {
                Text("Intención")
                    .font(.headline)
                    .foregroundStyle(.white)
                TextField("Opcional", text: Binding(get: { store.state.intention }, set: { value in
                    store.updateIntention(value)
                }), axis: .vertical)
                    .lineLimit(4...8)
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                    .background(Color.black.opacity(0.85))
                    .foregroundStyle(.orange)
                    .tint(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding()
            .background(.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        }
    }

    private var sessionSection: some View {
        let totalProgress = store.state.totalSeconds == 0 ? 0.0 : Double(store.state.elapsedSeconds) / Double(store.state.totalSeconds)
        let phaseDuration = max(1, store.state.currentPhase?.durationSeconds ?? 1)
        let phaseProgress = Double(store.state.currentPhaseElapsedSeconds) / Double(phaseDuration)
        return VStack(spacing: 14) {
                HStack(spacing: 10) {
                    TimerPill(symbol: "timer", text: formatSeconds(store.state.remainingSeconds))
                    ProgressView(value: max(0, min(1, totalProgress)))
                        .progressViewStyle(.linear)
                        .tint(Color(red: 0.36, green: 0.39, blue: 0.84))
                    TimerPill(symbol: "heart.fill", text: formatSeconds(store.state.currentPhaseRemainingSeconds))
                }
                .padding(.horizontal, 4)

                if let phase = store.state.currentPhase {
                    BreathingOrbView(
                        rhythm: store.state.breathingRhythm,
                        preparing: store.state.isPreparing,
                        paused: store.state.isPaused,
                        anchor: breathingAnchor
                    )
                    .frame(width: 250, height: 250)

                    BreathingCueView(
                        rhythm: store.state.breathingRhythm,
                        preparing: store.state.isPreparing,
                        paused: store.state.isPaused,
                        preparationRemainingSeconds: store.state.preparationRemainingSeconds,
                        anchor: breathingAnchor
                    )

                    SessionInfoPanel {
                        let guidanceDisplay = SessionGuidanceDisplay(
                            title: phase.title,
                            guidance: phase.currentGuidanceText(phaseProgress: phaseProgress),
                            emotionPrompt: phase.emotionPrompt
                        )

                        VStack(spacing: 8) {
                            ZStack {
                                ForEach([guidanceDisplay], id: \.id) { item in
                                    SessionGuidanceContent(display: item)
                                        .id(item.id)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.45), value: guidanceDisplay.id)

                            ProgressView(value: max(0, min(1, phaseProgress)))
                                .progressViewStyle(.linear)
                                .tint(Color(red: 0.55, green: 0.39, blue: 0.78))
                                .padding(.top, 6)
                        }
                    }
                }
        }
    }

    private var evaluationSection: some View {
        VStack(spacing: 12) {
            scoreSlider(title: "Calma / Coherencia después", value: store.state.afterScore, onChange: store.updateAfterScore)
            scoreSlider(title: "Claridad mental", value: store.state.mentalClarityScore, onChange: store.updateMentalClarityScore)
            scoreSlider(title: "Conexión con el corazón", value: store.state.heartConnectionScore, onChange: store.updateHeartConnectionScore)

            pickerCard(title: "Emoción predominante") {
                Picker("Emoción", selection: Binding(get: { store.state.predominantEmotion }, set: { value in
                    store.updatePredominantEmotion(value)
                })) {
                    ForEach(PostSessionEmotion.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Palabra final")
                    .font(.headline)
                    .foregroundStyle(.white)
                TextField("Opcional", text: Binding(get: { store.state.closingWord }, set: { value in
                    store.updateClosingWord(value)
                }))
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .background(.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Guardar evaluación") { store.saveEvaluation() }
                .buttonStyle(.bordered)
                .tint(.green)
        }
    }

    private var summarySection: some View {
        VStack(spacing: 10) {
            Text("Sesión completada")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Calma final: \(store.state.afterScore)/10")
                .foregroundStyle(.white)

            Text("Claridad: \(store.state.mentalClarityScore)/10 | Corazón: \(store.state.heartConnectionScore)/10")
                .foregroundStyle(.white.opacity(0.9))

            Button("Nueva sesión") { store.resetFlow() }
                .buttonStyle(.bordered)
                .tint(.teal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func pickerCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            content()
                .tint(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scoreSlider(title: String, value: Int, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title): \(value)")
                .font(.headline)
                .foregroundStyle(.white)
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { onChange(Int($0.rounded())) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(.mint)
        }
        .padding()
        .background(.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func playSessionMusicIfNeeded() {
        let customMusicURL = CardioCoherenceCustomMusicStore.currentCustomMusicURL()
        let shouldUseCustomMusic = useCustomMusicInSession && customMusicURL != nil

        if shouldUseCustomMusic {
            musicPlayer.playIfEnabled(
                isBackgroundMusicEnabled,
                startAt: 0,
                loopFrom: nil,
                customTrackURL: customMusicURL
            )
            return
        }

        musicPlayer.playIfEnabled(
            isBackgroundMusicEnabled,
            startAt: CardioCoherenceConstants.Audio.sessionLoopStartSeconds,
            loopFrom: CardioCoherenceConstants.Audio.sessionLoopStartSeconds,
            customTrackURL: nil
        )
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        let minuteText = m < 10 ? "0\(m)" : "\(m)"
        let secondText = s < 10 ? "0\(s)" : "\(s)"
        return "\(minuteText):\(secondText)"
    }

}

enum CardioCoherenceBackgroundResolver {
    static let bundleSubdirectory = "CoherenciaCCImagenes"
    static let defaultAssetName = "cc_5.JPG"
    static let lastAssetKey = "cardio_coherence_last_background_path"
    static let seenAssetsKey = "cardio_coherence_seen_background_paths"
    static let validExtensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "gif", "bmp", "heic", "heif", "avif"
    ]

    static func loadAssetURLs() -> [URL] {
        let fileManager = FileManager.default
        var collected: [URL] = []

        if let folderURL = Bundle.main.resourceURL?.appendingPathComponent(bundleSubdirectory, isDirectory: true),
           let folderURLs = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
           ) {
            collected.append(contentsOf: folderURLs)
        }

        // Fallback for projects where files are copied flattened into bundle root.
        if collected.isEmpty,
           let rootURL = Bundle.main.resourceURL,
           let rootFiles = try? fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
           ) {
            collected.append(contentsOf: rootFiles)
        }

        var uniqueByPath: [String: URL] = [:]
        for url in collected {
            uniqueByPath[url.standardizedFileURL.path] = url
        }

        return uniqueByPath.values
            .filter { url in
                let ext = url.pathExtension.lowercased()
                guard validExtensions.contains(ext) else { return false }
                let fileName = url.lastPathComponent.lowercased()
                let parentName = url.deletingLastPathComponent().lastPathComponent.lowercased()
                if parentName == bundleSubdirectory.lowercased() { return true }
                // Flattened fallback: keeps only coherence background naming convention.
                return fileName.hasPrefix("cc_")
            }
            .sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    static func bootstrapBackgroundSelection() -> (assets: [URL], selected: URL?, seen: Set<String>) {
        let assets = loadAssetURLs()
        let persisted = UserDefaults.standard.string(forKey: lastAssetKey)
        let validPersisted = assets.first { $0.path == persisted }
        let preferred = assets.first { $0.lastPathComponent == defaultAssetName }
        let selected = validPersisted ?? preferred ?? assets.randomElement()

        let persistedSeen = Set(UserDefaults.standard.stringArray(forKey: seenAssetsKey) ?? [])
        var seen = Set(assets.map(\.path)).intersection(persistedSeen)
        if let selectedPath = selected?.path {
            seen.insert(selectedPath)
        }
        return (assets, selected, seen)
    }
}

struct CardioCoherenceBackgroundView: View {
    let assetURL: URL?

    var body: some View {
        ZStack {
            if let image = loadImage() {
                Color.black
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.14, blue: 0.28),
                        Color(red: 0.16, green: 0.29, blue: 0.48),
                        Color(red: 0.84, green: 0.45, blue: 0.26)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.38),
                    Color(red: 0.09, green: 0.05, blue: 0.20).opacity(0.30),
                    Color.black.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
    }

    private func loadImage() -> UIImage? {
        guard let assetURL else { return nil }
        return UIImage(contentsOfFile: assetURL.path)
    }
}

private struct CardioCoherenceStatsView: View {
    let records: [CardioCoherenceRecord]
    @Environment(\.dismiss) private var dismiss
    @State private var stats = CardioCoherenceStatsSnapshot(records: [])

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.26),
                        Color(red: 0.11, green: 0.26, blue: 0.44),
                        Color(red: 0.95, green: 0.46, blue: 0.23)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        CardioHeadlineCards(stats: stats)
                        CardioWeeklyBarChart(stats: stats)
                        CardioRingsSection(stats: stats)
                        CardioEmotionSection(stats: stats)
                        CardioDotTrendSection(stats: stats)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Estadísticas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem {
                    Button {
                        stats = CardioCoherenceStatsSnapshot(records: records)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                stats = CardioCoherenceStatsSnapshot(records: records)
            }
        }
    }
}

private struct CardioCoherenceStatsSnapshot {
    struct WeekdayCount: Identifiable {
        var id: String { dayLabel }
        let dayLabel: String
        let count: Int
    }

    struct EmotionCount: Identifiable {
        var id: String { emotion }
        let emotion: String
        let count: Int
    }

    struct DayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let count: Int
    }

    let totalSessions: Int
    let totalMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageScoreDelta: Double
    let averageAfterScore: Double
    let averageMentalClarity: Double
    let averageHeartConnection: Double
    let weekdayCounts: [WeekdayCount]
    let topEmotions: [EmotionCount]
    private let dailyCounts: [Date: Int]

    init(records: [CardioCoherenceRecord]) {
        let calendar = Calendar.current
        let normalizedDays = records.map { Date(timeIntervalSince1970: Double($0.dateEpochMillis) / 1000.0) }
            .map { calendar.startOfDay(for: $0) }

        totalSessions = records.count
        totalMinutes = records.reduce(0) { $0 + $1.durationMinutes }
        averageScoreDelta = records.isEmpty ? 0 : Double(records.reduce(0) { $0 + ($1.afterScore - $1.beforeScore) }) / Double(records.count)
        averageAfterScore = records.isEmpty ? 0 : Double(records.reduce(0) { $0 + $1.afterScore }) / Double(records.count)
        averageMentalClarity = records.isEmpty ? 0 : Double(records.reduce(0) { $0 + $1.mentalClarityScore }) / Double(records.count)
        averageHeartConnection = records.isEmpty ? 0 : Double(records.reduce(0) { $0 + $1.heartConnectionScore }) / Double(records.count)

        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        let weekdayMap = Dictionary(grouping: normalizedDays, by: { calendar.component(.weekday, from: $0) }).mapValues(\.count)
        weekdayCounts = weekdaySymbols.enumerated().map { index, label in
            WeekdayCount(dayLabel: label, count: weekdayMap[index + 1] ?? 0)
        }

        topEmotions = Dictionary(grouping: records, by: { $0.predominantEmotion })
            .mapValues(\.count)
            .map { EmotionCount(emotion: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }

        let daysWithEntries = Set(normalizedDays)
        currentStreak = Self.calculateCurrentStreak(from: daysWithEntries, calendar: calendar)
        longestStreak = Self.calculateLongestStreak(from: daysWithEntries, calendar: calendar)
        dailyCounts = Dictionary(grouping: normalizedDays, by: { $0 }).mapValues(\.count)
    }

    func dayPoints(for days: Int) -> [DayPoint] {
        let safeDays = max(1, days)
        let calendar = Calendar.current
        var result: [DayPoint] = []
        for offset in stride(from: safeDays - 1, through: 0, by: -1) {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let start = calendar.startOfDay(for: targetDate)
            result.append(DayPoint(date: start, count: dailyCounts[start] ?? 0))
        }
        return result
    }

    private static func calculateCurrentStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        if !days.contains(cursor),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
           days.contains(yesterday) {
            cursor = yesterday
        }
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func calculateLongestStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        let sortedDays = days.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for index in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[index - 1], to: sortedDays[index]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return best
    }
}

private struct CardioHeadlineCards: View {
    let stats: CardioCoherenceStatsSnapshot
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        VStack(spacing: 12) {
            Text("Tu práctica de coherencia")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 12) {
                CardioMetricCard(title: "Sesiones", value: "\(stats.totalSessions)", subtitle: "total")
                CardioMetricCard(title: "Tiempo", value: "\(stats.totalMinutes)", subtitle: "minutos")
                CardioMetricCard(title: "Racha actual", value: "\(stats.currentStreak)", subtitle: "días")
                CardioMetricCard(title: "Mejor racha", value: "\(stats.longestStreak)", subtitle: "días")
                CardioMetricCard(title: "Cambio", value: cardioOneDecimal(stats.averageScoreDelta), subtitle: "promedio")
                CardioMetricCard(title: "Coherencia", value: "\(cardioOneDecimal(stats.averageAfterScore))/10", subtitle: "final media")
            }
        }
        .padding(.horizontal, 14)
    }
}

private struct CardioMetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct CardioWeeklyBarChart: View {
    let stats: CardioCoherenceStatsSnapshot
    private var maxCount: Int { max(stats.weekdayCounts.map(\.count).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Frecuencia semanal")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(stats.weekdayCounts) { item in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.15))
                                .frame(height: 120)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top))
                                .frame(height: CGFloat(item.count) / CGFloat(maxCount) * 120)
                        }
                        .frame(width: 30)
                        Text(item.dayLabel)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 14)
    }
}

private struct CardioRingsSection: View {
    let stats: CardioCoherenceStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Métricas internas")
                .font(.headline)
                .foregroundStyle(.white)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    CardioRingMetric(progress: stats.averageAfterScore / 10.0, color: .mint, title: "Coherencia", value: cardioOneDecimal(stats.averageAfterScore))
                    CardioRingMetric(progress: stats.averageMentalClarity / 10.0, color: .cyan, title: "Claridad", value: cardioOneDecimal(stats.averageMentalClarity))
                    CardioRingMetric(progress: stats.averageHeartConnection / 10.0, color: .purple, title: "Corazón", value: cardioOneDecimal(stats.averageHeartConnection))
                }
                VStack(spacing: 10) {
                    CardioRingMetric(progress: stats.averageAfterScore / 10.0, color: .mint, title: "Coherencia", value: cardioOneDecimal(stats.averageAfterScore))
                    CardioRingMetric(progress: stats.averageMentalClarity / 10.0, color: .cyan, title: "Claridad", value: cardioOneDecimal(stats.averageMentalClarity))
                    CardioRingMetric(progress: stats.averageHeartConnection / 10.0, color: .purple, title: "Corazón", value: cardioOneDecimal(stats.averageHeartConnection))
                }
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 14)
    }
}

private struct CardioRingMetric: View {
    let progress: Double
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 76, height: 76)

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CardioEmotionSection: View {
    let stats: CardioCoherenceStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emociones predominantes")
                .font(.headline)
                .foregroundStyle(.white)

            if stats.topEmotions.isEmpty {
                Text("Aún no hay datos emocionales suficientes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(stats.topEmotions.prefix(5).enumerated()), id: \.offset) { _, emotion in
                        HStack(spacing: 10) {
                            Text(emotion.emoji)
                                .font(.body)
                            Text(emotion.emotion)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(emotion.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 14)
    }
}

private struct CardioDotTrendSection: View {
    let stats: CardioCoherenceStatsSnapshot
    @State private var selectedDays: Int = 30

    private var points: [CardioCoherenceStatsSnapshot.DayPoint] { stats.dayPoints(for: selectedDays) }
    private var maxCount: Int { max(points.map(\.count).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tendencia de práctica")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer(minLength: 8)
                dayRangePicker
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(points) { point in
                        Circle()
                            .fill(point.count == 0 ? Color.white.opacity(0.22) : Color.orange)
                            .frame(width: 8, height: 8 + (CGFloat(point.count) / CGFloat(maxCount) * 18))
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 36)
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 14)
    }

    private var dayRangePicker: some View {
        Menu {
            Button("7 días") { selectedDays = 7 }
            Button("15 días") { selectedDays = 15 }
            Button("30 días") { selectedDays = 30 }
        } label: {
            HStack(spacing: 6) {
                Text(selectedDays == 7 ? "7 días" : selectedDays == 15 ? "15 días" : "30 días")
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
        }
    }
}

private func cardioOneDecimal(_ value: Double) -> String {
    let rounded = (value * 10).rounded() / 10
    let integerPortion = Double(Int(rounded))
    if rounded == integerPortion {
        return "\(Int(rounded)).0"
    }
    return "\(rounded)"
}

private extension CardioCoherenceStatsSnapshot.EmotionCount {
    var emoji: String {
        let lower = emotion.lowercased()
        if lower.contains("calma") { return "😌" }
        if lower.contains("gratitud") { return "🙏" }
        if lower.contains("amor") { return "💗" }
        if lower.contains("paz") { return "🕊️" }
        if lower.contains("alegr") { return "🙂" }
        if lower.contains("claridad") { return "✨" }
        if lower.contains("esperanza") { return "🌱" }
        return "😐"
    }
}

private struct TimerPill: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(Color.black.opacity(0.68))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.38))
        .clipShape(Capsule())
    }
}

private struct SessionInfoPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.34))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct BreathingOrbView: View {
    let rhythm: BreathingRhythmOption
    let preparing: Bool
    let paused: Bool
    let anchor: Date
    @State private var cycleProgress: CGFloat = 0.0
    @State private var cycleState: BreathingCycleState = .idle
    @State private var cyclePhaseProgress: CGFloat = 0.0
    @State private var displayedRingScale: CGFloat = CardioCoherenceConstants.Orb.minScale
    @State private var previousCycleState: BreathingCycleState = .idle
    @State private var inhaleEntryRingScale: CGFloat?
    @State private var ringVisibility: CGFloat = 0
    @State private var hasScheduledInitialRingReveal: Bool = false
    @State private var ringRevealTask: Task<Void, Never>?

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) * CardioCoherenceConstants.Orb.baseRadiusFactor
            let orbScale = CardioCoherenceConstants.Orb.minScale + (CardioCoherenceConstants.Orb.scaleRange * cycleProgress)
            let radius = baseRadius * orbScale

            let ringScale = max(0.01, displayedRingScale)
            let ringRadius = baseRadius * ringScale

            let orbRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.fill(
                Path(ellipseIn: orbRect),
                with: .radialGradient(
                    Gradient(colors: [
                        CardioCoherenceConstants.Orb.coreColor,
                        CardioCoherenceConstants.Orb.middleColor,
                        CardioCoherenceConstants.Orb.outerColor
                    ]),
                    center: center,
                    startRadius: 1,
                    endRadius: radius
                )
            )

            drawRosette(in: &context, center: center, radius: radius * CardioCoherenceConstants.Orb.rosetteRadiusFactor, cycleProgress: cycleProgress)

            let ringRect = CGRect(
                x: center.x - ringRadius,
                y: center.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            ).insetBy(
                dx: -ringRadius * CardioCoherenceConstants.Orb.ringInsetFactor,
                dy: -ringRadius * CardioCoherenceConstants.Orb.ringInsetFactor
            )

            context.stroke(
                Path(ellipseIn: ringRect),
                with: .color(CardioCoherenceConstants.Orb.ringColor.opacity(ringVisibility)),
                lineWidth: CardioCoherenceConstants.Orb.ringLineWidth
            )
        }
        .task(id: "\(rhythm.rawValue)-\(preparing)-\(paused)-\(anchor.timeIntervalSinceReferenceDate)") {
            if preparing {
                ringRevealTask?.cancel()
                ringRevealTask = nil
                ringVisibility = 0
                hasScheduledInitialRingReveal = false
            }

            let initialSnapshot = breathingCycleSnapshot(
                now: Date(),
                anchor: anchor,
                rhythm: rhythm,
                preparing: preparing,
                paused: paused
            )
            cycleProgress = initialSnapshot.progress
            cycleState = initialSnapshot.state
            previousCycleState = initialSnapshot.state
            cyclePhaseProgress = initialSnapshot.phaseProgress

            let initialOrbScale = CardioCoherenceConstants.Orb.minScale + (CardioCoherenceConstants.Orb.scaleRange * initialSnapshot.progress)
            let initialExhalePauseTail = exhalePauseTailScaleOffset(
                phaseProgress: initialSnapshot.phaseProgress,
                state: initialSnapshot.state,
                previousState: initialSnapshot.state
            )
            displayedRingScale = max(0.01, initialOrbScale + initialExhalePauseTail)

            while !Task.isCancelled {
                let snapshot = breathingCycleSnapshot(
                    now: Date(),
                    anchor: anchor,
                    rhythm: rhythm,
                    preparing: preparing,
                    paused: paused
                )
                let oldState = cycleState
                cycleProgress = snapshot.progress
                cycleState = snapshot.state
                previousCycleState = oldState
                cyclePhaseProgress = snapshot.phaseProgress

                let orbScale = CardioCoherenceConstants.Orb.minScale + (CardioCoherenceConstants.Orb.scaleRange * snapshot.progress)
                let exhalePauseTail = exhalePauseTailScaleOffset(
                    phaseProgress: snapshot.phaseProgress,
                    state: snapshot.state,
                    previousState: oldState
                )
                let rawTargetRingScale = max(0.01, orbScale + exhalePauseTail)

                if snapshot.state == .inhale, oldState != .inhale {
                    inhaleEntryRingScale = displayedRingScale
                }
                if snapshot.state != .inhale {
                    inhaleEntryRingScale = nil
                }

                if !hasScheduledInitialRingReveal,
                   snapshot.state == .inhale,
                   snapshot.phaseProgress > 0 {
                    hasScheduledInitialRingReveal = true
                    ringRevealTask?.cancel()
                    ringRevealTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        guard !Task.isCancelled else { return }

                        let duration = max(0.1, CardioCoherenceConstants.Orb.initialRingRevealDurationSeconds)
                        let frameNanos = max(1, CardioCoherenceConstants.BreathingPattern.frameRefreshNanos)
                        let steps = max(1, Int((duration * 1_000_000_000) / Double(frameNanos)))

                        for step in 0...steps {
                            guard !Task.isCancelled else { return }
                            let t = CGFloat(step) / CGFloat(steps)
                            let eased = t * t * (3 - (2 * t))
                            ringVisibility = eased
                            try? await Task.sleep(nanoseconds: frameNanos)
                        }

                        ringVisibility = 1
                    }
                }

                let targetRingScale: CGFloat
                if snapshot.state == .inhale, let entryScale = inhaleEntryRingScale {
                    let releaseT = min(max(snapshot.phaseProgress / CardioCoherenceConstants.Orb.inhaleReleaseWindow, 0), 1)
                    let eased = releaseT * releaseT * (3 - (2 * releaseT))
                    targetRingScale = entryScale + ((rawTargetRingScale - entryScale) * eased)
                } else {
                    targetRingScale = rawTargetRingScale
                }

                let smoothedScale = displayedRingScale + ((targetRingScale - displayedRingScale) * CardioCoherenceConstants.Orb.ringSpringSmoothing)
                let delta = smoothedScale - displayedRingScale
                let maxStep = CardioCoherenceConstants.Orb.maxRingScaleStepPerFrame
                let clampedDelta = min(max(delta, -maxStep), maxStep)
                displayedRingScale += clampedDelta

                try? await Task.sleep(nanoseconds: CardioCoherenceConstants.BreathingPattern.frameRefreshNanos)
            }
        }
    }

    private func drawRosette(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        cycleProgress: CGFloat
    ) {
        let breath = smoothBreath(cycleProgress)
        let rosetteRadius = radius * (CardioCoherenceConstants.Rosette.minRadiusFactor + ((CardioCoherenceConstants.Rosette.maxRadiusFactor - CardioCoherenceConstants.Rosette.minRadiusFactor) * breath))
        let rotation = CGFloat((CardioCoherenceConstants.Rosette.rotationDegrees * (breath - 0.5)) * .pi / 180.0)
        let outerCount = CardioCoherenceConstants.Rosette.petalCount

        for petal in 0..<outerCount {
            let angle = rotation + ((2 * .pi * CGFloat(petal)) / CGFloat(outerCount))
            let outerDistance = rosetteRadius * CardioCoherenceConstants.Rosette.petalOrbitFactor
            let petalCenter = CGPoint(
                x: center.x + (cos(angle) * outerDistance),
                y: center.y + (sin(angle) * outerDistance)
            )
            let widthScale = CardioCoherenceConstants.Rosette.widthScaleMin + ((CardioCoherenceConstants.Rosette.widthScaleMax - CardioCoherenceConstants.Rosette.widthScaleMin) * breath)
            let lengthScale = CardioCoherenceConstants.Rosette.lengthScaleMin + ((CardioCoherenceConstants.Rosette.lengthScaleMax - CardioCoherenceConstants.Rosette.lengthScaleMin) * breath)
            let rotationNormalized = (rotation / (2 * .pi))
            let petalPhase = (CGFloat(petal) / CGFloat(max(1, outerCount))) + rotationNormalized + breath
            let widthWave = sin(petalPhase * 2 * .pi)
            let widthVariation = 1 + (widthWave * CardioCoherenceConstants.Rosette.petalWidthVariationIntensity * breath)
            let lengthRadius = rosetteRadius * CardioCoherenceConstants.Rosette.petalLengthBaseFactor * lengthScale
            let widthRadius = rosetteRadius * CardioCoherenceConstants.Rosette.petalWidthBaseFactor * widthScale * max(0.25, widthVariation)

            var petal = Path(
                ellipseIn: CGRect(
                    x: petalCenter.x - lengthRadius,
                    y: petalCenter.y - widthRadius,
                    width: lengthRadius * 2,
                    height: widthRadius * 2
                )
            )
            let transform = CGAffineTransform(translationX: petalCenter.x, y: petalCenter.y)
                .rotated(by: angle)
                .translatedBy(x: -petalCenter.x, y: -petalCenter.y)
            petal = petal.applying(transform)

            context.fill(petal, with: .color(CardioCoherenceConstants.Rosette.petalFillColor))
            context.stroke(petal, with: .color(CardioCoherenceConstants.Rosette.petalStrokeColor), lineWidth: CardioCoherenceConstants.Rosette.petalStrokeWidth)
        }

        // Solape interno con pétalos pequeños para cubrir el centro sin crear un círculo concéntrico visible.
        let innerCount = max(6, outerCount / 2)
        let innerOrbit = rosetteRadius * 0.08
        let innerLength = rosetteRadius * 0.28
        let innerWidth = rosetteRadius * 0.18

        for index in 0..<innerCount {
            let innerAngle = -rotation + ((2 * .pi * CGFloat(index)) / CGFloat(innerCount))
            let innerCenter = CGPoint(
                x: center.x + (cos(innerAngle) * innerOrbit),
                y: center.y + (sin(innerAngle) * innerOrbit)
            )

            var innerPetal = Path(
                ellipseIn: CGRect(
                    x: innerCenter.x - innerLength,
                    y: innerCenter.y - innerWidth,
                    width: innerLength * 2,
                    height: innerWidth * 2
                )
            )
            let innerTransform = CGAffineTransform(translationX: innerCenter.x, y: innerCenter.y)
                .rotated(by: innerAngle)
                .translatedBy(x: -innerCenter.x, y: -innerCenter.y)
            innerPetal = innerPetal.applying(innerTransform)

            context.fill(innerPetal, with: .color(CardioCoherenceConstants.Rosette.petalFillColor.opacity(0.88)))
        }
    }

    private func smoothBreath(_ value: CGFloat) -> CGFloat {
        let clamped = min(max(0, value), 1)
        return clamped * clamped * (3 - (2 * clamped))
    }

    private func exhalePauseTailScaleOffset(
        phaseProgress: CGFloat,
        state: BreathingCycleState,
        previousState: BreathingCycleState
    ) -> CGFloat {
        let t = min(max(phaseProgress, 0), 1)
        let shrink = CardioCoherenceConstants.Orb.exhalePauseTailShrink

        switch state {
        case .exhalePause:
            // Durante la pausa inferior, el anillo sigue cerrando suavemente.
            let eased = t * t * (3 - (2 * t))
            return -shrink * eased

        case .inhale:
            // Esta compensación solo aplica cuando la inhalación viene de una exhalación previa.
            // Si el ciclo arranca desde idle/preparación no se contrae extra para evitar salto inicial.
            guard previousState == .exhalePause || previousState == .inhale else {
                return 0
            }
            let releaseT = min(max(t / CardioCoherenceConstants.Orb.inhaleReleaseWindow, 0), 1)
            let easedRelease = releaseT * releaseT * (3 - (2 * releaseT))
            return -shrink * (1 - easedRelease)

        default:
            return 0
        }
    }
}

private struct BreathingCueView: View {
    let rhythm: BreathingRhythmOption
    let preparing: Bool
    let paused: Bool
    let preparationRemainingSeconds: Int
    let anchor: Date
    @State private var label: String = "Prepárate"
    @State private var currentPhaseProgress: CGFloat = 0
    @State private var isRhythmTextVisible: Bool = false

    private var secondaryCueText: String {
        if preparing {
            return "La respiración empieza en \(preparationRemainingSeconds)"
        }

        return rhythm.displayLabel
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Text(label)
                    .id(label)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.48))
                    .transition(.opacity)
            }
            .frame(height: 44)

            ZStack {
                if isRhythmTextVisible {
                    Text(secondaryCueText)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.42))
                        .transition(.opacity)
                }
            }
            .frame(height: 18)
        }
        .animation(.easeInOut(duration: CardioCoherenceConstants.Orb.breathingCueTransitionDurationSeconds), value: label)
        .contentShape(Rectangle())
        .onTapGesture {
            guard label == "Inhala" || label == "Exhala" else { return }
            withAnimation(.easeInOut(duration: 0.30)) {
                isRhythmTextVisible.toggle()
            }
        }
        .task(id: "\(rhythm.rawValue)-\(preparing)-\(paused)-\(anchor.timeIntervalSinceReferenceDate)") {
            while !Task.isCancelled {
                let snapshot = breathingCycleSnapshot(
                    now: Date(),
                    anchor: anchor,
                    rhythm: rhythm,
                    preparing: preparing,
                    paused: paused
                )
                label = snapshot.label
                currentPhaseProgress = snapshot.phaseProgress
                try? await Task.sleep(nanoseconds: CardioCoherenceConstants.BreathingPattern.frameRefreshNanos)
            }
        }
    }
}

private struct BreathingCycleSnapshot {
    let progress: CGFloat
    let label: String
    let state: BreathingCycleState
    let phaseProgress: CGFloat
}

private enum BreathingCycleState {
    case idle
    case inhale
    case inhalePause
    case exhale
    case exhalePause
}

private func breathingCycleSnapshot(
    now: Date,
    anchor: Date,
    rhythm: BreathingRhythmOption,
    preparing: Bool,
    paused: Bool
) -> BreathingCycleSnapshot {
    if preparing || paused {
        return BreathingCycleSnapshot(progress: 0.0, label: "Prepárate", state: .idle, phaseProgress: 0.0)
    }

    let inhaleSeconds = Double(rhythm.inhaleMillis) / 1000.0
    let exhaleSeconds = Double(rhythm.exhaleMillis) / 1000.0
    let topPauseSeconds = Double(CardioCoherenceConstants.BreathingPattern.topPauseMillis) / 1000.0
    let cycleSeconds = max(0.001, inhaleSeconds + topPauseSeconds + exhaleSeconds + topPauseSeconds)
    let elapsed = max(0, now.timeIntervalSince(anchor))

    let preparatoryExhaleSeconds = max(0, CardioCoherenceConstants.BreathingPattern.initialPreparatoryExhaleSeconds)
    if elapsed < preparatoryExhaleSeconds {
        let prepProgress = CGFloat(elapsed / max(preparatoryExhaleSeconds, 0.001))
        let remaining = max(1, Int(ceil(preparatoryExhaleSeconds - elapsed)))
        return BreathingCycleSnapshot(
            progress: 0.0,
            label: "Vacía tus pulmones (\(remaining))",
            state: .idle,
            phaseProgress: prepProgress
        )
    }

    let activeElapsed = elapsed - preparatoryExhaleSeconds
    let t = activeElapsed.truncatingRemainder(dividingBy: cycleSeconds)

    if t < inhaleSeconds {
        return BreathingCycleSnapshot(
            progress: CGFloat(t / inhaleSeconds),
            label: "Inhala",
            state: .inhale,
            phaseProgress: CGFloat(t / inhaleSeconds)
        )
    }
    if t < inhaleSeconds + topPauseSeconds {
        let local = t - inhaleSeconds
        return BreathingCycleSnapshot(
            progress: 1.0,
            label: "Inhala",
            state: .inhalePause,
            phaseProgress: CGFloat(local / max(topPauseSeconds, 0.001))
        )
    }
    if t < inhaleSeconds + topPauseSeconds + exhaleSeconds {
        let local = t - inhaleSeconds - topPauseSeconds
        return BreathingCycleSnapshot(
            progress: CGFloat(1.0 - (local / exhaleSeconds)),
            label: "Exhala",
            state: .exhale,
            phaseProgress: CGFloat(local / exhaleSeconds)
        )
    }
    let local = t - inhaleSeconds - topPauseSeconds - exhaleSeconds
    return BreathingCycleSnapshot(
        progress: 0.0,
        label: "Exhala",
        state: .exhalePause,
        phaseProgress: CGFloat(local / max(topPauseSeconds, 0.001))
    )
}

private struct SessionGuidanceDisplay: Identifiable, Equatable {
    let title: String
    let guidance: String
    let emotionPrompt: String?

    var id: String {
        "\(title)|\(guidance)|\(emotionPrompt ?? "")"
    }
}

private struct SessionGuidanceContent: View {
    let display: SessionGuidanceDisplay

    var body: some View {
        VStack(spacing: 8) {
            Text(display.title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(display.guidance)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
            if let emotionPrompt = display.emotionPrompt {
                Text(emotionPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    CardioCoherenceMainView()
}
#else
import SwiftUI
import Combine

struct CardioCoherenceMainView: View {
    var body: some View {
        EmptyView()
    }
}

@MainActor
final class CardioCoherenceMusicPlayer: ObservableObject {
    func playIfEnabled(
        _ enabled: Bool,
        startAt: TimeInterval = 0,
        loopFrom: TimeInterval? = nil,
        customTrackURL: URL? = nil
    ) {}

    func fadeOutAndStop(duration: TimeInterval) {}
    func stop() {}
}
#endif
