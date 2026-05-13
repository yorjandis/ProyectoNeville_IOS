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
    
    //Colores Galaxys
    case G_verde_azul_1, G_verde_gris_1, G_natural_1, G_natural_2, G_azul_violeta_1
    case G_violeta_azul_1, G_natural_3, G_natural_4, G_natural_5, G_natural_6, G_natural_7
    case G_natural_8
    
    
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
            
            //Colores Galaxy:
        case .G_verde_azul_1: [
            Color(red: 0.85, green: 0.69, blue: 0.00),
            Color(red: 0.48, green: 0.64, blue: 0.55)
        ]
        case .G_verde_gris_1: [
            Color(red: 0.72, green: 0.69, blue: 0.32),
            Color(red: 0.48, green: 0.48, blue: 0.43)
        ]
        case .G_natural_1: [
            Color(red: 0.72, green: 0.59, blue: 0.32),
            Color(red: 0.48, green: 0.48, blue: 0.62)
        ]
        case .G_natural_2: [
            Color(red: 1.00, green: 0.52, blue: 0.84),
            Color(red: 0.39, green: 0.43, blue: 0.62)
        ]
        case .G_azul_violeta_1: [
            Color(red: 0.41, green: 0.50, blue: 0.84),
            Color(red: 0.52, green: 0.32, blue: 0.72)
        ]
        case .G_violeta_azul_1: [
            Color(red: 0.20, green: 0.19, blue: 0.51),
            Color(red: 0.37, green: 0.66, blue: 0.77)
        ]
        case .G_natural_3: [
            Color(red: 0.60, green: 0.65, blue: 0.46),
            Color(red: 0.31, green: 0.55, blue: 0.65),
            Color(red: 0.38, green: 0.66, blue: 0.79)
        ]
        case .G_natural_4: [
            Color(red: 0.69, green: 0.37, blue: 0.64),
            Color(red: 0.60, green: 0.51, blue: 0.65),
            Color(red: 0.52, green: 0.53, blue: 0.85)
        ]
        case .G_natural_5:[
            Color(red: 0.32, green: 0.64, blue: 0.75),
            Color(red: 0.47, green: 0.55, blue: 0.78),
            Color(red: 0.52, green: 0.53, blue: 0.54)
        ]
        case .G_natural_6: [
            Color(red: 0.47, green: 0.63, blue: 0.55),
            Color(red: 0.27, green: 0.49, blue: 0.58)
        ]
        case .G_natural_7: [
            Color(red: 0.29, green: 0.44, blue: 0.50),
            Color(red: 0.46, green: 0.51, blue: 0.83)
        ]
        case .G_natural_8: [
            Color(red: 0.65, green: 0.76, blue: 0.90),
            Color(red: 0.41, green: 0.49, blue: 0.90),
            Color(red: 0.46, green: 0.51, blue: 0.83)
        ]
        }
    }
    
}


//Colores Gradientes predefinidos:
extension LinearGradient {

    //Color grisAzulMate
    @MainActor static func FondoGrizAzulMate(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {
        
        LinearGradient(
            colors: [Color(red: 0.58, green: 0.67, blue: 0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    //Color oscuro para fondo
    @MainActor static func FondoOscuro(_ startPoint : UnitPoint = .top, _ endPoint : UnitPoint = .bottom   ) -> Self {

        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.55, blue: 0.55).opacity(0.4),
                        Color.gray.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    
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
