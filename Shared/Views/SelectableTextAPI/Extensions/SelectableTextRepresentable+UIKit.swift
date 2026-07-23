#if canImport(UIKit)
import SwiftUI
import UIKit

struct SelectableTextRepresentable: UIViewRepresentable {
    let text: String
    let documentID: String
    let fontSize: CGFloat
    let fontColor: Color
    let backgroundColor: Color
    let alignment: NSTextAlignment

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(usingTextLayoutManager: true)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        // La búsqueda del sistema instala trabajo adicional sobre el documento.
        // El lector solo necesita selección y copia, así que se mantiene apagada.
        textView.isFindInteractionEnabled = false
        textView.alwaysBounceVertical = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.contentInsetAdjustmentBehavior = .never
        textView.automaticallyAdjustsScrollIndicatorInsets = false
        textView.dataDetectorTypes = []
        textView.adjustsFontForContentSizeCategory = false
        textView.textContainerInset = UIEdgeInsets(top: 22, left: 20, bottom: 36, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.heightTracksTextView = false
        textView.isOpaque = true
        textView.decelerationRate = .normal
        textView.delaysContentTouches = false
        textView.canCancelContentTouches = true
        textView.isDirectionalLockEnabled = true
        textView.keyboardDismissMode = .interactive
        textView.accessibilityLabel = String(localized: "Contenido del documento")

        applyAppearance(to: textView, coordinator: context.coordinator)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        applyAppearance(to: textView, coordinator: context.coordinator)

        guard context.coordinator.documentID != documentID else { return }
        context.coordinator.documentID = documentID
        textView.text = text
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.setContentOffset(
            CGPoint(x: 0, y: -textView.adjustedContentInset.top),
            animated: false
        )
    }

    private func applyAppearance(to textView: UITextView, coordinator: Coordinator) {
        if coordinator.fontSize != fontSize {
            coordinator.fontSize = fontSize
            textView.font = .systemFont(ofSize: fontSize)
        }

        if coordinator.fontColor != fontColor {
            coordinator.fontColor = fontColor
            let nativeColor = UIColor(fontColor)
            textView.textColor = nativeColor
            textView.tintColor = nativeColor
        }

        if coordinator.backgroundColor != backgroundColor {
            coordinator.backgroundColor = backgroundColor
            textView.backgroundColor = UIColor(backgroundColor)
        }

        if coordinator.alignment != alignment {
            coordinator.alignment = alignment
            textView.textAlignment = alignment
        }
    }

    final class Coordinator {
        var documentID: String?
        var fontSize: CGFloat?
        var fontColor: Color?
        var backgroundColor: Color?
        var alignment: NSTextAlignment?
    }
}
#endif
