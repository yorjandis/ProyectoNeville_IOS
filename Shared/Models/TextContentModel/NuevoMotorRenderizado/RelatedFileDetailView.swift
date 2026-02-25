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
            Text( UtilFuncs.FileRead(fileName, omittingFirstLines: 0))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(fileName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
