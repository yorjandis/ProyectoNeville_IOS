//
//  HelperView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/2/26.
//

import SwiftUI


//Modificador personalizado: Aplicar glass effect a una View en dependencia si estamos en iOS 26+ / iOS 18-
#if os(iOS)
extension View {
    @ViewBuilder
    func applyGlassEffect() -> some View {
        if #available(iOS 26, *){
            self.glassEffect()
        }else{
            self.background(.ultraThinMaterial)
        }
    }
}
#endif
