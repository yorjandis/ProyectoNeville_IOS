//
//  PlatFormShareView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//

import SwiftUI

extension View {
    func SelectableTextShareView(getContent: String, fontSizeContenido: CGFloat, textContentdColor: UIColor ) -> some View {
        SelectableText(
            text: getContent,
            fontSize: fontSizeContenido,
            fonColor: textContentdColor,
            alignment: .left
        )
            .padding(.horizontal, 5)
    }
}

