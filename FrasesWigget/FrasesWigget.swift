//
//  FrasesWigget.swift
//  FrasesWigget
//
//  Created by Yorjandis Garcia on 21/11/23.
//

import WidgetKit
import SwiftUI
import AppIntents
import CoreData

//Representa una entrada
struct Datos: TimelineEntry {
    let date: Date //Fecha en que se mostrará esta entrada
    let frase: String
}


//Datos
struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> Datos {
        Datos(date: Date(), frase: "Imaginar crea la realidad")
    }

    //Apariencia en el Cajón de widget
    func getSnapshot(in context: Context, completion: @escaping (Datos) -> ()) {
        let entry = Datos(date: Date(), frase: "Imaginar crea la realidad")
       completion(entry)
    }

    //Devuelve las entradas que serán mostradas en el widget, desfazadas. La propiedad .atEnd hace que una vez
    //se alcance la última entrada, comience de nuevo:
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        var entries: [Datos] = []

        // Genera una línea de tiempo (timeline) de cinco entradas, desfasadas en un minuto, Iniciando desde el minuto actual.
        let currentDate = Date()
        for hourOffset in 0 ..< 3 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
            let entry = Datos(date: entryDate, frase: UtilFuncs.FileReadToArray("listfrases").randomElement() ?? "")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        completion(timeline)
    }
    
 
    
}





//Vista: Se le pasa como parámetro el arreglo de entry generado por el provider
struct FrasesWiggetEntryView : View {
    var entry: Provider.Entry
    

    var body: some View {
        VStack{
            Spacer()
            Text(entry.frase)
                .fontDesign(.serif)
                .italic()
                .font(.system(size: 18))
                .id(entry.frase)
                .transition(.push(from: .bottom))
                .animation(.smooth(duration: 2), value: entry.frase)
            Spacer()
            HStack{
                Spacer()
                Button(intent: TestAppIntent()) {
                    Image(systemName:"arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.gray)
                }
                
            }
            
        }
        .foregroundColor(Color.white)

        

    }
}



//Manager
struct FrasesWigget: Widget {
    
    let kind: String = "FrasesWigget"

    var body: some WidgetConfiguration {
        
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                FrasesWiggetEntryView(entry: entry)
                    .containerBackground(Color(red: 0.03632194176, green: 0.06894936413, blue: 0.09002960473), for: .widget)

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





