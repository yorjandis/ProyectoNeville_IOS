//
//  WatchComplicationLaLey.swift
//  WatchComplicationLaLey
//
//  Created by Yorjandis Garcia on 15/2/24.
//

import WidgetKit
import SwiftUI

//representa los datos
struct SimpleEntry: TimelineEntry {
    let date: Date
    let image : String
}

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), image: "🥰")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), image: "🥰")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        //for hourOffset in 0 ..< 5 {
          //  let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
          //  let entry = SimpleEntry(date: entryDate,image: "🥰")
          //  entries.append(entry)
       // }
        entries.append(SimpleEntry(date: currentDate, image: ""))

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}



struct WatchComplicationLaLeyEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack{
        //La imagen que aparecerá en en la esfera del reloj
            //Las dimensiones deben ser: 1x:38x38, 2x:60x60, 3x:90X90
            //Aquí icon es una imagen tomada de Assets
            Image("icon")
                .resizable()
                .scaledToFit() // Mejor mantener proporción
                .frame(width: 38, height: 38)
                .foregroundColor(.primary) // Permitir tintado
        }
    }
}

@main
struct WatchComplicationLaLey: Widget {
    let kind: String = "WatchComplicationLaLey"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(watchOS 10.0, *) {
                WatchComplicationLaLeyEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WatchComplicationLaLeyEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("La Ley")
        .description("Watch Complication")
    }
}


