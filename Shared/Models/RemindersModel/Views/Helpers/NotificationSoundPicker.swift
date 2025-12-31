//
//  NotificationSoundPicker.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 27/12/25.
//

//Permite selecciona un tono y reproducirlo en preview

import SwiftUI

struct NotificationSoundPicker: View {

    @Binding var selection: NotificationSound

    var body: some View {
            Picker("Sonido", selection: $selection) {
                ForEach(NotificationSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
            .padding(.horizontal)
    }
}
