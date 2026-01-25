//
//  SelectableText.swift
//
//
//  Created by Kevin Hermawan on 14/02/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

///  A view that displays one or more lines of read-only selectable text.
///
/// Initializing with plain text:
/// ```swift
/// SelectableText("This is some selectable text.")
/// ```
///
/// Initializing with `AttributedString`:
/// ```swift
/// let attributes: AttributeContainer = [
///     .foregroundColor: NSColor.systemPink,
///     .font: NSFont.preferredFont(forTextStyle: .body)
/// ]
///
/// let attributedString = AttributedString("This is some styled selectable text.", attributes: attributes)
/// SelectableText(attributedString)
/// ```
///
/// Initializing with `NSAttributedString`:
/// ```swift
/// let nsAttributes: [NSAttributedString.Key: Any] = [
///     .foregroundColor: NSColor.systemPink,
///     .font: NSFont.preferredFont(forTextStyle: .body)
/// ]
///
/// let nsAttributedString = NSAttributedString(string: "This is some styled selectable text.", attributes: nsAttributes)
/// SelectableText(nsAttributedString)
/// ```
public struct SelectableText: View {
    private var text: String? = nil
    private var fontSize: CGFloat = 50

    private var fontColor: UIColor = .black

    private var alignment: NSTextAlignment = .left
    private var attributedText: NSAttributedString? = nil
    @State private var layoutHeight: CGFloat = .zero
    
    /// Inicializa la vista con texto plano
    /// - Parameter text: The text to be displayed.
    public init(text: String, fontSize: CGFloat = 25,fonColor : UIColor = .black, alignment : NSTextAlignment = .justified) {
        self.text = text
        self.fontSize = fontSize
        self.fontColor = fonColor
        self.alignment = alignment
    }
    
    /// Inicializa la vista con un  `AttributedString`.
    /// - Parameter attributedText: The attributed text to be displayed.
    public init(
        _ attributedText: AttributedString,
        fontSize: CGFloat = 25,
        fonColor: UIColor = .black,
        alignment: NSTextAlignment = .left
    ) {
        // Convertimos a NSMutableAttributedString para poder modificar atributos
        let mutable = NSMutableAttributedString(attributedText)
        
        // Rango de todo el texto
        let rango = NSRange(location: 0, length: mutable.length)
        
        // Fuente
        mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: rango)
        
        // Color
        mutable.addAttribute(.foregroundColor, value: fonColor, range: rango)
        
        // Alineación
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: rango)
        
        self.attributedText = mutable
        self.fontSize = fontSize
        self.fontColor = fonColor
        self.alignment = alignment
    }
    
    /// Initializes the view with an `NSAttributedString`.
    /// - Parameter attributedText: The attributed text to be displayed.
    public init(_ attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }
    
    public var body: some View {
        
         GeometryReader { proxy in
             SelectableTextRepresentable(
                 text: text ?? "",
                 attributedText: attributedText,
                 fontSize: self.fontSize,
                 fontColor: self.fontColor,
                 alignment: self.alignment,
                 maxLayoutWidth: proxy.maxWidth,
                 layoutHeight: $layoutHeight
             )
         }
         .frame(height: layoutHeight)
  
    }
}


