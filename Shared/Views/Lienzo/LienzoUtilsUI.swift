//
//  LienzoUtilsUI.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/11/25.
//

//Librerias visuales de apoyo a las funciones de Lienzo

import SwiftUI
import Combine
#if os(iOS)
import PhotosUI
#endif

//ViewModel que Almacena los colores de fondo actualmente
@MainActor
final class ColoresFondo : ObservableObject {
    @Published var coloresFondo: [Color] = []
    
    static var shared = ColoresFondo()
    
    private init(){}
}


//Renderiza una UI a imagen: png
@MainActor
func renderViewAsImage<V: View>(_ view: V) -> UIImage? {
    let renderer = ImageRenderer(content: view)

    #if os(iOS)
    // Opcional: asegura un tamaño concreto si es necesario
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
    #elseif os(macOS)
    // Opcional: define la escala manualmente (no hay UIScreen en macOS)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        return renderer.nsImage
    
    #endif
}


//Solo macOS: función que guarda la imagen en el
#if os(macOS)
import AppKit
import UniformTypeIdentifiers

//Guarda una imagen en la carpeta de Descargas en el Finder:
func guardarImagenEnDescargasConTimestamp(_ imagen: NSImage) {
    // Generar timestamp
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss" // Ej: 20251121_143955
    let timestamp = formatter.string(from: Date())

    let nombre = "imagen_\(timestamp).png"
    
    // Obtener carpeta Downloads
    guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
        print("❌ No se pudo obtener la carpeta Descargas.")
        return
    }

    let fileURL = downloadsURL.appendingPathComponent(nombre)

    // Convertir NSImage → PNG
    guard let tiffData = imagen.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("❌ No se pudo convertir la imagen.")
        return
    }

    do {
        try pngData.write(to: fileURL)
        print("✔ Imagen guardada en: \(fileURL.path)")
    } catch {
        print("❌ Error al guardar la imagen: \(error)")
    }
}

//Abre un cuadro de diálogo para seleccionar una imagen. Solo MacOS:
func seleccionarImagen() -> NSImage {
        let panel = NSOpenPanel()
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [
                .png,
                .jpeg,
                .heic,
                .tiff,
                .gif,
                .image
            ]
        } else {
            panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic", "tiff", "gif"]
        }
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
            return image
        }else{
           return  NSImage(named: "placeholder") ?? NSImage()
        }
    }
#endif



//Abre una imagen de la galeria. Solo iOS:
#if os(iOS)
@MainActor
class ImagePickerViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?

    // Función para cargar la imagen desde la galería
    func loadImage() {
        Task {
            guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data)
            else { return }
            
            self.selectedImage = uiImage
        }
    }
}
/*
 Ejemplo de uso:
 @StateObject private var viewModel = ImagePickerViewModel()
 // Mostrar imagen cargada
             if let image = viewModel.selectedImage {
                 Image(uiImage: image)
                     .resizable()
                     .scaledToFit()
                     .frame(height: 250)
             } else {
                 Text("No hay imagen seleccionada")
                     .foregroundColor(.gray)
             }
 // Botón que abre la galería
             PhotosPicker(
                 selection: $viewModel.selectedItem, //La imagen se toma del viewModel
                 matching: .images,
                 photoLibrary: .shared()
             ) {
                 Button("Cargar imagen de la galería") {
                     // Aquí simplemente se dispara el selector
                 }
                 .font(.headline)
             }
 */

#endif
