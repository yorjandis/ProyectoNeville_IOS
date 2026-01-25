//
//  PlatFormShareView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//

import SwiftUI

/*
 extension View {
     func SelectableTextShareView(getContent : String ,fontSizeContenido : CGFloat, textContentdColor : UIColor) -> some View {
 #if os(macOS)
 Text(getContent)
     .font(.system(size: CGFloat(fontSizeContenido)) )
     .foregroundStyle(Color(textContentdColor))
     .textSelection(.enabled)
     .padding(.horizontal, 5)
     
 #else
 SelectableText(getContent, fontSize: CGFloat(fontSizeContenido), fonColor: textContentdColor , alignment: .left)
     .padding(.horizontal, 5)
 #endif
     }
 }

 */

extension View {
    func SelectableTextShareView(getContent: String, fontSizeContenido: CGFloat, textContentdColor: UIColor ) -> some View {
        
#if os(macOS)
        return Text(getContent)
            .font(.system(size: fontSizeContenido))
            .foregroundStyle(Color(textContentdColor))
            .textSelection(.enabled)
            .padding(.horizontal, 5)
        
#else
    
        return SelectableText( text : getContent, fontSize:fontSizeContenido,fonColor: textContentdColor, alignment: .left)
            .padding(.horizontal, 5)
       
#endif
    }
}



