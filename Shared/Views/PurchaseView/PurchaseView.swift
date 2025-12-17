//
//  PurchaseView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//

import SwiftUI


struct PurchaseView: View {
    
    @StateObject private var purchaseModel : PurchaseManager = .shared
    
    var body: some View {
        VStack{
            ZStack{
                
                LinearGradient(colors: [.orange.opacity(0.8),.purple.opacity(0.8),], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack{
                    Image(uiImage: UIImage(named: "Logo")!)
                        .resizable()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        .shadow(color: .purple, radius: 3)
                    Text("🎉 La Ley Premium ✨")
                        .bold()
                        .font(.title)
                        .fontDesign(.rounded)
                        .padding(8)
                        .background{
                            Color.gray.opacity(0.3)
                        }
                        .cornerRadius(20)
                    
                    Text("Desbloquea todas las Funciones!")
                        .bold()
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        
                    ScrollView{
                        VStack( alignment: .leading ,spacing: 15){
                            Text("🔵 Inteligencia Artificial (IA): Resumen, Interpretación, concejos prácticos y chat").bold()
                                .multilineTextAlignment(.leading)
                            
                            Text("🔵 Atajos & Comandos Siri: Abrir notas, crear notas, abrir Diario, crear Entrada del Diario, abrir una conferencia al azar, etc").bold()
                                .multilineTextAlignment(.leading)
                            Text("🔵 Opciones del Menu Compartir: Leer QR code, OCR(extraer texto de imagen), importar Notas/Frase desde QR").bold()
                                .multilineTextAlignment(.leading)
                            Text("🔵 Lienzo: Diseña vistosas imágenes con frases y pensamientos para compartir en redes sociales y con amigos").bold()
                                .multilineTextAlignment(.leading)
                            Text("🔵 Importar Nota/Frase por QR code. Comparte frases y notas en redes sociales utilizando un código QR").bold()
                                .multilineTextAlignment(.leading)
                            Text("🔵 Proteger las Notas: Permite proteger el acceso a notas con biometría o contraseña.").bold()
                                .multilineTextAlignment(.leading)
                             
                        }
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
                                .padding(.top, 20)
                            Button{
                                Task{
                                    await self.purchaseModel.purchasePremium()
                                }
                                
                            }label: {
                                Text("Adquirir Premium")
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

                    
                    VStack(alignment: .center){
                        Text("💕 El acceso a las enseñanzas de neville seguirán siendo gratis. Nada cambiará eso 💕")
                            .bold()
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
                }
                .padding()
                
                
            }
        }
        
    }
    
    
}



#Preview {
    PurchaseView()
}
