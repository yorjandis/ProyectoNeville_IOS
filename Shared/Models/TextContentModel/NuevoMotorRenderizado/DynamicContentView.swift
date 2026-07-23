//
//  TxtContentShow_nuevo.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/2/26.
//

import SwiftUI


 struct DynamicContentView: View {
     
     let blocks: [ContentBlock]
     let fontSize: CGFloat
     let fontColor: Color
     let backgroundColor: Color
     let documentID: String

     private let continuousText: String?
     private let processedBlocks: [ContentBlock]
     
     init(
        blocks: [ContentBlock],
        fontSize: CGFloat,
        fontColor: Color,
        backgroundColor: Color,
        documentID: String
     ) {
         self.blocks = blocks
         self.fontSize = fontSize
         self.fontColor = fontColor
         self.backgroundColor = backgroundColor
         self.documentID = documentID

         if blocks.count == 1, case .text(let text) = blocks[0].content {
             self.continuousText = text
             self.processedBlocks = []
         } else {
             self.continuousText = nil
             self.processedBlocks = blocks.expandedTextBlocks()
         }
     }
     
     var body: some View {
         if let continuousText {
             continuousTextView(continuousText)
         } else {
             blocksScrollView
         }
     }

     @ViewBuilder
     private func continuousTextView(_ text: String) -> some View {
         SelectableText(
             text: text,
             fontSize: self.fontSize,
             fontColor: self.fontColor,
             backgroundColor: self.backgroundColor,
             alignment: .left,
             isScrollEnabled: true,
             documentID: self.documentID
         )
     }

     private var blocksScrollView: some View {
         ScrollView {
             LazyVStack(alignment: .leading, spacing: 16) {
                 ForEach(self.processedBlocks) { block in
                     BlockView(
                        block: block,
                        fontSize: self.fontSize,
                        fontColor: UIColor(self.fontColor)
                     )
                 }
             }
             .padding()
         }
     }
 }


