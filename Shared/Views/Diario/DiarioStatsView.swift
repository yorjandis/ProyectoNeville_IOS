import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct DiarioStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diarioModel = DiarioModel.shared

    @State private var stats = DiarioStatsSnapshot(entries: [])

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
                        DiarioHeadlineCards(stats: stats)
                        DiarioWeeklyBarChart(stats: stats)
                        DiarioMoodRingsSection(stats: stats)
                        DiarioDotTrendSection(stats: stats)
                    }
                    .padding()
                }
            }
            .navigationTitle("Estadísticas del Diario")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem {
                    Button {
                        reloadStats()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }

                ToolbarItem {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                reloadStats()
            }
        }
    }

    private func reloadStats() {
        let entries = diarioModel.getAllItemGET()
        stats = DiarioStatsSnapshot(entries: entries)
    }
}

private struct DiarioStatsSnapshot {
    struct WeekdayCount: Identifiable {
        var id: String { dayLabel }
        let dayLabel: String
        let count: Int
    }

    struct EmotionCount: Identifiable {
        var id: String { emotion }
        let emotion: String
        let count: Int

        var emoji: String {
            Emociones(rawValue: emotion)?.emoji ?? Emociones.neutral.emoji
        }

        var name: String {
            emotion.capitalized
        }
    }

    struct DayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let count: Int
    }

    let totalEntries: Int
    let favoritesCount: Int
    let currentStreak: Int
    let longestStreak: Int
    let weeklyAverage: Double
    let monthlyAverage: Double
    let weekdayCounts: [WeekdayCount]
    let topEmotions: [EmotionCount]
    let dayPoints: [DayPoint]
    private let dailyCounts: [Date: Int]

    init(entries: [Diario]) {
        let calendar = Calendar.current
        let normalizedDays = entries.compactMap { $0.fecha }.map { calendar.startOfDay(for: $0) }

        totalEntries = entries.count
        favoritesCount = entries.filter(\.isFav).count

        let emotionMap = Dictionary(grouping: entries, by: { $0.emotion ?? Emociones.neutral.rawValue })
            .mapValues(\.count)
            .map { EmotionCount(emotion: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        topEmotions = Array(emotionMap.prefix(5))

        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        let weekdayMap = Dictionary(grouping: normalizedDays, by: { calendar.component(.weekday, from: $0) })
            .mapValues(\.count)

        weekdayCounts = weekdaySymbols.enumerated().map { index, label in
            let weekday = index + 1
            return WeekdayCount(dayLabel: label, count: weekdayMap[weekday] ?? 0)
        }

        if let firstDate = normalizedDays.min(), let lastDate = normalizedDays.max() {
            let daysRange = max(calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0, 1)
            weeklyAverage = Double(totalEntries) / (Double(daysRange) / 7.0)

            let monthRange = max(calendar.dateComponents([.month], from: firstDate, to: lastDate).month ?? 0, 1)
            monthlyAverage = Double(totalEntries) / Double(monthRange)
        } else {
            weeklyAverage = 0
            monthlyAverage = 0
        }

        let daysWithEntries = Set(normalizedDays)
        longestStreak = Self.calculateLongestStreak(from: daysWithEntries, calendar: calendar)
        currentStreak = Self.calculateCurrentStreak(from: daysWithEntries, calendar: calendar)

        dailyCounts = Dictionary(grouping: normalizedDays, by: { $0 }).mapValues(\.count)
        dayPoints = Self.buildDayPoints(days: 30, calendar: calendar, dailyCounts: dailyCounts)
    }

    func dayPoints(for days: Int) -> [DayPoint] {
        let safeDays = max(days, 1)
        return Self.buildDayPoints(days: safeDays, calendar: Calendar.current, dailyCounts: dailyCounts)
    }

    private static func buildDayPoints(days: Int, calendar: Calendar, dailyCounts: [Date: Int]) -> [DayPoint] {
        var points: [DayPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: Date.now) else {
                continue
            }
            let start = calendar.startOfDay(for: targetDate)
            points.append(DayPoint(date: start, count: dailyCounts[start] ?? 0))
        }
        return points
    }

    private static func calculateCurrentStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else {
            return 0
        }

        var streak = 0
        var cursor = calendar.startOfDay(for: Date.now)

        if !days.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), days.contains(yesterday) {
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }

    private static func calculateLongestStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        let sortedDays = days.sorted()
        guard !sortedDays.isEmpty else {
            return 0
        }

        var best = 1
        var current = 1

        for index in 1..<sortedDays.count {
            let previous = sortedDays[index - 1]
            let currentDay = sortedDays[index]
            let diff = calendar.dateComponents([.day], from: previous, to: currentDay).day ?? 0

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

private struct DiarioHeadlineCards: View {
    let stats: DiarioStatsSnapshot

    var body: some View {
        VStack(spacing: 12) {
            Text("Tu ritmo de escritura")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                DiarioMetricCard(
                    title: "Entradas",
                    value: "\(stats.totalEntries)",
                    subtitle: "Total",
                    infoTitle: "Entradas Totales",
                    infoMessage: "Cantidad total de entradas registradas en el Diario desde el inicio."
                )
                DiarioMetricCard(
                    title: "Favoritas",
                    value: "\(stats.favoritesCount)",
                    subtitle: "Guardadas",
                    infoTitle: "Entradas Favoritas",
                    infoMessage: "Número de entradas marcadas como favoritas para acceso rápido."
                )
            }

            HStack(spacing: 12) {
                DiarioMetricCard(
                    title: "Racha actual",
                    value: "\(stats.currentStreak)",
                    subtitle: "días",
                    infoTitle: "Racha Actual",
                    infoMessage: "Días consecutivos recientes con al menos una entrada creada por día."
                )
                DiarioMetricCard(
                    title: "Mejor racha",
                    value: "\(stats.longestStreak)",
                    subtitle: "días",
                    infoTitle: "Mejor Racha",
                    infoMessage: "Mayor número histórico de días consecutivos con actividad en el Diario."
                )
            }

            HStack(spacing: 12) {
                DiarioMetricCard(
                    title: "Promedio",
                    value: String(format: "%.1f", stats.weeklyAverage),
                    subtitle: "por semana",
                    infoTitle: "Promedio Semanal",
                    infoMessage: "Promedio de entradas creadas por semana durante el período de datos disponible."
                )
                DiarioMetricCard(
                    title: "Promedio",
                    value: String(format: "%.1f", stats.monthlyAverage),
                    subtitle: "por mes",
                    infoTitle: "Promedio Mensual",
                    infoMessage: "Promedio de entradas creadas por mes considerando todo el historial del Diario."
                )
            }
        }
    }
}

private struct DiarioMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let infoTitle: String
    let infoMessage: String
    @State private var infoItem: DiarioInfoItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Button {
                    openInfo(title: infoTitle, message: infoMessage, systemImage: "chart.bar.xaxis")
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

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
        #if os(iOS)
        .sheet(item: $infoItem) { info in
            DiarioInfoFloatingCard(info: info)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    private func openInfo(title: String, message: String, systemImage: String) {
        let info = DiarioInfoItem(title: title, message: message, systemImage: systemImage)
        #if os(macOS)
        showWindow(
            for: DiarioInfoFloatingCard(info: info),
            environmentObjects: [],
            title: "Información",
            size: AppCons.windows_size_content_small,
            isModal: true
        )
        #else
        infoItem = info
        #endif
    }
}

private struct DiarioWeeklyBarChart: View {
    let stats: DiarioStatsSnapshot
    @State private var infoItem: DiarioInfoItem?

    var maxCount: Int {
        max(stats.weekdayCounts.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Frecuencia semanal")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    openInfo(
                        title: "Frecuencia Semanal",
                        message: "Cuenta cuántas entradas fueron creadas en cada día de la semana usando la fecha de creación.",
                        systemImage: "chart.bar.fill"
                    )
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(stats.weekdayCounts) { item in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.15))
                                .frame(height: 120)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
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
        #if os(iOS)
        .sheet(item: $infoItem) { info in
            DiarioInfoFloatingCard(info: info)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    private func openInfo(title: String, message: String, systemImage: String) {
        let info = DiarioInfoItem(title: title, message: message, systemImage: systemImage)
        #if os(macOS)
        showWindow(
            for: DiarioInfoFloatingCard(info: info),
            environmentObjects: [],
            title: "Información",
            size: AppCons.windows_size_content_small,
            isModal: true
        )
        #else
        infoItem = info
        #endif
    }
}

private struct DiarioMoodRingsSection: View {
    let stats: DiarioStatsSnapshot
    @State private var infoItem: DiarioInfoItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Sentimientos predominantes")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    openInfo(
                        title: "Sentimientos Predominantes",
                        message: "Ordena las emociones por frecuencia y visualiza las 3 más frecuentes con su peso relativo en el Diario.",
                        systemImage: "face.smiling"
                    )
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            if stats.topEmotions.isEmpty {
                Text("Aún no hay datos emocionales suficientes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                HStack(spacing: 12) {
                    ForEach(Array(stats.topEmotions.prefix(3).enumerated()), id: \.offset) { index, emotion in
                        let fraction = Double(emotion.count) / Double(max(stats.totalEntries, 1))
                        DiarioRingMetric(
                            progress: fraction,
                            color: ringColor(for: index),
                            emoji: emotion.emoji,
                            title: emotion.name,
                            value: emotion.count
                        )
                    }
                }
            }
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        #if os(iOS)
        .sheet(item: $infoItem) { info in
            DiarioInfoFloatingCard(info: info)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    private func openInfo(title: String, message: String, systemImage: String) {
        let info = DiarioInfoItem(title: title, message: message, systemImage: systemImage)
        #if os(macOS)
        showWindow(
            for: DiarioInfoFloatingCard(info: info),
            environmentObjects: [],
            title: "Información",
            size: AppCons.windows_size_content_small,
            isModal: true
        )
        #else
        infoItem = info
        #endif
    }

    private func ringColor(for index: Int) -> Color {
        return .mint
        /*
         switch index {
         case 0: return .purple
         case 1: return .mint
         default: return .cyan
         }
         */
    }
}

private struct DiarioRingMetric: View {
    let progress: Double
    let color: Color
    let emoji: String
    let title: String
    let value: Int
    @State private var infoItem: DiarioInfoItem?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button {
                    openInfo(
                        title: "Anillo de Emoción",
                        message: "Cada anillo representa el porcentaje de una emoción sobre el total de entradas registradas.",
                        systemImage: "circle.dotted"
                    )
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(emoji)
                    .font(.title3)
            }
            .frame(width: 76, height: 76)

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(value)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        #if os(iOS)
        .sheet(item: $infoItem) { info in
            DiarioInfoFloatingCard(info: info)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    private func openInfo(title: String, message: String, systemImage: String) {
        let info = DiarioInfoItem(title: title, message: message, systemImage: systemImage)
        #if os(macOS)
        showWindow(
            for: DiarioInfoFloatingCard(info: info),
            environmentObjects: [],
            title: "Información",
            size: AppCons.windows_size_content_small,
            isModal: true
        )
        #else
        infoItem = info
        #endif
    }
}

private struct DiarioDotTrendSection: View {
    let stats: DiarioStatsSnapshot
    @State private var infoItem: DiarioInfoItem?
    @State private var selectedDays: Int = 30

    private let dayOptions: [Int] = [7, 15, 30, 45, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Actividad de los últimos \(selectedDays) días")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    openInfo(
                        title: "Actividad de los últimos \(selectedDays) Días",
                        message: "Cada punto representa un día. Puedes cambiar el rango a 7, 15, 30, 45, 60 o 90 días para analizar tu ritmo de escritura.",
                        systemImage: "point.3.connected.trianglepath.dotted"
                    )
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            Text("Visualización por puntos al estilo Fitness")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dayOptions, id: \.self) { days in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDays = days
                            }
                        } label: {
                            Text("\(days)d")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedDays == days ? .black : .white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(selectedDays == days ? .white : .white.opacity(0.16))
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(selectedDays == days ? 0 : 0.35), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 12
            ) {
                ForEach(stats.dayPoints(for: selectedDays)) { point in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(dotColor(for: point.count))
                            .frame(width: dotSize(for: point.count), height: dotSize(for: point.count))
                            .overlay {
                                if point.count > 0 {
                                    Text("\(point.count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.black).bold()
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: point.count)

                        Text(point.date.formatted(.dateTime.day()))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .padding()
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        #if os(iOS)
        .sheet(item: $infoItem) { info in
            DiarioInfoFloatingCard(info: info)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    private func openInfo(title: String, message: String, systemImage: String) {
        let info = DiarioInfoItem(title: title, message: message, systemImage: systemImage)
        #if os(macOS)
        showWindow(
            for: DiarioInfoFloatingCard(info: info),
            environmentObjects: [],
            title: "Información",
            size: AppCons.windows_size_content_small,
            isModal: true
        )
        #else
        infoItem = info
        #endif
    }

    private func dotSize(for count: Int) -> CGFloat {
        switch count {
        case 0: return 10
        case 1: return 16
        case 2...3: return 20
        default: return 24
        }
    }

    private func dotColor(for count: Int) -> Color {
        switch count {
        case 0: return .white.opacity(0.2)
        case 1: return .green
        case 2...3: return .yellow
        default: return .orange
        }
    }
}

private struct DiarioInfoItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let systemImage: String
}

private struct DiarioInfoFloatingCard: View {
    let info: DiarioInfoItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .orange, .purple.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: info.systemImage)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.black)

                    Text(info.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Button {
                        #if os(macOS)
                        if let window = NSApp.keyWindow {
                            closeWindow(window)
                        }
                        #else
                        dismiss()
                        #endif
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView(showsIndicators: false) {
                    Text(info.message)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.black).bold()
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(18)
        }
    }
}


