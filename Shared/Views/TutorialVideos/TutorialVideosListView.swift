import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

private enum TutorialCopy {
    private static let translations: [String: (english: String, chinese: String)] = [
        "Videos Tutoriales": ("Tutorial Videos", "教程视频"),
        "Lienzo": ("Canvas", "画布"),
        "Lienzo es una forma creativa de compartir las enseñanzas de los grandes maestros.": ("Canvas is a creative way to share the teachings of the great masters.", "画布是一种分享伟大导师教诲的创意方式。"),
        "Metas": ("Goals", "目标"),
        "Metas es un poderosa heramienta para crear buenos hábitos y reprogramar el cerebro.": ("Goals is a powerful tool for building good habits and reprogramming the brain.", "目标是一种培养良好习惯并重新塑造大脑的强大工具。"),
        "Ritual Matutino": ("Morning Ritual", "晨间仪式"),
        "Diseñe su día y establezca una intención clara y definida para afrontar cada situación que se le presente. Elige reaccionar concientemente y dejar de ser un efecto de su entorno.": ("Design your day and set a clear intention for every situation you encounter. Choose how to respond consciously instead of being shaped by your surroundings.", "规划好一天，为将要面对的每种情况设定清晰明确的意图。选择有意识地回应，而不是被周围环境所左右。"),
        "Lector de Etiquetas": ("Label Scanner", "标签扫描器"),
        "El Lector de Etiquetas es una herramienta útil para inspeccionar la calidad de un alimento. Permite determinar su grado de procesamiento, la concentración de sus macronutrientes y su origen natural.": ("The Label Scanner is a useful tool for assessing food quality. It helps determine the degree of processing, macronutrient concentration, and natural origin.", "标签扫描器是一款用于评估食品质量的实用工具。它可以帮助判断食品的加工程度、宏量营养素含量以及天然来源。"),
        "Espacio Calma": ("Calm Space", "宁静空间"),
        "Espacio Calma es una experiencia inmersiva que ayuda a relajar el cuerpo, calmar la mente y restaurar el equilibrio emocional.": ("Calm Space is an immersive experience that helps relax the body, calm the mind, and restore emotional balance.", "宁静空间是一种沉浸式体验，帮助放松身体、平静心灵并恢复情绪平衡。"),
        "Coherencia Cardio Cerebral": ("Cardio-Cerebral Coherence", "心脑一致性"),
        "La coherencia Cardio cerebral es una técnica que unifica el ritmo del corazón  con el estado de las ondas cerebrales. En este estado mental, se abre la puerta a la restauración de la línea base en el cerebro y comienza el estado de curación holística.": ("Cardio-cerebral coherence is a technique that synchronizes the heart rhythm with the state of the brain waves. In this mental state, the brain's baseline can be restored and holistic healing can begin.", "心脑一致性是一种将心脏节律与脑电波状态协调起来的技术。在这种心理状态下，大脑的基线得以恢复，整体疗愈也由此开始。"),
        "Comandos de Voz": ("Voice Commands", "语音指令"),
        "Guía visual rápida para usar comandos de voz dentro de la app.": ("A quick visual guide to using voice commands in the app.", "在应用中使用语音指令的快速图文指南。"),
        "Oye Siri, en La Ley crea una Nota": ("Hey Siri, in La Ley create a Note", "嘿 Siri，在 La Ley 中创建一条笔记"),
        "Siri pedirá un título y un contenido para crear la Nota": ("Siri will ask for a title and content to create the Note.", "Siri 会要求输入标题和内容，以创建这条笔记。"),
        "Oye Siri, en La Ley crea una entrada": ("Hey Siri, in La Ley create an entry", "嘿 Siri，在 La Ley 中创建一条日记记录"),
        "Siri pedirá un título y un contenido para crear la entrada en el Diario": ("Siri will ask for a title and content to create the Journal entry.", "Siri 会要求输入标题和内容，以在日记中创建记录。"),
        "Oye Siri, en La Ley crea una frase para Calma": ("Hey Siri, in La Ley create a Calm Space affirmation", "嘿 Siri，在 La Ley 中为宁静空间创建一句肯定语"),
        "Siri pedirá un título y un contenido para crear la frase personal para Espacio Calma": ("Siri will ask for a title and content to create your personal affirmation for Calm Space.", "Siri 会要求输入标题和内容，以在宁静空间中创建个人肯定语。"),
        "Oye Siri, en La Ley crea entrada en Agenda": ("Hey Siri, in La Ley create a Calendar entry", "嘿 Siri，在 La Ley 中创建一条日程"),
        "Siri pedirá un título, un contenido y un horario para crear la entrada en la Agenda": ("Siri will ask for a title, content, and time to create the Calendar entry.", "Siri 会要求输入标题、内容和时间，以在日程中创建记录。"),
        "Oye Siri, en La Ley crea una frase": ("Hey Siri, in La Ley create an affirmation", "嘿 Siri，在 La Ley 中创建一句肯定语"),
        "Siri pedirá el texto de la frase": ("Siri will ask for the text of the affirmation.", "Siri 会要求输入肯定语的文本。")
    ]

    static func localized(_ spanish: String) -> String {
        guard let translation = translations[spanish] else { return spanish }
        switch AppLanguage.current {
        case .english: return translation.english
        case .simplifiedChinese: return translation.chinese
        case .spanish: return spanish
        }
    }
}

struct TutorialVideo: Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: URL?
    let videoURL: URL?

    init(videoId: String, title: String, description: String) {
        self.id = videoId
        self.title = title
        self.description = description
        self.thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg")
        self.videoURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")
    }
}

struct TutorialImageStep: Identifiable {
    let id = UUID()
    let stepTitle: String
    let imageName: String
    let caption: String
}

struct TutorialImageGuide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let coverImageName: String
    let steps: [TutorialImageStep]
}

private enum TutorialListItem: Identifiable {
    case video(TutorialVideo)
    case imageGuide(TutorialImageGuide)

    var id: String {
        switch self {
        case .video(let video):
            return "video-\(video.id)"
        case .imageGuide(let guide):
            return "guide-\(guide.id.uuidString)"
        }
    }
}

/*
 Tutorial rápido: agregar nuevos videos o guías en "Videos Tutoriales"

 1) Video de YouTube:
    TutorialVideo(
        videoId: "ABC123XYZ",
        title: "Título del video",
        description: "Descripción breve del contenido."
    )

 2) Guía por imágenes (assets dentro de "Images-Tutoriales"):
    TutorialImageGuide(
        title: "Título",
        description: "Descripción",
        coverImageName: "mi_portada.png",
        steps: [
            TutorialImageStep(imageName: "paso_1.png", caption: "Texto del paso 1"),
            TutorialImageStep(imageName: "paso_2.png", caption: "Texto del paso 2")
        ]
    )
*/
struct TutorialVideosListView: View {
    @State private var selectedGuide: TutorialImageGuide?

    private let videos: [TutorialVideo] = [
        TutorialVideo(videoId: "Qtv7R46NK4Y", title: TutorialCopy.localized("Lienzo"), description: TutorialCopy.localized("Lienzo es una forma creativa de compartir las enseñanzas de los grandes maestros.")),
        TutorialVideo(videoId: "7Lkv71cVlbA", title: TutorialCopy.localized("Metas"), description: TutorialCopy.localized("Metas es un poderosa heramienta para crear buenos hábitos y reprogramar el cerebro.")),
        TutorialVideo(videoId: "zoNihDZeh8k", title: TutorialCopy.localized("Ritual Matutino"), description: TutorialCopy.localized("Diseñe su día y establezca una intención clara y definida para afrontar cada situación que se le presente. Elige reaccionar concientemente y dejar de ser un efecto de su entorno.")),
        TutorialVideo(
            videoId: "aywaTrF7J74",
            title: TutorialCopy.localized("Lector de Etiquetas"),
            description: TutorialCopy.localized("El Lector de Etiquetas es una herramienta útil para inspeccionar la calidad de un alimento. Permite determinar su grado de procesamiento, la concentración de sus macronutrientes y su origen natural.")
        ),
        TutorialVideo(videoId: "xKc-cRC94Xo", title: TutorialCopy.localized("Espacio Calma"), description: TutorialCopy.localized("Espacio Calma es una experiencia inmersiva que ayuda a relajar el cuerpo, calmar la mente y restaurar el equilibrio emocional.")),
        TutorialVideo(
            videoId: "ozQlIio6E_I",
            title: TutorialCopy.localized("Coherencia Cardio Cerebral"),
            description: TutorialCopy.localized("La coherencia Cardio cerebral es una técnica que unifica el ritmo del corazón  con el estado de las ondas cerebrales. En este estado mental, se abre la puerta a la restauración de la línea base en el cerebro y comienza el estado de curación holística.")
        )
    ]

    private let imageGuides: [TutorialImageGuide] = [
        TutorialImageGuide(
            title: TutorialCopy.localized("Comandos de Voz"),
            description: TutorialCopy.localized("Guía visual rápida para usar comandos de voz dentro de la app."),
            coverImageName: "tuto_running.png",
            steps: [
                TutorialImageStep(stepTitle: TutorialCopy.localized("Oye Siri, en La Ley crea una Nota"), imageName: "tuto_running.png", caption: TutorialCopy.localized("Siri pedirá un título y un contenido para crear la Nota")),
                TutorialImageStep(stepTitle: TutorialCopy.localized("Oye Siri, en La Ley crea una Nota"), imageName: "tuto_ciclismo.png", caption: TutorialCopy.localized("Siri pedirá un título y un contenido para crear la Nota")),
                TutorialImageStep(stepTitle: TutorialCopy.localized("Oye Siri, en La Ley crea una entrada"), imageName: "tuto_crear_entrada.png", caption: TutorialCopy.localized("Siri pedirá un título y un contenido para crear la entrada en el Diario")),
                TutorialImageStep(stepTitle: TutorialCopy.localized("Oye Siri, en La Ley crea una frase para Calma"), imageName: "tuto_crearFraseEspacioCalma.png", caption: TutorialCopy.localized("Siri pedirá un título y un contenido para crear la frase personal para Espacio Calma")),
                TutorialImageStep(stepTitle: TutorialCopy.localized("Oye Siri, en La Ley crea entrada en Agenda"), imageName: "tuto_crearAgenda.png", caption: TutorialCopy.localized("Siri pedirá un título, un contenido y un horario para crear la entrada en la Agenda")),
                TutorialImageStep(stepTitle: TutorialCopy.localized("Oye Siri, en La Ley crea una frase"), imageName: "tuto_crearFrase.png", caption: TutorialCopy.localized("Siri pedirá el texto de la frase")),
            ]
        )
    ]

    private var items: [TutorialListItem] {
        let guideItems = self.imageGuides.map { TutorialListItem.imageGuide($0) }
        let videoItems = self.videos.map { TutorialListItem.video($0) }
        return guideItems + videoItems
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(self.items) { item in
                    switch item {
                    case .video(let video):
                        Link(destination: video.videoURL ?? URL(string: "https://www.youtube.com")!) {
                            TutorialVideoCardView(video: video)
                        }
                        .buttonStyle(.plain)

                    case .imageGuide(let guide):
                        Button {
                            selectedGuide = guide
                        } label: {
                            TutorialImageGuideCardView(guide: guide)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(LinearGradient.AzulTecnologico())
        .navigationTitle(TutorialCopy.localized("Videos Tutoriales"))
        .sheet(item: $selectedGuide) { guide in
            NavigationStack {
                TutorialImagesDetailView(guide: guide)
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

private struct TutorialVideoCardView: View {
    let video: TutorialVideo

    var body: some View {
        HStack(spacing: 0) {
            AsyncImage(url: self.video.thumbnailURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(width: 150, height: 112)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(self.video.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(self.video.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct TutorialImageGuideCardView: View {
    let guide: TutorialImageGuide

    var body: some View {
        HStack(spacing: 0) {
            TutorialLiteralImage(name: guide.coverImageName)
                .scaledToFill()
                .frame(width: 150, height: 112)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(guide.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(guide.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

}


private struct TutorialLiteralImage: View {
    let name: String

    var body: some View {
        if let image = loadImage() {
            image
                .resizable()
        } else {
            ZStack {
                Rectangle().fill(Color.white.opacity(0.08))
                Image(systemName: "photo")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private func loadImage() -> Image? {
#if os(iOS)
        if let path = Bundle.main.path(forResource: name, ofType: nil),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        return nil
#elseif os(macOS)
        if let path = Bundle.main.path(forResource: name, ofType: nil),
           let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        return nil
#else
        return nil
#endif
    }
}

private struct TutorialImagesDetailView: View {
    let guide: TutorialImageGuide

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 10) {
                        TutorialLiteralImage(name: step.imageName)
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )

                        Text(step.stepTitle)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(step.caption)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding()
        }
        .background(LinearGradient.AzulTecnologico())
        .navigationTitle(guide.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

}
