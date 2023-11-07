//
//  TestView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 3/11/23.
//

import SwiftUI

struct TestView: View {
    
    private let iconos = ["feliz", "desanimado", "diatraido","enfadado"]
    
    @State private var icono : String = "feliz"

    var body: some View {
        NavigationStack{
            VStack() {
                VStack{
                    
                    Image("feliz")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    
                }
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 15)
                .padding(.top, 20)
                .offset(x:150)
                .onTapGesture {
                    
                }
                
                Spacer()
            }
            
        }
        
    }

    
}

#Preview {
    TestView()
}
