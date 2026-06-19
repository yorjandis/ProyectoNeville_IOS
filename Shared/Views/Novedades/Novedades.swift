//
//  Novedades.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/12/25.
//

import SwiftUI

//Ventana de Novedades de la App
struct Novedades: View {
    
    @Environment(\.dismiss) var dismiss
    
    private struct NewsItem: Identifiable {
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
    
    private static let news: [NewsItem] = [
        NewsItem(iconName: "paintpalette", title: "Lienzo", description: "Una forma creativa de diseñar tus propios fondos con imágenes, colores y texto. Ideal para compartir frases y pensamientos en redes sociales y con amigos."),
        NewsItem(iconName: "person.3", title: "Nuevos autores", description: "Se han incorporado enseñanzas de Joe Dispenza, Bruce Lipton y Gregg Braden. Sus aportes apoyan las enseñanzas de Neville y empoderan una vida más saludable y en armonía."),
        NewsItem(iconName: "book.closed", title: "Enciclopedia de conocimientos", description: "Nuevo espacio de aprendizaje y conocimiento relacionado con las enseñanzas."),
        NewsItem(iconName: "checkmark.seal", title: "Evidencia científica", description: "Resumen acotado y en crecimiento sobre investigaciones y estudios científicos que apoyan estas enseñanzas."),
        NewsItem(iconName: "bell.badge", title: "Recordatorios", description: "Programa avisos para no olvidarte de nada. También resultan útiles para sesiones de meditación, entrenamiento y otras prácticas."),
        NewsItem(iconName: "sun.max", title: "Ritual matutino", description: "Una forma de organizar intencionalmente tu día y mantener el foco en el presente."),
        NewsItem(iconName: "eye", title: "Presencia Consciente", description: "Registra pequeños momentos de despertar durante el día y vuelve al presente con un solo toque. Observa cuándo sales del piloto automático, reconoce tu estado de ánimo y refuerza la emoción del futuro que deseas vivir."),
        NewsItem(iconName: "leaf", title: "Espacio Calma", description: "Experiencia inmersiva para relajarte y desconectarte. Ayuda a disminuir el estrés y la ansiedad."),
        NewsItem(iconName: "barcode.viewfinder", title: "Lector de Etiquetas", description: "Ofrece información sobre alimentos y consejos de uso leyendo su código de barras."),
        NewsItem(iconName: "heart.circle", title: "Coherencia Cardio-Cerebral", description: "Asistente de guía para entrar en estado de coherencia entre corazón y cerebro."),
        NewsItem(iconName: "calendar", title: "Agenda", description: "Organiza tareas, eventos y compromisos en el tiempo para liberar memoria, priorizar lo importante y usar tu tiempo de manera más óptima e intencional."),
        NewsItem(iconName: "quote.bubble", title: "Mejoras en Frases", description: "Ahora es posible editar frases personales. También se añadieron opciones de compartir la frase y almacenarla en Notas desde el menú contextual."),
        NewsItem(iconName: "book.pages", title: "Diario desbloqueado", description: "Nueva opción en Ajustes para mantener el Diario desbloqueado después del acceso, evitando repetir la validación en cada entrada."),
        NewsItem(iconName: "lock.shield", title: "Privacidad actualizada", description: "Se modificaron las políticas de privacidad para explicar cómo se gestiona la privacidad en las nuevas funciones de Inteligencia Artificial."),
        NewsItem(iconName: "note.text", title: "Mejoras en Notas", description: "Ahora las notas se pueden filtrar por fecha de creación o modificación, y también exportar a PDF."),
        NewsItem(iconName: "clock.arrow.circlepath", title: "Conferencias recientes", description: "Nuevo acceso a las cinco conferencias vistas recientemente."),
        NewsItem(iconName: "pencil.and.scribble", title: "Mejoras en Reflexiones", description: "Ahora es posible editar las reflexiones."),
        NewsItem(iconName: "textformat.abc", title: "Menú de texto copiado", description: "Al copiar texto en conferencias, frases, notas o respuestas de IA aparecen acciones rápidas como copiar en Notas, enviar al Lienzo o abrir en ChatIA."),
        NewsItem(iconName: "qrcode", title: "QR Code mejorado", description: "El lector y generador QR ahora maneja el Formato de Importación de Notas para importar notas automáticamente."),
        NewsItem(iconName: "brain.head.profile", title: "IA más natural", description: "Se revisaron y afinaron los ajustes de la IA. Ahora responde de forma más natural y fluida, con una base de conocimiento enriquecida sobre Neville."),
        NewsItem(iconName: "person.crop.circle.badge.questionmark", title: "Rol de IA configurable", description: "Nueva opción en Ajustes para elegir tono Personal o Impersonal. En Personal, la IA actúa como si fuera Neville."),
        NewsItem(iconName: "textformat.size", title: "Corrección de tipografía", description: "Corregido: no se aplicaba el tamaño de letra a las listas de elementos. Ahora sí."),
        NewsItem(iconName: "envelope", title: "Email actualizado", description: "Se actualizó el email de Ajustes para enviar comentarios y sugerencias desde la app.")
    ]
    
    private static let shortcuts: [ShortcutItem] = [
        ShortcutItem(title: "Abrir el Diario", description: "Abre directamente la ventana del Diario.", commands: ["<Oye Siri> en la ley abre mi diario"], footer: nil),
        ShortcutItem(title: "Crear entrada del Diario", description: "Crea una entrada de diario sin abrir la aplicación, de manera silenciosa.", commands: ["<Oye Siri> en la la ley crea una entrada"], footer: "Siri te pedirá la contraseña, un título y un contenido para crear la entrada del Diario. Si la contraseña es confusa, conviene deletrearla de manera clara y pausada."),
        ShortcutItem(title: "Abrir las notas", description: "Abre la ventana de la lista de Notas en la aplicación.", commands: ["<Oye Siri> en la ley abre mis notas"], footer: nil),
        ShortcutItem(title: "Crear una nota", description: "Crea una nota de manera silenciosa, sin abrir la aplicación.", commands: ["<Oye Siri> en la ley crea una nota"], footer: "Siri te pedirá que dictes un título y la nota."),
        ShortcutItem(title: "Crear una frase", description: "Crea una frase personal de manera silenciosa, sin abrir la aplicación.", commands: ["<Oye Siri> en la ley crea una frase"], footer: "Siri pedirá que dictes la nueva frase."),
        ShortcutItem(title: "Crear una frase para Espacio Calma", description: "Crea una frase personal para mostrarse en Espacio Calma.", commands: ["<Oye Siri> en la ley crea una frase para calma"], footer: "Siri pedirá que dictes la nueva frase."),
        ShortcutItem(title: "Abrir una conferencia al azar", description: "Abre la aplicación y muestra una conferencia al azar.", commands: ["<Oye Siri> en la ley abre conferencia"], footer: nil)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerView
                    newsView
                    shortcutsView
                    footerText
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
                
            
            Text("Esta versión: \(AppCons.appVersion ?? ""), cuenta con las siguientes Novedades:")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(16)
        .background(Color.blue.opacity(1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }
    
    private var newsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(Self.news.enumerated()), id: \.element.id) { index, item in
                newsCard(
                    item,
                    backgroundColor: Self.cardColors[index % Self.cardColors.count],
                    titleFontDesign: Self.headerFontDesigns[index % Self.headerFontDesigns.count]
                )
            }
        }
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Atajos & Comandos de Siri", iconName: "mic")
            
            ForEach(Self.shortcuts) { shortcut in
                shortcutCard(shortcut)
            }
        }
    }
    
    private func sectionTitle(_ title: String, iconName: String) -> some View {
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
    
    private func newsCard(
        _ item: NewsItem,
        backgroundColor: Color,
        titleFontDesign: Font.Design
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Image(systemName: item.iconName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.34))
                    .frame(width: 24)
                
                Text(item.title)
                    .font(.system(size: 19, weight: .bold, design: titleFontDesign))
                    .foregroundStyle(Color(red: 0.04, green: 0.23, blue: 0.22))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
            
            Text(item.description)
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
    
    private var footerText: some View {
        Text("Estas Novedades estarán en Ajustes, en el área de información.")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
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

#Preview("Novedades") {
    Novedades()
}
