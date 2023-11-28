//
//  AppIntentWidget.swift
//  FrasesWiggetExtension
//
//  Created by Yorjandis Garcia on 24/11/23.
//

import AppIntents
import WidgetKit

struct TestAppIntent : AppIntent{
    
    static var title: LocalizedStringResource = "Actualiza frases"
    static var description: IntentDescription? = "Actualizar Frases"
    

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "FrasesWigget") //reload the widget! Available in Siri as "Actualiza frases"
        return .result()
    }

}
