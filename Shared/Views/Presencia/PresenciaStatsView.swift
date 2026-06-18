#if os(iOS)
import SwiftUI

struct PresenciaStatsView: View {
    private let embeddedInNavigation: Bool
    @State private var dayStats: [PresenciaDayStats] = []
    @State private var moodStats: [PresenciaMoodStats] = []
    @State private var todayPresentCount = 0
    @State private var selectedRange = 14
    @State private var futureFeelingCount = 0
    @State private var streakStats = PresenciaStreakStats(currentDays: 0, bestDays: 0)
    @State private var showResetConfirmation = false

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    private let repository = PresenciaRepository()

    init(embeddedInNavigation: Bool = false) {
        self.embeddedInNavigation = embeddedInNavigation
    }

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    var body: some View {
        Group {
            if embeddedInNavigation {
                content
            } else {
                NavigationStack {
                    content
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
            if hasPremiumAccess {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        insightCards
                        rangePicker
                        PresenciaBarsView(stats: dayStats)
                        PresenciaRatioDotsView(stats: dayStats)
                        moodSection
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
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Resetear estadísticas")
                    }
                }
                .confirmationDialog(
                    "Resetear estadísticas de Presencia",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Borrar historial completo", role: .destructive) {
                        resetPresenceStats()
                    }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Esta acción borrará todo el historial de Presencia en Core Data y CloudKit, actualizará los contadores de iOS y enviará el reset al Apple Watch. No se puede deshacer.")
                }
                .onAppear(perform: reload)
                .onChange(of: selectedRange) { _, _ in reload() }
                .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
                    reload()
                }
            } else {
                PurchaseView()
            }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presencia")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Hoy has vuelto al presente \(todayPresentCount) veces.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var rangePicker: some View {
        Picker("Rango", selection: $selectedRange) {
            Text("14 días").tag(14)
            Text("30 días").tag(30)
            Text("90 días").tag(90)
        }
        .pickerStyle(.segmented)
    }

    private var insightCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 12)], spacing: 12) {
            TodayReturnsCard(count: todayPresentCount)
            CurrentStreakCard(days: streakStats.currentDays)
            WeeklyAverageCard(weekStats: currentWeekStats)
            DominantMoodCard(summary: dominantMoodSummary)
        }
    }

    private var ratioText: String {
        let presentes = dayStats.reduce(0) { $0 + $1.presentes }
        let inconscientes = dayStats.reduce(0) { $0 + $1.inconscientes }
        let total = presentes + inconscientes
        guard total > 0 else { return "0%" }
        return "\(Int((Double(presentes) / Double(total) * 100).rounded()))%"
    }

    private var currentWeekStats: [PresenciaDayStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            return dayStats.first { calendar.isDate($0.date, inSameDayAs: date) }
                ?? PresenciaDayStats(date: date, presentes: 0, inconscientes: 0, estadosAnimo: 0, futuroAhora: 0)
        }
    }

    private var dominantMoodSummary: DominantMoodSummary? {
        guard let dominant = moodStats.first else { return nil }
        let total = moodStats.reduce(0) { $0 + $1.count }
        let percentage = total > 0 ? Int((Double(dominant.count) / Double(total) * 100).rounded()) : 0
        return DominantMoodSummary(title: dominant.title, percentage: percentage)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estados de ánimo")
                .font(.headline)
                .foregroundStyle(.white)

            if moodStats.isEmpty {
                Text("Aún no hay estados registrados.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            } else {
                ForEach(moodStats.prefix(8)) { item in
                    HStack {
                        Text(item.title)
                        Spacer()
                        Text("\(item.count)")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reload() {
        dayStats = repository.dayStats(days: selectedRange)
        moodStats = repository.moodStats(days: selectedRange)
        todayPresentCount = repository.todayPresentCount()
        futureFeelingCount = repository.futureFeelingCount(days: selectedRange)
        streakStats = repository.streakStats(days: selectedRange)
    }

    private func resetPresenceStats() {
        guard repository.resetAllEvents() else { return }
        WatchDataSyncToWatch.shared.sendPresenceReset()
        reload()
    }
}

private struct DominantMoodSummary: Hashable {
    let title: String
    let percentage: Int
}

private struct PresenceGlassCard<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, minHeight: 184, alignment: .topLeading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                )
                .shadow(color: accent.opacity(0.18), radius: 18, y: 10)
        )
    }
}

private struct PresenceCardHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color(red: 0.13, green: 0.11, blue: 0.24))
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TodayReturnsCard: View {
    let count: Int

    var body: some View {
        PresenceGlassCard(accent: .purple) {
            PresenceCardHeader(icon: "sun.max", title: "Hoy", subtitle: "Retornos", accent: .purple)

            Spacer(minLength: 0)

            Text("\(count)")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)

            Text(count >= 10 ? "¡Sigue así!" : "Vuelve cuando lo notes")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.purple.opacity(0.9))
                .frame(maxWidth: .infinity)
        }
    }
}

private struct CurrentStreakCard: View {
    let days: Int

    var body: some View {
        PresenceGlassCard(accent: .orange) {
            PresenceCardHeader(icon: "flame.fill", title: "Racha", subtitle: "actual", accent: .orange)

            Spacer(minLength: 0)

            Text("\(days)")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)

            Text("días seguidos")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.13, green: 0.11, blue: 0.24))
                .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index < min(days, 7) ? .orange : .clear)
                        .overlay(Circle().stroke(.orange, lineWidth: 1))
                        .frame(width: 11, height: 11)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct WeeklyAverageCard: View {
    let weekStats: [PresenciaDayStats]

    private var average: Int {
        guard !weekStats.isEmpty else { return 0 }
        let total = weekStats.reduce(0) { $0 + $1.presentes }
        return Int((Double(total) / Double(weekStats.count)).rounded())
    }

    private var maxValue: Int {
        max(weekStats.map(\.presentes).max() ?? 1, 1)
    }

    var body: some View {
        PresenceGlassCard(accent: .green) {
            PresenceCardHeader(icon: "arrow.up.right", title: "Esta semana", subtitle: "Promedio diario", accent: .green)

            Spacer(minLength: 0)

            Text("\(average)")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)

            Text("retornos")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.13, green: 0.11, blue: 0.24))
                .frame(maxWidth: .infinity)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(weekStats.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.green.opacity(day.presentes == 0 ? 0.28 : 0.62))
                            .frame(width: 8, height: max(CGFloat(day.presentes) / CGFloat(maxValue) * 28, day.presentes == 0 ? 5 : 9))
                        Text(weekdayLetter(for: day.date))
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.13, green: 0.11, blue: 0.24).opacity(0.82))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func weekdayLetter(for date: Date) -> String {
        let symbol = Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        return String(symbol.prefix(1)).uppercased()
    }
}

private struct DominantMoodCard: View {
    let summary: DominantMoodSummary?

    var body: some View {
        PresenceGlassCard(accent: .blue) {
            PresenceCardHeader(icon: "heart", title: "Estado de ánimo", subtitle: "predominante", accent: .blue)

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                Circle()
                    .stroke(.blue.opacity(0.82), lineWidth: 3)
                Image(systemName: summary == nil ? "face.dashed" : "face.smiling")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.blue)
            }
            .frame(width: 74, height: 74)
            .frame(maxWidth: .infinity)

            Text(summary?.title ?? "Sin registros")
                .font(.headline)
                .foregroundStyle(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            Text(summary.map { "\($0.percentage)% de tus registros" } ?? "Registra un estado")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.13, green: 0.11, blue: 0.24))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct PresenciaBarsView: View {
    let stats: [PresenciaDayStats]

    private var maxValue: Int {
        max(stats.map { max($0.presentes, $0.inconscientes) }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Eventos diarios")
                .font(.headline)
                .foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(stats) { day in
                        VStack(spacing: 3) {
                            Spacer(minLength: 0)
                            bar(value: day.presentes, color: .mint)
                            bar(value: day.inconscientes, color: .orange)
                            Text(day.date, format: .dateTime.day())
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .frame(width: 16)
                    }
                }
                .frame(minWidth: minChartWidth, minHeight: 180, alignment: .bottomLeading)
            }
            .frame(height: 180)
            legend
        }
        .padding(14)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func bar(value: Int, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color.opacity(value == 0 ? 0.2 : 0.9))
            .frame(width: 7, height: max(CGFloat(value) / CGFloat(maxValue) * 70, value == 0 ? 3 : 8))
    }

    private var minChartWidth: CGFloat {
        max(CGFloat(stats.count) * 23, 320)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            Label("Presente", systemImage: "circle.fill")
                .foregroundStyle(.mint)
            Label("Piloto automático", systemImage: "circle.fill")
                .foregroundStyle(.orange)
        }
        .font(.caption)
    }
}

private struct PresenciaRatioDotsView: View {
    let stats: [PresenciaDayStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cociente presente/inconsciente")
                .font(.headline)
                .foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(stats) { day in
                        VStack(spacing: 6) {
                            Spacer(minLength: 0)
                            Circle()
                                .fill(day.total == 0 ? .white.opacity(0.22) : .cyan)
                                .frame(width: 9, height: 9)
                                .offset(y: CGFloat(1 - day.ratioPresencia) * 80)
                            Text(day.date, format: .dateTime.day())
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .frame(width: 16)
                    }
                }
                .frame(minWidth: minChartWidth, minHeight: 120, alignment: .bottomLeading)
            }
            .frame(height: 120)
            Text("Más alto significa que, entre los eventos registrados, hubo más retornos conscientes.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(14)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var minChartWidth: CGFloat {
        max(CGFloat(stats.count) * 24, 320)
    }
}
#endif


#Preview{
    PresenciaStatsView()
}
