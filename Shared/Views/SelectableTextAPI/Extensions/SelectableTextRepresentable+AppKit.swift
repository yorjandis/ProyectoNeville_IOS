#if canImport(AppKit)
import AppKit
import SwiftUI

struct SelectableTextRepresentable: NSViewRepresentable {
    let text: String
    let documentID: String
    let fontSize: CGFloat
    let fontColor: Color
    let backgroundColor: Color
    let alignment: NSTextAlignment

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let contentStorage = NSTextContentStorage()
        let layoutManager = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.textContainer = textContainer

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 20, height: 22)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.drawsBackground = true
        textView.setAccessibilityLabel(String(localized: "Contenido del documento"))

        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        textView.frame = scrollView.contentView.bounds
        scrollView.documentView = textView

        context.coordinator.contentStorage = contentStorage
        context.coordinator.layoutManager = layoutManager
        context.coordinator.textView = textView
        applyAppearance(to: textView, scrollView: scrollView, coordinator: context.coordinator)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        applyAppearance(to: textView, scrollView: scrollView, coordinator: context.coordinator)

        guard context.coordinator.documentID != documentID else { return }
        context.coordinator.documentID = documentID
        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func applyAppearance(
        to textView: NSTextView,
        scrollView: NSScrollView,
        coordinator: Coordinator
    ) {
        if coordinator.fontSize != fontSize {
            coordinator.fontSize = fontSize
            textView.font = .systemFont(ofSize: fontSize)
        }

        if coordinator.fontColor != fontColor {
            coordinator.fontColor = fontColor
            let nativeColor = NSColor(fontColor)
            textView.textColor = nativeColor
            textView.insertionPointColor = nativeColor
        }

        if coordinator.backgroundColor != backgroundColor {
            coordinator.backgroundColor = backgroundColor
            let nativeColor = NSColor(backgroundColor)
            textView.backgroundColor = nativeColor
            scrollView.backgroundColor = nativeColor
        }

        if coordinator.alignment != alignment {
            coordinator.alignment = alignment
            textView.alignment = alignment
        }
    }

    final class Coordinator {
        var documentID: String?
        var fontSize: CGFloat?
        var fontColor: Color?
        var backgroundColor: Color?
        var alignment: NSTextAlignment?
        var contentStorage: NSTextContentStorage?
        var layoutManager: NSTextLayoutManager?
        weak var textView: NSTextView?
    }
}
#endif
