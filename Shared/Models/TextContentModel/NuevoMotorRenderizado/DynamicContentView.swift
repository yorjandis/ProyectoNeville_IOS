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
     let fontColor: UIColor

     @State private var processedBlocks: [ContentBlock] = []
     
     var body: some View {
         ScrollView {
              //Si existe un solo bloque LazyVStack no lo muestra correctamwente.
              if self.processedBlocks.count == 1 {
                  VStack(alignment: .leading, spacing: 16){
                      ForEach(processedBlocks) { block in
                          BlockView(block: block, fontSize: self.fontSize, fontColor: self.fontColor)
                      }
                  }
                  .padding()
              }else{
                  LazyVStack(alignment: .leading, spacing: 16) {
                      ForEach(processedBlocks) { block in
                          BlockView(block: block, fontSize: self.fontSize, fontColor: self.fontColor)
                      }
                  }
                  .padding()
              }
         }
         .onAppear{
             self.processedBlocks = self.blocks.expandedTextBlocks()
         }
     }
 }




