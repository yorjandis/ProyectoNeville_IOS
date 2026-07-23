//
//  RelatedFileDetailView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/2/26.
//

import SwiftUI

struct RelatedFileDetailView: View {
    
    let fileName: String
    
    var body: some View {
        ScrollView {
            SelectableText(
                text: UtilFuncs.FileRead(fileName, omittingFirstLines: 0),
                fontSize: 18,
                fontColor: .primary,
                alignment: .left
            )
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(fileName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
