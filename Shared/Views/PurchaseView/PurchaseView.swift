//
//  PurchaseView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//

import SwiftUI
import StoreKit


struct PurchaseView: View {
    
    @StateObject private var purchaseModel : PurchaseManager = .shared
    
    var mostrarLogo : Bool = true
    
    var mostrarBotonCerrarMacOS : Bool = false

    private let termsOfUseURL = URL(string: "https://ypgcode.es/neville-ios-terms-of-use/")
    private let privacyPolicyURL = URL(string: "https://ypgcode.es/neville-ios-privacy-policy/")
    
    private struct PremiumFeature: Identifiable {
        let id = UUID()
        let iconName: String
        let title: String
        let description: String
    }
    
    private static let premiumFeatures: [PremiumFeature] = [
        PremiumFeature(
            iconName: "sparkles",
            title: "Contenido exclusivo",
            description: "Accede a las frases y enseñanzas de Joe Dispenza, Bruce Lipton y Gregg Braden."
        ),
        PremiumFeature(
            iconName: "cross.case.fill",
            title: String(localized: "Centro Sanador"),
            description: String(localized: "Guías rápidas para momentos difíciles: ansiedad, miedo, estrés, bloqueo, conflicto o impulso. Comprende qué ocurre en tu cuerpo y aplica técnicas prácticas paso a paso cuando más lo necesitas.")
        ),
        PremiumFeature(
            iconName: "target",
            title: "Metas y transformación personal",
            description: "Define objetivos claros, mide tu progreso y adopta hábitos respaldados por la neurociencia. Incluye programas prácticos para reprogramar patrones negativos y empoderarte."
        ),
        PremiumFeature(
            iconName: "paintpalette",
            title: "Lienzo creativo",
            description: "Diseña imágenes impactantes con tus frases favoritas para compartir en redes o usar como tarjetas personales de enfoque y motivación."
        ),
        PremiumFeature(
            iconName: "sun.max",
            title: "Ciclo consciente diario",
            description: "Diseña tu mañana con intención, registra tu presencia, cierra el día con aprendizaje y transforma todo en un Diario útil para mañana. Incluye recordatorios, estadísticas y Mi día."
        ),
        PremiumFeature(
            iconName: "sparkles.rectangle.stack",
            title: "Revisión semanal guiada",
            description: "Cierra la semana con una síntesis de metas, agenda, diario, emociones, presencia, coherencia y logros. Elige el día, recibe un recordatorio opcional y conserva tus revisiones sincronizadas."
        ),
        PremiumFeature(
            iconName: "calendar",
            title: "Agenda",
            description: "Organiza tus actividades y tareas en el tiempo, liberando recursos y memoria. Añade recordatorios para no olvidar lo importante."
        ),
        PremiumFeature(
            iconName: "heart.circle",
            title: String(localized: "Coherencia cardio - Cerebral"),
            description: String(localized: "Entra en estado de coherencia con la ayuda de este asistente personal. El estado de coherencia es creativo por naturaleza.")
        ),
        PremiumFeature(
            iconName: "doc.text",
            title: "Exportación PDF",
            description: "Exporta Notas, Frases, Actividades de la Agenda, Reflexiones y respuestas de Chat IA a formato portable PDF estándar."
        ),
        PremiumFeature(
            iconName: "leaf",
            title: "Espacio Calma",
            description: "Experiencia inmersiva para relajarte y aprender mientras activas tu sistema parasimpático."
        ),
        PremiumFeature(
            iconName: "eye",
            title: "Presencia Consciente",
            description: "Registra pequeños momentos de despertar durante el día y vuelve al presente con un solo toque. Observa cuándo sales del piloto automático, reconoce tu estado de ánimo y refuerza la emoción del futuro que deseas vivir."
        ),
        PremiumFeature(
            iconName: "bell.badge",
            title: "Recordatorios inteligentes",
            description: "Programa avisos para tus prácticas esenciales como meditar, agradecer, visualizar o revisar tus metas."
        ),
        PremiumFeature(
            iconName: "book.closed",
            title: "Enciclopedia",
            description: "Amplio catálogo educativo y práctico basado en neurociencia y meditación: hábitos, mente, epigenética, hormonas del estrés, ritmos circadianos y más."
        ),
        PremiumFeature(
            iconName: "barcode.viewfinder",
            title: String(localized: "Lector de Etiquetas"),
            description: String(localized: "Analiza cualquier alimento y obtiene información nutricional detallada: consumo saludable, impacto en el metabolismo y posibles efectos negativos.")
        ),
        PremiumFeature(
            iconName: "checkmark.seal",
            title: "Evidencia científica",
            description: "Resumen de investigaciones que respaldan estas enseñanzas, debidamente acotados para su fácil consulta."
        ),
        PremiumFeature(
            iconName: "brain.head.profile",
            title: "Inteligencia Artificial integrada",
            description: "Obtén resúmenes, interpretaciones, consejos prácticos y un chat para resolver dudas al instante, con respuestas basadas en el campo de conocimiento de cada autor."
        ),
        PremiumFeature(
            iconName: "mic",
            title: "Atajos y comandos con Siri",
            description: "Crea notas, añade entradas al diario o abre contenido usando solo tu voz, sin entrar en la app."
        ),
        PremiumFeature(
            iconName: "square.and.arrow.down",
            title: "Importación desde cualquier lugar",
            description: "Guarda texto o imágenes desde webs y apps con el menú compartir. Incluye OCR y lectura de códigos QR."
        ),
        PremiumFeature(
            iconName: "link",
            title: "Frases Relacionadas (FR)",
            description: "Conecta ideas de distintos autores y tus propias reflexiones para crear un mapa visual del pensamiento compartido."
        ),
        PremiumFeature(
            iconName: "qrcode",
            title: "Comparte con QR",
            description: "Genera códigos QR para compartir notas y frases fácilmente en redes sociales o con amigos."
        ),
        PremiumFeature(
            iconName: "lock.shield",
            title: "Notas protegidas",
            description: "Bloquea el acceso a tus notas con biometría o contraseña para mantener tu contenido seguro."
        ),
        PremiumFeature(
            iconName: "textformat.abc",
            title: "Menú inteligente de texto copiado",
            description: "Selecciona cualquier fragmento dentro de la app y accede a acciones rápidas como guardar en Notas o Frases al instante."
        )
    ]
    
    private static let featureCardColors: [Color] = [
        Color(red: 0.88, green: 0.96, blue: 0.91),
        Color(red: 0.88, green: 0.94, blue: 0.98),
        Color(red: 0.91, green: 0.96, blue: 0.94),
        Color(red: 0.86, green: 0.93, blue: 0.96)
    ]
    
    private static let featureHeaderFontDesigns: [Font.Design] = [
        .rounded,
        .serif,
        .monospaced,
        .default
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 18) {
                        headerView
                        featuresView
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.visible)
                
                bottomPurchasePanel
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
                    .background {
                        bottomPurchasePanelBackground
                    }
            }
        }
        .task {
            self.purchaseModel.startProductLoadingRetriesWhileVisible()
        }
        .onDisappear {
            self.purchaseModel.stopProductLoadingRetries()
        }
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
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
    }

    @ViewBuilder
    private var bottomPurchasePanelBackground: some View {
        #if os(macOS)
        Color.white.opacity(0.9)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.65))
                    .frame(height: 1)
            }
        #else
        Rectangle()
            .fill(.ultraThinMaterial)
        #endif
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            if self.mostrarLogo {
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
            
            Text("Primera semana gratis")
                .bold()
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.45))
                .clipShape(Capsule())
        }
    }
    
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(Self.premiumFeatures.enumerated()), id: \.element.id) { index, feature in
                featureCard(
                    feature,
                    backgroundColor: Self.featureCardColors[index % Self.featureCardColors.count],
                    titleFontDesign: Self.featureHeaderFontDesigns[index % Self.featureHeaderFontDesigns.count]
                )
            }
        }
        .multilineTextAlignment(.leading)
        .foregroundStyle(.black)
    }
    
    private func featureCard(
        _ feature: PremiumFeature,
        backgroundColor: Color,
        titleFontDesign: Font.Design
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Image(systemName: feature.iconName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.34))
                    .frame(width: 24)
                
                Text(feature.title)
                    .font(.system(size: 19, weight: .bold, design: titleFontDesign))
                    .foregroundStyle(Color(red: 0.04, green: 0.23, blue: 0.22))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
            
            Text(feature.description)
                .font(.system(size: 17))
                .fontWeight(.semibold)
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(backgroundColor.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }
    
    private var bottomPurchasePanel: some View {
        VStack(alignment: .center, spacing: 8) {
            if !self.purchaseModel.isPremium {
                Text("7 días gratis, después suscripción anual")
                    .bold()
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                
                Button {
                    Task {
                        await self.purchaseModel.purchasePremium()
                    }
                } label: {
                    VStack(spacing: 4) {
                        if let premiumProduct = self.purchaseModel.products.first {
                            Text("\(premiumProduct.displayPrice)/año")
                                .purchasePrimaryButtonTextStyle()
                                .font(.headline)
                                .bold()
                        } else {
                            Text("Cargando precio…")
                                .purchasePrimaryButtonTextStyle()
                                .font(.headline)
                                .bold()
                        }
                        
                        Text("Acceder a la Versión Extendida")
                            .purchasePrimaryButtonTextStyle()
                            .font(.title2)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    #if os(macOS)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 0.08, green: 0.34, blue: 0.78))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
                    #endif
                }
                #if os(macOS)
                .buttonStyle(.plain)
                #else
                .buttonStyle(.bordered)
                .tint(.blue.opacity(0.6))
                #endif
                .disabled(self.purchaseModel.products.isEmpty)
                
                Text("La suscripción se renueva automáticamente cada año hasta que se cancele.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                
                Text("Puedes gestionar o cancelar la suscripción en Ajustes de tu Apple ID tras la compra.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
            } else {
                Text("Versión Extendida Habilitada! 🎉")
                    .bold()
                    .font(.system(size: 20))
                    .foregroundStyle(.black)
                    .padding(.vertical, 6)
            }
            
            Button {
                Task {
                    await self.purchaseModel.restorePurchases()
                }
            } label: {
                Text("Restaurar Compras")
                    .font(.system(size: 15))
                    .bold()
                    #if os(macOS)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 0.20, green: 0.20, blue: 0.22))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    }
                    #else
                    .foregroundStyle(.white)
                    #endif
            }
            #if os(macOS)
            .buttonStyle(.plain)
            #else
            .buttonStyle(.bordered)
            .tint(.black.opacity(0.5))
            #endif
            
            legalLinksView
            
            #if os(macOS)
            if self.mostrarBotonCerrarMacOS {
                if !ventanaActualEsModalPropia() {
                    Button("Cerrar") {
                        if let windows = NSApp.keyWindow {
                            closeWindowPropia(windows)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            #endif
        }
    }
    
    private var legalLinksView: some View {
        HStack(spacing: 8) {
            if let termsOfUseURL {
                Link("Términos de Uso", destination: termsOfUseURL)
                    .font(.footnote)
                    .bold()
            }
            
            Text("·")
                .font(.footnote)
                .bold()
            
            if let privacyPolicyURL {
                Link("Política de Privacidad", destination: privacyPolicyURL)
                    .font(.footnote)
                    .bold()
            }
        }
        .lineLimit(1)
        .foregroundStyle(.black)
    }

}

private extension View {
    @ViewBuilder
    func purchasePrimaryButtonTextStyle() -> some View {
        #if os(macOS)
        self.foregroundStyle(.white)
        #else
        self.foregroundStyle(.black)
        #endif
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


#Preview("PurchaseView") {
    PurchaseView()
}
