import SwiftUI

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

/*
 Tutorial rápido: agregar nuevos videos en "Videos Tutoriales"

 1) Busca el ID del video en YouTube:
    Ejemplo: https://www.youtube.com/watch?v=ABC123XYZ
    ID = ABC123XYZ

 2) En `TutorialVideosListView`, dentro de `videos`, añade una línea:
    TutorialVideo(
        videoId: "ABC123XYZ",
        title: "Título del video",
        description: "Descripción breve del contenido."
    )

 3) No hace falta añadir URL manual:
    - `thumbnailURL` se genera automáticamente desde `videoId`.
    - `videoURL` se genera automáticamente desde `videoId`.
*/
struct TutorialVideosListView: View {
    // Para agregar un nuevo video, añade un nuevo TutorialVideo(videoId:title:description:) en esta lista.
    private let videos: [TutorialVideo] = [
        TutorialVideo(videoId: "Qtv7R46NK4Y", title: "Lienzo", description: "Lienzo es una forma creativa de compartir las enseñanzas de los grandes maestros."),
        TutorialVideo(videoId: "7Lkv71cVlbA", title: "Metas", description: "Metas es un poderosa heramienta para crear buenos hábitos y reprogramar el cerebro."),
        TutorialVideo(videoId: "zoNihDZeh8k", title: "Ritual Matutino", description: "Diseñe su día y establezca una intención clara y definida para afrontar cada situación que se le presente. Elige reaccionar concientemente y dejar de ser un efecto de su entorno."),
        TutorialVideo(videoId: "aywaTrF7J74", title: "Lector de Etiquetas", description: "El Lector de Etiqueta es una herramienta útil para inspeccionaer la calidad de  un alimento. Permite determinar su grado procesamiento, las concentraciones de sus macrinutrientes y su origen natural."),
        TutorialVideo(videoId: "xKc-cRC94Xo", title: "Espacio Calma", description: "Espacio Calma es una experiencia inmersiva que ayuda a relajar el cuerpo, calmar la mente y restaurar el equilibrio emocional."),
        TutorialVideo(videoId: "ozQlIio6E_I", title: "Coherencia Cardio Cerebral", description: "La coherencia Cardio cerebral es una técnica que unifica el ritmo del corazón  con el estado de las ondas cerebrales. En este estado mental, se abre la puerta a la restauración de la línea base en el cerebro y comienza el estado de curación holística.")
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(self.videos) { video in
                    Link(destination: video.videoURL ?? URL(string: "https://www.youtube.com")!) {
                        TutorialVideoCardView(video: video)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(LinearGradient.AzulTecnologico())
        .navigationTitle("Videos Tutoriales")
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
