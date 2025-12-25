//
//  VerticalSliderHoursMinutes.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

import SwiftUI

import SwiftUI


struct Time {
    var hour: Int
    var minute: Int
}

struct TimePickerWheel: View {
    
    @Binding var time: Time
    
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    
    var body: some View {
        HStack(spacing: 0) {
            
            // Picker de horas
            VStack{
                Text("Hora")
                Picker("Horas", selection: $time.hour) {
                    ForEach(hours, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .tag(hour)
                    }
                }
                #if os(iOS)
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
                    #elseif os(macOS)
                .pickerStyle(.menu) // o .popUpButton()
                .frame(width: 80)
                #endif
                Spacer()
            }
            
            
            Text(":")
                .font(.title)
                .padding(.horizontal, 4)
                .offset(y:15)
            
            // Picker de minutos
            VStack{
                Text("Minutos")
                Picker("Minutos", selection: $time.minute) {
                    ForEach(minutes, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                #if os(iOS)
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
                #elseif os(macOS)
                .pickerStyle(.menu) // o .popUpButton()
                .frame(width: 80)
                #endif
                Spacer()
            }
            
        }
        .frame(height: 125)
    }
}
