//
//  SelectableTextRepresentable+AppKit.swift
//
//
//  Created by Kevin Hermawan on 14/02/24.
//

#if canImport(UIKit)
import UIKit
import SwiftUI

 struct SelectableTextRepresentable: UIViewRepresentable {
     var text: String? = nil
     var attributedText: NSAttributedString? = nil
     var fontSize : CGFloat
     var fontColor : UIColor = .black
     var alignment : NSTextAlignment
     var maxLayoutWidth: CGFloat = .zero
     @Binding var layoutHeight: CGFloat
     
     func makeUIView(context: Context) -> UITextView {
         let textView = BaseTextView()
         textView.isEditable = false
         textView.isSelectable = true
         textView.isScrollEnabled = false
         textView.backgroundColor = .clear
         textView.textColor = self.fontColor
         textView.font = UIFont.systemFont(ofSize: self.fontSize)
         textView.textContainerInset = .zero
         textView.textAlignment = self.alignment
         textView.textContainer.lineFragmentPadding = 0
         textView.adjustsFontForContentSizeCategory = true
         textView.maxLayoutWidth = self.maxLayoutWidth
         
         if let text {
             textView.text = text
             textView.textColor = self.fontColor
             textView.font = UIFont.systemFont(ofSize: self.fontSize)
             textView.textAlignment = self.alignment
         }
         
         if let attributedText {
             textView.attributedText = attributedText
         }
         
         return textView
     }
     
     func updateUIView(_ uiView: UITextView, context: Context) {
         if let baseView = uiView as? BaseTextView {
            baseView.maxLayoutWidth = self.maxLayoutWidth
        }

         if let text, uiView.text != text {
             uiView.text = text
         }

         if uiView.textColor != self.fontColor {
             uiView.textColor = self.fontColor
         }

         if uiView.font?.pointSize != self.fontSize {
             uiView.font = UIFont.systemFont(ofSize: self.fontSize)
         }

         if uiView.textAlignment != self.alignment {
             uiView.textAlignment = self.alignment
         }

         if let attributedText, uiView.attributedText != attributedText {
             uiView.attributedText = attributedText
         }

         let newHeight = uiView.intrinsicContentSize.height
         if abs(self.layoutHeight - newHeight) > 0.5 {
             DispatchQueue.main.async {
                 self.layoutHeight = newHeight
             }
         }
     }
 }




#endif
