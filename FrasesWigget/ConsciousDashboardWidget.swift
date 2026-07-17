import SwiftUI
import WidgetKit

private enum WidgetL10n {
  static func exact(_ spanish: String) -> String {
    Bundle.main.localizedString(forKey: spanish, value: spanish, table: "Localizable")
  }
}

struct ConsciousDashboardEntry: TimelineEntry {
  let date: Date
  let snapshot: ConsciousDashboardSnapshot
}

struct ConsciousDashboardProvider: TimelineProvider {
  func placeholder(in context: Context) -> ConsciousDashboardEntry {
    ConsciousDashboardEntry(date: .now, snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (ConsciousDashboardEntry) -> Void) {
    let now = Date()
    completion(
      ConsciousDashboardEntry(
        date: now,
        snapshot: context.isPreview ? .placeholder : .load().normalized(for: now)
      )
    )
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<ConsciousDashboardEntry>) -> Void
  ) {
    let now = Date()
    let entry = ConsciousDashboardEntry(date: now, snapshot: .load().normalized(for: now))
    let nextRefresh =
      Calendar.current.date(byAdding: .minute, value: 15, to: now)
      ?? now.addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }
}

private struct ConsciousMetric: Identifiable {
  let id: String
  let title: String
  let compactTitle: String
  let symbol: String
  let colors: [Color]
  let destination: URL
  let requiresPremium: Bool
  let value: Int
  let primaryText: String
  let detailText: String
  let progress: Double?
  let completed: Bool
}

private struct ConsciousDashboardBackground: View {
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    if renderingMode == .fullColor {
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.025, green: 0.055, blue: 0.16),
            Color(red: 0.12, green: 0.055, blue: 0.25),
            Color(red: 0.01, green: 0.18, blue: 0.23),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        Circle()
          .fill(Color.cyan.opacity(0.22))
          .frame(width: 190, height: 190)
          .blur(radius: 34)
          .offset(x: 130, y: -100)

        Circle()
          .fill(Color.pink.opacity(0.22))
          .frame(width: 170, height: 170)
          .blur(radius: 40)
          .offset(x: -140, y: 120)
      }
    } else {
      Color.clear
    }
  }
}

struct ConsciousDashboardEntryView: View {
  let entry: ConsciousDashboardEntry

  @Environment(\.widgetFamily) private var family
  @Environment(\.widgetRenderingMode) private var renderingMode
  @Environment(\.isLuminanceReduced) private var isLuminanceReduced

  private var snapshot: ConsciousDashboardSnapshot { entry.snapshot }

  private var metrics: [ConsciousMetric] {
    [
      ConsciousMetric(
        id: "metas",
        title: WidgetL10n.exact("Metas activas"),
        compactTitle: WidgetL10n.exact("Metas"),
        symbol: "target",
        colors: [.green, .mint],
        destination: dashboardURL("metas"),
        requiresPremium: true,
        value: snapshot.completedGoalUnits,
        primaryText: "\(snapshot.activeGoals)",
        detailText: snapshot.totalGoalUnits > 0
          ? "\(snapshot.completedGoalUnits)/\(snapshot.totalGoalUnits) \(WidgetL10n.exact("unidades"))"
          : WidgetL10n.exact("Sin unidades activas"),
        progress: snapshot.goalProgress,
        completed: snapshot.activeGoals > 0 && snapshot.goalProgress >= 1
      ),
      ConsciousMetric(
        id: "presencia",
        title: WidgetL10n.exact("Presencia"),
        compactTitle: WidgetL10n.exact("Presencia"),
        symbol: "camera.macro",
        colors: [.cyan, .mint],
        destination: dashboardURL("presencia"),
        requiresPremium: true,
        value: snapshot.presenceReturns,
        primaryText: "\(snapshot.presenceReturns)",
        detailText: snapshot.automaticPilotEvents > 0
          ? "\(snapshot.automaticPilotEvents) \(WidgetL10n.exact("en automático"))"
          : WidgetL10n.exact("retornos conscientes"),
        progress: min(Double(snapshot.presenceReturns) / 5, 1),
        completed: snapshot.presenceReturns >= 5
      ),
      ConsciousMetric(
        id: "agenda",
        title: WidgetL10n.exact("Agenda de hoy"),
        compactTitle: WidgetL10n.exact("Agenda"),
        symbol: "calendar.badge.clock",
        colors: [.yellow, .orange],
        destination: dashboardURL("agenda"),
        requiresPremium: true,
        value: snapshot.agendaCompleted,
        primaryText: "\(snapshot.agendaCompleted)/\(snapshot.agendaToday)",
        detailText: WidgetL10n.exact(snapshot.agendaToday == 1 ? "actividad" : "actividades"),
        progress: snapshot.agendaProgress,
        completed: snapshot.agendaToday > 0 && snapshot.agendaCompleted == snapshot.agendaToday
      ),
      ConsciousMetric(
        id: "diario",
        title: WidgetL10n.exact("Diario"),
        compactTitle: WidgetL10n.exact("Diario"),
        symbol: "book.closed.fill",
        colors: [.purple, .pink],
        destination: dashboardURL("diario"),
        requiresPremium: false,
        value: snapshot.journalEntriesToday,
        primaryText: "\(snapshot.journalEntriesToday)",
        detailText: WidgetL10n.exact(snapshot.journalEntriesToday == 1 ? "entrada hoy" : "entradas hoy"),
        progress: snapshot.journalEntriesToday > 0 ? 1 : 0,
        completed: snapshot.journalEntriesToday > 0
      ),
      ConsciousMetric(
        id: "ritual",
        title: WidgetL10n.exact("Ritual matutino"),
        compactTitle: WidgetL10n.exact("Ritual"),
        symbol: "sunrise.fill",
        colors: [.pink, .orange],
        destination: dashboardURL("ritual-matutino"),
        requiresPremium: true,
        value: snapshot.morningRitualCompleted ? 1 : 0,
        primaryText: WidgetL10n.exact(snapshot.morningRitualCompleted ? "Hecho" : "Pendiente"),
        detailText: WidgetL10n.exact(snapshot.morningRitualCompleted ? "día intencionado" : "diseña tu día"),
        progress: snapshot.morningRitualCompleted ? 1 : 0,
        completed: snapshot.morningRitualCompleted
      ),
      ConsciousMetric(
        id: "cierre",
        title: WidgetL10n.exact("Cierre consciente"),
        compactTitle: WidgetL10n.exact("Cierre"),
        symbol: "moon.stars.fill",
        colors: [.indigo, .purple],
        destination: dashboardURL("cierre"),
        requiresPremium: true,
        value: snapshot.eveningReviewCompleted ? 1 : 0,
        primaryText: WidgetL10n.exact(snapshot.eveningReviewCompleted ? "Hecho" : "Pendiente"),
        detailText: WidgetL10n.exact(snapshot.eveningReviewCompleted ? "día integrado" : "integra tu día"),
        progress: snapshot.eveningReviewCompleted ? 1 : 0,
        completed: snapshot.eveningReviewCompleted
      ),
      ConsciousMetric(
        id: "coherencia",
        title: WidgetL10n.exact("Coherencia"),
        compactTitle: WidgetL10n.exact("Coherencia"),
        symbol: "waveform.path.ecg",
        colors: [.indigo, .teal],
        destination: dashboardURL("coherencia"),
        requiresPremium: true,
        value: snapshot.coherenceSessions,
        primaryText: "\(snapshot.coherenceSessions)",
        detailText: coherenceDetail,
        progress: min(Double(snapshot.coherenceMinutes) / 15, 1),
        completed: snapshot.coherenceSessions > 0
      ),
    ]
  }

  var body: some View {
    Group {
      switch family {
      case .systemMedium:
        compactDashboard
      case .systemLarge, .systemExtraLarge:
        expandedDashboard
      default:
        compactDashboard
      }
    }
    .containerBackground(for: .widget) {
      ConsciousDashboardBackground()
    }
    .foregroundStyle(.white)
    .accessibilityElement(children: .contain)
    .accessibilityLabel(WidgetL10n.exact("Panel de control consciente"))
  }

  private var compactDashboard: some View {
    VStack(spacing: 6) {
      HStack(spacing: 8) {
        pulseMark(size: 27, lineWidth: 4)

        VStack(alignment: .leading, spacing: 0) {
          Text("AHORA")
            .font(.system(size: 9, weight: .black, design: .rounded))
            .tracking(1.4)
            .foregroundStyle(renderingMode == .fullColor ? .cyan : .white)
            .widgetAccentable()
          Text("Panel consciente")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .lineLimit(1)
        }

        Spacer(minLength: 2)

        Text("\(snapshot.consciousPulse)%")
          .font(.system(size: 17, weight: .black, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText())
          .animation(widgetAnimation, value: snapshot.consciousPulse)
      }

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 5)
      {
        ForEach(metrics) { metric in
          metricTile(metric, compact: true)
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
  }

  private var expandedDashboard: some View {
    VStack(spacing: family == .systemExtraLarge ? 14 : 10) {
      HStack(spacing: 12) {
        pulseMark(size: family == .systemExtraLarge ? 72 : 58, lineWidth: 7)

        VStack(alignment: .leading, spacing: 3) {
          Text("TU ESTADO · AHORA")
            .font(.caption2.weight(.black))
            .tracking(1.5)
            .foregroundStyle(renderingMode == .fullColor ? .cyan : .white)
            .widgetAccentable()
          Text("Panel consciente")
            .font(
              .system(size: family == .systemExtraLarge ? 26 : 21, weight: .bold, design: .rounded))
          Text("Actualizado \(snapshot.generatedAt, style: .time)")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.70))
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 0) {
          Text("\(snapshot.consciousPulse)")
            .font(
              .system(size: family == .systemExtraLarge ? 38 : 31, weight: .black, design: .rounded)
            )
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(widgetAnimation, value: snapshot.consciousPulse)
          Text("pulso")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.68))
        }
      }

      expandedMetricsLayout
    }
    .padding(family == .systemExtraLarge ? 18 : 14)
  }

  @ViewBuilder
  private var expandedMetricsLayout: some View {
    if family == .systemExtraLarge {
      VStack(spacing: 8) {
        LazyVGrid(columns: expandedColumns, spacing: 8) {
          ForEach(metrics.filter { $0.id != "presencia" }) { metric in
            metricTile(metric, compact: false)
          }
        }

        LazyVGrid(columns: expandedColumns, spacing: 8) {
          Color.clear

          if let presence = metrics.first(where: { $0.id == "presencia" }) {
            metricTile(presence, compact: false)
          }

          Color.clear
        }
      }
    } else {
      LazyVGrid(columns: expandedColumns, spacing: 8) {
        ForEach(metrics) { metric in
          metricTile(metric, compact: false)
        }
      }
    }
  }

  private var expandedColumns: [GridItem] {
    let count = family == .systemExtraLarge ? 3 : 2
    return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
  }

  @ViewBuilder
  private func metricTile(_ metric: ConsciousMetric, compact: Bool) -> some View {
    let isLocked = metric.requiresPremium && !snapshot.hasPremiumAccess

    Link(destination: metric.destination) {
      if compact {
        compactMetricTile(metric, isLocked: isLocked)
      } else {
        expandedMetricTile(metric, isLocked: isLocked)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(metric.title)
    .accessibilityValue(
      isLocked ? "Requiere Premium" : "\(metric.primaryText), \(metric.detailText)"
    )
    .accessibilityHint("\(WidgetL10n.exact("Abre")) \(metric.title) \(WidgetL10n.exact("en La Ley"))")
  }

  private func compactMetricTile(_ metric: ConsciousMetric, isLocked: Bool) -> some View {
    VStack(spacing: 3) {
      ZStack(alignment: .topTrailing) {
        Image(systemName: metric.symbol)
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(metricForeground(metric))
          .symbolEffect(.bounce, value: metric.value)
          .widgetAccentable()

        if isLocked {
          Image(systemName: "lock.fill")
            .font(.system(size: 7, weight: .black))
            .offset(x: 8, y: -3)
        }
      }

      Text(isLocked ? "PRO" : metric.primaryText)
        .font(.system(size: 12.5, weight: .black, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText())
        .animation(widgetAnimation, value: metric.value)

      Text(metric.compactTitle)
        .font(.system(size: 9, weight: .bold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .foregroundStyle(.white.opacity(0.88))
    }
    .frame(maxWidth: .infinity, minHeight: 49)
    .background(metricBackground(metric))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(.white.opacity(renderingMode == .fullColor ? 0.14 : 0.34), lineWidth: 0.7)
    }
  }

  private func expandedMetricTile(_ metric: ConsciousMetric, isLocked: Bool) -> some View {
    HStack(spacing: 10) {
      ZStack {
        Circle()
          .fill(metricForeground(metric).opacity(0.18))
        Image(systemName: isLocked ? "lock.fill" : metric.symbol)
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(metricForeground(metric))
          .symbolEffect(.bounce, value: metric.value)
          .widgetAccentable()
      }
      .frame(width: 35, height: 35)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(metric.title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .lineLimit(1)
          if isLocked {
            Text("PRO")
              .font(.system(size: 6, weight: .black, design: .rounded))
              .padding(.horizontal, 4)
              .padding(.vertical, 2)
              .background(.white.opacity(0.18))
              .clipShape(Capsule())
          }
        }

        Text(isLocked ? WidgetL10n.exact("Desbloquear") : metric.primaryText)
          .font(.system(size: 15, weight: .black, design: .rounded))
          .monospacedDigit()
          .lineLimit(1)
          .contentTransition(.numericText())
          .animation(widgetAnimation, value: metric.value)

        Text(isLocked ? WidgetL10n.exact("Acceso Premium") : metric.detailText)
          .font(.system(size: 8.5, weight: .medium, design: .rounded))
          .lineLimit(1)
          .foregroundStyle(.white.opacity(0.68))
      }

      Spacer(minLength: 2)

      if !isLocked, let progress = metric.progress {
        metricProgressRing(metric, progress: progress)
      }
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, minHeight: family == .systemExtraLarge ? 66 : 57)
    .background(metricBackground(metric))
    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .stroke(.white.opacity(renderingMode == .fullColor ? 0.14 : 0.34), lineWidth: 0.8)
    }
  }

  private func metricProgressRing(_ metric: ConsciousMetric, progress: Double) -> some View {
    let size: CGFloat = family == .systemExtraLarge ? 28 : 25
    let lineWidth: CGFloat = family == .systemExtraLarge ? 3.2 : 2.8
    let clampedProgress = min(max(progress, 0), 1)

    return ZStack {
      Circle()
        .stroke(.white.opacity(0.14), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: max(clampedProgress, 0.025))
        .stroke(
          metricForeground(metric),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(widgetAnimation, value: clampedProgress)
    }
    .frame(width: size, height: size)
    .widgetAccentable()
    .accessibilityHidden(true)
  }

  private func pulseMark(size: CGFloat, lineWidth: CGFloat) -> some View {
    ZStack {
      Circle()
        .stroke(.white.opacity(0.13), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: max(Double(snapshot.consciousPulse) / 100, 0.025))
        .stroke(
          renderingMode == .fullColor
            ? AnyShapeStyle(AngularGradient(colors: [.cyan, .mint, .pink, .cyan], center: .center))
            : AnyShapeStyle(Color.white),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(widgetAnimation, value: snapshot.consciousPulse)
        .widgetAccentable()
      Image(systemName: "sparkles")
        .font(.system(size: size * 0.28, weight: .black))
        .symbolEffect(.pulse, value: snapshot.consciousPulse)
    }
    .frame(width: size, height: size)
  }

  private func metricForeground(_ metric: ConsciousMetric) -> Color {
    renderingMode == .fullColor ? metric.colors[0] : .white
  }

  private func metricBackground(_ metric: ConsciousMetric) -> some ShapeStyle {
    LinearGradient(
      colors: renderingMode == .fullColor
        ? [metric.colors[0].opacity(0.22), metric.colors[1].opacity(0.10)]
        : [.white.opacity(0.12), .white.opacity(0.04)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var coherenceDetail: String {
    if let score = snapshot.coherenceScore {
      return "\(snapshot.coherenceMinutes) min · \(score)/10"
    }
    return snapshot.coherenceMinutes > 0 ? "\(snapshot.coherenceMinutes) minutos" : "sin sesión hoy"
  }

  private var widgetAnimation: Animation? {
    isLuminanceReduced ? nil : .spring(duration: 0.55, bounce: 0.22)
  }

  private func dashboardURL(_ tool: String) -> URL {
    URL(string: "laley://dashboard/\(tool)")!
  }
}

struct ConsciousDashboardWidget: Widget {
  let kind = ConsciousDashboardSnapshot.widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ConsciousDashboardProvider()) { entry in
      ConsciousDashboardEntryView(entry: entry)
    }
    .configurationDisplayName("Panel consciente")
    .description("Metas, presencia, Agenda, Diario, rituales y coherencia en un único estado vivo.")
    .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    .contentMarginsDisabled()
  }
}

#Preview(as: .systemMedium) {
  ConsciousDashboardWidget()
} timeline: {
  ConsciousDashboardEntry(date: .now, snapshot: .placeholder)
}

#Preview(as: .systemLarge) {
  ConsciousDashboardWidget()
} timeline: {
  ConsciousDashboardEntry(date: .now, snapshot: .placeholder)
}
