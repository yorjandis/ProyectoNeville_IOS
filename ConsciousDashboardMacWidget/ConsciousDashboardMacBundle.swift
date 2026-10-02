import SwiftUI
import WidgetKit

@main
struct ConsciousDashboardMacBundle: WidgetBundle {
    var body: some Widget {
        ConsciousDashboardWidget()

        if #available(macOSApplicationExtension 26.0, *) {
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
