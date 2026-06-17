#if os(iOS)
import SwiftUI

struct PresenciaStatsView: View {
    @State private var dayStats: [PresenciaDayStats] = []
    @State private var moodStats: [PresenciaMoodStats] = []
    @State private var todayPresentCount = 0
    @State private var selectedRange = 14

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

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
                .onAppear(perform: reload)
                .onChange(of: selectedRange) { _, _ in reload() }
            } else {
                PurchaseView()
            }
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
            HStack(spacing: 10) {
                metricCard(title: "Presente", value: "\(dayStats.reduce(0) { $0 + $1.presentes })")
                metricCard(title: "Piloto auto.", value: "\(dayStats.reduce(0) { $0 + $1.inconscientes })")
                metricCard(title: "Ratio", value: ratioText)
            }
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

    private var ratioText: String {
        let presentes = dayStats.reduce(0) { $0 + $1.presentes }
        let inconscientes = dayStats.reduce(0) { $0 + $1.inconscientes }
        let total = presentes + inconscientes
        guard total > 0 else { return "0%" }
        return "\(Int((Double(presentes) / Double(total) * 100).rounded()))%"
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reload() {
        dayStats = repository.dayStats(days: selectedRange)
        moodStats = repository.moodStats(days: selectedRange)
        todayPresentCount = repository.todayPresentCount()
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
                    .frame(maxWidth: .infinity)
                }
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
            .frame(height: max(CGFloat(value) / CGFloat(maxValue) * 70, value == 0 ? 3 : 8))
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
                    .frame(maxWidth: .infinity)
                }
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
}
#endif
