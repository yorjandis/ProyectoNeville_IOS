//
//  UtilsForViews.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 19/9/23.
//Objetivo: Agrupa modificadores personalizados y funciones que modifican la UIx
//

import SwiftUI


//Show messages only in debug mode: Print
func msg(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
    #endif
    /*
     examples:
     msg("Frases Repetidas:", dto.id, dto.texto)
     */
}

//Show messages (utilice Dump) only in debug mode: Dump
func dmsg<T>(_ value: T, name: String? = nil, maxDepth: Int = 5) {
    #if DEBUG
    Swift.dump(value, name: name, maxDepth: maxDepth)
    #endif
    /*
     examples:
     dmsg(structType, name: "DataDTO", maxDepth: 2)
     */
}

//use Log System:
enum LogLevel {
    case debug, info, warning, error
}
func log(_ level: LogLevel = .debug, _ message: String) {
    #if DEBUG
    switch level {
    case .debug:    print("🟢 DEBUG:", message)
    case .info:     print("🔵 INFO:", message)
    case .warning:  print("🟠 WARNING:", message)
    case .error:    print("🔴 ERROR:", message)
    }
    #endif
    /*
     Examples
     log(.debug, "Frase repetida: \(dto.id)")
     log(.warning, "Relación no encontrada: \(idRelacionada)")
     */
}





//Custom Modifier: Para frases
struct mof_frases : ViewModifier{
    func body(content: Content) -> some View { content
        .multilineTextAlignment(.center)
        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).bold().italic()
        .padding(.horizontal, 5)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 5, y: 5)
        .shadow(color: Color.black.opacity(0.10), radius: 5, x: -5, y: -5)
    }
}

//Buttom Style
struct GradientButtonStyle: ViewModifier {
    var alto : CGFloat = 20
    var ancho : CGFloat = 100
    var colors : [Color] = [.red, .orange]
    
    func body(content: Content) -> some View { content
            .frame(width: ancho, height: alto)
            .foregroundColor(Color.white)
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom))
            .cornerRadius(15.0)
    }
}


//Extensión de Bundle para obtener el nombre de la App
extension Bundle {
    ///  Obtiene el nombre de la App
    var displayName: String? {
            return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}






//Botón Personaizado Para menus
@ViewBuilder
func CreateMenuItemButton(text : String,sysImageStr : String, action : @MainActor @escaping ()->()) -> some View{
    
    Button{
        action()
    }label: {
        Label(text, systemImage: sysImageStr)
    }
    
    
}


//Muestra una vista de felicitación por el cumpleaños
@ViewBuilder
func MostrarCumpleaños() -> some View {
    
    let componentes = Calendar.current.dateComponents([.day, .month], from: Date())
    if (componentes.day == 19 && componentes.month == 2){
        VStack{
            Text("Feliz Cumpleaños Maestro Neville! 💖").font(.title).fontDesign(.serif)
                .frame(maxWidth: .infinity)
            Text("Gracias por tu Amor y Enseñanzas").font(.callout).fontDesign(.serif)
                .frame(maxWidth: .infinity)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)
        
    }
}

//Crea una rectángulo áureo con una image en el centro
@ViewBuilder
func GoldenLogoNeville() -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.yellow.opacity(0.2))
            .frame(width: 80, height: 80 / 1.618) // rectángulo áureo

        Image("Logo")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .shadow(radius: 2)
    }
}

//Determina si estamos en modo Debug y muestra un texto:
@ViewBuilder
func MostrarModoDebug() -> some View {
#if DEBUG
    Text("Debug Mode").padding(2)
#else
    EmptyView()
#endif
}

//Muestra un botón para actualizar la app si existe una nueva actualización:
#if os(iOS)
@MainActor
struct ViewIfNewUpdateAvailable : View {
    
    //Crea un espacio de almacenamiento fuera del ambito de la vista (del struct) pero asociado a la misma
    //Cuando cambia ese valor SwiftUI marca la vista para regenerar el body con el nuevo valor.
    @State private var existeNuevaVersion : Bool = false
    
    var body: some View {
        VStack{
            //Si existe una versión superior en la AppStore (lo normal), entonces:
            if self.existeNuevaVersion{
                Button{
                    if let url = URL(string: "https://apps.apple.com/es/app/la-ley/id6472626696"),
                       UIApplication.shared.canOpenURL(url){
                        UIApplication.shared.open(url, options: [:]) { (opened) in
                            if(opened){
                                // print("App Store Opened")
                            }
                        }
                    } else {
                        // print("Can't Open URL on Simulator")
                    }
                }label: {
                    VStack{
                        HStack{
                            Image(systemName: "exclamationmark.circle")
                                .symbolEffect(.pulse, isActive: true)
                            Text("Existe una nueva versión de la App").bold()
                            
                        }
                        Text("Toca aqui para actualizar").bold()
                    }
                    
                    .foregroundStyle(Color.black)
                    .font(.system(size: 15))
                    
                }
            }
        }
        .task {
            Task{
                self.existeNuevaVersion = await Self.getAppNewVersion()
            }
            
            
        }
    }

    private static func getAppNewVersion() async -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else {
            return false
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let results = json["results"] as? [[String: Any]],
                let appInfo = results.first,
                let appStoreVersion = appInfo["version"] as? String,
                let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            else {
                return false
            }

            return appStoreVersion.compare(localVersion, options: .numeric) == .orderedDescending
        } catch {
            return false
        }
    }
}
#endif



//Para aplicar el thema de colores en la app:
//Theme
enum Theme: String, CaseIterable{
    case auto, light, dark
}

extension View {
    @ViewBuilder
    func applyTheme(_ scheme: Theme) -> some View {
            switch scheme{
            case .dark:
                self.colorScheme(.dark)
            case .light:
                self.colorScheme(.light)
            case .auto:
                self // auto → hereda del sistema
            }
        
    }
}





#if os(macOS)
//Para redimencionar los iconos dentro de un menu
func iconMenu(nombre: String?, title: String, tamaño: CGFloat = 24, imagenPorDefecto: String = "b_carpeta") -> some View {
    // Cargar la imagen de recursos
    guard let nsImage = NSImage(named: nombre ?? imagenPorDefecto) else {
        return AnyView(Image(nsImage: NSImage())) // Imagen vacía en caso de error
    }
    
    // Mantener proporción
    let ratio = nsImage.size.height / nsImage.size.width
    nsImage.size.height = tamaño
    nsImage.size.width = tamaño / ratio
    
    // Devolver como Image de SwiftUI
    return AnyView( HStack(spacing: 0){
        Text(title)
        Image(nsImage: nsImage)
            .resizable()
            .clipShape(RoundedRectangle(cornerRadius: 10))
    })

}

#endif

#if os(iOS)
func iconoRedimensionado(nombre: String?, tamaño: CGFloat = 24, imagenPorDefecto: String = "b_carpeta") -> Image {
    
    // Cargar la imagen desde Assets
    guard let uiImage = UIImage(named: nombre ?? imagenPorDefecto) else {
        return Image(uiImage: UIImage())
    }
    
    // Mantener proporción
    let ratio = uiImage.size.height / uiImage.size.width
    let nuevoAncho = tamaño / ratio
    let nuevoAlto = tamaño
    
    let nuevoSize = CGSize(width: nuevoAncho, height: nuevoAlto)
    
    // Redimensionar usando contexto gráfico
    let renderer = UIGraphicsImageRenderer(size: nuevoSize)
    
    let imagenRedimensionada = renderer.image { _ in
        uiImage.draw(in: CGRect(origin: .zero, size: nuevoSize))
    }
    
    return Image(uiImage: imagenRedimensionada)
}

#endif

