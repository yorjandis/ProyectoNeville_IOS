//
//  RespondView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 20/10/25.
//

import SwiftUI
import RichText


@available(iOS 26.0, *)
struct RespondView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model : IAModelAppleIntelligence = IAModelAppleIntelligence()
    @State private var notasModel : NotasModel = NotasModel()
    
    @State private var isloading : Bool = false
    @State private var bounce = false //Para animar la imagend de IA en el centro de la pantalla
    
    @AppStorage(AppCons.UD_setting_fontContentSize)    var fontSizeContenido : Int = 24
    @AppStorage(AppCons.UD_setting_AceptacionDescargoIA)    var DescargoDeIA : Bool = false // Si es true se permite utilizar la IA.
    
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    
    
    
    let nameConference : String //Nombre de la conferencia
    let texto : String
    let tipoSalida : TiposSalida //Especifica el tipo de salida desea: Puntos Claves / Resumen General
    
    private var creatorContentToShare : String{
        
        switch tipoSalida {
        case .puntosClaves:
            return  self.model.puntosClaves.joined(separator: "\n")
        case .resumen:
            return self.model.resumenGeneral
        case .practicas:
            return  self.model.practicas.joined(separator: "\n")
        case .practicaConcreta:
            return self.model.practicaConcreta
        case .interpretar:
            return self.model.interpretacion
        }
    }

    
    
    var body: some View {
        ZStack{
            LinearGradient(colors: [.orange.opacity(0.7),  .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .bottom)
            
            if self.DescargoDeIA{
                ScrollView {
                    
                    switch self.tipoSalida {
                    case .puntosClaves:
                        VistaPuntosClaves()
                    case .resumen:
                        VistaDeResumenGeneral()
                    case .practicas:
                        VistaPracticas()
                    case .practicaConcreta:
                        VistaPracticaConcreta()
                    case .interpretar:
                        VistaInterpretacion()
                    }
                }
                .redacted(reason: self.isloading ? .placeholder : []) //Mostrar un skeleton mientras se carga el contenido
                //Mostrando la vista de procesamiento
                    if self.isloading{
                        VistaDeProcesamiento().padding()
                    }
            }else{
                DescargoResponsabilidadIA(VentanaEnSetting: false)
            }
  
        }
        .onAppear{
            Task { @MainActor in
                withAnimation {
                    self.isloading = true
                }
                
               generarTexto()
                
                withAnimation {
                    self.isloading = false
                }
                
            }
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("Chat"), message: Text(self.alertMessage))
        }
        .toolbar{
            if !self.isloading {
                //Share the text
                ToolbarItem {
                    ShareLink(item: self.creatorContentToShare){
                        Label("", systemImage: "square.and.arrow.up")
                    }
                     
                }
                
                ToolbarSpacer(.fixed)
                
                ToolbarItem {
                    Button{
                        
                        if self.notasModel.addNote(nota: "\(self.creatorContentToShare ) \n\n ----Texto de Referencia---- \n \(self.tipoSalida == .interpretar ? self.texto : self.nameConference + " (Conferencia)")", title: "Nota de IA"){
                            self.alertMessage = "Se ha guardado la respuesta en Notas"
                            self.showAlert = true
                        }else{
                            self.alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
                            self.showAlert = true
                        }
                    }label:{
                        Image(systemName: "text.page")
                    }
                }
            }
            
        }
    }
    
    
//Vista que se muestra mientras se procesa la información
@ViewBuilder
    private func VistaDeProcesamiento() -> some View{
        VStack{
            VStack{
                Image(systemName: "sparkles")
                    .padding()
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .offset(y: bounce ? -5 : 5) // movimiento hacia arriba y abajo
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: bounce
                                )
                                .onAppear {
                                    bounce = true
                                }
                //Text(self.tipoSalida == .puntosClaves ? "Generando Puntos Claves" : "Creando  Resumen")
                switch self.tipoSalida {
                case .puntosClaves:
                    Text("Generando Puntos Claves")
                case .resumen:
                    Text("Creando Resumen")
                case .practicas:
                    Text("Generando Concejos Prácticos")
                case .practicaConcreta:
                    Text("Generando Aplicación Práctica")
                case .interpretar:
                    Text("Interpretando Texto")
                }
                
                //Mostrando progreso solo si el texto a procesar excede de 4000 caracteres
                if self.texto.count > 4000{
                    Text("Completado: \(self.model.fragmentoActual)/\(self.model.noFragmentos)")
                    //Barra de Progreso
                    ProgressView(value: Double(self.model.fragmentoActual),
                                 total: max(Double(self.model.noFragmentos), 1))
                    .progressViewStyle(.linear)
                    .tint(.black)
                    .frame(maxWidth: 300)
                }
                
            }
            
        }
        .font(.system(size: 24))
    }
    
    
    
//Para mostrar un listado de los puntos claves de una conferencia (solo conferencia)
@ViewBuilder
    private func VistaPuntosClaves() -> some View{
        VStack(alignment: .leading, spacing: 16) {
            
            ForEach (self.model.puntosClaves, id: \.self){ idea in
                ContenidoView(contenido: idea)
            }
            
            BotonRegenerarView()
            
        }
        .padding()
    }
    
    
//Para mostrar un resumen General de la conferencia (solo conferencia)
@ViewBuilder
    private func VistaDeResumenGeneral() -> some View{
        VStack{
            ContenidoView(contenido: self.model.resumenGeneral)
            BotonRegenerarView()
        }
        .padding()

    }
    

//Para mostrar un listado de acciones prácticas (solo Conferencia)
@ViewBuilder
    private func VistaPracticas() -> some View{
        VStack(alignment: .leading, spacing: 16) {
            
            ForEach (self.model.practicas, id: \.self){ idea in
                ContenidoView(contenido: idea)

            }
            
            BotonRegenerarView()
        }
        .padding()
    }


@ViewBuilder
    private func VistaPracticaConcreta() -> some View {
        if !model.practicaConcreta.isEmpty{
            VStack{
                
                ContenidoView(contenido: self.model.practicaConcreta)
                
                BotonRegenerarView()
                
                Spacer()
                
                VStack{
                    TextoReferenciaView()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
           
        }else{
            EmptyView()
        }
    }
   
    

@ViewBuilder
    private func VistaInterpretacion() -> some View {
        
            VStack{
                
                ContenidoView(contenido: self.model.interpretacion)
                
                BotonRegenerarView()
                
                Spacer()
                
                VStack{
                    TextoReferenciaView()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
            }
            .padding()

        
    }

    
    
    
//-----  Componentes visuales del cuadro de Contenido que se presenta al usuario
    
//Vista de contenido
    @ViewBuilder
    private func ContenidoView(contenido: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text(contenido)
                .font(.system(size: CGFloat(self.fontSizeContenido)))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .contentTransition(.opacity)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
        
    }
    
//Vista del botón de regenerar
    @ViewBuilder
    private func BotonRegenerarView() -> some View {
        VStack{
            Button{
                generarTexto() //Función que regenera el contenido
            }label: {
                Label("", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24))
            }
            .tint(.black)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
//Vista del texto de referencia(Solo para Frases, reflexiones, citas, etc. NO conferencias):
    @ViewBuilder
    private func TextoReferenciaView() -> some View {
        VStack(alignment: .leading){
            Text("Texto de referencia:").font(.title2).bold().foregroundStyle(.black.opacity(0.7))
            ScrollView{
                Text(self.texto)
                    .font(.body).fontDesign(.serif).italic()
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .contentTransition(.opacity)
            }
        }
        .padding()
    }

//---- FIN
    
    
    

    //Funciones del botón de Regenerar Texto
    private func generarTexto(){
            switch self.tipoSalida {
            case .puntosClaves:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestPuntosClaves(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .practicas:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestListAplicacionPractica(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .practicaConcreta:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestPracticaConcreta(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .resumen:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestResumenGeneral(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .interpretar:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestInterpretaTexto(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
        }
            
        }
    
}//fin del struct






  

#Preview {
    if #available(iOS 26.0, *) {
        RespondView(nameConference: "NameConference", texto: "Esto es un ejemplo Yor", tipoSalida: .puntosClaves)
    }
   
}

