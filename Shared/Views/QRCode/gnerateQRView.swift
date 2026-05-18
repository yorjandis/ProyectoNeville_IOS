//
//  gnerateQR.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Muestra una imagen con un pie de página

import SwiftUI
import PhotosUI
#if os(macOS)
import AppKit
#endif



struct GenerateQRView : View {
    
    //@StateObject private var purchasePremium : PurchaseManager = .shared
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @State var  footer : String = ""
    
    @State  var title : String = "Toque el texto para modificarlo"
    
    //Para importar una imagen de la galeria
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage : UIImage? //La image que se ha leído de la galeria
    
    @State  var  showImage = true //muestra la imagen del QR ya generado
    
    //Para manejar el botón y el fomrato de importación de notas
    @State private var showImportButtonNotas    : Bool = false
    @State private var formatImportNotas        : (String, String, Bool)? = nil
    
    //Para manejar el botón y el fomrato de importación de frase
    @State private var showImportButtonFrase    : Bool = false
    @State private var formatImportFrase        : String? = nil
    @State private var formatImportFraseAutor   : String? = nil
    @State private var formatImportFraseNota    : String? = nil
    @State private var formatImportFraseisFav   : Bool = false
    
    
    
    @FocusState private var focusState : Bool //Para ocultar el teclado
    
    #if os(iOS)
    @State private var imagen : UIImage? = UIImage(systemName: "qrcode")
    #endif
    
    #if os(macOS)
    @State private var imagen : UIImage? = UIImage(systemSymbolName: "qrcode", accessibilityDescription: nil)
    
    #endif
    @State private var showAlert = false
    @State private var alertMessage: String = ""
    
    
   //UIImage(data: QRModel().generateQRCode(text: string)!)!
    
    var body: some View {
        
        if (self.purchaseStatus || self.yorjPremium){
            NavigationStack{
                ZStack{
                    LinearGradient(colors: [.black.opacity(0.5), .brown.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 10){
                        Text(title)
                            .padding(5)
                            .padding(.top, 25)
                        Divider()
                        if showImage {
                            #if os(iOS)
                            if self.focusState == false{ //Oculta la imagen mientras se escribe en el textField
                                Image(uiImage: imagen!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300 )
                                    .onTapGesture {
                                        focusState = false
                                    }
                                    .contextMenu {
                                        
                                        ShareLink( item: Image(uiImage: imagen!),
                                                        preview: SharePreview("Compartir",
                                                            image: Image(systemName: "book")
                                                        )
                                         )
                                        
                                        if self.footer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false{
                                            
                                            Button("Guardar en Frases"){
                                                if FrasesModel.shared.AddFrase(frase: footer, autor: "personal") == false{
                                                    self.alertMessage = "Error el guardar en Frases"
                                                    self.showAlert = true
                                                }
                                            }
                                            //Muestra la opción de guardar en notas si el texto del QR no tiene un formato de importación
                                            if self.formatImportNotas == nil{
                                                Button("Guardar en Notas"){
                                                   
                                                    _ = NotasModel().addNote(nota: footer, title: "\(String(String(footer).prefix(footer.count / 3 )))...")
                                                }
                                            }
                                            
                                            if self.formatImportNotas == nil{
                                                Button("Formato de Nota"){
                                                        let result = "nota>>NuevaNotaQR>>\(self.footer)>>no"
                                                        self.footer = result
                                                        imagen = getImageQR()
                                                        showImage = true
                                                        focusState = false
                                                }
                                            }
                                        }
                                    }
                            }
                            
                            
                            #elseif os(macOS)
                                Image(nsImage: imagen!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300 )
                                .onTapGesture {
                                    focusState = false
                                }
                                .contextMenu {
                                    
                                    ShareLink( item: Image(nsImage: imagen!),
                                                    preview: SharePreview("Compartir",
                                                        image: Image(systemName: "book")
                                                    )
                                     )
                                    Button("Guardar en Frases"){
                                        if FrasesModel.shared.AddFrase(frase: footer, autor: "personal") == false{
                                            self.alertMessage = "No se pudo guardar la frase"
                                            self.showAlert = true
                                        }
                                    }
                                    Button("Guardar en Notas"){
                                        _ = NotasModel().addNote(nota: footer, title: "\(String(String(footer).prefix(footer.count / 3 )))...")
                                    }
                                    
                                    if self.formatImportNotas == nil{
                                        Button("Formato de Nota"){
                                            let result = "\(AppCons.zspNota)NuevaNotaQR::\(self.footer)::no"
                                                self.footer = result
                                                imagen = getImageQR()
                                                showImage = true
                                                focusState = false
                                        }
                                    }
                                    
                                    
                                }
                                #endif
                                
                        }
                       
                            TextField("Escriba un texto...!", text: $footer, axis: .vertical)
                                .font(.title2)
                                .padding(.horizontal, 10)
                                .lineLimit(12)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .padding(.top, 20)
                                .focused($focusState)
                                .onTapGesture {
                                    withAnimation {
                                        showImage = false
                                    }
                                }
                        
                        Spacer()

                        //Mostrar el botón de importación de Notas si se ha mostrado un QR de formato de importación de notas:
                        if self.showImportButtonNotas{
                            HStack{
                                Button("Importar a Notas"){
                                    if (self.purchaseStatus || self.yorjPremium){
                                        Task{
                                            self.imagen = getImageQR() //Recrea la imagen QR a partir del texto actual. Esto es para el caso de que se modifique el texto antes de importar.
                                            validarFormatoImportacion()
                                            if let formato = self.formatImportNotas{
                                                if NotasModel().addNote(nota: formato.1, title: formato.0, isFav: formato.2){
                                                    self.alertMessage = "Nota importada correctamente"
                                                    self.showAlert = true
                                                }
                                            }
                                        }
                                    }else{
                                        self.alertMessage = "Esta función requiere Premium"
                                        self.showAlert = true
                                    }
      
                                }
                                .tint(.blue)
                                .buttonStyle(.bordered)
                                
                                Image(systemName: "info.circle")
                                    .onTapGesture {
                                        self.alertMessage = "El formato de importación de Notas permite generar un QR que se importa automáticamente a las Notas. Utilice el lector de QR incorporado para esta función"
                                        self.showAlert = true
                                    }
                            }
                           
                        }
                        
                        //Mostrar un botón de importación de Frases
                        if self.showImportButtonFrase{
                            HStack{
                                Button("Importar a Frases"){
                                    if (self.purchaseStatus || self.yorjPremium){
                                        Task{
                                            self.imagen = getImageQR() //Recrea la imagen QR a partir del texto actual. Esto es para el caso de que se modifique el texto antes de importar.
                                            validarFormatoImportacion()
                                            if let frase = self.formatImportFrase{
                                                if FrasesModel.shared.AddFrase(frase: frase, autor: "personal"){
                                                    self.alertMessage = "Frase importada correctamente"
                                                    self.showAlert = true
                                                }
                                            }
                                        }
                                    }else{
                                        self.alertMessage = "Esta función requiere Premium"
                                        self.showAlert = true
                                    }
                                    
                                }
                                .tint(.blue)
                                .buttonStyle(.bordered)
                                
                                Image(systemName: "info.circle")
                                    .onTapGesture {
                                        self.alertMessage = "El formato de importación de Frase permite generar un QR que se importa automáticamente a las Frases Personales. Utilice el lector de QR incorporado para esta función"
                                        self.showAlert = true
                                    }
                            }
                           
                        }
                        
                        
                        #if os(macOS)
                        //Barra inferior para cerrar la ventana modal en macOS
                        HStack{
                            Spacer()
                            Button("Cerrar"){
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                    }
                            }
                        }
                        .padding()
                        #endif

                }
                .onAppear {
                        if showImage {
                            imagen = getImageQR()
                            validarFormatoImportacion() //Validar si la entrada tiene un formato de importación
                        }
                    }
                }
                .onTapGesture {
                    self.focusState = false
                }
                //Si el TextField pierde el foco se crea la imagen QR a partir del texto en self.footer
                .onChange(of: self.focusState, { oldValue, newValue in
                    if newValue == false{
                        imagen = getImageQR()
                    }
                })
                .onChange(of: self.imagen, { _ , newValue in
                    //En cada cambio de imagen, se chequea si corresponde a un formato de importación de Notas
                    if newValue != nil{
                        validarFormatoImportacion()
                    }
                })
                
                .navigationTitle("Generar Código QR")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                
                .toolbar{
                    ToolbarItem{
                        Button{
                            withAnimation {
                                if !self.footer.isEmpty {
                                    imagen = getImageQR()
                                    showImage = true
                                    focusState = false
                                }
                            }
                            
                        }label: {
                            Image(systemName: "qrcode")
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    
                    //Importar una imagen de la galeria (iOS) o de la carpeta del sistema(macOS)
                    #if os(macOS)
                    ToolbarItem{
                        Button("Importar Imagen QR"){
                            
                            if let imageTemp = seleccionarImagen(){
                                
                                QRModel.leerQRConVision(from: imageTemp) { str in
                                    if let texto = str {
                                        Task {
                                            await MainActor.run{
                                                self.footer = texto
                                                imagen = getImageQR()
                                                showImage = true
                                                focusState = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                   
                     
                    #else
                    ToolbarItem{
                        //Permite leer una imagen de  QR almacenado en la galeria:
                        PhotosPicker(selection: $selectedItem, matching: .images){
                            Label("Importar imagen QR", systemImage: "photo")
                        }
                        .onChange(of: selectedItem) {
                            
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    
                                    guard let temp = UIImage(data: data) else {return}//Aqui tenemos la imagen de la galería
                                    
                                    //Intentanto leer la imagen cargada
                                    if let features = detectQRCode(temp), !features.isEmpty{
                                        for case let row as CIQRCodeFeature in features{
                                            self.footer = row.messageString ?? ""
                                            imagen = getImageQR()
                                            showImage = true
                                            focusState = false
                                        }
                                        
                                    }else{
                                        
                                        self.imagen = UIImage(systemName: "qrcode")
                                        
                                        self.footer = ""
                                    }
                                }else{
                                    msg("Fallo al cargar la imagen de la galeria")
                                }
                            }
                        }
                        .tint(.blue)
                        .controlSize(.large)
                        .buttonStyle(.bordered)
                    }
                    #endif

                    
                    //Compartir imagen & Aplicar formatos de importación de Frases/Notas
                    ToolbarItem{
                        Menu{
                            
                            if showImage {
                                #if os(iOS)
                                ShareLink(
                                    item: Image(uiImage: imagen!),
                                                preview: SharePreview("Compartir",
                                                    image: Image(systemName: "book")
                                                )
                                 )
                                #elseif os(macOS)
                                if let imagen = self.imagen,
                                   let url = QRModel.guardarImagenTemporalmente(imagen: imagen) {
                                            ShareLink(
                                                item: url,
                                                preview: SharePreview("Compartir Imagen", image: Image(nsImage: imagen))
                                            ) {
                                                Label("Compartir Imagen", systemImage: "square.and.arrow.up")
                                            }
                                        }
                                
                                #endif
                                
                                
                                #if os(iOS)
                                Button{
                                    UIImageWriteToSavedPhotosAlbum(imagen!, nil, nil, nil)
                                    self.alertMessage = "Se ha guardado la imagen QR en la galería"
                                    showAlert = true
                                }label: {
                                    Label("Guardar en Galeria", systemImage: "photo.badge.arrow.down.fill")
                                }
                                #endif
                                
                                
                                
                                
                                Button{
                                    self.footer =  QRModel.aplicarFormatoImportacion(texto: self.footer, tipo: .Notas)
                                    imagen = getImageQR()
                                    showImage = true
                                    focusState = false
                                    validarFormatoImportacion()
                                }label:{
                                    Label("Aplicar formato importación Notas", systemImage: "pencil.and.scribble")
                                }
                                
                                Button{
                                    self.footer =   QRModel.aplicarFormatoImportacion(texto: self.footer, tipo: .Frases)
                                    imagen = getImageQR()
                                    showImage = true
                                    focusState = false
                                    validarFormatoImportacion()
                                }label:{
                                    Label("Aplicar formato importación Frases", systemImage: "pencil.and.scribble")
                                }
                                
                                
                                
                            }
                            
                           
                            
                        }label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(Angle(degrees: 135))
                        }
                    }
                    
                    
                    
                    
                }
                 
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("La Ley"), message: Text(self.alertMessage))
                }
            }
        }else{
            PurchaseView()
        }
        
       
            

    }
    
    
    //Obtiene la imagen QR de un texto
    func getImageQR()->UIImage{
        return UIImage(data: QRModel().generateQRCode(text: self.footer)!)!
    }
    
    //Función que determina si el texto dado tiene un formato de importación de Notas/Frases y, e ese caso, rellena los valores:
    func validarFormatoImportacion(){
        
        if let result = QRModel.detectFormatImportNota(text: self.footer){ //Chequeando formato importación de Notas
            self.formatImportNotas = (result.1.0, result.1.1, result.1.2) //Almacenando en una estructura el título, el contenido de la nota, y su estado de favorito
            self.showImportButtonNotas  = true
            self.formatImportFrase      = nil
            self.showImportButtonFrase  = false
            
        }else if let result = QRModel.detectFormatImportFrase(frase: self.footer){ //Chequeando formato importación de Frases
            self.formatImportFrase      = result.0 //Almacenando el texto de la Frase
            self.formatImportFraseAutor = result.1 //Almacenando el autor de la Frase
            self.formatImportFraseNota  = result.2 //Almacenando la nota de la Frase
            self.formatImportFraseisFav = result.3 //Almacenando el estado favorito de la Frase
            
            self.showImportButtonFrase  = true
            self.formatImportNotas      = nil
            self.showImportButtonNotas  = false
            
        }else{ //Si el texto no tiene ningún formato de importación, se desactivan las opciones para importar
            self.formatImportNotas      = nil
            self.showImportButtonNotas  = false
            self.formatImportFrase      = nil
            self.showImportButtonFrase  = false
        }
    }
     
    
    #if os(iOS)
    //Auxiliar para cargar una imagen QR de la galería y decodificarla
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                      context: nil,
                                      options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
            let ciImage = CIImage(image: pickedImage),
              let _ = detector.features(in: ciImage) as? [CIQRCodeFeature] else { return }
    }
    
    //Lee una UIImage y decodifica su QR si existe, si falla retorna nil
    func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
        if let image = image, let ciImage = CIImage.init(image: image){
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            } else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features

        }
        return nil
    }
    
    #endif
    
 
}




