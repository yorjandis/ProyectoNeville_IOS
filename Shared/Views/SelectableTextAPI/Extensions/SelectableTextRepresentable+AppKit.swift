//
//  SelectableTextRepresentable+AppKit.swift
//
//
//  Created by Kevin Hermawan on 14/02/24.
//

#if canImport(AppKit)
import AppKit
import SwiftUI

 struct SelectableTextRepresentable: NSViewRepresentable {
     var text: String? = nil
     var attributedText: NSAttributedString? = nil
     var fontSize : CGFloat
     var fontColor : UIColor = .black
     var alignment : NSTextAlignment
     var maxLayoutWidth: CGFloat = .zero
     
     @Binding var layoutHeight: CGFloat
     
     func makeNSView(context: Context) -> NSTextView {
         let textView = BaseTextView()
         textView.isEditable = false
         textView.isSelectable = true
         textView.backgroundColor = .clear
         textView.textContainerInset = .zero
         textView.textContainer?.lineFragmentPadding = 0
         textView.maxLayoutWidth = self.maxLayoutWidth
         
         // Configurar la fuente y color
         textView.font = NSFont.systemFont(ofSize: self.fontSize)
         textView.textColor = self.fontColor
         
         // Configurar alineación mediante paragraph style
         let paragraphStyle = NSMutableParagraphStyle()
         paragraphStyle.alignment = self.alignment

         // Aplicar el estilo al texto plano
         textView.typingAttributes = [
             .paragraphStyle: paragraphStyle,
             .font: NSFont.systemFont(ofSize: self.fontSize),
             .foregroundColor: self.fontColor
         ]

         if let text {
             textView.string = text
         }

         return textView
     }
     
     func updateNSView(_ nsView: NSTextView, context: Context) {
         if let text {
             nsView.string = text
         }
         
         if let attributedText {
             nsView.isRichText = true
             nsView.textStorage?.setAttributedString(attributedText)
         }
         
         DispatchQueue.main.async {
             self.layoutHeight = nsView.intrinsicContentSize.height
         }
     }
 }




#endif
