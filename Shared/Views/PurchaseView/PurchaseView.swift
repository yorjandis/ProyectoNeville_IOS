//
//  PurchaseView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//

import SwiftUI


struct PurchaseView: View {
    
    @StateObject private var purchaseModel : PurchaseManager = .shared
    
    var mostrarLogo : Bool = true
    
    var mostrarBotonCerrarMacOS : Bool = false
    
    var body: some View {
        VStack{
            ZStack{
                #if os(macOS)
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.55, blue: 0.30),
                        Color(red: 1.00, green: 0.80, blue: 0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                #else
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.55, blue: 0.30),
                        Color(red: 1.00, green: 0.80, blue: 0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                #endif
                
                
                VStack{
                   
                    if self.mostrarLogo{
                        Image("Logo")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                            .shadow(color: .purple, radius: 3)
                    }

                    Text("🎉 Versión Extendida ✨")
                        .bold()
                        .font(.title)
                        .fontDesign(.rounded)
                        .padding(8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .orange, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .background {
                            Color.black.opacity(0.4)
                        }
                        .cornerRadius(20)
                    
                    Text("Accede a todo el contenido")
                        .bold()
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                    
                    Spacer()
                        
                    ScrollView{
                        VStack(alignment: .leading, spacing: 15) {
                            
                            Text("🔵 Contenido exclusivo de grandes referentes: Accede a las frases y enseñanzas de  Joe Dispenza, Bruce Lipton y Gregg Braden").bold()
                            
                            Text("🔵 Metas y transformación personal: Define objetivos claros, mide tu progreso y adopta hábitos respaldados por la neurociencia. Incluye programas prácticos para reprogramar patrones negativos y empoderarte.").bold()
                            
                            Text("🔵 Lienzo creativo: Diseña imágenes impactantes con tus frases favoritas para compartir en redes o usar como tarjetas personales de enfoque y motivación.").bold()
                            
                            Text("🔵 Recordatorios inteligentes: Programa avisos para tus prácticas esenciales como meditar, agradecer, visualizar o revisar tus metas.").bold()
                            
                            Text("🔵 Enciclopedia: Amplio catálogo de contenido educativo y práctico sobre diferentes temas. Basado en las últimas investigaciones de la neurociencia y la meditación. Aprende cómo funcionan los hábitos, la mente, la epigenética, las hormonas del estrés, los ritmos circadianos y muchos otros.").bold()
                            
                            Text("🔵 Evidencia científica: Resumen de investigaciones que respaldan estas enseñanzas, debidamente acotados para su fácil consulta").bold()
                            
                            Text("🔵 Inteligencia Artificial integrada: Obtén resúmenes, interpretaciones, consejos prácticos y un chat para resolver dudas al instante. En el chat, podemos escoger el autor que responderá y las respuestas se basará en su particular campo de conocimientos.").bold()
                            
                            Text("🔵 Atajos y comandos con Siri: Crea notas, añade entradas al diario o abre contenido usando solo tu voz, sin entrar en la app.").bold()
                            
                            Text("🔵 Importación desde cualquier lugar: Guarda texto o imágenes desde webs y apps con el menú compartir. Incluye OCR y lectura de códigos QR.").bold()
                            
                            Text("🔵 Frases Relacionadas (FR): Conecta ideas de distintos autores y tus propias reflexiones para crear un mapa visual del pensamiento compartido.").bold()
                            
                            Text("🔵 Comparte con QR: Genera códigos QR para compartir notas y frases fácilmente en redes sociales o con amigos.").bold()
                            
                            Text("🔵 Notas protegidas: Bloquea el acceso a tus notas con biometría o contraseña para mantener tu contenido seguro.").bold()
                            
                            Text("🔵 Menú inteligente de texto copiado: Selecciona cualquier fragmento dentro de la app y accede a acciones rápidas como guardar en Notas o Frases al instante.").bold()
                        }
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                    }
                    .scrollIndicators(.visible)

                   Spacer()
                    
                    if !self.purchaseModel.isPremium {
                        VStack(alignment: .center){
                            Text("!Suscripción anual, muy asequible!")
                                .bold()
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .padding()
                            Button{
                                Task{
                                    await self.purchaseModel.purchasePremium()
                                }
                                
                            }label: {
                                Text("Acceder a la Versión Extendida")
                                    .foregroundStyle(.black)
                                    .font(.title2)
                                    .bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue.opacity(0.6))
                        }
                    }else{
                        Text("Versión Extendida Habilitada! 🎉")
                            .bold()
                            .font(.system(size: 20))
                            .foregroundStyle(.black)
                            .padding()
                    }

                    VStack{
                        Button{
                            Task{
                                await self.purchaseModel.restorePurchases()
                            }
                            
                        }label: {
                            Text("Restaurar Compras")
                                .font(.system(size: 15))
                                .bold()
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black.opacity(0.5))
                        
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center){
                        Text("💕 Las enseñanzas de neville seguirán disponibles. Nada cambiará eso 💕")
                            .bold()
                            .foregroundStyle(.black)
                    }
                    
                    #if os(macOS)
                    if self.mostrarBotonCerrarMacOS {
                        if !ventanaActualEsModalPropia() {
                            Button("Cerrar"){
                                if let windows = NSApp.keyWindow{
                                    closeWindowPropia(windows)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    #endif
                   
                }
                .padding()
            }
        }
        
    }
    
    
}

#if os(macOS)
fileprivate func ventanaActualEsModalPropia() -> Bool {
    guard let window = NSApp.keyWindow else {
        return false
    }
    
    return window.isSheet || window.isModalPanel
}

fileprivate func closeWindowPropia(_ window: NSWindow) {
    if let parent = window.sheetParent {
        // Es un sheet modal
        parent.endSheet(window)
    } else {
        // Es una ventana normal
        window.close()
    }
}

#endif


#Preview {
    PurchaseView()
}
