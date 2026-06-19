//
//  Features.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 9/12/25.
//

import SwiftUI

//Ventana de Características de la App
struct Features: View {
    
    @Environment(\.dismiss) var dismiss
    
    private struct FeatureItem: Identifiable {
        let id = UUID()
        let iconName: String
        let title: String
        let description: String
    }
    
    private struct ShortcutItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let commands: [String]
        let footer: String?
    }
    
    private static let cardColors: [Color] = [
        Color(red: 0.88, green: 0.96, blue: 0.91),
        Color(red: 0.88, green: 0.94, blue: 0.98),
        Color(red: 0.91, green: 0.96, blue: 0.94),
        Color(red: 0.98, green: 0.93, blue: 0.84)
    ]
    
    private static let headerFontDesigns: [Font.Design] = [
        .rounded,
        .serif,
        .monospaced,
        .default
    ]
    
    private static let features: [FeatureItem] = [
        FeatureItem(iconName: "books.vertical", title: "Conferencias y libros", description: "Más de 470 conferencias y libros de toda la obra de Neville Goddard."),
        FeatureItem(iconName: "quote.bubble", title: "Compendio de frases", description: "439 frases incorporadas, extraídas textualmente de la obra de Neville. También puedes crear nuevas frases personales."),
        FeatureItem(iconName: "person.3", title: "Autores incorporados", description: "Enseñanzas de Joe Dispenza, Bruce Lipton y Gregg Braden para apoyar la obra de Neville y empoderarte hacia una vida más saludable y armónica."),
        FeatureItem(iconName: "book.closed", title: "Enciclopedia", description: "Un espacio de aprendizaje y nuevo conocimiento relacionado con las enseñanzas."),
        FeatureItem(iconName: "checkmark.seal", title: "Evidencia científica", description: "Resumen acotado y en crecimiento sobre investigaciones y estudios científicos que apoyan estas enseñanzas."),
        FeatureItem(iconName: "note.text", title: "Notas personales ilimitadas", description: "Crea notas con comandos de voz, comparte, exporta a QR, envía al lienzo y marca favoritas. Admiten funciones IA: interpretar, aplicación práctica y ChatIA."),
        FeatureItem(iconName: "book.pages", title: "Diario personal", description: "Registra experiencias y hechos de cada día para observar tus asunciones, deseos y vivencias con estas enseñanzas."),
        FeatureItem(iconName: "target", title: "Metas", description: "Crea objetivos y sigue su progreso con la información necesaria para lograrlos de manera óptima."),
        FeatureItem(iconName: "bell.badge", title: "Recordatorios", description: "Programa avisos para no olvidar nada. También resultan útiles para meditación, entrenamiento y otras prácticas."),
        FeatureItem(iconName: "sun.max", title: "Ritual matutino", description: "Una forma de organizar intencionalmente tu día y mantener el foco en el presente."),
        FeatureItem(iconName: "eye", title: "Presencia Consciente", description: "Registra pequeños momentos de despertar durante el día y vuelve al presente con un solo toque. Observa cuándo sales del piloto automático, reconoce tu estado de ánimo y refuerza la emoción del futuro que deseas vivir."),
        FeatureItem(iconName: "leaf", title: "Espacio Calma", description: "Experiencia inmersiva para relajarte y desconectarte. Ayuda a disminuir el estrés y la ansiedad."),
        FeatureItem(iconName: "barcode.viewfinder", title: "Lector de Etiquetas", description: "Ofrece información sobre alimentos y consejos de uso leyendo su código de barras."),
        FeatureItem(iconName: "heart.circle", title: "Coherencia Cardio-Cerebral", description: "Asistente de guía para entrar en estado de coherencia entre corazón y cerebro."),
        FeatureItem(iconName: "calendar", title: "Agenda", description: "Organiza tareas, eventos y compromisos en el tiempo para liberar memoria, priorizar lo importante y usar mejor tu tiempo."),
        FeatureItem(iconName: "gamecontroller", title: "Evaluación", description: "Juego de respuesta correcta o incorrecta para consolidar y repasar lo aprendido. Las preguntas pueden ser sutiles y desafiantes."),
        FeatureItem(iconName: "qrcode", title: "QR integrado", description: "Importa y exporta información como notas y frases con un formato propio para compartir con amigos y la comunidad."),
        FeatureItem(iconName: "brain.head.profile", title: "Inteligencia Artificial", description: "Interpretación, resumen, consejos prácticos y chat sobre las enseñanzas. Funciona localmente y responde dentro del contexto de Neville."),
        FeatureItem(iconName: "paintpalette", title: "Lienzo", description: "Diseña fondos con imágenes, colores y texto. Ideal para compartir frases y pensamientos en redes sociales y con amigos."),
        FeatureItem(iconName: "alarm", title: "Recordatorios", description: "Programa avisos para meditaciones, lectura, oración, gratitud, afirmaciones, lista de compras y tareas del día.")
    ]
    
    private static let shortcuts: [ShortcutItem] = [
        ShortcutItem(title: "Abrir el Diario", description: "Abre directamente la ventana del Diario.", commands: ["<Oye Siri> en la ley abre diario", "<Oye Siri> en la ley abre mi diario"], footer: nil),
        ShortcutItem(title: "Crear entrada del Diario", description: "Crea una entrada de diario sin abrir la aplicación, de manera silenciosa.", commands: ["<Oye Siri> en la la ley crea una entrada"], footer: "Siri te pedirá la contraseña, un título y un contenido para crear la entrada del Diario. Si la contraseña es confusa, conviene deletrearla de manera clara y pausada."),
        ShortcutItem(title: "Crear frase para Espacio Calma", description: "Crea una frase personal para Espacio Calma.", commands: ["<Oye Siri> en la la ley crea una frase para calma", "<Oye Siri> en la Ley crea una frase personal para calma"], footer: "Siri pedirá que le dictes el texto de la frase."),
        ShortcutItem(title: "Crear una actividad en la Agenda", description: "Crea una actividad en la Agenda.", commands: ["<Oye Siri> en la la ley crea una actividad en agenda", "<Oye Siri> en la Ley crea entrada en agenda"], footer: "Siri pedirá que le dictes un título, una fecha y un contenido."),
        ShortcutItem(title: "Abrir las notas", description: "Abre la ventana de la lista de Notas en la aplicación.", commands: ["<Oye Siri> en la ley abre mis notas"], footer: nil),
        ShortcutItem(title: "Crear una nota", description: "Crea una nota de manera silenciosa, sin abrir la aplicación.", commands: ["<Oye Siri> en la ley crea una nota"], footer: "Siri te pedirá que dictes un título y la nota."),
        ShortcutItem(title: "Crear una frase", description: "Crea una frase personal de manera silenciosa, sin abrir la aplicación.", commands: ["<Oye Siri> en la ley crea una frase"], footer: "Siri pedirá que dictes la nueva frase."),
        ShortcutItem(title: "Abrir una conferencia al azar", description: "Abre la aplicación y muestra una conferencia al azar.", commands: ["<Oye Siri> en la ley abre conferencia"], footer: nil)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerView
                    featuresView
                    shortcutsView
                    closeButton
                }
                .padding()
            }
            .padding(.horizontal, 10)
            #if os(macOS)
            .frame(width: 660, height: 400)
            #endif
        }
        .background {
            LinearGradient.AzulTecnologico()
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bienvenido a una nueva versión de La Ley")
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.white)
            
            Text("Esta versión: \(AppCons.appVersion ?? ""), cuenta con las siguientes Características:")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.blue.opacity(1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }
    
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(Self.features.enumerated()), id: \.element.id) { index, feature in
                featureCard(
                    feature,
                    backgroundColor: Self.cardColors[index % Self.cardColors.count],
                    titleFontDesign: Self.headerFontDesigns[index % Self.headerFontDesigns.count]
                )
            }
        }
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureSectionTitle("Atajos & Comandos de Siri", iconName: "mic")
            
            ForEach(Self.shortcuts) { shortcut in
                shortcutCard(shortcut)
            }
        }
    }
    
    private func featureSectionTitle(_ title: String, iconName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.title3)
                .bold()
                .fontDesign(.rounded)
        }
        .foregroundStyle(.white)
        .padding(.top, 4)
    }
    
    private func featureCard(
        _ feature: FeatureItem,
        backgroundColor: Color,
        titleFontDesign: Font.Design
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Image(systemName: feature.iconName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.34))
                    .frame(width: 24)
                
                Text(feature.title)
                    .font(.system(size: 19, weight: .bold, design: titleFontDesign))
                    .foregroundStyle(Color(red: 0.04, green: 0.23, blue: 0.22))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
            
            Text(feature.description)
                .font(.system(size: 17))
                .fontWeight(.semibold)
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(backgroundColor.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }
    
    private func shortcutCard(_ shortcut: ShortcutItem) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                
                Text(shortcut.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.04, green: 0.23, blue: 0.22))
            }
            
            Text(shortcut.description)
                .font(.system(size: 16))
                .fontWeight(.semibold)
                .foregroundStyle(.black.opacity(0.82))
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(shortcut.commands, id: \.self) { command in
                    Text(command)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .italic()
                        .foregroundStyle(.indigo)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            if let footer = shortcut.footer {
                Text(footer)
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                    .foregroundStyle(.black.opacity(0.76))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(red: 0.98, green: 0.96, blue: 0.89).opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }
    
    private var closeButton: some View {
        Button("Cerrar") {
            dismiss()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .foregroundStyle(.black)
        .buttonStyle(.bordered)
        .padding(.vertical, 10)
    }
}

#Preview("Features") {
    Features()
}
