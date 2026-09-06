#if os(iOS) || os(macOS)
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Presentación comercial común para cualquier herramienta de la Versión Extendida.
/// Admite una acción externa para abrir el muro de pago; si no se proporciona,
/// presenta `PurchaseView` de forma nativa en iOS y macOS.
struct PremiumFeaturePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let feature: PremiumFeatureID
    private let onOpenPurchase: (() -> Void)?

    @State private var showsPurchase = false
    @State private var selectedScreenshot: PremiumScreenshotSelection?
    @State private var glowOffset: CGFloat = -36

    init(feature: PremiumFeatureID, onOpenPurchase: (() -> Void)? = nil) {
        self.feature = feature
        self.onOpenPurchase = onOpenPurchase
    }

    private var presentation: PremiumFeaturePresentation {
        feature.presentation
    }

    var body: some View {
        ZStack {
            premiumBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: contentSpacing) {
                    header
                    if !presentation.screenshotNames.isEmpty {
                        screenshotGallery
                    }
                    valueCard
                    purchaseCallToAction
                }
                .frame(maxWidth: 920)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(.white)
        .environment(\.locale, AppLanguage.current.locale)
        .sheet(isPresented: $showsPurchase) {
            PurchaseView(mostrarLogo: true, mostrarBotonCerrarMacOS: true)
        }
#if os(iOS)
        .fullScreenCover(item: $selectedScreenshot) { selection in
            PremiumScreenshotFullscreenView(selection: selection)
        }
#else
        .sheet(item: $selectedScreenshot) { selection in
            PremiumScreenshotFullscreenView(selection: selection)
        }
#endif
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.18), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.exact("Cerrar"))
            .padding(16)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                glowOffset = 42
            }
        }
#if os(macOS)
        .frame(minWidth: 620, idealWidth: 760, minHeight: 680, idealHeight: 820)
#endif
    }

    private var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.20, blue: 0.48),
                    Color(red: 0.19, green: 0.25, blue: 0.68),
                    Color(red: 0.43, green: 0.27, blue: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.cyan.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -150 + glowOffset, y: -250)

            Circle()
                .fill(.purple.opacity(0.30))
                .frame(width: 390, height: 390)
                .blur(radius: 85)
                .offset(x: 190 - glowOffset, y: 300)

            LinearGradient(
                colors: [.white.opacity(0.10), .clear, .black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        Text(presentation.title)
            .font(.system(size: titleSize, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 38)
            .accessibilityAddTraits(.isHeader)
    }

    private var screenshotGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: gallerySpacing) {
                ForEach(Array(presentation.screenshotNames.enumerated()), id: \.element) { index, name in
                    PremiumScreenshotCard(
                        assetName: name,
                        feature: presentation,
                        position: index + 1
                    ) {
                        selectedScreenshot = PremiumScreenshotSelection(
                            assetName: name,
                            feature: presentation,
                            position: index + 1
                        )
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private var valueCard: some View {
        VStack(alignment: .leading, spacing: valueCardSpacing) {
            valueSection(
                icon: "sparkles",
                title: PremiumFeatureLocalization.string("premium.preview.what_it_does", fallback: "Lo que hará por ti"),
                text: presentation.description
            )

            Divider().overlay(.white.opacity(0.18))

            valueSection(
                icon: "arrow.up.right.circle.fill",
                title: PremiumFeatureLocalization.string("premium.preview.practical_value", fallback: "Valor práctico"),
                text: presentation.practicalValue
            )
        }
        .padding(valueCardPadding)
        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
    }

    private func valueSection(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: valueSectionSpacing) {
            Image(systemName: icon)
                .font(valueIconFont)
                .foregroundStyle(.cyan)
                .frame(width: valueIconSize, height: valueIconSize)
                .background(.cyan.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: valueTextSpacing) {
                Text(title)
                    .font(.headline.weight(.bold))
                Text(text)
                    .font(valueBodyFont)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(valueLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var purchaseCallToAction: some View {
        VStack(spacing: callToActionSpacing) {
            Button(action: openPurchase) {
                HStack(spacing: 11) {
                    Image(systemName: "sparkles")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(PremiumFeatureLocalization.string("premium.preview.cta", fallback: "Desbloquear esta función"))
                            .font(.headline.weight(.bold))
                        Text(PremiumFeatureLocalization.string("premium.preview.cta_detail", fallback: "Ver la suscripción y la prueba disponible"))
                            .font(.caption)
                            .opacity(0.76)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.42))
                .padding(.horizontal, 20)
                .padding(.vertical, callToActionVerticalPadding)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.white, Color(red: 0.84, green: 0.94, blue: 1.00)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 19, style: .continuous)
                )
                .shadow(color: .cyan.opacity(0.30), radius: 18, y: 8)
            }
            .buttonStyle(PremiumCTAButtonStyle())

            // Debe permanecer siempre como último mensaje de la presentación.
            Label(
                PremiumFeatureLocalization.string(
                    "premium.preview.annual_note",
                    fallback: "La suscripción anual muy asequible. Además, los primeros siete días son gratuitos."
                ),
                systemImage: "checkmark.seal.fill"
            )
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func openPurchase() {
        if let onOpenPurchase {
            onOpenPurchase()
        } else {
            showsPurchase = true
        }
    }

    private var contentSpacing: CGFloat {
#if os(iOS)
        14
#else
        24
#endif
    }

    private var horizontalPadding: CGFloat {
#if os(iOS)
        16
#else
        20
#endif
    }

    private var topPadding: CGFloat {
#if os(iOS)
        12
#else
        22
#endif
    }

    private var bottomPadding: CGFloat {
#if os(iOS)
        18
#else
        28
#endif
    }

    private var titleSize: CGFloat {
#if os(iOS)
        28
#else
        34
#endif
    }

    private var gallerySpacing: CGFloat {
#if os(iOS)
        12
#else
        16
#endif
    }

    private var valueCardSpacing: CGFloat {
#if os(iOS)
        13
#else
        18
#endif
    }

    private var valueCardPadding: CGFloat {
#if os(iOS)
        16
#else
        22
#endif
    }

    private var cardCornerRadius: CGFloat {
#if os(iOS)
        22
#else
        26
#endif
    }

    private var valueSectionSpacing: CGFloat {
#if os(iOS)
        11
#else
        14
#endif
    }

    private var valueTextSpacing: CGFloat {
#if os(iOS)
        4
#else
        6
#endif
    }

    private var valueIconSize: CGFloat {
#if os(iOS)
        30
#else
        34
#endif
    }

    private var valueIconFont: Font {
#if os(iOS)
        .headline.weight(.semibold)
#else
        .title3.weight(.semibold)
#endif
    }

    private var valueBodyFont: Font {
#if os(iOS)
        .subheadline
#else
        .body
#endif
    }

    private var valueLineSpacing: CGFloat {
#if os(iOS)
        1.5
#else
        3
#endif
    }

    private var callToActionSpacing: CGFloat {
#if os(iOS)
        10
#else
        13
#endif
    }

    private var callToActionVerticalPadding: CGFloat {
#if os(iOS)
        12
#else
        15
#endif
    }

}

/// Wrapper reutilizable para que las nuevas herramientas no repitan la lógica de acceso.
struct PremiumFeatureGate<Content: View>: View {
    @AppStorage("purchaseStatus") private var purchaseStatus = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium = false

    let feature: PremiumFeatureID
    private let content: Content

    init(feature: PremiumFeatureID, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.content = content()
    }

    var body: some View {
        if purchaseStatus || yorjPremium {
            content
        } else {
            PremiumFeaturePreviewView(feature: feature)
        }
    }
}

private struct PremiumScreenshotCard: View {
    let assetName: String
    let feature: PremiumFeaturePresentation
    let position: Int
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            Group {
                if let screenshotImage {
                    screenshotImage
                        .resizable()
                        .scaledToFit()
                } else {
                    PremiumScreenshotPlaceholder(feature: feature, position: position)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .padding(.vertical, 5)
            .clipped()
            .background(.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.24), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.22), radius: 16, y: 10)
        .accessibilityLabel(
            PremiumFeatureLocalization.format(
                "premium.preview.screenshot_accessibility",
                fallback: "Vista previa {0} de {1}",
                String(position),
                feature.title
            )
        )
        .accessibilityHint(PremiumFeatureLocalization.string(
            "premium.preview.open_screenshot",
            fallback: "Ver imagen a pantalla completa"
        ))
    }

    private var screenshotImage: Image? {
        PremiumScreenshotImageLoader.image(named: assetName)
    }

    private var cardWidth: CGFloat {
#if os(macOS)
        390
#else
        150
#endif
    }

    private var cardHeight: CGFloat {
#if os(macOS)
        244
#else
        270
#endif
    }
}

private struct PremiumScreenshotSelection: Identifiable {
    let assetName: String
    let feature: PremiumFeaturePresentation
    let position: Int

    var id: String { "\(assetName)-\(position)" }
}

private struct PremiumScreenshotFullscreenView: View {
    @Environment(\.dismiss) private var dismiss

    let selection: PremiumScreenshotSelection

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if let image = PremiumScreenshotImageLoader.image(named: selection.assetName) {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    PremiumScreenshotPlaceholder(
                        feature: selection.feature,
                        position: selection.position
                    )
                    .aspectRatio(0.77, contentMode: .fit)
                    .frame(maxWidth: 620, maxHeight: 760)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
            }
            .padding(24)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.50), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.exact("Cerrar"))
            .padding(18)
        }
#if os(macOS)
        .frame(minWidth: 620, idealWidth: 900, minHeight: 620, idealHeight: 820)
#endif
    }
}

private enum PremiumScreenshotImageLoader {
    static func image(named assetName: String) -> Image? {
#if os(iOS)
        guard let image = UIImage(named: assetName) else { return nil }
        return Image(uiImage: image)
#else
        guard let image = NSImage(named: NSImage.Name(assetName)) else { return nil }
        return Image(nsImage: image)
#endif
    }
}

private struct PremiumScreenshotPlaceholder: View {
    let feature: PremiumFeaturePresentation
    let position: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .white.opacity(0.20),
                    .cyan.opacity(0.20),
                    .purple.opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { dot in
                        Circle()
                            .fill(dot == 0 ? .pink.opacity(0.75) : .white.opacity(0.38))
                            .frame(width: 7, height: 7)
                    }
                    Spacer()
                }

                Spacer()

                Image(systemName: feature.iconName)
                    .font(.system(size: 42, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.92))

                Text(feature.title)
                    .font(.headline.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(PremiumFeatureLocalization.string("premium.preview.screenshot_placeholder", fallback: "Vista previa"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))

                Spacer()

                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { item in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(item == position % 3 ? 0.58 : 0.19))
                            .frame(height: 8)
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct PremiumCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview("Presentación premium") {
    NavigationStack {
        PremiumFeaturePreviewView(feature: .healingCenter)
    }
}
#endif
