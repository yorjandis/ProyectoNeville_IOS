//
//  FrasesWigget.swift
//  FrasesWigget
//
//  Created by Yorjandis Garcia on 21/11/23.
//

import WidgetKit
import SwiftUI

//Representa una entrada
struct SimpleEntry: TimelineEntry {
    let date: Date //Fecha en que se mostrará esta entrada
    let frase: String
}


//Datos
struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), frase: "Imaginar crea la realidad")
    }

    //Apariencia en el Cajón de widget
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), frase: "Imaginar crea la realidad")
       completion(entry)
    }

    //Devuelve las entradas que serán mostradas en el widget, desfazadas. La propiedad .atEnd hace que una vez
    //se alcance la última entrada, comience de nuevo:
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Genera una línea de tiempo (timeline) de cinco entradas, desfasadas en un minuto, Iniciando desde el minuto actual.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, frase: UtilFuncs.FileReadToArray("listfrases").randomElement() ?? "")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}





//Vista
struct FrasesWiggetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack{
                Text(entry.frase)
                    .fontDesign(.serif)
                    .italic()
                    .font(.system(size: 18))
               
        }

        
    }
}


//Manager
struct FrasesWigget: Widget {
    let kind: String = "FrasesWigget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FrasesWiggetEntryView(entry: entry)
                    .containerBackground(.fill, for: .widget)
            } else {
                FrasesWiggetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("La Ley")
        .description("Compendio de Frases")
    }
}









#Preview(as: .systemSmall) {
    FrasesWigget()
} timeline: {
    SimpleEntry(date: .now, frase: "Esto es solo uyn ejemplo de lo que podemos hacer en este momento tan")
    SimpleEntry(date: .now, frase: "🤩")
}
