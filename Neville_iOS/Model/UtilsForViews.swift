//
//  UtilsForViews.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 19/9/23.
//Objetivo: Agrupa modificadores personalizados y funciones que modifican la UIx
//

import SwiftUI

//Custom Modifier: crea un gradiente de 3 color: Observe que el último color es opcional, si es nil solo se utiliza los dos primeros.
struct mof_ColorGradient : ViewModifier {
    
    @Binding var colorInit : Color
    @Binding var colorEnd : Color
    
    func body(content : Content)->some View{content
        .background( LinearGradient(gradient: Gradient(colors: [colorInit, colorEnd]), startPoint: .top, endPoint: .bottom))
    }
}


//Custom Modifier: Para frases
struct mof_frases : ViewModifier{
    func body(content: Content) -> some View { content
        .multilineTextAlignment(.center)
        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).bold().italic()
        .padding(.horizontal, 5)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 5, y: 5)
        .shadow(color: Color.black.opacity(0.10), radius: 5, x: -5, y: -5)
       
    }
}

//Buttom Style
struct GradientButtonStyle: ViewModifier {
    
    var ancho : CGFloat = 100
    var colors : [Color] = [.red, .orange]
    
    func body(content: Content) -> some View { content
            .frame(width: ancho, height: 20)
            .foregroundColor(Color.white)
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom))
            .cornerRadius(15.0)
    }
}


