//
//  helperFont.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/2/26.
//


import SwiftUI

//Aplicar un tamaño de fuente según la plataforma: iOS / macOS
extension Font {
    static func platFormSize(iOS : CGFloat = 20, mac : CGFloat = 22, weight : Font.Weight = .regular) -> Font{
        #if os(macOS)
        return .system(size: mac, weight: weight)
        #else
        return .system(size: iOS, weight: weight)
        #endif
    }
}


