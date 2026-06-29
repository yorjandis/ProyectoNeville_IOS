#if os(iOS) || os(macOS)
import SwiftUI

private struct AgendaCompletedStatusCardPreview: View {
    var body: some View {
        ZStack {
            previewBackground
            card
        }
    }

    private var previewBackground: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        [
            .blue.opacity(0.6),
            .blue.opacity(0.2)
        ]
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleRow
            completedStatusRow
            detailText
        }
        .padding(12)
        .frame(maxWidth: 360, alignment: .leading)
        .background(cardBackground)
        .padding()
    }

    private var titleRow: some View {
        HStack {
            Circle()
                .fill(Color(red: 0.87, green: 0.74, blue: 0.48))
                .frame(width: 10, height: 10)

            Text("Revisar intencion del dia")
                .font(.headline)
                .foregroundStyle(.black)

            Spacer()
        }
    }

    private var completedStatusRow: some View {
        HStack(spacing: 5) {
            completedIcon

            Text("Completada")
                .font(.body)
                .foregroundStyle(.black)
        }
    }

    private var completedIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .symbolRenderingMode(.palette)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white, Color(red: 0.0, green: 0.48, blue: 0.22))
            .background(iconBackdrop)
    }

    private var iconBackdrop: some View {
        Circle()
            .fill(.white.opacity(0.92))
            .frame(width: 14, height: 14)
    }

    private var detailText: some View {
        Text("Entrada de ejemplo para comprobar el contraste del circulo de completado sobre el fondo azul.")
            .font(.body)
            .foregroundStyle(.black.opacity(0.82))
            .lineLimit(2)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.white.opacity(0.5))
    }
}

#Preview("Agenda - Estado completado") {
    AgendaCompletedStatusCardPreview()
}
#endif
