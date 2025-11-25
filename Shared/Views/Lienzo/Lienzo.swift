import SwiftUI
#if os(iOS)
import PhotosUI
#endif


struct LienzoMain: View {
    
    @State private var textMain: String = "Cuando ores cree que lo has recibido, y lo habrá recibido, porque eres el alma de la tierra."
    @State private var textSecundary: String = "Texto Secundario para plasmar una idea secundaria"
    
    @State private var tamañoLienzoAncho : CGFloat = 400
    @State private var tamañoLienzoAlto : CGFloat = 300
    
    @State private var imagenDebajo: Bool = true
    
    #if os(iOS)
    @State private var imagen: UIImage?  = UIImage(systemName: "heart") //Imagen si el usuario la carga
    #elseif os(macOS)
    @State private var imagen: UIImage?  = NSImage(systemSymbolName: "heart", accessibilityDescription: nil)
    #endif
    
    @State private var TamañoPrimerTexto: CGFloat = 24 //
    @State private var TamañoSegundoTexto: CGFloat = 20 //
    @State private var TamañoImagen: CGFloat = 60
    
    @State private var imagenAExportar : UIImage?
    
    
    @State private var ocultarSegundoTexto: Bool = false
    @State private var ocultarImagen: Bool = false
    
    //Alterna entre campos de edición de texto y texto de solo lectura
    @State private var editarTextoPrincipal: Bool = false
    @State private var editarTextoSecundario: Bool = false
    
 
    
    //Para el panel de opciones:
    @State private var selectedOpcion: Int = 0
    @State private var imagePositionDonw : Bool = true //true: imagen debajo del texto; false: imagen encima del texto
    
    @StateObject private var modelColorsFondo : ColoresFondo = .shared //Model que almacena los colores de fondo.
    

    #if os(iOS)
    @StateObject private var photosPicker = ImagePickerViewModel()
    #endif
    
    var body: some View {
        VStack{
            //Área útil: la que se va a compartir
            VStack(alignment: .center, spacing: 3){
                
                //Imagen encima del texto
                if !self.imagePositionDonw {
                    if let imagen = self.imagen{
                        if self.ocultarImagen == false{
                            #if os(iOS)
                            Image(uiImage: imagen)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(width: self.TamañoImagen, height: self.TamañoImagen)
                                .clipped()
                            
                            #elseif os(macOS)
                            Image(nsImage: imagen)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(width: self.TamañoImagen, height: self.TamañoImagen)
                                .clipped()
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    self.imagen = seleccionarImagen()
                                }
                                .help("Doble click para cambiar la imagen")
                            #endif
                                
                        }
                        
                    }
                }
                
                    //Texto Principal
                    if self.editarTextoPrincipal {
                        VStack{
                            TextEditor(text: self.$textMain)
                                .font(.system(size: 22))
                                .textFieldStyle(.roundedBorder)
                                .cornerRadius(20)
                            Button{
                                self.editarTextoPrincipal = false
                            }label: {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .foregroundStyle(.green)
                        }
                        
                    }else{
                        Text(self.textMain)
                            .font(.system(size: self.TamañoPrimerTexto))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding()
                            .onTapGesture(count: 2) {
                                self.editarTextoPrincipal = true
                            }
                    }
                    
                //Texto Secundario
                if self.ocultarSegundoTexto == false{
                    if self.editarTextoSecundario {
                        
                        VStack{
                            TextEditor(text: self.$textSecundary)
                                .font(.system(size: 22))
                                .textFieldStyle(.roundedBorder)
                                .cornerRadius(20)
                            Button{
                                self.editarTextoSecundario = false
                            }label: {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .foregroundStyle(.green)
                        }
                        
                    } else {
                        Text(self.textSecundary)
                            .font(.system(size: self.TamañoSegundoTexto))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                            .padding()
                            .onTapGesture(count: 2) {
                                self.editarTextoSecundario = true
                            }
                    }
                    
                }
                
                //Imagen debajo del texto
                if self.imagePositionDonw {
                    if let imagen = self.imagen{
                        if self.ocultarImagen == false{
                            #if os(iOS)
                            Image(uiImage: imagen)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(width: self.TamañoImagen, height: self.TamañoImagen)
                                .clipped()
 
                            #elseif os(macOS)
                            Image(nsImage: imagen)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(width: self.TamañoImagen, height: self.TamañoImagen)
                                .clipped()
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    self.imagen = seleccionarImagen()
                                }
                                .help("Doble click para cambiar la imagen")
                            #endif
                                
                        }
                        
                    }
                }
            }
            .frame(width: self.tamañoLienzoAncho, height: self.tamañoLienzoAlto)
            .background{
                LinearGradient(colors: self.modelColorsFondo.coloresFondo , startPoint: .topLeading , endPoint: .bottomTrailing )
            }
            .cornerRadius(20)
            .padding(10)

            //Opciones
            VStack(spacing: 0) {
                        // Barra de pestañas horizontal
                HStack(spacing: 10) {
                            Spacer()
                            
                            Button("Fondo"){self.selectedOpcion = 0}
                            Button("Texto"){self.selectedOpcion = 1}
                            Button("Imagen"){self.selectedOpcion = 2}
                           
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.gray.opacity(0.7))
                        .cornerRadius(20)
                        
                        //Divider()
                        
                        // Contenido del panel
                        ZStack {
                            switch self.selectedOpcion {
                            case 0:
                                PanelOpcionesDeFondo()
                            case 1:
                                PanelOpcionesDeTexto()
                            case 2:
                                PanelOpcionesDeImagen()
                            default:
                                EmptyView()
                            }
                        }
                        //.animation(.easeInOut, value: selectedOpcion)
                    }
            .padding(20)
            /*
             VStack(alignment: .leading ,spacing: 5){
                 //Texto Primario
                 HStack{
                     Text("Texto Primario: ")
                     Slider(value: self.$TamañoPrimerTexto, in: 0...80)
                     .padding(.horizontal, 5)
                     .frame(width: 200)
                     
                 }
                 //Texto Secundario
                 HStack{
                     Text("Texto Secundario: ")
                     Slider(value: self.$TamañoSegundoTexto, in: 10...80)
                     .padding(.horizontal, 5)
                     .frame(width: 200)
                     Image(systemName: self.ocultarSegundoTexto ? "eye.slash" : "eye")
                         .onTapGesture {
                             self.ocultarSegundoTexto.toggle()
                         }.padding(.horizontal)
                 }
                 
                 
                 //Imagen
                 HStack{
                     Text("Imagen: ")
                     Slider(value: self.$TamañoImagen, in: 10...200)
                     .padding(.horizontal, 5)
                     .frame(width: 200)
                     Image(systemName: self.ocultarImagen ? "eye.slash" : "eye")
                         .onTapGesture {
                             self.ocultarImagen.toggle()
                         }.padding(.horizontal)
                 }
                 
                 
                 
                 //Boton Crear, compartir y guardar en descargas
                 HStack{
                     Button("Crear Imagen"){
                         imagenAExportar = renderViewAsImage(
                             LienzoMainExportar(
                                 textMain:               self.textMain,
                                 textSecundary:          self.textSecundary,
                                 tamañoLienzoAncho:      self.tamañoLienzoAncho,
                                 tamañoLienzoAlto:       self.tamañoLienzoAlto,
                                 imagenDebajo:           self.imagenDebajo,
                                 imagen:                 self.imagen,
                                 TamañoPrimerTexto:      self.TamañoPrimerTexto,
                                 TamañoSegundoTexto:     self.TamañoSegundoTexto,
                                 TamañoImagen:           self.TamañoImagen,
                                 ocultarSegundoTexto :   self.ocultarSegundoTexto,
                                 ocultarImagen :         self.ocultarImagen)
                         )
                     }
                     
                     if let imagen = self.imagenAExportar {
                         Spacer()
                         #if os(iOS)
                         ShareLink(item: Image(uiImage: imagen), preview: SharePreview("Mi tarjeta", image: Image(uiImage: imagen)))
                         #elseif os(macOS)
                         
                         ShareLink(item: Image(nsImage: imagen), preview: SharePreview("Mi tarjeta", image: Image(nsImage: imagen)))
                         
                         Button("Guardar en Descargas"){
                             guardarImagenEnDescargasConTimestamp(imagen)
                         }
                         .padding(.horizontal)
                         #endif
                         
                         
                     }
                     
                     
                 }
                 .padding(.top, 15)
                 .padding(.horizontal, 10)
                 
                 
             }
             */
            
            
            Spacer()
            
        }
        .onChange(of: self.TamañoPrimerTexto) { _, _  in
            self.imagenAExportar = nil
        }
        .onChange(of: self.TamañoSegundoTexto) { _, _  in
            self.imagenAExportar = nil
        }
        .onChange(of: self.TamañoImagen) { _, _  in
            self.imagenAExportar = nil
        }
    }
    
    
    //Paneles de opciones
    @ViewBuilder
    func  PanelOpcionesDeFondo() -> some View {
        VStack{
           //Mostrar varios degradados de fondo
            GradientGridView()
                .environmentObject(self.modelColorsFondo)
        }
    }
    
    @ViewBuilder
    func  PanelOpcionesDeTexto() -> some View {
        VStack{
            //Texto Primario
            HStack{
                Text("Texto Primario: ")
                Slider(value: self.$TamañoPrimerTexto, in: 0...80)
                .padding(.horizontal, 5)
                .frame(width: 200)
                
            }
            //Texto Secundario
            HStack{
                Text("Texto Secundario: ")
                Slider(value: self.$TamañoSegundoTexto, in: 10...80)
                .padding(.horizontal, 5)
                .frame(width: 200)
                
                Image(systemName: self.ocultarSegundoTexto ? "eye.slash" : "eye")
                    .onTapGesture {
                        withAnimation {
                            self.ocultarSegundoTexto.toggle()
                        }
                        
                    }.padding(.horizontal)
            }
        }
        .padding(20)
    }
    
    
    @ViewBuilder
    func  PanelOpcionesDeImagen() -> some View {
        VStack{
            
            HStack{
                Text("Posición:")
                
                Button(self.imagePositionDonw ? "Arriba del texto" : "Debajo del texto"){
                    withAnimation(.bouncy) {
                        imagePositionDonw.toggle()
                    }
                }
                
                
            }
            
            HStack{
                Text("Tamaño: ")
                Slider(value: self.$TamañoImagen, in: 10...200)
                .padding(.horizontal, 5)
                .frame(width: 200)
                Image(systemName: self.ocultarImagen ? "eye.slash" : "eye")
                    .onTapGesture {
                        withAnimation {
                            self.ocultarImagen.toggle()
                        }
                       
                    }.padding(.horizontal)
            }
            
            //Cambiar la imagen por una en la galeria:iOS
            #if os(iOS)
            VStack{
                PhotosPicker(
                    selection: $photosPicker.selectedItem, //La imagen se toma del viewModel
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Cargar imagen de la galería...")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.white)
                            .background(.blue)
                            .cornerRadius(8)
                    }
                    .font(.headline)
            }
            .onChange(of: photosPicker.selectedItem) { _, _ in
                photosPicker.loadImage()
            }
            .onChange(of: photosPicker.selectedImage) { _, nueva in
                if let nueva = nueva {
                    self.imagen = nueva
                }
            }
            #endif
            
            #if os(macOS)
            //Cambiar la imagen
            VStack{
                Button("Cambiar Imagen...") {
                    self.imagen = seleccionarImagen()
                }
            }
            #endif
            
        }
        .padding(20)
    }
    
    
}



@ViewBuilder
func  LienzoMainExportar(
    textMain:           String,
    textSecundary:      String,
    tamañoLienzoAncho : CGFloat,
    tamañoLienzoAlto :  CGFloat,
    imagenDebajo:       Bool,
    imagen:             UIImage?,
    TamañoPrimerTexto:  CGFloat,
    TamañoSegundoTexto: CGFloat,
    TamañoImagen:       CGFloat,
    ocultarSegundoTexto:Bool,
    ocultarImagen :     Bool,
    coloresFondo:       [Color]
) -> some View {
//Área útil: la que se va a compartir
    VStack(alignment: .center, spacing: 3){
        
        Spacer()
        
        if imagenDebajo{
            Text(textMain)
                .font(.system(size: TamañoPrimerTexto))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
            
            if ocultarSegundoTexto == false{
                Text(textSecundary)
                    .font(.system(size: TamañoSegundoTexto))
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if let imagen = imagen{
                if ocultarImagen == false{
                    #if os(iOS)
                    Image(uiImage: imagen)
                        .resizable()
                        .scaledToFill()
                        .frame(width: TamañoImagen, height: TamañoImagen)
                    #elseif os(macOS)
                    Image(nsImage: imagen)
                        .resizable()
                        .scaledToFill()
                        .frame(width: TamañoImagen, height: TamañoImagen)
                    #endif
                }
                
            }
        }else{
            if let imagen = imagen{
                if ocultarImagen == false{
                    #if os(iOS)
                    Image(uiImage: imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(width: TamañoImagen, height: TamañoImagen)
                    #elseif os(macOS)
                    Image(nsImage: imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(width: TamañoImagen, height: TamañoImagen)
                    #endif
                }
            }
            Text(textMain)
                .font(.largeTitle)
                .padding()
            
            if ocultarSegundoTexto == false{
                Text(textSecundary)
                    .font(.title2)
                    .padding()
            }
        }
        
        Spacer()
        
    }
    .frame(width: tamañoLienzoAncho, height: tamañoLienzoAlto + 100)
    .background{
        LinearGradient(colors: coloresFondo, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    .cornerRadius(20)
    
}







