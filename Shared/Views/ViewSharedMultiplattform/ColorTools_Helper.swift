//
//  template.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 21/04/2026.
//

import SwiftUI

#if(DEBUG)
struct ColorTool_Helper : View {
    
    /*
     Color(red: 0.26, green: 0.51, blue: 0.76),
     Color(red: 0.46, green: 0.51, blue: 0.83)
     */
    
    @State private var colorA_1 : Double = 0.26
    @State private var colorA_2 : Double = 0.51
    @State private var colorA_3 : Double = 0.76
    
    @State private var colorB_1 : Double = 0.21
    @State private var colorB_2 : Double = 0.36
    @State private var colorB_3 : Double = 0.90
    
    @State private var colorC_1 : Double = 0.46
    @State private var colorC_2 : Double = 0.51
    @State private var colorC_3 : Double = 0.83
    
    @State private var isActive : Bool = true
    @State private var tercerColor : Bool = true
    
    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
    
    var body: some View {
        ZStack {
            if !self.tercerColor {
                LinearGradient(
                    colors: [
                        Color(red: self.colorA_1, green: self.colorA_2, blue: self.colorA_3),
                        Color(red: self.colorC_1, green: self.colorC_2, blue: self.colorC_3),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }else{
                LinearGradient(
                    colors: [
                        Color(red: self.colorA_1, green: self.colorA_2, blue: self.colorA_3),
                        Color(red: self.colorB_1, green: self.colorB_2, blue: self.colorB_3),
                        Color(red: self.colorC_1, green: self.colorC_2, blue: self.colorC_3),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            
            
            VStack{
                Spacer()
                if self.isActive{
                    Slider(value: self.$colorA_1, in: 0.0...1.0)
                    Slider(value: self.$colorA_2, in: 0.0...1.0)
                    Slider(value: self.$colorA_3, in: 0.0...1.0)
                    
                    Divider()
                    
                    if self.tercerColor{
                        Slider(value: self.$colorB_1, in: 0.0...1.0)
                        Slider(value: self.$colorB_2, in: 0.0...1.0)
                        Slider(value: self.$colorB_3, in: 0.0...1.0)
                        
                        Divider()
                    }
                    
                    Slider(value: self.$colorC_1, in: 0.0...1.0)
                    Slider(value: self.$colorC_2, in: 0.0...1.0)
                    Slider(value: self.$colorC_3, in: 0.0...1.0)
                }
                
                
                HStack{
                    Button(self.isActive ? "Hide" : "Show"){
                        self.isActive.toggle()
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("3r Color"){
                        self.tercerColor.toggle()
                    }
                    
                    Spacer()
                    
                    Button("Copy To Clipboard") {
                        let text = """
                        Color(red: \(format(colorA_1)), green: \(format(colorA_2)), blue: \(format(colorA_3))),
                        \(self.tercerColor ? "Color(red: \(format(colorB_1)), green: \(format(colorB_2)), blue: \(format(colorB_3)))," : "")
                        Color(red: \(format(colorC_1)), green: \(format(colorC_2)), blue: \(format(colorC_3)))
                        """
                        
                        UIPasteboard.general.string = text
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                
                
                
            }
            
        }
    }
}



#Preview {
    ColorTool_Helper()
}


#endif

