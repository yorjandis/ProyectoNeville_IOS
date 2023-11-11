//
//  GamePLay.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/11/23.
//

import SwiftUI

struct GamePLay: View {
    
    @State private var show = false
    @State private var trim : Double = 0
    @State private var percentage = 0
    
    @State private var opacidad : Double  = 1
    
    @State var tope = 50
    
    let tt = [("Yorjandis",true),("Carlito",false),("Juan", true),("Perez", false)]
    
    var body: some View {
        ZStack(alignment: .bottom){
            
            LinearGradient(colors: [.brown, .orange], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
            Text("Yorjandis")
                .offset(x: Double.random(in: 0...50),y: -CGFloat(percentage * 5) )
                .opacity(opacidad)
                .onTapGesture {
                    withAnimation {
                        opacidad = 0
                    }
                    
                }
     
                Circle()
                .trim(from: 0,to: trim)
                .stroke(Color.black.opacity(0.7), lineWidth: 40)
                .rotationEffect(.degrees(180))
                .padding(.bottom, -228)
                //.opacity(percentage > 100 + 2 ? 0 : 1)
            
            Text(percentage > tope ? "Completado!" : "\(percentage) %")
                .contentTransition(.numericText(value: Double(percentage)))
                .font(.system(size: percentage > 20 ? 50 : 40))
                .foregroundStyle(.black)
                .bold()
                //.opacity(percentage > 100 + 2 ? 0 : 1 )
                .onTapGesture {
                    Timer.scheduledTimer(withTimeInterval: 0.50, repeats: true) { timer in
                        withAnimation {  
                            if percentage <= tope {
                                percentage += 1
                                trim += (1/Double(tope)) / 2
                            }
                            
                            
                        }
                        
                    }
                }

        }

    }
}

#Preview {
    GamePLay()
}
