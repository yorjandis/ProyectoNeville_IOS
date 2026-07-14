import Foundation
import HealthKit

enum StressLevel: String, CaseIterable, Sendable {
    case low = "Bajo"
    case moderate = "Moderado"
    case high = "Alto"
    case veryHigh = "Muy alto"
    case activity = "Actividad"
    case unavailable = "Sin datos"

    init(score: Double) {
        switch score {
        case ..<25: self = .low
        case ..<50: self = .moderate
        case ..<75: self = .high
        default: self = .veryHigh
        }
    }
}

enum StressConfidence: String, Sendable {
    case low = "Baja"
    case medium = "Media"
    case high = "Alta"

    init(value: Double) {
        switch value {
        case ..<0.48: self = .low
        case ..<0.76: self = .medium
        default: self = .high
        }
    }
}

struct StressSignal: Identifiable, Sendable {
    let name: String
    let value: String
    let detail: String

    var id: String { name }
}

struct StressAssessment: Sendable {
    let date: Date
    let score: Double?
    let level: StressLevel
    let confidenceValue: Double
    let signals: [StressSignal]
    let sourceNames: [String]
    let dataAge: TimeInterval?

    var confidence: StressConfidence { StressConfidence(value: confidenceValue) }

    static let unavailable = StressAssessment(
        date: .now,
        score: nil,
        level: .unavailable,
        confidenceValue: 0,
        signals: [],
        sourceNames: [],
        dataAge: nil
    )
}

struct StressHistoryPoint: Identifiable, Sendable {
    let date: Date
    let score: Double
    let confidence: Double
    let level: StressLevel
    let isActivity: Bool

    var id: Date { date }
}

enum StressAccessState: Equatable, Sendable {
    case notRequested
    case loading
    case ready
    case noData
    case unavailable
    case failed(String)
}

@MainActor
final class StressMonitor: ObservableObject {
    static let shared = StressMonitor()

    @Published private(set) var assessment: StressAssessment = .unavailable
    @Published private(set) var history: [StressHistoryPoint] = []
    @Published private(set) var accessState: StressAccessState
    @Published private(set) var isRefreshing = false
    @Published private(set) var selectedHistoryDays = 7

    private let healthStore = HKHealthStore()
    private let authorizationDefaultsKey = "StressHealthAuthorizationWasRequested"
    private var observerQueries: [HKObserverQuery] = []
    private var observersStarted = false
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0
    private var lastSuccessfulRefresh: Date?

    private static let heartRateType = HKQuantityType(.heartRate)
    private static let restingHeartRateType = HKQuantityType(.restingHeartRate)
    private static let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
    private static let respiratoryRateType = HKQuantityType(.respiratoryRate)
    private static let stepCountType = HKQuantityType(.stepCount)

    private static var readTypes: Set<HKObjectType> {
        [
            heartRateType,
            restingHeartRateType,
            hrvType,
            respiratoryRateType,
            stepCountType,
            HKObjectType.workoutType()
        ]
    }

    private init() {
        if !HKHealthStore.isHealthDataAvailable() {
            accessState = .unavailable
        } else if UserDefaults.standard.bool(forKey: authorizationDefaultsKey) {
            accessState = .noData
        } else {
            accessState = .notRequested
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    func activateBackgroundObservationIfNeeded() {
        guard UserDefaults.standard.bool(forKey: authorizationDefaultsKey) else { return }
        startObserversIfNeeded()
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            accessState = .unavailable
            return
        }

        accessState = .loading
        do {
            try await healthStore.requestAuthorization(toShare: [], read: Self.readTypes)
            UserDefaults.standard.set(true, forKey: authorizationDefaultsKey)
            startObserversIfNeeded()
            await refresh(days: selectedHistoryDays, force: true)
        } catch {
            accessState = .failed(error.localizedDescription)
        }
    }

    func refresh(days: Int? = nil, force: Bool = false) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            accessState = .unavailable
            return
        }
        guard UserDefaults.standard.bool(forKey: authorizationDefaultsKey) else {
            accessState = .notRequested
            return
        }

        let requestedDays = min(max(days ?? selectedHistoryDays, 1), 30)
        if !force,
           let lastSuccessfulRefresh,
           Date().timeIntervalSince(lastSuccessfulRefresh) < 60 {
            return
        }
        refreshGeneration += 1
        let generation = refreshGeneration
        selectedHistoryDays = requestedDays
        isRefreshing = true
        if assessment.score == nil { accessState = .loading }
        defer {
            if generation == refreshGeneration {
                isRefreshing = false
            }
        }

        do {
            let now = Date()
            let baselineStart = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now.addingTimeInterval(-30 * 86_400)

            let heartRates = try await quantityValues(
                type: Self.heartRateType,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: baselineStart,
                end: now,
                includeMotionContext: true
            )
            let restingHeartRates = try await quantityValues(
                type: Self.restingHeartRateType,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: baselineStart,
                end: now
            )
            let hrvValues = try await quantityValues(
                type: Self.hrvType,
                unit: .secondUnit(with: .milli),
                start: baselineStart,
                end: now
            )
            let respiratoryRates = try await quantityValues(
                type: Self.respiratoryRateType,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: baselineStart,
                end: now
            )
            let steps = try await quantityValues(
                type: Self.stepCountType,
                unit: .count(),
                start: Calendar.current.date(byAdding: .day, value: -requestedDays, to: now) ?? baselineStart,
                end: now
            )
            let workouts = try await workoutIntervals(start: now.addingTimeInterval(-30 * 60), end: now)

            let payload = StressHealthPayload(
                heartRates: heartRates,
                restingHeartRates: restingHeartRates,
                hrv: hrvValues,
                respiratoryRates: respiratoryRates,
                steps: steps,
                hasRecentWorkout: !workouts.isEmpty
            )
            let baseline = StressEstimator.baseline(from: payload)
            guard generation == refreshGeneration else { return }
            assessment = StressEstimator.currentAssessment(from: payload, baseline: baseline, now: now)
            history = StressEstimator.history(
                from: payload,
                baseline: baseline,
                days: requestedDays,
                now: now
            )
            accessState = assessment.score == nil && history.isEmpty ? .noData : .ready
            lastSuccessfulRefresh = Date()
            startObserversIfNeeded()
        } catch {
            if generation == refreshGeneration {
                accessState = .failed(error.localizedDescription)
            }
        }
    }

    private func startObserversIfNeeded() {
        guard !observersStarted, HKHealthStore.isHealthDataAvailable() else { return }
        observersStarted = true

        for type in [Self.heartRateType, Self.hrvType, Self.restingHeartRateType, Self.respiratoryRateType] {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
                completion()
                guard error == nil else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.scheduleObservedRefresh()
                }
            }
            observerQueries.append(query)
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
        }
    }

    private func scheduleObservedRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self else { return }
            await self.refresh()
        }
    }

    private func quantityValues(
        type: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date,
        includeMotionContext: Bool = false
    ) async throws -> [StressTimedValue] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [descriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let values = (samples as? [HKQuantitySample] ?? []).map { sample in
                    let motionContext: Int?
                    if includeMotionContext {
                        motionContext = (sample.metadata?[HKMetadataKeyHeartRateMotionContext] as? NSNumber)?.intValue
                    } else {
                        motionContext = nil
                    }

                    return StressTimedValue(
                        date: sample.startDate,
                        endDate: sample.endDate,
                        value: sample.quantity.doubleValue(for: unit),
                        motionContext: motionContext,
                        sourceName: sample.sourceRevision.source.name
                    )
                }
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }
    }

    private func workoutIntervals(start: Date, end: Date) async throws -> [DateInterval] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let intervals = (samples as? [HKWorkout] ?? []).map {
                    DateInterval(start: $0.startDate, end: $0.endDate)
                }
                continuation.resume(returning: intervals)
            }
            healthStore.execute(query)
        }
    }
}

private struct StressTimedValue: Sendable {
    let date: Date
    let endDate: Date
    let value: Double
    let motionContext: Int?
    let sourceName: String

    var isActiveHeartRate: Bool { motionContext == HKHeartRateMotionContext.active.rawValue }
}

private struct StressHealthPayload: Sendable {
    let heartRates: [StressTimedValue]
    let restingHeartRates: [StressTimedValue]
    let hrv: [StressTimedValue]
    let respiratoryRates: [StressTimedValue]
    let steps: [StressTimedValue]
    let hasRecentWorkout: Bool
}

private struct StressBaseline: Sendable {
    let heartRate: Double?
    let heartRateSampleCount: Int
    let hrv: Double?
    let hrvSampleCount: Int
    let respiratoryRate: Double?
    let respiratorySampleCount: Int
}

private enum StressEstimator {
    static func baseline(from payload: StressHealthPayload) -> StressBaseline {
        let resting = payload.restingHeartRates.map(\.value).filter(Self.isPlausibleHeartRate)
        let sedentary = payload.heartRates
            .filter { !$0.isActiveHeartRate && Self.isPlausibleHeartRate($0.value) }
            .map(\.value)

        let heartRateBaseline: Double?
        let heartRateCount: Int
        if resting.count >= 5 {
            heartRateBaseline = median(resting)
            heartRateCount = resting.count
        } else {
            heartRateBaseline = percentile(sedentary, 0.25)
            heartRateCount = sedentary.count
        }

        let hrv = payload.hrv.map(\.value).filter { (5...250).contains($0) }
        let respiratory = payload.respiratoryRates.map(\.value).filter { (6...40).contains($0) }

        return StressBaseline(
            heartRate: heartRateBaseline,
            heartRateSampleCount: heartRateCount,
            hrv: median(hrv),
            hrvSampleCount: hrv.count,
            respiratoryRate: median(respiratory),
            respiratorySampleCount: respiratory.count
        )
    }

    static func currentAssessment(
        from payload: StressHealthPayload,
        baseline: StressBaseline,
        now: Date
    ) -> StressAssessment {
        let heartRateWindow = DateInterval(start: now.addingTimeInterval(-20 * 60), end: now)
        let recentHeartRates = payload.heartRates.filter { heartRateWindow.contains($0.date) }
        let recentSteps = payload.steps
            .filter { $0.date >= now.addingTimeInterval(-10 * 60) }
            .reduce(0) { $0 + $1.value }
        let activeRatio = recentHeartRates.isEmpty
            ? 0
            : Double(recentHeartRates.filter(\.isActiveHeartRate).count) / Double(recentHeartRates.count)
        let isActive = payload.hasRecentWorkout || recentSteps >= 120 || activeRatio >= 0.5

        let usableHeartRates = recentHeartRates
            .filter { !$0.isActiveHeartRate && isPlausibleHeartRate($0.value) }
        let currentHeartRate = median(usableHeartRates.map(\.value))
        let currentHRV = payload.hrv.last { $0.date >= now.addingTimeInterval(-3 * 60 * 60) && (5...250).contains($0.value) }
        let currentRespiratory = payload.respiratoryRates.last {
            $0.date >= now.addingTimeInterval(-2 * 60 * 60) && (6...40).contains($0.value)
        }

        let latestDates = [usableHeartRates.last?.date, currentHRV?.date, currentRespiratory?.date].compactMap { $0 }
        let sources = Set(
            usableHeartRates.map(\.sourceName)
                + [currentHRV?.sourceName, currentRespiratory?.sourceName].compactMap { $0 }
        ).sorted()

        if isActive {
            return StressAssessment(
                date: now,
                score: nil,
                level: .activity,
                confidenceValue: min(0.9, 0.45 + activeRatio * 0.45),
                signals: [
                    StressSignal(
                        name: "Movimiento",
                        value: recentSteps > 0 ? "\(Int(recentSteps)) pasos" : "Detectado",
                        detail: "Se pausa la estimación para no confundir ejercicio con estrés."
                    )
                ],
                sourceNames: sources,
                dataAge: latestDates.max().map { now.timeIntervalSince($0) }
            )
        }

        guard let result = score(
            heartRate: currentHeartRate,
            hrv: currentHRV?.value,
            respiratoryRate: currentRespiratory?.value,
            baseline: baseline
        ) else {
            return .unavailable
        }

        let newestDate = latestDates.max()
        let age = newestDate.map { max(0, now.timeIntervalSince($0)) }
        let freshness = age.map { clamp(1 - ($0 / (3 * 60 * 60)), 0.15, 1) } ?? 0
        let baselineCoverage = min(1, Double(baseline.heartRateSampleCount) / 14) * 0.55
            + min(1, Double(baseline.hrvSampleCount) / 20) * 0.45
        let signalCoverage = min(1, result.weight / 0.90)
        let confidence = clamp(0.40 * freshness + 0.32 * baselineCoverage + 0.28 * signalCoverage, 0, 1)

        var signals: [StressSignal] = []
        if let currentHeartRate, let heartRateBaseline = baseline.heartRate {
            signals.append(
                StressSignal(
                    name: "Pulso",
                    value: "\(Int(currentHeartRate.rounded())) lpm",
                    detail: "Referencia personal: \(Int(heartRateBaseline.rounded())) lpm"
                )
            )
        }
        if let currentHRV, let hrvBaseline = baseline.hrv {
            signals.append(
                StressSignal(
                    name: "VFC (SDNN)",
                    value: "\(Int(currentHRV.value.rounded())) ms",
                    detail: "Referencia personal: \(Int(hrvBaseline.rounded())) ms"
                )
            )
        }
        if let currentRespiratory, let respiratoryBaseline = baseline.respiratoryRate {
            signals.append(
                StressSignal(
                    name: "Respiración",
                    value: String(format: "%.1f rpm", currentRespiratory.value),
                    detail: String(format: "Referencia personal: %.1f rpm", respiratoryBaseline)
                )
            )
        }

        return StressAssessment(
            date: newestDate ?? now,
            score: result.value,
            level: StressLevel(score: result.value),
            confidenceValue: confidence,
            signals: signals,
            sourceNames: sources,
            dataAge: age
        )
    }

    static func history(
        from payload: StressHealthPayload,
        baseline: StressBaseline,
        days: Int,
        now: Date
    ) -> [StressHistoryPoint] {
        let binDuration: TimeInterval = days <= 1 ? 30 * 60 : days <= 7 ? 2 * 60 * 60 : 6 * 60 * 60
        let rawStart = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now.addingTimeInterval(-Double(days) * 86_400)
        var cursor = rawStart
        var result: [StressHistoryPoint] = []

        while cursor < now {
            let end = min(cursor.addingTimeInterval(binDuration), now)
            let heartRates = payload.heartRates.filter { $0.date >= cursor && $0.date < end }
            let activeRatio = heartRates.isEmpty
                ? 0
                : Double(heartRates.filter(\.isActiveHeartRate).count) / Double(heartRates.count)
            let steps = payload.steps
                .filter { $0.date >= cursor && $0.date < end }
                .reduce(0) { $0 + $1.value }
            let activeThreshold = 12 * (binDuration / 60)
            let isActive = activeRatio >= 0.5 || steps >= activeThreshold

            if !isActive {
                let usableHeartRates = heartRates
                    .filter { !$0.isActiveHeartRate && isPlausibleHeartRate($0.value) }
                    .map(\.value)
                let hrv = payload.hrv.last {
                    $0.date < end && $0.date >= end.addingTimeInterval(-4 * 60 * 60) && (5...250).contains($0.value)
                }?.value
                let respiratory = payload.respiratoryRates.last {
                    $0.date < end && $0.date >= cursor && (6...40).contains($0.value)
                }?.value

                if let score = score(
                    heartRate: median(usableHeartRates),
                    hrv: hrv,
                    respiratoryRate: respiratory,
                    baseline: baseline
                ) {
                    let sampleSupport = min(1, Double(usableHeartRates.count) / 3)
                    let signalSupport = min(1, score.weight / 0.90)
                    let confidence = clamp(0.55 * sampleSupport + 0.45 * signalSupport, 0, 1)
                    if confidence >= 0.28 {
                        result.append(
                            StressHistoryPoint(
                                date: cursor.addingTimeInterval(end.timeIntervalSince(cursor) / 2),
                                score: score.value,
                                confidence: confidence,
                                level: StressLevel(score: score.value),
                                isActivity: false
                            )
                        )
                    }
                }
            }
            cursor = end
        }

        return result
    }

    private static func score(
        heartRate: Double?,
        hrv: Double?,
        respiratoryRate: Double?,
        baseline: StressBaseline
    ) -> (value: Double, weight: Double)? {
        var weightedScore = 0.0
        var totalWeight = 0.0

        if let heartRate, let baselineHeartRate = baseline.heartRate, baselineHeartRate > 0 {
            let relativeElevation = heartRate / baselineHeartRate - 1
            let component = clamp((relativeElevation - 0.02) / 0.28, 0, 1) * 100
            weightedScore += component * 0.48
            totalWeight += 0.48
        }

        if let hrv, let baselineHRV = baseline.hrv, baselineHRV > 0 {
            let suppression = (baselineHRV - hrv) / max(10, baselineHRV * 0.45)
            weightedScore += clamp(suppression, 0, 1) * 100 * 0.42
            totalWeight += 0.42
        }

        if let respiratoryRate, let baselineRespiratory = baseline.respiratoryRate, baselineRespiratory > 0 {
            let relativeElevation = respiratoryRate / baselineRespiratory - 1
            let component = clamp((relativeElevation - 0.03) / 0.30, 0, 1) * 100
            weightedScore += component * 0.10
            totalWeight += 0.10
        }

        guard totalWeight >= 0.38 else { return nil }
        return (clamp(weightedScore / totalWeight, 0, 100), totalWeight)
    }

    private static func isPlausibleHeartRate(_ value: Double) -> Bool {
        (35...220).contains(value)
    }

    private static func median(_ values: [Double]) -> Double? {
        percentile(values, 0.5)
    }

    private static func percentile(_ values: [Double], _ percentile: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let position = clamp(percentile, 0, 1) * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        guard lower != upper else { return sorted[lower] }
        let fraction = position - Double(lower)
        return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
    }

    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}
