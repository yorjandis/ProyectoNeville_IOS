//
//  LienzoUtilsUI.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/11/25.
//

//Librerias visuales de apoyo a las funciones de Lienzo

import SwiftUI
import Combine
import CoreGraphics
import UniformTypeIdentifiers
#if os(iOS)
import Photos
import PhotosUI
#endif



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

func seleccionarImagen() -> NSImage? {
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
           return  nil
        }
    }
#endif



//Abre una imagen de la galeria. Solo iOS:
#if os(iOS)
@MainActor
class ImagePickerViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    
    @Published var selectedItemImagenSecundaria: PhotosPickerItem?
    @Published var selectedImageImageSecundaria: UIImage?

    // Función para cargar la imagen desde la galería
    func loadImage() {
        Task {
            guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data)
            else { return }
            
            self.selectedImage = uiImage
        }
    }
    
    func loadImageSecundaria() {
        Task {
            guard let data = try? await selectedItemImagenSecundaria?.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data)
            else { return }
            
            self.selectedImageImageSecundaria = uiImage
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



#if os(iOS)
//Guarda una imagen en la galería: solo iOS:
func saveImageToGallery(_ image: UIImage) async throws {
    // 1. Solicitar permiso
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

    guard status == .authorized else {
        throw NSError(
            domain: "PhotoAccess",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Permiso denegado"]
        )
    }

    // 2. Guardar fuera del MainActor
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        DispatchQueue.global(qos: .userInitiated).async {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "PhotoAccess",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Error desconocido al guardar"]
                        )
                    )
                }
            }
        }
    }
}





//Exportar a URL temporal con extensión .png
func exportImageToTempURL(_ image: UIImage) -> URL? {
    //eliminando todo contenido previo en la carpeta temporal:
    //listarCarpetaTemporal()
    limpiarCarpetaTemporal()
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("MiImagen.png")
    if let data = image.pngData() {
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Error guardando imagen temporal: \(error)")
            return nil
        }
    }
    return nil
}

#endif

//Función útil: elimina el contenido de la carpeta de temporales
func limpiarCarpetaTemporal() {
    let tempDir = FileManager.default.temporaryDirectory
    do {
        let archivos = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        for archivo in archivos {
            try FileManager.default.removeItem(at: archivo)
        }
        print("Carpeta temporal vaciada correctamente")
    } catch {
        print("Error al limpiar la carpeta temporal: \(error)")
    }
}

//Función útil: Listar los archivos en la carpeta temporal:
func listarCarpetaTemporal() {
    let tempDir = FileManager.default.temporaryDirectory
    do {
        let archivos = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        if archivos.isEmpty {
            print("La carpeta temporal está vacía.")
        } else {
            print("Contenido de la carpeta temporal:")
            for archivo in archivos {
                print("- \(archivo.lastPathComponent)")
            }
        }
    } catch {
        print("Error al listar la carpeta temporal: \(error)")
    }
}





//Funciones de compartir la imagen generada: macOS
#if os(macOS)
func shareImage(_ image: NSImage) {
    let picker = NSSharingServicePicker(items: [image])
    
    if let window = NSApplication.shared.windows.first,
       let view = window.contentView {
        picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
}


// Exportar a URL temporal con extensión .png
func exportImageToTempURL(_ image: NSImage) -> URL? {
    // Limpiar carpeta temporal:
    limpiarCarpetaTemporal()

    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("MiImagen.png")

    // Convertir NSImage a datos PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        print("No se pudo convertir NSImage a PNG")
        return nil
    }

    do {
        try pngData.write(to: fileURL, options: .atomic)
        return fileURL
    } catch {
        print("Error guardando imagen temporal: \(error)")
        return nil
    }
}

#endif



//Extensión de Color que permite calcular el nivel de oscuridad o de brillo de un fondo y devolver el "color blanco" si el fondo es oscuro o "color negro" si el fondo es claro.
//esto se utiliza en el botón de muestra de color en el tab fondo de la ventana del lienzo:
extension Color {
    /// Convierte el Color en componentes RGB entre 0 y 1
    func rgbComponents() -> (r: Double, g: Double, b: Double) {
            #if os(macOS)
            let ns = NSColor(self).usingColorSpace(.sRGB)
            guard let c = ns else {
                return (0, 0, 0)  // fallback seguro
            }
            
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            #else
            let ui = UIColor(self)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            #endif
            
            return (Double(r), Double(g), Double(b))
        }
    
    func averageColor(_ c1: Color, _ c2: Color) -> Color {
        let r = (c1.rgbComponents().r + c2.rgbComponents().r) / 2
        let g = (c1.rgbComponents().g + c2.rgbComponents().g) / 2
        let b = (c1.rgbComponents().b + c2.rgbComponents().b) / 2
        
        return Color(red: r, green: g, blue: b)
    }
    
    /// Calcula luminancia relativa para determinar si el color es oscuro o claro
    func luminance() -> Double {
        let rgb = self.rgbComponents()
        
        func adjust(_ value: Double) -> Double {
            return value <= 0.03928 ? value / 12.92 :
                    pow((value + 0.055) / 1.055, 2.4)
        }
        
        let r = adjust(rgb.r)
        let g = adjust(rgb.g)
        let b = adjust(rgb.b)
        
        return 0.2126*r + 0.7152*g + 0.0722*b
    }
    
    /// Para un Color:  Devuelve blanco si el color es oscuro, negro si es claro
    func adaptiveTextColor() -> Color {
        return self.luminance() < 0.5 ? .white : .black
    }
    
    /// Para dos colores (fondo degradado): Devuelve blanco si el color es oscuro, negro si es claro
    func adaptiveTextColorForGradient(_ color1: Color, _ color2: Color) -> Color {
        let avg = averageColor(color1, color2)
        return avg.luminance() < 0.5 ? .white : .black
    }
    
}
