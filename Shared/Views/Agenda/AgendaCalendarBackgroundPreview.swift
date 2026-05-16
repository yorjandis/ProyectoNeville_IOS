import SwiftUI

struct AgendaCalendarBackgroundPreviewSamples: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                previewCard(
                    title: "Actual",
                    gradient: LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.93, blue: 0.75),
                            Color(red: 0.95, green: 0.83, blue: 0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                previewCard(
                    title: "Opción A",
                    gradient: LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.97, blue: 1.00),
                            Color(red: 0.74, green: 0.90, blue: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                previewCard(
                    title: "Opción B",
                    gradient: LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.94, blue: 0.87),
                            Color(red: 1.00, green: 0.85, blue: 0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .padding()
        }
        .background(Color(white: 0.95))
    }

    @ViewBuilder
    private func previewCard(title: String, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(["L", "M", "X", "J", "V", "S", "D"], id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.7))
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        Text("\(day)")
                            .font(day == 4 ? .headline : .body)
                            .fontWeight(day == 2 || day == 5 ? .bold : .regular)
                            .foregroundStyle(day == 4 ? Color.black : (day == 2 || day == 5 ? Color.blue : Color.black))
                            .frame(maxWidth: .infinity, minHeight: 28)
                            .background(
                                Circle().fill(day == 4 ? Color(red: 0.95, green: 0.67, blue: 0.37) : .clear)
                            )
                    }
                }
            }
            .padding(10)
            .background(gradient, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("Agenda · Fondo Calendario") {
    AgendaCalendarBackgroundPreviewSamples()
}
