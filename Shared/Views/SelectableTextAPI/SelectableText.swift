import SwiftUI

/// Superficie de texto seleccionable compartida por iOS y macOS.
///
/// Los documentos extensos usan TextKit 2 y desplazamiento nativo. Los textos
/// pequeños usan `Text` con selección para no crear vistas de texto pesadas.
public struct SelectableText: View {
    private let text: String?
    private let attributedText: AttributedString?
    private let fontSize: CGFloat
    private let fontColor: Color
    private let backgroundColor: Color
    private let alignment: NSTextAlignment
    private let isScrollEnabled: Bool
    private let documentID: String

    public init(
        text: String,
        fontSize: CGFloat = 25,
        fontColor: Color,
        backgroundColor: Color = .clear,
        alignment: NSTextAlignment = .justified,
        isScrollEnabled: Bool = false,
        documentID: String = ""
    ) {
        self.text = text
        self.attributedText = nil
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        self.alignment = alignment
        self.isScrollEnabled = isScrollEnabled
        self.documentID = documentID
    }

    /// Compatibilidad con los puntos existentes que todavía entregan colores nativos.
    public init(
        text: String,
        fontSize: CGFloat = 25,
        fonColor: UIColor = .black,
        backgroundColor: UIColor = .clear,
        alignment: NSTextAlignment = .justified,
        isScrollEnabled: Bool = false,
        documentID: String = ""
    ) {
        self.init(
            text: text,
            fontSize: fontSize,
            fontColor: Color(fonColor),
            backgroundColor: Color(backgroundColor),
            alignment: alignment,
            isScrollEnabled: isScrollEnabled,
            documentID: documentID
        )
    }

    public init(
        _ text: String,
        fontSize: CGFloat = 25,
        fonColor: UIColor = .black,
        alignment: NSTextAlignment = .justified
    ) {
        self.init(text: text, fontSize: fontSize, fonColor: fonColor, alignment: alignment)
    }

    public init(
        _ attributedText: AttributedString,
        fontSize: CGFloat = 25,
        fonColor: UIColor = .black,
        alignment: NSTextAlignment = .left
    ) {
        self.text = nil
        self.attributedText = attributedText
        self.fontSize = fontSize
        self.fontColor = Color(fonColor)
        self.backgroundColor = .clear
        self.alignment = alignment
        self.isScrollEnabled = false
        self.documentID = ""
    }

    public init(_ attributedText: NSAttributedString) {
        self.text = nil
        self.attributedText = AttributedString(attributedText)
        self.fontSize = 25
        self.fontColor = .primary
        self.backgroundColor = .clear
        self.alignment = .left
        self.isScrollEnabled = false
        self.documentID = ""
    }

    public var body: some View {
        if isScrollEnabled, let text {
            SelectableTextRepresentable(
                text: text,
                documentID: documentID,
                fontSize: fontSize,
                fontColor: fontColor,
                backgroundColor: backgroundColor,
                alignment: alignment
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let attributedText {
            Text(attributedText)
                .textSelection(.enabled)
                .multilineTextAlignment(swiftUIAlignment)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
        } else {
            Text(text ?? "")
                .font(.system(size: fontSize))
                .foregroundStyle(fontColor)
                .multilineTextAlignment(swiftUIAlignment)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .background(backgroundColor)
        }
    }

    private var swiftUIAlignment: TextAlignment {
        switch alignment {
        case .center:
            .center
        case .right:
            .trailing
        default:
            .leading
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .center:
            .center
        case .right:
            .trailing
        default:
            .leading
        }
    }
}
