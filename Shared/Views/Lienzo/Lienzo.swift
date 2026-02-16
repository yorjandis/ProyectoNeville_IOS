import SwiftUI
#if os(iOS)
import PhotosUI
//import UniformTypeIdentifiers
#endif


struct LienzoMain: View {
    
    @StateObject private var lienzoModel : LienzoModel = .shared //ViewModel para el Lienzo
    //@StateObject private var purchasePremium : PurchaseManager = .shared
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    let texto: String? //Si se da,  se coloca este texto en el texto principal. Para importar frase o nota
    


    //Almacena la imagen a exportar:
    @State private var imagenAExportar : UIImage?
    
 
    //Edición de texto para Texto Principal & Texto Secundario
    @State private var editarTextoPrincipal: Bool = false
    @State private var editarTextoSecundario: Bool = false
    

    //Para el panel de opciones:
    @State private var selectedOpcion: Int = 0 //Pestaña de opciones seleccionada
   
    //Alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    

    #if os(iOS)
    //Para seleccionar una imagen de la galería: ImagenLienzo Principal
    @StateObject private var photosPicker = ImagePickerViewModel()
    //Para mostrar el selector de imagen dentro del context menu de la imagen en iOS:
    @State private var mostrarPicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    //Para seleccionar una imagen de la galería: ImagenLienzo Secundario
    @StateObject private var photosPickerImagenLienzoSecundario = ImagePickerViewModel()
    //Para mostrar el selector de imagen dentro del context menu de la imagen en iOS:
    @State private var mostrarPickerImagenLienzoSecundario = false
    @State private var selectedItemImagenLienzoSecundario: PhotosPickerItem?
    
    #endif
    
    //Aplicando la imagen de fondo:
    @AppStorage(LienzoModel.key_imagenFondoAplicada) var imagenFondoAplicada: Bool = false
    
    var body: some View {
        
        if self.purchaseStatus {
            VStack{
                
                //Área útil: la que se va a compartir
                VStack(alignment: .center, spacing: 3){
                    
                    //Primera fila
                    HStack{
                        VStack(){
                            HStack{
                                if lienzoModel.posicionImagenLienzoSecundario == .arriba {
                                    if lienzoModel.visibilidadImagenLienzoSecundario{
                                       ImagenLienzoSecundario()
                                    }
                                    
                                }
                                if lienzoModel.posicionImagenLienzo == .arriba {
                                    if lienzoModel.visibilidadImagenLienzo{
                                        ImagenLienzo()
                                    }
                                    
                                }
                            }
                            
                            
                            if lienzoModel.posicionTextoPrincipal == .arriba{
                                TextoPrincipal()
                            }
                            
                            if lienzoModel.posicionTextoSecundario == .arriba{
                                if lienzoModel.visibilidadTextoSecundario{
                                    TextoSecundario()
                                }
                            }
                            
                        }
                        
                    }
                    
                    //Segunda fila
                    HStack{
                        
                        VStack{
                            VStack{
                                if lienzoModel.posicionImagenLienzo == .izquierda {
                                    if lienzoModel.visibilidadImagenLienzo{
                                        ImagenLienzo()
                                    }
                                    
                                }
                                if lienzoModel.posicionImagenLienzoSecundario == .izquierda {
                                    if lienzoModel.visibilidadImagenLienzoSecundario{
                                       ImagenLienzoSecundario()
                                    }
                                    
                                }
                            }
                            if lienzoModel.posicionTextoPrincipal == .izquierda{
                                TextoPrincipal()
                            }
                            
                            if lienzoModel.posicionTextoSecundario == .izquierda{
                                if lienzoModel.visibilidadTextoSecundario{
                                    TextoSecundario()
                                }
                            }
                            
                        }
                        
                        VStack{
                            if lienzoModel.posicionTextoPrincipal == .centro{
                                TextoPrincipal()
                            }
                            
                            if lienzoModel.posicionTextoSecundario == .centro{
                                if lienzoModel.visibilidadTextoSecundario{
                                    TextoSecundario()
                                }
                            }
                        }
                        
                        VStack{
                            
                            HStack{
                                if lienzoModel.posicionImagenLienzo == .derecha {
                                    if lienzoModel.visibilidadImagenLienzo{
                                        ImagenLienzo()
                                    }
                                    
                                }
                                
                                if lienzoModel.posicionImagenLienzoSecundario == .derecha {
                                    if lienzoModel.visibilidadImagenLienzoSecundario{
                                       ImagenLienzoSecundario()
                                    }
                                    
                                }
                            }
                            
                            if lienzoModel.posicionTextoPrincipal == .derecha{
                                TextoPrincipal()
                            }
                            
                            if lienzoModel.posicionTextoSecundario == .derecha{
                                if lienzoModel.visibilidadTextoSecundario{
                                    TextoSecundario()
                                }
                            }
                        }
                        
                        
                    }
                    
                    //Tercera fila
                    HStack{
                        VStack(){
                            
                            if lienzoModel.posicionTextoPrincipal == .abajo{
                                TextoPrincipal()
                            }
                            
                            if lienzoModel.posicionTextoSecundario == .abajo{
                                if lienzoModel.visibilidadTextoSecundario{
                                    TextoSecundario()
                                }
                            }
                            
                            HStack{
                                if lienzoModel.posicionImagenLienzoSecundario == .abajo {
                                    if lienzoModel.visibilidadImagenLienzoSecundario{
                                       ImagenLienzoSecundario()
                                    }
                                    
                                }
                                if lienzoModel.posicionImagenLienzo == .abajo {
                                    if lienzoModel.visibilidadImagenLienzo{
                                        ImagenLienzo()
                                    }
                                    
                                }
                            }
                            
                        }
                    }
                    
                    
                }
                .frame(width: lienzoModel.tamañoLienzoAncho, height: lienzoModel.tamañoLienzoAlto)
                .background{
                    //Fondo
                    if self.imagenFondoAplicada {
                        #if os(macOS)
                        Image(nsImage: lienzoModel.obtenerImagenFondo() ?? NSImage(named: "fondo")!)
                            .resizable()
                            .scaledToFill()
                        #else
                        Image(uiImage: lienzoModel.obtenerImagenFondo() ?? UIImage(named: "fondo")!)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            
                        #endif
                        
                    }else{
                        LinearGradient(colors: [self.lienzoModel.coloresFondo1, self.lienzoModel.coloresFondo2] , startPoint: .topLeading , endPoint: .bottomTrailing )
                    }
                    
                }
                .cornerRadius(20)
                .padding(20)
                .task {
                    if let textotmp = self.texto{
                        if !textotmp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                            lienzoModel.textoPrincipal = textotmp
                            self.lienzoModel.visibilidadTextoSecundario = false
                        }
                        
                    }
                }

                //Panel de Opciones
                VStack(spacing: 0) {
                            // Barra de pestañas horizontal
                    HStack(spacing: 10) {
                        Spacer()
                        
                        Button("Fondo"){self.selectedOpcion = 0}
                            .foregroundStyle(self.selectedOpcion == 0 ? .black : .primary)
                            .padding(5)
                            .contentShape(Rectangle())
                            .background( RoundedRectangle(cornerRadius: 15)
                                .fill(self.selectedOpcion == 0 ? .orange : .gray))
                            .buttonStyle(.plain)
                            
                            
                            
                        Button("Texto"){self.selectedOpcion = 1}
                            .foregroundStyle(self.selectedOpcion == 1 ? .black : .primary)
                            .padding(5)
                            .contentShape(Rectangle())
                            .background( RoundedRectangle(cornerRadius: 15)
                                .fill(self.selectedOpcion == 1 ? .orange : .gray))
                            .buttonStyle(.plain)
                        
                        Button("Imagen"){self.selectedOpcion = 2}
                            .foregroundStyle(self.selectedOpcion == 2 ? .black : .primary)
                            .padding(5)
                            .contentShape(Rectangle())
                            .background( RoundedRectangle(cornerRadius: 15)
                                .fill(self.selectedOpcion == 2 ? .orange : .gray))
                            .buttonStyle(.plain)
                        
                        //Botón Exportar imagen:
                        Button{
                            Task{
                                self.imagenAExportar =  renderViewAsImage(LienzoMainExportar())
                                self.selectedOpcion = 3
                            }
                           
                        }label: {
                            Text("Exportar")
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
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
                                case 3:
                                    PanelOpcionesExportacion()
                                default:
                                    EmptyView()
                                }
                            }
                            //.animation(.easeInOut, value: selectedOpcion)
                        }
                .padding(20)
                
                Spacer()
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Lienzo"), message: Text(self.alertMessage), dismissButton: .default(Text("OK")))
            }
        }else{
            PurchaseView()
        }
        
        
    }
    
    
    //Paneles de opciones
    @ViewBuilder
    func  PanelOpcionesDeFondo() -> some View {
        VStack{
           //Mostrar varios degradados de fondo
            Lienzo_Fondo()
                .environmentObject(self.lienzoModel)
        }
    }
    
    
    //Panel de opciones de texto
    @ViewBuilder
    func  PanelOpcionesDeTexto() -> some View {
        ScrollView(.vertical, showsIndicators: false){
            VStack(spacing: 20){
                Picker("Posición de Texto Principal", selection: $lienzoModel.posicionTextoPrincipal.animation()) {
                    ForEach(PosicionElemento.allCases) { posicion in
                            Text(posicion.rawValue).tag(posicion)
                    }
                }
                .pickerStyle(.segmented)
                
                ColorPicker("Color Texto Principal", selection: $lienzoModel.colorTextoPrincipal)
                
                
                HStack{
                    Text("Tamaño Texto Primario: ")
                    Slider(value: $lienzoModel.tamañoTextoPrincipal, in: 0...80)
                    .padding(.horizontal, 5)
                    .frame(width: 200)
                }
                
                
                
                //Texto Secundario
                
                Picker("Posición de Texto Secundario", selection: $lienzoModel.posicionTextoSecundario.animation()) {
                    ForEach(PosicionElemento.allCases) { posicion in
                            Text(posicion.rawValue).tag(posicion)
                    }
                }
                .pickerStyle(.segmented)
                
                ColorPicker("Color Texto Secundario", selection: $lienzoModel.colorTextoSecundario)
                
                HStack{
                    Text("Tamaño Texto Secundario: ")
                    Slider(value: $lienzoModel.tamañoTextoSecundario, in: 10...80)
                    .padding(.horizontal, 5)
                    .frame(width: 200)
                    
                    Image(systemName: lienzoModel.visibilidadTextoSecundario ? "eye" : "eye.slash")
                        .foregroundStyle(lienzoModel.visibilidadTextoSecundario ? .primary : Color.orange)
                        .onTapGesture {
                            withAnimation {
                                lienzoModel.visibilidadTextoSecundario.toggle()
                            }
                            
                        }.padding(.horizontal)
                }
                
                
                VStack(alignment: .leading){
                    Text("Tip: Doble tap/click sobre el texto, en el lienzo, para editarlo")
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .padding(20)
            
            
        }
        
    }
    
    
    @ViewBuilder
    func  PanelOpcionesDeImagen() -> some View {
        VStack(alignment: .leading ,spacing: 25){
            ScrollView(.vertical, showsIndicators: false) {
                
                //Area de la Imagen de Lienzo Principal
                VStack{
                    Text("Imagen Principal:")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                    //Posición de la Imagen Lienzo Principal
                    HStack{
                        Picker("Posición de Imagen", selection: $lienzoModel.posicionImagenLienzo.animation()) {
                            ForEach(PosicionElemento.allCases) { posicion in
                                if posicion != .centro {
                                    Text(posicion.rawValue).tag(posicion)
                                }
                                
                            }
                        }
                        .pickerStyle(.segmented)
                        
                    }
                    
                    //Tamaño imagen Lienzo Principal
                    HStack{
                        Text("Tamaño: ")
                        Slider(value: $lienzoModel.tamañoImagenLienzo, in: 10...200)
                        .padding(.horizontal, 5)
                        .frame(width: 200)
                        
                        Image(systemName: lienzoModel.visibilidadImagenLienzo ? "eye" : "eye.slash")
                            .foregroundStyle(lienzoModel.visibilidadImagenLienzo ? .primary : Color.orange)
                            .onTapGesture {
                                withAnimation {
                                    lienzoModel.visibilidadImagenLienzo.toggle()
                                }
                               
                            }.padding(.horizontal)
                    }
                    
                    //Cambiar la imagen lienzo Principal por una en la galeria:iOS
                    #if os(iOS)
                    VStack(alignment: .leading){
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
                        Spacer()
                      
                    }
                    .onChange(of: photosPicker.selectedItem) { _, _ in
                        photosPicker.loadImage()
                    }
                    .onChange(of: photosPicker.selectedImage) { _, nueva in
                        if let nueva = nueva {
                            lienzoModel.imagenLienzo = nueva
                        }
                    }
                    
                    //Escoger una imagen de lienzo Principal Predeterminada: neville, addulhall, William Blake
                    VStack(alignment: .leading, spacing: 20){
                        Text("Imágines predeterminadas")
                        HStack(spacing: 10){
                            
                            Image(uiImage: UIImage(named: "nev-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                lienzoModel.imagenLienzo = UIImage(named: "nev-min")!
                            }
                                
                            
                            Image(uiImage: UIImage(named: "ad-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "ad-min")!
                                }
                            Image(uiImage: UIImage(named: "william")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "william")!
                                }
                            Image(nsImage: UIImage(named: "jd-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "jd-min")!
                                }
                            Image(nsImage: UIImage(named: "bruce-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "bruce-min")!
                                }
                             
                        }
                    }
                    .padding(.vertical, 10)
                    
                    #endif
                    
                    #if os(macOS)
                    //Cambiar la imagen de lienzo Principal
                    VStack{
                        Button("Cambiar Imagen...") {
                            if let image = seleccionarImagen(){
                                lienzoModel.imagenLienzo = image
                            }else{
                                lienzoModel.imagenLienzo = UIImage(named: "nev-min")!
                            }
                           
                        }
                    }
                    
                    //Escoger una imagen de lienzo Principal Predeterminada: neville, addulhall, William Blake
                    VStack(spacing: 20){
                        Text("Imágines predeterminadas")
                        HStack(spacing: 10){
                            
                            Image(nsImage: UIImage(named: "nev-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                lienzoModel.imagenLienzo = UIImage(named: "nev-min")!
                            }
                                
                            
                            Image(nsImage: UIImage(named: "ad-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "ad-min")!
                                }
                            Image(nsImage: UIImage(named: "william")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "william")!
                                }
                            Image(nsImage: UIImage(named: "jd-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "jd-min")!
                                }
                            Image(nsImage: UIImage(named: "bruce-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzo = UIImage(named: "bruce-min")!
                                }
                             
                        }
                    }
                    .padding(.vertical, 15)
                    
                    #endif
                }
                
                
                //Area de la imagen de Lienzo Secundario:
                VStack{
                    Text("Imagen Secundaria:")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                    //Posición de la Imagen Lienzo Secundario
                    HStack{
                        Picker("Posición de Imagen", selection: $lienzoModel.posicionImagenLienzoSecundario.animation()) {
                            ForEach(PosicionElemento.allCases) { posicion in
                                if posicion != .centro {
                                    Text(posicion.rawValue).tag(posicion)
                                }
                                
                            }
                        }
                        .pickerStyle(.segmented)
                        
                    }
                    
                    //Tamaño imagen Lienzo secundario
                    HStack{
                        Text("Tamaño: ")
                        Slider(value: $lienzoModel.tamañoImagenLienzoSecundario, in: 10...200)
                        .padding(.horizontal, 5)
                        .frame(width: 200)
                        
                        Image(systemName: lienzoModel.visibilidadImagenLienzoSecundario ? "eye" : "eye.slash")
                            .foregroundStyle(lienzoModel.visibilidadImagenLienzoSecundario ? .primary : Color.orange)
                            .onTapGesture {
                                withAnimation {
                                    lienzoModel.visibilidadImagenLienzoSecundario.toggle()
                                }
                               
                            }.padding(.horizontal)
                    }
                    
                    //Cambiar la imagen lienzo Secundario por una en la galeria:iOS
                    #if os(iOS)
                    VStack(alignment: .leading){
                        PhotosPicker(
                            selection: $photosPickerImagenLienzoSecundario.selectedItemImagenSecundaria, //La imagen se toma del viewModel
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
                        Spacer()
                      
                    }
                    .onChange(of: photosPickerImagenLienzoSecundario.selectedItemImagenSecundaria) { _, _ in
                        photosPickerImagenLienzoSecundario.loadImageSecundaria()
                    }
                    .onChange(of: photosPickerImagenLienzoSecundario.selectedImageImageSecundaria) { _, nueva in
                        if let nueva = nueva {
                            lienzoModel.imagenLienzoSecundario = nueva
                        }
                    }
                    
                    //Escoger una imagen de lienzo Secundario Predeterminada: neville, addulhall, William Blake
                    VStack(alignment: .leading, spacing: 20){
                        Text("Imágines predeterminadas")
                        HStack(spacing: 10){
                            
                            Image(uiImage: UIImage(named: "nev-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                lienzoModel.imagenLienzoSecundario = UIImage(named: "nev-min")!
                            }
                                
                            
                            Image(uiImage: UIImage(named: "ad-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzoSecundario = UIImage(named: "ad-min")!
                                }
                            Image(uiImage: UIImage(named: "william")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzoSecundario = UIImage(named: "william")!
                                }
                             
                        }
                    }
                    .padding(.vertical, 10)
                    VStack(alignment: .leading){
                        Text("Tip: Click sostenido sobre la imagen para cambiarla")
                    }
                   
                    
                    
                    #endif
                    
                    #if os(macOS)
                    //Cambiar la imagen de lienzo Secundario
                    VStack{
                        Button("Cambiar Imagen...") {
                            if let image = seleccionarImagen(){
                                lienzoModel.imagenLienzoSecundario = image
                            }else{
                                lienzoModel.imagenLienzoSecundario = UIImage(named: "nev-min")!
                            }
                           
                        }
                    }
                    
                    //Escoger una imagen de lienzo Secundario Predeterminada: neville, addulhall, William Blake
                    VStack(spacing: 20){
                        Text("Imágines predeterminadas")
                        HStack(spacing: 10){
                            
                            Image(nsImage: UIImage(named: "nev-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                lienzoModel.imagenLienzoSecundario = UIImage(named: "nev-min")!
                            }
                                
                            
                            Image(nsImage: UIImage(named: "ad-min")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzoSecundario = UIImage(named: "ad-min")!
                                }
                            Image(nsImage: UIImage(named: "william")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    lienzoModel.imagenLienzoSecundario = UIImage(named: "william")!
                                }
                             
                        }
                    }
                    .padding(.vertical, 15)
                    
                    #endif
                }
                .padding(.top, 20)
                
                
            }
            
        }
        .padding(20)
    }
    
    
    //Panel de opciones de Exportación:
    @ViewBuilder
    func PanelOpcionesExportacion()-> some View{
        VStack(spacing: 20){
            #if os(macOS)
            //Botón para guadar la imagen en la carpeta descargas
            Button("Guardar Imagen en Descargas..."){
                if self.imagenAExportar != nil {
                    guardarImagenEnDescargasConTimestamp(self.imagenAExportar!)
                    self.alertMessage = "La imagen se ha guardado en Descargas"
                    self.showAlert = true
                }
            }
            
            //Botón para compartir la imagen
            if let image = imagenAExportar,
               let fileURL = exportImageToTempURL(image) {
                ShareLink(item: fileURL, preview: SharePreview("Mi Imagen", image: Image(nsImage: image))) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
            
            #else
            //Botón guadar la imagen en la galaria: iOS
            Button("Guardar imagen en la galería..."){
                if self.imagenAExportar != nil {
                    Task{ 
                        do{
                            try await saveImageToGallery(self.imagenAExportar!)
                            self.alertMessage = "La imagen se ha guardado en la galería"
                            self.showAlert = true
                        }catch{
                            msg(error.localizedDescription)
                        }
                     
                    }
                   
                }
            }
            .buttonStyle(.bordered)
            //botón compartir la imagen: iOS
            if let image = imagenAExportar,
               let fileURL = exportImageToTempURL(image) {
                ShareLink(item: fileURL, preview: SharePreview("Mi Imagen", image: Image(uiImage: image))) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
            }
            
            #endif
           
        }
        .padding(20)
        
    }
    
    
    //Elementos de la intefaz
    @ViewBuilder
    func ImagenLienzo()-> some View{
    #if os(iOS)
        Image(uiImage: lienzoModel.imagenLienzo ?? UIImage(named: "nev-min")! )
    .resizable()
    .scaledToFit()
    .cornerRadius(5)
    .frame(width: lienzoModel.tamañoImagenLienzo, height: lienzoModel.tamañoImagenLienzo)
    .clipped()
    .contextMenu{
        Button("Cambiar Imagen..."){
            self.mostrarPicker = true
        }
        
    }
    .photosPicker(
                isPresented: $mostrarPicker,
                selection: $selectedItem,
                matching: .images
            )
    .onChange(of: selectedItem) { old, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        lienzoModel.imagenLienzo = uiImage
                    }
                }
    }

    #elseif os(macOS)
        Image(nsImage: lienzoModel.imagenLienzo ?? UIImage(named: "nev-min")! )
    .resizable()
    .scaledToFit()
    .cornerRadius(5)
    .frame(width: lienzoModel.tamañoImagenLienzo, height: lienzoModel.tamañoImagenLienzo)
    .clipped()
    .contentShape(Rectangle())
    .onTapGesture(count: 2) {
        if let image = lienzoModel.imagenLienzo{
            lienzoModel.imagenLienzo = image
        }else{
            lienzoModel.imagenLienzo = NSImage(named: "nev-min")
        }
    }
    .help("Doble click para cambiar la imagen")
    #endif
    }
    
    
    @ViewBuilder
    func ImagenLienzoSecundario()-> some View{
    #if os(iOS)
        Image(uiImage: lienzoModel.imagenLienzoSecundario ?? UIImage(named: "nev-min")! )
    .resizable()
    .scaledToFit()
    .cornerRadius(5)
    .frame(width: lienzoModel.tamañoImagenLienzoSecundario, height: lienzoModel.tamañoImagenLienzoSecundario)
    .clipped()
    .contextMenu{
        Button("Cambiar Imagen..."){
            self.mostrarPickerImagenLienzoSecundario = true
        }
    }
    .photosPicker(
                isPresented: $mostrarPickerImagenLienzoSecundario,
                selection: $selectedItemImagenLienzoSecundario,
                matching: .images
            )
    .onChange(of: selectedItemImagenLienzoSecundario) { old, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        lienzoModel.imagenLienzoSecundario = uiImage
                    }
                }
    }

    #elseif os(macOS)
        Image(nsImage: lienzoModel.imagenLienzoSecundario ?? UIImage(named: "nev-min")! )
    .resizable()
    .scaledToFit()
    .cornerRadius(5)
    .frame(width: lienzoModel.tamañoImagenLienzoSecundario, height: lienzoModel.tamañoImagenLienzoSecundario)
    .clipped()
    .contentShape(Rectangle())
    .onTapGesture(count: 2) {
        if let image = lienzoModel.imagenLienzoSecundario{
            lienzoModel.imagenLienzoSecundario = image
        }else{
            lienzoModel.imagenLienzoSecundario = NSImage(named: "nev-min")
        }
    }
    .help("Doble click para cambiar la imagen")
    #endif
    }
    
    
    @ViewBuilder
    func TextoPrincipal()-> some View{
        
        if self.editarTextoPrincipal{
            TextoPrincipalEditor()
        }else{
            Text(lienzoModel.textoPrincipal)
                .font(.system(size: lienzoModel.tamañoTextoPrincipal))
                .foregroundStyle(lienzoModel.colorTextoPrincipal)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .onTapGesture(count: 2) {
                    self.editarTextoPrincipal = true
                }
                .contextMenu{
                    Button("QR code del texto"){
                        if let image =  self.lienzoModel.obtenerImagenQR(texto: lienzoModel.textoPrincipal){
                            self.lienzoModel.imagenLienzoSecundario = image
                        }
                    }
                }
        }
        
        
    }
    
    @ViewBuilder
    func TextoPrincipalEditor()-> some View{
        VStack{
            TextEditor(text: $lienzoModel.textoPrincipal)
                .font(.system(size: 22))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(20)
                
            Button{
                if lienzoModel.textoPrincipal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                    lienzoModel.textoPrincipal = "Imaginar Crea La Realidad"
                }
                self.editarTextoPrincipal = false
            }label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
            }
            .foregroundStyle(.green)
        }
    }
    
    @ViewBuilder
    func TextoSecundario()-> some View{
        
        if editarTextoSecundario {
            TextoSecundarioEditor()
        }else{
            Text(lienzoModel.textoSecundario)
                .font(.system(size: lienzoModel.tamañoTextoSecundario))
                .foregroundStyle(lienzoModel.colorTextoSecundario)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .padding()
                .onTapGesture(count: 2) {
                    self.editarTextoSecundario = true
                }
                .contextMenu{
                    Button("QR code del texto"){
                        if let image =  self.lienzoModel.obtenerImagenQR(texto: lienzoModel.textoSecundario){
                            self.lienzoModel.imagenLienzoSecundario = image
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    func TextoSecundarioEditor()-> some View{
        VStack{
            TextEditor(text: $lienzoModel.textoSecundario)
                .font(.system(size: 22))
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .cornerRadius(20)
            Button{
                if lienzoModel.textoSecundario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                    lienzoModel.textoSecundario = "Si imaginas y sientes un estado ningún poder el mundo impedirá su manifestación"
                }
                self.editarTextoSecundario = false
            }label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
            }
            .foregroundStyle(.green)
        }
    }
    
    
    
    //PLantilla de exportación. Debe recrear los mismos elementos que la plantilla de prueba.
    @ViewBuilder
    func  LienzoMainExportar() -> some View {
    //Área útil: la que se va a compartir
        VStack(alignment: .center, spacing: 3){
            //Primera fila
            HStack{
                VStack(){
                    HStack{
                        if lienzoModel.posicionImagenLienzoSecundario == .arriba {
                            if lienzoModel.visibilidadImagenLienzoSecundario{
                               ImagenLienzoSecundario()
                            }
                            
                        }
                        if lienzoModel.posicionImagenLienzo == .arriba {
                            if lienzoModel.visibilidadImagenLienzo{
                                ImagenLienzo()
                            }
                            
                        }
                    }
                    
                    
                    if lienzoModel.posicionTextoPrincipal == .arriba{
                        TextoPrincipal()
                    }
                    
                    if lienzoModel.posicionTextoSecundario == .arriba{
                        if lienzoModel.visibilidadTextoSecundario{
                            TextoSecundario()
                        }
                    }
                    
                }
                
            }
            
            //Segunda fila
            HStack{
                
                VStack{
                    VStack{
                        if lienzoModel.posicionImagenLienzo == .izquierda {
                            if lienzoModel.visibilidadImagenLienzo{
                                ImagenLienzo()
                            }
                            
                        }
                        if lienzoModel.posicionImagenLienzoSecundario == .izquierda {
                            if lienzoModel.visibilidadImagenLienzoSecundario{
                               ImagenLienzoSecundario()
                            }
                            
                        }
                    }
                    if lienzoModel.posicionTextoPrincipal == .izquierda{
                        TextoPrincipal()
                    }
                    
                    if lienzoModel.posicionTextoSecundario == .izquierda{
                        if lienzoModel.visibilidadTextoSecundario{
                            TextoSecundario()
                        }
                    }
                    
                }
                
                VStack{
                    if lienzoModel.posicionTextoPrincipal == .centro{
                        TextoPrincipal()
                    }
                    
                    if lienzoModel.posicionTextoSecundario == .centro{
                        if lienzoModel.visibilidadTextoSecundario{
                            TextoSecundario()
                        }
                    }
                }
                
                VStack{
                    
                    HStack{
                        if lienzoModel.posicionImagenLienzo == .derecha {
                            if lienzoModel.visibilidadImagenLienzo{
                                ImagenLienzo()
                            }
                            
                        }
                        
                        if lienzoModel.posicionImagenLienzoSecundario == .derecha {
                            if lienzoModel.visibilidadImagenLienzoSecundario{
                               ImagenLienzoSecundario()
                            }
                            
                        }
                    }
                    
                    if lienzoModel.posicionTextoPrincipal == .derecha{
                        TextoPrincipal()
                    }
                    
                    if lienzoModel.posicionTextoSecundario == .derecha{
                        if lienzoModel.visibilidadTextoSecundario{
                            TextoSecundario()
                        }
                    }
                }
                
                
            }
            
            //Tercera fila
            HStack{
                VStack(){
                    
                    if lienzoModel.posicionTextoPrincipal == .abajo{
                        TextoPrincipal()
                    }
                    
                    if lienzoModel.posicionTextoSecundario == .abajo{
                        if lienzoModel.visibilidadTextoSecundario{
                            TextoSecundario()
                        }
                    }
                    
                    HStack{
                        if lienzoModel.posicionImagenLienzoSecundario == .abajo {
                            if lienzoModel.visibilidadImagenLienzoSecundario{
                               ImagenLienzoSecundario()
                            }
                            
                        }
                        if lienzoModel.posicionImagenLienzo == .abajo {
                            if lienzoModel.visibilidadImagenLienzo{
                                ImagenLienzo()
                            }
                            
                        }
                    }
                    
                }
            }
        }
        .frame(width: lienzoModel.tamañoLienzoAncho, height: lienzoModel.tamañoLienzoAlto)
        .background{
            //Fondo
            if self.imagenFondoAplicada {
                #if os(macOS)
                Image(nsImage: lienzoModel.obtenerImagenFondo() ?? NSImage(named: "fondo")!)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: lienzoModel.obtenerImagenFondo() ?? UIImage(named: "fondo")!)
                    .resizable()
                    .scaledToFill()
                #endif
                
            }else{
                LinearGradient(colors: [self.lienzoModel.coloresFondo1, self.lienzoModel.coloresFondo2] , startPoint: .topLeading , endPoint: .bottomTrailing )
            }
        }
        .cornerRadius(20)
        
    }
    
    
   
}











