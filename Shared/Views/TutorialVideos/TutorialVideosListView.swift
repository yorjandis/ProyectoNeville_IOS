import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

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
        TutorialVideo(videoId: "Qtv7R46NK4Y", title: "Lienzo", description: "Lienzo es una forma creativa de compartir las enseñanzas de los grandes maestros."),
        TutorialVideo(videoId: "7Lkv71cVlbA", title: "Metas", description: "Metas es un poderosa heramienta para crear buenos hábitos y reprogramar el cerebro."),
        TutorialVideo(videoId: "zoNihDZeh8k", title: "Ritual Matutino", description: "Diseñe su día y establezca una intención clara y definida para afrontar cada situación que se le presente. Elige reaccionar concientemente y dejar de ser un efecto de su entorno."),
        TutorialVideo(videoId: "aywaTrF7J74", title: "Lector de Etiquetas", description: "El Lector de Etiqueta es una herramienta útil para inspeccionaer la calidad de  un alimento. Permite determinar su grado procesamiento, las concentraciones de sus macrinutrientes y su origen natural."),
        TutorialVideo(videoId: "xKc-cRC94Xo", title: "Espacio Calma", description: "Espacio Calma es una experiencia inmersiva que ayuda a relajar el cuerpo, calmar la mente y restaurar el equilibrio emocional."),
        TutorialVideo(videoId: "ozQlIio6E_I", title: "Coherencia Cardio Cerebral", description: "La coherencia Cardio cerebral es una técnica que unifica el ritmo del corazón  con el estado de las ondas cerebrales. En este estado mental, se abre la puerta a la restauración de la línea base en el cerebro y comienza el estado de curación holística.")
    ]

    private let imageGuides: [TutorialImageGuide] = [
        TutorialImageGuide(
            title: "Comandos de Voz",
            description: "Guía visual rápida para usar comandos de voz dentro de la app.",
            coverImageName: "tuto_running.png",
            steps: [
                TutorialImageStep(stepTitle: "Oye Siri, en La Ley crea una Nota", imageName: "tuto_running.png", caption: "Siri pedirá un título y un contenido para crear la Nota"),
                TutorialImageStep(stepTitle: "Oye Siri, en La Ley crea una Nota", imageName: "tuto_ciclismo.png", caption: "Siri pedirá un título y un contenido para crear la Nota"),
                TutorialImageStep(stepTitle: "Oye Siri, en La Ley crea una entrada", imageName: "tuto_crear_entrada.png", caption: "Siri pedirá un título y un contenido para crear la entrada en el Diario"),
                TutorialImageStep(stepTitle: "Oye Siri, en La Ley crea una frase para Calma", imageName: "tuto_crearFraseEspacioCalma.png", caption: "Siri pedirá un título y un contenido para crear la frase personal para Espacio Calma"),
                TutorialImageStep(stepTitle: "Oye Siri, en La Ley crea entrada en Agenda", imageName: "tuto_crearAgenda.png", caption: "Siri pedirá un título, un contenido y un horario para crear la entrada en la Agenda"),
                TutorialImageStep(stepTitle: "Oye Siri, en La Ley crea una frase", imageName: "tuto_crearFrase.png", caption: "Siri pedirá el texto de la frase"),
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
        .navigationTitle("Videos Tutoriales")
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
