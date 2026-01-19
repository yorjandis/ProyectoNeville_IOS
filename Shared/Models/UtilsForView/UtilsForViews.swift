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

//Show messages only in debug mode: Dump
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


//Custom Modifier: crea un gradiente de 3 color: Observe que el último color es opcional, si es nil solo se utiliza los dos primeros.
struct mof_ColorGradient : ViewModifier {

    @Binding var colorInit : Color
    @Binding var colorEnd : Color
    
    func body(content : Content)->some View{content
        .background( LinearGradient(gradient: Gradient(colors: [colorInit, colorEnd]), startPoint: .top, endPoint: .bottom))
    }
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


//Modificador personalizado: Aplicar glass effect a una View en dependencia si estamos en iOS 26+ / iOS 18-
#if os(iOS)
extension View {
    @ViewBuilder
    func applyGlassEffect() -> some View {
        if #available(iOS 26, *){
            self.glassEffect()
        }else{
            self.background(.ultraThinMaterial)
        }
    }
}
#endif



//Botón Personaizado Para menus
@ViewBuilder
func CreateMenuItemButton(text : String,sysImageStr : String, action : @MainActor @escaping ()->()) -> some View{
    
    Button{
        action()
    }label: {
        Label(text, systemImage: sysImageStr)
    }
    
    
}


//Muestra una de felicitación por el cumpleaños
@ViewBuilder
func MostrarCumpleaños() -> some View {
    
    let componentes = Calendar.current.dateComponents([.day, .month], from: Date())
    if (componentes.day == 19 && componentes.month == 2){
        VStack{
            Text("Feliz Cumpleaños Maestro Neville! 💖").font(.title).fontDesign(.serif)
            Text("Gracias por tu Amor y Enseñanzas").font(.callout).fontDesign(.serif)
        }.foregroundStyle(.black)
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
                self.existeNuevaVersion = await CheckAppStatus.getAppNewVersion()
            }
            
            
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

//Extensión de Color Para expresar los colores en formato hexadecimal:
/*
 Ejemplo de uso:
 let amarillo = Color(hex: 0xFFCB0CFF)
 let verde = Color(hex: 0x38B300FF)
 */
extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 24) & 0xFF) / 255
        let g = Double((hex >> 16) & 0xFF) / 255
        let b = Double((hex >> 8) & 0xFF) / 255
        let a = Double(hex & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}


//Colores Gradientes predefinidos:
extension LinearGradient {
    /*
     Colores cálidos y energéticos, perfectos para pantallas de bienvenida.
     💡 Sensación: vitalidad, optimismo, energía matinal
     */
    static func Amanecer(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.00, green: 0.55, blue: 0.30), // naranja
                Color(red: 1.00, green: 0.80, blue: 0.45)  // amarillo suave
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Ideal para apps relajantes o de bienestar.
     💡 Sensación: calma, frescura, limpieza.
     */
    static func Oceano(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.00, green: 0.65, blue: 0.80), // azul turquesa
                Color(red: 0.20, green: 0.85, blue: 0.75)  // verde agua
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    
    /*
     Muy buena opción para apps ecológicas, salud o productividad.
     💡 Sensación: equilibrio, naturaleza, crecimiento.
     */
    static func Bosque(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.10, green: 0.60, blue: 0.35), // verde bosque
                Color(red: 0.40, green: 0.80, blue: 0.50)  // verde lima natural
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Transmite profundidad y elegancia sin perder viveza.
     💡 Sensación: creatividad, introspección, sofisticación.
     */
    static func AtardecerVioleta(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.55, green: 0.30, blue: 0.85), // violeta
                Color(red: 0.95, green: 0.40, blue: 0.55)  // rosa coral
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Muy luminosa y natural, excelente para dashboards.
     💡 Sensación: renovación, ligereza, frescura.
     */
    static func Primavera(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.55, green: 0.85, blue: 0.40), // verde claro
                Color(red: 0.75, green: 0.95, blue: 0.65)  // verde pastel
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Potente y llamativa, ideal para métricas o estados activos.
     💡 Sensación: acción, intensidad, dinamismo.
     */
    static func Fuego(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.55, green: 0.85, blue: 0.40), // verde claro
                Color(red: 0.75, green: 0.95, blue: 0.65)  // verde pastel
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Elegante y tecnológico, excelente para dashboards y apps financieras.
     💡 Sensación: profundidad, confianza, estabilidad.
     */
    static func AzulTecnologico(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.20, blue: 0.45), // azul profundo
                        Color(red: 0.15, green: 0.40, blue: 0.70)  // azul petróleo
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Minimalista, ideal para interfaces profesionales y fondos neutros.
     💡 Sensación: precisión, tecnología, sobriedad.
     */
    static func GrisMetalizado(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.30, green: 0.32, blue: 0.35), // gris acero oscuro
                        Color(red: 0.60, green: 0.62, blue: 0.65)  // gris aluminio
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Natural pero sofisticado, muy bueno para bienestar y longevidad.
     💡 Sensación: equilibrio, salud, serenidad profunda.
     */
    static func JadeProfundo(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.00, green: 0.45, blue: 0.40), // jade oscuro
                        Color(red: 0.20, green: 0.70, blue: 0.60)  // jade vivo
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Ultra moderno, perfecto para modo oscuro real y enfoque total.
     💡 Sensación: elegancia, silencio visual, concentración.
     */
    static func NegroMate(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.06), // negro mate
                Color(red: 0.18, green: 0.18, blue: 0.20)  // grafito
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Orgánico y cálido, muy alineado con diseño bio-inspirado.
     💡 Sensación: arraigo, calidez, autenticidad.
     */
    static func BarroNatural(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.55, green: 0.30, blue: 0.20), // barro oscuro
                Color(red: 0.75, green: 0.45, blue: 0.30)  // terracota
            ]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    
    
    
}
