//
//  FrasesWiggetBundle.swift
//  FrasesWigget
//
//  Created by Yorjandis Garcia on 21/11/23.
//

import WidgetKit
import SwiftUI

@main
struct FrasesWiggetBundle: WidgetBundle {

    var body: some Widget {
        FrasesWigget()
        ConsciousDashboardWidget()

        if #available(iOSApplicationExtension 18.0, *) {
            NevilleLaunchControl<NewNoteControl>()
            NevilleLaunchControl<NewVoiceNoteControl>()
            NevilleLaunchControl<NewDiaryEntryControl>()
            NevilleLaunchControl<NewAgendaEntryControl>()
            NevilleLaunchControl<NewReminderControl>()
            NevilleLaunchControl<PresenceControl>()
            NevilleLaunchControl<MorningRitualControl>()
            NevilleLaunchControl<ClosingRitualControl>()
            NevilleLaunchControl<OpenDiaryControl>()
            NevilleLaunchControl<OpenAgendaControl>()
            NevilleLaunchControl<OpenNotesControl>()
            NevilleLaunchControl<OpenGoalsControl>()
            NevilleLaunchControl<OpenCalmSpaceControl>()
            NevilleLaunchControl<OpenCoherenceControl>()
            NevilleLaunchControl<OpenAuthorsControl>()
            NevilleLaunchControl<OpenAIChatControl>()
            NevilleLaunchControl<OpenHealingCenterControl>()
            NevilleLaunchControl<OpenConferencesControl>()
            NevilleLaunchControl<OpenWeeklyReviewControl>()
            NevilleLaunchControl<OpenLabelScannerControl>()
        }
    }
}
