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
    
    var body: some View {
        VStack{
            ZStack{
                #if os(macOS)
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.9),
                        Color.blue.opacity(0.7),
                        Color.blue.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                #else
                LinearGradient(
                    colors: [
                        Color.orange,
                        Color.pink.opacity(0.8),
                        Color.purple.opacity(0.7)
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

                    Text("🎉 La Ley Premium ✨")
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
                    
                    Text("Desbloquea todas las Funciones!")
                        .bold()
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                    
                    Spacer()
                        
                    ScrollView{
                        VStack( alignment: .leading ,spacing: 15){
                            Text("🔵 Inteligencia Artificial (IA): Resumen, Interpretación, concejos prácticos y chat").bold()
                                
                            
                            Text("🔵 Atajos & Comandos Siri: Abrir notas, crear notas, abrir Diario, crear Entrada del Diario, abrir una conferencia al azar, etc").bold()
                                
                            Text("🔵 Opciones del Menu Compartir: Leer QR code, OCR(extraer texto de imagen), importar Notas/Frase desde QR").bold()
                                
                            Text("🔵 Lienzo: Diseña vistosas imágenes con frases y pensamientos para compartir en redes sociales y con amigos").bold()
                            
                            Text("🔵 Recordatorios: Programa avisos para no olvidarse de nada esencial: meditaciones, dar gracias, revisión, orar, etc.").bold()
                                
                            Text("🔵 Importar Nota/Frase por QR code. Comparte frases y notas en redes sociales utilizando un código QR").bold()
                                
                            Text("🔵 Proteger las Notas: Permite proteger el acceso a notas con biometría o contraseña.").bold()
                                
                            Text("🔵 Menú Texto Copiado: Crea un menú con accesos útiles cuando seleccionamos y copiamos un texto en conferencias, diario, notas, etc").bold()
                               
                             
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
                                .foregroundColor(.white)
                                .padding()
                            Button{
                                Task{
                                    await self.purchaseModel.purchasePremium()
                                }
                                
                            }label: {
                                Text("Adquirir Premium")
                                    .foregroundStyle(.black)
                                    .font(.title2)
                                    .bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue.opacity(0.6))
                        }
                    }else{
                        Text("Eres premium 🎉")
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
                        Text("💕 El acceso a las enseñanzas de neville seguirán siendo gratis. Nada cambiará eso 💕")
                            .bold()
                            .foregroundStyle(.white)
                    }
                    
                    #if os(macOS)
                    if !ventanaActualEsModalPropia() {
                        Button("Cerrar"){
                            if let windows = NSApp.keyWindow{
                                closeWindowPropia(windows)
                            }
                        }
                        .buttonStyle(.borderedProminent)
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
