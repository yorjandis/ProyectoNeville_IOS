import SwiftUI

// Plantilla de tarjeta con título y hasta dos botones con acciones.
@MainActor
@ViewBuilder
func card(
    title: String,
    buttonTitle1: String,
    buttonTitle2: String = "",
    buttonAction1: @escaping () -> Void,
    buttonAction2: (() -> Void)? = nil
) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.headline)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .foregroundStyle(.black)

        HStack(spacing: 10) {
            Button(buttonTitle1) {
                buttonAction1()
            }
            .buttonStyle(.bordered)
            .tint(.black)
            .foregroundStyle(.white)

            if !buttonTitle2.isEmpty {
                Button(buttonTitle2) {
                    buttonAction2?()
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .foregroundStyle(.white)
            }
        }
    }
    .padding(12)
    .frame(height: 90, alignment: .topLeading)
    .background(Color.blue.opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay {
        RoundedRectangle(cornerRadius: 14)
            .stroke(.white.opacity(0.22), lineWidth: 1)
    }
}
