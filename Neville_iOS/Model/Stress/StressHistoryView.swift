import Charts
import SwiftUI

//HealthKitReadOnlyNotice

struct StressHomeIndicator: View {
    @ObservedObject var monitor: StressMonitor
    let primaryText: Color
    let secondaryText: Color
    let trackColor: Color

    private var score: Double { monitor.assessment.score ?? 0 }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .trim(from: 0.11, to: 0.95)
                    .stroke(trackColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(90))

                if monitor.assessment.score != nil {
                    Circle()
                        .trim(from: 0.11, to: 0.11 + 0.84 * min(max(score / 100, 0), 1))
                        .stroke(
                            AngularGradient(
                                colors: [.mint, .yellow, .orange, .pink],
                                center: .center,
                                startAngle: .degrees(130),
                                endAngle: .degrees(430)
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(90))
                }

                Circle()
                    .fill(levelColor.opacity(0.16))
                    .frame(width: 38, height: 38)

                Image(systemName: monitor.assessment.level == .activity ? "figure.run" : "waveform.path.ecg")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(levelColor)
            }
            .frame(width: 68, height: 68)

            Text("Estrés")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)

            Text(statusText)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(secondaryText)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estrés fisiológico con HealthKit")
        .accessibilityValue(statusText)
        .accessibilityHint("Abre el histórico y las estadísticas")
    }

    private var statusText: String {
        switch monitor.accessState {
        case .notRequested:
            return L10n.exact("Configurar")
        case .loading where monitor.assessment.score == nil:
            return L10n.exact("Leyendo…")
        case .unavailable:
            return L10n.exact("No disponible")
        case .failed:
            return L10n.exact("Reintentar")
        default:
            if monitor.assessment.level == .activity { return L10n.exact("En actividad") }
            guard let score = monitor.assessment.score else { return L10n.exact("Sin lectura") }
            return L10n.format(
                "home.stress.level_score",
                fallback: "{0} · {1}",
                monitor.assessment.level.displayName,
                "\(Int(score.rounded()))"
            )
        }
    }

    private var levelColor: Color {
        monitor.assessment.level.color
    }
}

struct StressHistoryView: View {
    @ObservedObject var monitor: StressMonitor
    @State private var range: StressHistoryRange = .week
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                HealthKitReadOnlyNotice()
                
                currentCard

                if monitor.accessState == .notRequested {
                    permissionCard
                } else if monitor.accessState == .unavailable {
                    unavailableCard
                } else {
                    if case .failed(let message) = monitor.accessState {
                        errorCard(message)
                    }
                    historyContent
                }

                methodCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Salud y HealthKit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await monitor.refresh(days: range.days, force: true) }
                } label: {
                    if monitor.isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(monitor.isRefreshing || monitor.accessState == .notRequested)
                .accessibilityLabel("Actualizar datos de Salud")
            }
        }
        .task {
            monitor.activateBackgroundObservationIfNeeded()
            await monitor.refresh(days: range.days)
        }
        .onChange(of: range) { _, newRange in
            Task { await monitor.refresh(days: newRange.days, force: true) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            Task {
                await monitor.refresh(days: range.days, force: true)
            }
        }
    }

    private var currentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(monitor.assessment.level.color.opacity(0.18), lineWidth: 9)
                    if let score = monitor.assessment.score {
                        Circle()
                            .trim(from: 0, to: min(max(score / 100, 0.01), 1))
                            .stroke(
                                monitor.assessment.level.color,
                                style: StrokeStyle(lineWidth: 9, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(score.rounded()))")
                            .font(.title2.bold())
                    } else {
                        Image(systemName: monitor.assessment.level == .activity ? "figure.run" : "heart.text.square")
                            .font(.title2)
                            .foregroundStyle(monitor.assessment.level.color)
                    }
                }
                .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 4) {
                    Text(monitor.assessment.level.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(monitor.assessment.level.color)
                    Text(currentSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if monitor.assessment.score != nil {
                        Label(
                            L10n.format(
                                "home.stress.confidence",
                                fallback: "Confianza {0}",
                                monitor.assessment.confidence.displayName.lowercased()
                            ),
                            systemImage: "checkmark.shield"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            if !monitor.assessment.signals.isEmpty {
                Divider()
                ForEach(monitor.assessment.signals) { signal in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(signal.name).font(.subheadline.bold())
                            Text(signal.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(signal.value).font(.subheadline.monospacedDigit())
                    }
                }
            }

            if !monitor.assessment.sourceNames.isEmpty {
                Text(L10n.format(
                    "home.stress.source",
                    fallback: "Fuente: {0}",
                    monitor.assessment.sourceNames.joined(separator: ", ")
                ))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var permissionCard: some View {
        VStack(spacing: 13) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 36))
                .foregroundStyle(.pink)
            Text("Conecta Salud con HealthKit")
                .font(.headline)
            Text("La Ley puede usar HealthKit para leer pulso, VFC, respiración, pasos y entrenamientos guardados por Apple Watch y la app Salud. Los datos se procesan en este dispositivo y La Ley no añade ni modifica datos de Salud.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await monitor.requestAuthorization() }
            } label: {
                Label("Continuar", systemImage: "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var unavailableCard: some View {
        ContentUnavailableView(
            "Salud no está disponible",
            systemImage: "heart.slash",
            description: Text("Este indicador necesita un dispositivo compatible con HealthKit.")
        )
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("No se pudieron leer los datos", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message).font(.caption).foregroundStyle(.secondary)
            Button("Reintentar") {
                Task { await monitor.refresh(days: range.days, force: true) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var historyContent: some View {
        Picker("Periodo", selection: $range) {
            ForEach(StressHistoryRange.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)

        if monitor.history.isEmpty && !monitor.isRefreshing {
            healthAccessOrEmptyDataCard
        } else {
            statisticsGrid
            timelineCard
            dailyPatternCard
            practicalInsightCard
        }
    }

    private var statisticsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statisticCard("Promedio", value: averageScore.map { "\(Int($0.rounded()))/100" } ?? "—", symbol: "waveform.path.ecg")
            statisticCard("Pico habitual", value: peakHourText, symbol: "clock.badge.exclamationmark")
            statisticCard("Lecturas altas", value: elevatedPercentageText, symbol: "exclamationmark.arrow.triangle.2.circlepath")
            statisticCard("Cobertura", value: coverageText, symbol: "checkmark.shield")
        }
    }

    private func statisticCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(.pink)
            Text(value).font(.headline).minimumScaleFactor(0.75).lineLimit(1)
            Text(L10n.exact(title)).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolución").font(.headline)
            Chart(monitor.history) { point in
                AreaMark(
                    x: .value(L10n.exact("Hora"), point.date),
                    y: .value(L10n.exact("Nivel"), point.score)
                )
                .foregroundStyle(
                    LinearGradient(colors: [.pink.opacity(0.32), .pink.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                )
                LineMark(
                    x: .value(L10n.exact("Hora"), point.date),
                    y: .value(L10n.exact("Nivel"), point.score)
                )
                .foregroundStyle(.pink)
                .lineStyle(StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100])
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: range == .day ? .dateTime.hour() : .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 220)
            Text("Se excluyen periodos con ejercicio o movimiento significativo.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var dailyPatternCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patrón por hora del día").font(.headline)
            Chart(hourlyAverages) { item in
                BarMark(
                    x: .value(L10n.exact("Hora"), item.hour),
                    y: .value(L10n.exact("Nivel medio"), item.average)
                )
                .foregroundStyle(item.average >= 50 ? Color.orange : Color.mint)
                .cornerRadius(3)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) { Text(String(format: "%02d h", hour)) }
                    }
                }
            }
            .frame(height: 190)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var practicalInsightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Información práctica", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.indigo)
            Text(practicalInsight)
                .font(.subheadline)
            if let calm = calmHourText {
                Text(L10n.format(
                    "home.stress.calm_period",
                    fallback: "Tu franja comparativamente más calmada es {0}. Puede ser un buen momento para tareas que requieren concentración.",
                    calm
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.indigo.opacity(0.09), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var methodCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Cómo funciona con HealthKit", systemImage: "info.circle")
                .font(.headline)
            Text("La Ley usa HealthKit para leer datos de la app Salud. La estimación compara el pulso, la variabilidad cardiaca (VFC/SDNN) y, cuando es reciente, la respiración con una referencia personal robusta de hasta 30 días. Detecta movimiento, pasos y entrenamientos para no interpretar el ejercicio como estrés, y muestra la confianza según cobertura y antigüedad de los datos.")
            Text("Apple Watch realiza lecturas periódicas; fuera de un entrenamiento no son continuas. Por eso “en tiempo real” significa la estimación más reciente disponible en Salud.")
            Text("Es una orientación de bienestar, no un diagnóstico médico. Una lectura alta también puede deberse a cafeína, fiebre, falta de sueño, medicación u otras causas. Si tienes síntomas preocupantes, consulta a un profesional sanitario.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    
    private var healthAccessOrEmptyDataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("No se pueden leer datos de Salud", systemImage: "heart.slash")
                .font(.headline)
                .foregroundStyle(.pink)

            Text("La Ley no ha podido obtener lecturas recientes desde la app Salud. Puede que el acceso a HealthKit esté desactivado o que todavía no haya suficientes datos registrados por Apple Watch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Para comprobarlo:")
                    .font(.body.bold())

                Text("1. Abre Ajustes.")
                Text("2. Entra en Privacidad y seguridad.")
                Text("3. Abre Salud.")
                Text("4. Selecciona La Ley.")
                Text("5. Activa los datos necesarios: pulso, VFC, respiración, pasos y entrenamientos.")
            }
            .font(.body)
            .foregroundStyle(.secondary)

            Button {
                Task {
                    await monitor.refresh(days: range.days, force: true)
                }
            } label: {
                Label("Volver a comprobar", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var currentSubtitle: String {
        if monitor.isRefreshing && monitor.assessment.score == nil { return L10n.exact("Consultando Salud…") }
        if monitor.assessment.level == .activity { return L10n.exact("Estimación pausada durante el movimiento") }
        guard let age = monitor.assessment.dataAge else { return L10n.exact("Sin lectura reciente") }
        if age < 60 { return L10n.exact("Actualizado ahora") }
        if age < 3_600 {
            return L10n.format(
                "home.stress.updated_minutes_ago",
                fallback: "Actualizado hace {0} min",
                "\(Int(age / 60))"
            )
        }
        return L10n.format(
            "home.stress.updated_hours_ago",
            fallback: "Actualizado hace {0} h",
            "\(Int(age / 3_600))"
        )
    }

    private var averageScore: Double? {
        guard !monitor.history.isEmpty else { return nil }
        return monitor.history.map(\.score).reduce(0, +) / Double(monitor.history.count)
    }

    private var elevatedPercentageText: String {
        guard !monitor.history.isEmpty else { return "—" }
        let elevated = monitor.history.filter { $0.score >= 50 }.count
        return "\(Int((Double(elevated) / Double(monitor.history.count) * 100).rounded())) %"
    }

    private var coverageText: String {
        let expected = max(1, Int(Double(range.days * 86_400) / range.binDuration))
        return "\(min(100, Int((Double(monitor.history.count) / Double(expected) * 100).rounded()))) %"
    }

    private var hourlyAverages: [StressHourlyAverage] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: monitor.history) { calendar.component(.hour, from: $0.date) }
        return grouped.map { hour, points in
            StressHourlyAverage(hour: hour, average: points.map(\.score).reduce(0, +) / Double(points.count))
        }.sorted { $0.hour < $1.hour }
    }

    private var peakHourText: String {
        guard let peak = hourlyAverages.max(by: { $0.average < $1.average }) else { return "—" }
        return hourRange(peak.hour)
    }

    private var calmHourText: String? {
        hourlyAverages.min(by: { $0.average < $1.average }).map { hourRange($0.hour) }
    }

    private var practicalInsight: String {
        guard let peak = hourlyAverages.max(by: { $0.average < $1.average }) else {
            return L10n.exact("Aún hacen falta más lecturas para detectar un patrón diario fiable.")
        }
        if peak.average >= 50 {
            return L10n.format(
                "home.stress.high_period_insight",
                fallback: "La activación tiende a concentrarse entre {0}. Considera reservar una pausa breve de respiración o movimiento suave antes de esa franja.",
                hourRange(peak.hour)
            )
        }
        return L10n.format(
            "home.stress.normal_period_insight",
            fallback: "No aparece una franja persistentemente alta en este periodo. La mayor activación relativa se concentra entre {0}.",
            hourRange(peak.hour)
        )
    }

    private func hourRange(_ hour: Int) -> String {
        String(format: "%02d:00–%02d:00", hour, (hour + 1) % 24)
    }
}

private enum StressHistoryRange: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }
    var title: String {
        switch self {
        case .day: L10n.exact("24 h")
        case .week: L10n.exact("7 días")
        case .month: L10n.exact("30 días")
        }
    }
    var days: Int {
        switch self {
        case .day: 1
        case .week: 7
        case .month: 30
        }
    }
    var binDuration: TimeInterval {
        switch self {
        case .day: 30 * 60
        case .week: 2 * 60 * 60
        case .month: 6 * 60 * 60
        }
    }
}

private struct StressHourlyAverage: Identifiable {
    let hour: Int
    let average: Double
    var id: Int { hour }
}

private extension StressLevel {
    var color: Color {
        switch self {
        case .low: .mint
        case .moderate: .yellow
        case .high: .orange
        case .veryHigh: .pink
        case .activity: .blue
        case .unavailable: .secondary
        }
    }
}


//Tarjeta informativa
struct HealthKitReadOnlyNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.message")
                .foregroundStyle(.pink)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 4) {
                Text("Datos de HealthKit (solo lectura)")
                    .font(.headline)
                Text("Los datos para el cálculo de estrés se toman de la aplicación Salud, utilizando HealthKit en modo solo lectura.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Aviso de privacidad")
        .accessibilityHint("La app solo lee datos de HealthKit.")
    }
}
