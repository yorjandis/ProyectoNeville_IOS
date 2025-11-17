//
//  UtilsForViews.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 19/9/23.
//Objetivo: Agrupa modificadores personalizados y funciones que modifican la UIx
//

import SwiftUI

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


