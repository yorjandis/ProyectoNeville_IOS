//
//  HelperColors.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/2/26.
//

import SwiftUI


//Extensión de Color Para expresar los colores en formato hexadecimal:
/*
 Ejemplo de uso:
 let color1 = Color(hex: 0xE9D154)
 let color2 = Color(hex: 0xE9D154, alpha: 0.5)
 
 */
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
            let r = Double((hex >> 16) & 0xFF) / 255
            let g = Double((hex >> 8) & 0xFF) / 255
            let b = Double(hex & 0xFF) / 255
            
            self.init(red: r, green: g, blue: b, opacity: alpha)
        }
}

//Extensión de Color que convierte formato RGB:
extension Color {
    init(rgbRed: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: rgbRed / 255,
            green: green / 255,
            blue: blue / 255,
            opacity: opacity
        )
    }
}


//Aplica un color sólido según la plataforma: iOS, macOS, watchOS, ipadOS
extension Color {
    
    static func platformColor(coloriOS: Color?, colorMac : Color?, opacity: Double = 1) -> Color {
        #if os(iOS) || os(tvOS) || os(watchOS)
        
        if let color = coloriOS {
            return color.opacity(opacity)
        }else{return Color.clear}
        
        #elseif os(macOS)
        
        if let color = colorMac {
            return color.opacity(opacity)
        }else{return Color.clear}
        
        #endif
        
    }
}
    
//Aplica un color degradado según la plataforma
extension Color {
        
    static func platformColorGradient(colorsIOS: [Color]?, colorsMac: [Color]?, startPoint: UnitPoint = .top, endPoint: UnitPoint = .bottom) -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS)
            
        if let colors = colorsIOS {
            return LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
        }else{
            return LinearGradient(colors: [.clear], startPoint: startPoint, endPoint: endPoint)
        }
        
        #elseif os(macOS)
        
        if let colors = colorsMac {
            return LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
        }else{
            return LinearGradient(colors: [.clear], startPoint: startPoint, endPoint: endPoint)
        }
        
        #endif
            
        }
    }


//Custom Modifier: crea un gradiente de 3 color: Observe que el último color es opcional, si es nil solo se utiliza los dos primeros.
struct mof_ColorGradient : ViewModifier {

    @Binding var colorInit : Color
    @Binding var colorEnd : Color
    
    func body(content : Content)->some View{content
        .background( LinearGradient(gradient: Gradient(colors: [colorInit, colorEnd]), startPoint: .top, endPoint: .bottom))
    }
}



//Conjuntos de Colores Preestablecidos
enum GradientesPreselect{
    
    case Amanecer, Oceano, Bosque, AtardecerVioleta, Primavera, Fuego, AzulTecnologico
    case GrisMetalizado, JadeProfundo, NegroMate, BarroNatural
    case FondoListado, AmanecerFondo, OceanoFondo
    
     var getColors : [Color]{
        switch self {
        case .Amanecer : [
            Color(red: 1.00, green: 0.55, blue: 0.30), // naranja
            Color(red: 1.00, green: 0.80, blue: 0.45)  // amarillo suave
        ]
        case .Oceano: [
            Color(red: 0.00, green: 0.65, blue: 0.80), // azul turquesa
            Color(red: 0.20, green: 0.85, blue: 0.75)  // verde agua
        ]
        case .Bosque: [
            Color(red: 0.10, green: 0.60, blue: 0.35), // verde bosque
            Color(red: 0.40, green: 0.80, blue: 0.50)  // verde lima natural
        ]
        case .AtardecerVioleta: [
            Color(red: 0.55, green: 0.30, blue: 0.85), // violeta
            Color(red: 0.95, green: 0.40, blue: 0.55)  // rosa coral
        ]
        case .Primavera: [
            Color(red: 0.55, green: 0.85, blue: 0.40), // verde claro
            Color(red: 0.75, green: 0.95, blue: 0.65)  // verde pastel]
            ]
        case .Fuego: [
            Color(red: 0.75, green: 0.20, blue: 0.15),
                Color(red: 0.90, green: 0.45, blue: 0.20),
                Color(red: 0.95, green: 0.65, blue: 0.35)
        ]
        case .AzulTecnologico: [
            Color(red: 0.05, green: 0.20, blue: 0.45), // azul profundo
            Color(red: 0.15, green: 0.40, blue: 0.70)  // azul petróleo
        ]
        case .GrisMetalizado:  [
            Color(red: 0.30, green: 0.32, blue: 0.35), // gris acero oscuro
            Color(red: 0.60, green: 0.62, blue: 0.65)  // gris aluminio
        ]
        case .JadeProfundo:  [
            Color(red: 0.00, green: 0.45, blue: 0.40), // jade oscuro
            Color(red: 0.20, green: 0.70, blue: 0.60)  // jade vivo
        ]
        case .NegroMate:  [
            Color(red: 0.05, green: 0.05, blue: 0.06), // negro mate
            Color(red: 0.18, green: 0.18, blue: 0.20)  // grafito
        ]
        case .BarroNatural:  [
            Color(red: 0.55, green: 0.30, blue: 0.20), // barro oscuro
            Color(red: 0.75, green: 0.45, blue: 0.30)  // terracota
        ]
        case .AmanecerFondo: [
            Color(red: 0.95, green: 0.65, blue: 0.50),
            Color(red: 0.98, green: 0.85, blue: 0.70)
        ]
        case .OceanoFondo: [
            Color(red: 0.15, green: 0.55, blue: 0.70),
            Color(red: 0.45, green: 0.75, blue: 0.80)
        ]
        case .FondoListado: [
            Color.platformColor(coloriOS: Color(rgbRed: 183, green: 123, blue: 206), colorMac: Color(rgbRed: 237, green: 184, blue: 130)),
            Color.platformColor(coloriOS: Color(rgbRed: 164, green: 158, blue: 207), colorMac: Color(rgbRed: 243, green: 214, blue: 177))
            ]
        }
    }
    
}


//Colores Gradientes predefinidos:
extension LinearGradient {
    /*
     Colores cálidos y energéticos, perfectos para pantallas de bienvenida.
     💡 Sensación: vitalidad, optimismo, energía matinal
     */
    @MainActor static func Amanecer(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.Amanecer.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Ideal para apps relajantes o de bienestar.
     💡 Sensación: calma, frescura, limpieza.
     */
    @MainActor static func Oceano(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.Oceano.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    
    /*
     Muy buena opción para apps ecológicas, salud o productividad.
     💡 Sensación: equilibrio, naturaleza, crecimiento.
     */
    @MainActor static func Bosque(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.Bosque.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Transmite profundidad y elegancia sin perder viveza.
     💡 Sensación: creatividad, introspección, sofisticación.
     */
    @MainActor static func AtardecerVioleta(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.AtardecerVioleta.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Muy luminosa y natural, excelente para dashboards.
     💡 Sensación: renovación, ligereza, frescura.
     */
    @MainActor static func Primavera(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.Primavera.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Potente y llamativa, ideal para métricas o estados activos.
     💡 Sensación: acción, intensidad, dinamismo.
     */
    @MainActor static func Fuego(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.Fuego.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Elegante y tecnológico, excelente para dashboards y apps financieras.
     💡 Sensación: profundidad, confianza, estabilidad.
     */
    @MainActor static func AzulTecnologico(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.AzulTecnologico.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Minimalista, ideal para interfaces profesionales y fondos neutros.
     💡 Sensación: precisión, tecnología, sobriedad.
     */
    @MainActor static func GrisMetalizado(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.GrisMetalizado.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Natural pero sofisticado, muy bueno para bienestar y longevidad.
     💡 Sensación: equilibrio, salud, serenidad profunda.
     */
    @MainActor static func JadeProfundo(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.JadeProfundo.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Ultra moderno, perfecto para modo oscuro real y enfoque total.
     💡 Sensación: elegancia, silencio visual, concentración.
     */
    @MainActor static func NegroMate(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.NegroMate.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Orgánico y cálido, muy alineado con diseño bio-inspirado.
     💡 Sensación: arraigo, calidez, autenticidad.
     */
    @MainActor static func BarroNatural(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.BarroNatural.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /*
     Azul fondo, para los menus y listado de temas
     💡 Sensación: arraigo, calidez, autenticidad.
     */
    @MainActor static func FondoListado(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        LinearGradient(
            gradient: Gradient(colors: GradientesPreselect.FondoListado.getColors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
 
}
