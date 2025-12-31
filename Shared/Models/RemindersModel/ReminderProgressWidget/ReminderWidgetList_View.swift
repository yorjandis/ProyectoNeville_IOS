//
//  ReminderWidgetList_View.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//

import SwiftUI

struct ReminderWidgetList_View : View {
    
    @EnvironmentObject private var settingModel : SettingModel
    
    @StateObject private var modelRecordatorios: SelectedReminderModel = .shared
    
    
    
    var body: some View {
        VStack{
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(modelRecordatorios.selectedReminders) { reminder in
                        ReminderProgressWidget(
                           reminder: reminder,
                           subtitle: reminder.title
                        )
                        .foregroundStyle(settingModel.colorFondo_b.adaptiveTextColor()) //Adapta el color del texto al fondo donde esta.
                        .padding(5)
                        .frame(width: 130)
                    }
                }
            }
        }
        .padding(3)
    }
    
}


