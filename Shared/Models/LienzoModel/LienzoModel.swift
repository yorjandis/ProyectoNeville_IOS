//
//  LienzoModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/11/25.
//

import SwiftUI
import Combine
import CoreGraphics
import UniformTypeIdentifiers   // ← Necesario




//Posicion de elementos:
enum PosicionElemento : String, CaseIterable, Identifiable{
    case arriba, abajo, derecha, izquierda, centro
    var id : String { self.rawValue }
}

//ViewModel que Almacena los colores de fondo actualmente
@MainActor
final class LienzoModel : ObservableObject {
    
    enum TipoColorAProcesar{
        case lienzo, custom
    }
    
    //claves de colores de muestra
    let lienzo_color1: String = "lienzo_color1"
    let lienzo_color2: String = "lienzo_color2"
    
    //claves para almacenar el color custom creado por el usuario
    let key_lienzo_custom_color1: String = "lienzo_custom_color1"
    let key_lienzo_custom_color2: String = "lienzo_custom_color2"

    //Nombres de Claves UserDefault para almacenar los valores del lienzo
    static let key_textoPrincipal: String               = "textoPrincipal"
    static let key_textoSecundario: String              = "textoSecundario"
    static let key_tamañoTextoPrincipal: String         = "tamañoTextoPrincipal"
    static let key_tamañoTextoSecundario: String        = "tamañoTextoSecundario"
    static let key_tamañoImagen: String                 = "tamañoImagen"
    static let key_posicionTextoPrincipal: String       = "posicionTextoPrincipal"
    static let key_posicionTextoSecundario: String      = "posicionTextoSecundario"
    static let key_posicionImagenLienzo: String         = "posicionImagenLienzo"
    static let key_imagenLienzo: String                 = "imagenLienzo"
    static let key_visibilidadTextoSecundario: String   = "visibilidadTextoSecundario"
    static let key_visibilidadImagenLienzo: String      = "key_visibilidadImagenLienzo"
    static let key_colorTextoPrincipal: String          = "colorTextoPrincipal"
    static let key_colorTextoSecundario: String         = "colorTextoSecundario"
    static let key_imagenFondoAplicada: String          = "imagenFondoAplicada"
    
    
    
    //Valores observables del lienzo, cada valor reacciona a su propio cambio y se persiste :
    
    //Valores Texto Principal:
    @Published var textoPrincipal : String =  "" {
        didSet {
                UserDefaults.standard.set(textoPrincipal,forKey: Self.key_textoPrincipal)
            }
    } 
    
    @Published var tamañoTextoPrincipal : CGFloat = 24 {
        didSet{
            UserDefaults.standard.set(tamañoTextoPrincipal,forKey: Self.key_tamañoTextoPrincipal)
        }
    }
    
    @Published var posicionTextoPrincipal : PosicionElemento = .derecha {
        didSet {
            UserDefaults.standard.set(posicionTextoPrincipal.rawValue,forKey: Self.key_posicionTextoPrincipal)
            }
    }
    
    @Published var colorTextoPrincipal  : Color = .black {
        didSet{
            Task{
               saveColorTextoPrincipal(colorTextoPrincipal: colorTextoPrincipal)
            }
        }
    }
   
    //Valores Texto Secundario:
    @Published var textoSecundario : String = "Si imaginas y sientes un estado ningún poder el mundo impedirá su manifestación" {
        didSet{
            UserDefaults.standard.set(textoSecundario,forKey: Self.key_textoSecundario)
        }
    }
    @Published var tamañoTextoSecundario : CGFloat = 20{
        didSet{
            UserDefaults.standard.set(tamañoTextoSecundario,forKey: Self.key_tamañoTextoSecundario)
        }
    }
    @Published var posicionTextoSecundario : PosicionElemento = .derecha {
        didSet{
            UserDefaults.standard.set(posicionTextoSecundario.rawValue,forKey: Self.key_posicionTextoSecundario)
        }
    }
    @Published var colorTextoSecundario  : Color = .black{
        didSet{
            Task{
                saveColorTextoSecundario(colorTexttoSecundario: colorTextoSecundario)
            }
        }
    }
    @Published var visibilidadTextoSecundario  : Bool = true {
        didSet{
            UserDefaults.standard.set(visibilidadTextoSecundario,forKey: Self.key_visibilidadTextoSecundario)
        }
    }
    
    //Valores Imagen:
    @Published var imagenLienzo : UIImage? = UIImage(named: "nev-min"){
        didSet{
            Task{
                saveImagenLienzo(imagenLienzo ?? UIImage(named: "nev-min")!)
                 
            }
        }
    }
    @Published var posicionImagenLienzo : PosicionElemento = .izquierda{
        didSet{
            UserDefaults.standard.set(posicionImagenLienzo.rawValue,forKey: Self.key_posicionImagenLienzo)
        }
    }
    @Published var tamañoImagenLienzo : CGFloat = 120{
        didSet{
            UserDefaults.standard.set(tamañoImagenLienzo,forKey: Self.key_tamañoImagen)
        }
    }
    @Published var visibilidadImagenLienzo : Bool = true{
        didSet{
            UserDefaults.standard.set(visibilidadImagenLienzo,forKey: Self.key_visibilidadImagenLienzo)
        }
    }
    
    
    
    //Color de fondo del lienzo & imagen de Fondo:
    @Published var coloresFondo1: Color = .green //Los colores de fondo actualmente seleccionados
    @Published var coloresFondo2: Color = .orange //Los colores de fondo actualmente seleccionados
    
    @Published var coloresFondoCustom1: Color = Color.green  //Almacena los colores custom del usuario.
    @Published var coloresFondoCustom2: Color = Color.orange //Almacena los colores custom del usuario.
    
    @Published var ImagenFondoAplicar: Bool = false { //Si esta flag esta en true se aplicará la imgen de fondo
        didSet{
            UserDefaults.standard.set(ImagenFondoAplicar,forKey: Self.key_imagenFondoAplicada)
        }
    }
    @Published var imagenFondo: UIImage? = nil { //Imagen que tendrá el fondo, en vez de colores.
        didSet{
            //Al cambiar la imagen de fondo esta se restaura
            if imagenFondo != nil{
               _ = saveImagenFondo(image: imagenFondo!)
            }
        }
    }
    private  let fileNameImagenFondo = "imagen_fondo.png"
    private  var fileURLImagenFondo: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(fileNameImagenFondo)
    }
    
    //Tamaño del Lienzo:
    //Tamaños del lienzo
    @Published  var tamañoLienzoAncho : CGFloat = 400
    @Published  var tamañoLienzoAlto : CGFloat = 300
    
    private var cancellables: Set<AnyCancellable> = []
    
    //Para almacenar y recuperar el archivo de imagen del lienzo del directorio document de la app:
    private  let fileNameImagenLienzo = "imagen_lienzo.png" //nombre de la imagen del Lienzo que será almacenada en el directorio document de la app: Buenas prácticas.
    /// URL completa del archivo en Documents
        private  var fileURLImagenLienzo: URL {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return urls[0].appendingPathComponent(fileNameImagenLienzo)
        }
    
    static var shared = LienzoModel() //Singleton
    
    
    private init(){
        
        CargarEstadoLienzo() //Carga el estado del lienzo
        
    }
    
    

    
    //Salva el color actual
    func saveColorFondo(tipoColor: TipoColorAProcesar = .lienzo ){
        if tipoColor == .lienzo{
            let colortemp1 = UIColor(self.coloresFondo1).cgColor
            let colortemp2 = UIColor(self.coloresFondo2).cgColor
            
            if let component1 = colortemp1.components, let component2 = colortemp2.components{
                
                UserDefaults.standard.setValue(component1, forKey: self.lienzo_color1)
                UserDefaults.standard.setValue(component2, forKey: self.lienzo_color2)
                
            }
        }else if tipoColor == .custom{
            let colortemp1 = UIColor(self.coloresFondoCustom1).cgColor
            let colortemp2 = UIColor(self.coloresFondoCustom2).cgColor
            
            if let component1 = colortemp1.components, let component2 = colortemp2.components{
                
                UserDefaults.standard.setValue(component1, forKey: self.key_lienzo_custom_color1)
                UserDefaults.standard.setValue(component2, forKey: self.key_lienzo_custom_color2)
                
            }
        }
        
         
         
    }
    
    //Carga los colores de fondo:
    func loadColoresFondo(tipoColor : TipoColorAProcesar = .lienzo ) {
        
        if tipoColor == .lienzo{
            // Recuperamos los arrays guardados
            guard let comp1 = UserDefaults.standard.array(forKey: self.lienzo_color1) as? [Double],
                  let comp2 = UserDefaults.standard.array(forKey: self.lienzo_color2) as? [Double],
                  comp1.count >= 3,
                  comp2.count >= 3
            else {
                // Si no existen valores guardados, Devuelve un color de muestra
                self.coloresFondo1 =  Color(red: 0.95, green: 0.93, blue: 0.92)
                self.coloresFondo2 =  Color(red: 0.92, green: 0.65, blue: 0.40)
                        
                return
            }
            
            // Reconstruimos UIColor desde RGBA
            let color1 = UIColor(
                red: CGFloat(comp1[0]),
                green: CGFloat(comp1[1]),
                blue: CGFloat(comp1[2]),
                alpha: comp1.count >= 4 ? CGFloat(comp1[3]) : 1.0
            )
            
            let color2 = UIColor(
                red: CGFloat(comp2[0]),
                green: CGFloat(comp2[1]),
                blue: CGFloat(comp2[2]),
                alpha: comp2.count >= 4 ? CGFloat(comp2[3]) : 1.0
            )

            // Convertimos a Color de SwiftUI
            self.coloresFondo1 = Color(color1)
            self.coloresFondo2 = Color(color2)

        }else if tipoColor == .custom{
            // Recuperamos los arrays guardados
            guard let comp1 = UserDefaults.standard.array(forKey: self.key_lienzo_custom_color1) as? [Double],
                  let comp2 = UserDefaults.standard.array(forKey: self.key_lienzo_custom_color2) as? [Double],
                  comp1.count >= 3,
                  comp2.count >= 3
            else {
                // Si no existen valores guardados, Devuelve un color de muestra
                self.coloresFondoCustom1 =  Color(red: 0.95, green: 0.93, blue: 0.92)
                self.coloresFondoCustom2 =  Color(red: 0.92, green: 0.65, blue: 0.40)
                        
                return
            }
            
            // Reconstruimos UIColor desde RGBA
            let color1 = UIColor(
                red: CGFloat(comp1[0]),
                green: CGFloat(comp1[1]),
                blue: CGFloat(comp1[2]),
                alpha: comp1.count >= 4 ? CGFloat(comp1[3]) : 1.0
            )
            
            let color2 = UIColor(
                red: CGFloat(comp2[0]),
                green: CGFloat(comp2[1]),
                blue: CGFloat(comp2[2]),
                alpha: comp2.count >= 4 ? CGFloat(comp2[3]) : 1.0
            )

            // Convertimos a Color de SwiftUI
            self.coloresFondoCustom1  = Color(color1)
            self.coloresFondoCustom2  = Color(color2)
            
        } 
    }
    
    

    //Salva los colores del texto principal en UserDefault
    func saveColorTextoPrincipal(colorTextoPrincipal: Color) {
        let colortempTextoPrincipal = UIColor(colorTextoPrincipal).cgColor
        
        if let colortempTextoPrincipal = colortempTextoPrincipal.components{
            UserDefaults.standard.setValue(colortempTextoPrincipal, forKey: LienzoModel.key_colorTextoPrincipal)
            
        }
    }
    
    //Salva los colores del texto secundario en UserDefault
    func saveColorTextoSecundario(colorTexttoSecundario: Color) {
        let colortempTextSecundario = UIColor(colorTexttoSecundario).cgColor
        
        if let colortempTextSecundario = colortempTextSecundario.components{
            
            UserDefaults.standard.setValue(colortempTextSecundario, forKey: LienzoModel.key_colorTextoSecundario)
        }
    }
    
    
    
    //Devuelve los colores guardado del texto principal & texto secundario en una tupla: (colorTextoPrincipal, colorTextoSecundario)
    func getColorTextoPrincipalYTextoSecundario() -> (Color, Color)? {
        // Recuperamos los arrays guardados
        guard let comp1 = UserDefaults.standard.array(forKey: LienzoModel.key_colorTextoPrincipal) as? [Double],
              let comp2 = UserDefaults.standard.array(forKey: LienzoModel.key_colorTextoSecundario) as? [Double],
              comp1.count >= 3,
              comp2.count >= 3
        else {
            // Si no existen valores guardados, Devuelve un color de muestra
            return (.black, .black)
        }
        
        // Reconstruimos UIColor desde RGBA
        let color1 = UIColor(
            red: CGFloat(comp1[0]),
            green: CGFloat(comp1[1]),
            blue: CGFloat(comp1[2]),
            alpha: comp1.count >= 4 ? CGFloat(comp1[3]) : 1.0
        )
        
        let color2 = UIColor(
            red: CGFloat(comp2[0]),
            green: CGFloat(comp2[1]),
            blue: CGFloat(comp2[2]),
            alpha: comp2.count >= 4 ? CGFloat(comp2[3]) : 1.0
        )

        // Convertimos a Color de SwiftUI
        return (Color(color1),Color(color2))
        
    }
    

    
    //Guarda la imagen de fondo en Document
    func saveImagenFondo(image: UIImage) -> Bool{
        guard let data = imagePNGData(from: image) else {
            print("ImageStorage: no se pudo obtener data PNG de la imagen.")
            return false
        }

        do {
            // Primero eliminar el archivo previo si existe (evita acumulación)
            try removeExistingFileIfNeeded()

            // Escribe el nuevo archivo de forma atómica
            try data.write(to: fileURLImagenFondo, options: .atomic)

            // Opcional: establecer exclusionFromBackup en iOS si quieres que no se suba a iCloud
            #if os(iOS)
            var fileURL = fileURLImagenFondo // Copiamos a variable mutable
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try fileURL.setResourceValues(resourceValues)
            #endif

            return true
        } catch {
            print("ImageStorage: error guardando imagen: \(error)")
            return false
        }
        
    }
    
    //Devuelve la imagen de fondo guardada en Document
    func obtenerImagenFondo() -> UIImage?{
        let path = fileURLImagenFondo.path
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURLImagenFondo)
            #if os(iOS)
            return UIImage(data: data)
            #elseif os(macOS)
            return NSImage(data: data)
            #endif
        } catch {
            print("ImageStorage: error cargando imagen: \(error)")
            return nil
        }
    }
    
    
    
    //Funcion que recupera el Estado de los elementos al inicial el Lienzo:
    //Se llama en el init() de LienzoModel
    func CargarEstadoLienzo(){
        
        //Recuperando los colores de fondo o imagen de fondo:
        //chequeando el flag que indica que hay que aplicar una imagen de fondo, previamente almacenada en Document.
        if UserDefaults.standard.bool(forKey: LienzoModel.key_imagenFondoAplicada) {
            if let image = obtenerImagenFondo(){ //Intenta obtener la imagen de fondo
                self.imagenFondo = image
            }else{
                //Si no puede cargar la imagen de fondo, entonces carga los colores de fondo.
                loadColoresFondo(tipoColor: .lienzo)
                loadColoresFondo(tipoColor: .custom)
            }
            
        }else{ //Si el flag de imagen de fondo aplicada esta a false, se carga los colores almacenados en userdefault
            loadColoresFondo(tipoColor: .lienzo)
            loadColoresFondo(tipoColor: .custom)
        }
        
        
        
        //Cargar Valores de Texto Principal:
        self.textoPrincipal = UserDefaults.standard.string(forKey: LienzoModel.key_textoPrincipal) ?? "Imaginar Crea la realidad"

        let posicionTextoPrincipal_tmp = UserDefaults.standard.string(forKey: LienzoModel.key_posicionTextoPrincipal) ?? "derecha"
        switch posicionTextoPrincipal_tmp{
            case "arriba":
            self.posicionTextoPrincipal = .arriba
        case "centro":
            self.posicionTextoPrincipal = .centro
        case "abajo":
            self.posicionTextoPrincipal = .abajo
        case "derecha":
            self.posicionTextoPrincipal = .derecha
        case "izquierda":
            self.posicionTextoPrincipal = .izquierda
        default:
            self.posicionTextoPrincipal = .derecha
        }
        
        let tamañoTextoPrincipal_tmp = UserDefaults.standard.float(forKey: LienzoModel.key_tamañoTextoPrincipal)
        if tamañoTextoPrincipal_tmp == 0.0{
            self.tamañoTextoPrincipal = 24.0
        }else{
            self.tamañoTextoPrincipal = CGFloat(tamañoTextoPrincipal_tmp)
        }
        
        let colorTextoPrincipal_tmp = getColorTextoPrincipalYTextoSecundario()
            self.colorTextoPrincipal = colorTextoPrincipal_tmp?.0 ?? .black
       
        
        //Cargar Valores del Texto Secundario:
        let textoSecundario_tmp = UserDefaults.standard.string(forKey: LienzoModel.key_textoSecundario) ?? "Si asumes el sentimiento del deseo cumplido ningún poder puede impedir su manifestación"
        if textoSecundario_tmp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            self.textoSecundario = "Si asumes el sentimiento del deseo cumplido ningún poder puede impedir su manifestación"
        }else{
            self.textoSecundario = textoSecundario_tmp
        }
        
        let posicionTextoSecundario_tmp = UserDefaults.standard.string(forKey: LienzoModel.key_posicionTextoSecundario) ?? "derecha"
        switch posicionTextoSecundario_tmp{
            case "arriba":
            self.posicionTextoSecundario = .arriba
        case "centro":
            self.posicionTextoSecundario = .centro
        case "abajo":
            self.posicionTextoSecundario = .abajo
        case "derecha":
            self.posicionTextoSecundario = .derecha
        case "izquierda":
            self.posicionTextoSecundario = .izquierda
        default:
            self.posicionTextoSecundario = .derecha
        }
        
        let tamañoTextoSecundario_tmp = UserDefaults.standard.float(forKey: LienzoModel.key_tamañoTextoSecundario)
        if tamañoTextoSecundario_tmp == 0.0{
            self.tamañoTextoSecundario = 20.0
        }else{
            self.tamañoTextoSecundario = CGFloat(tamañoTextoSecundario_tmp)
        }
        
        let colorTextoSecundario_tmp = getColorTextoPrincipalYTextoSecundario()
        
        
        self.colorTextoSecundario = colorTextoSecundario_tmp?.1 ?? .black
        
        let visibilityTextoSecundario_tmp = UserDefaults.standard.bool(forKey: LienzoModel.key_visibilidadTextoSecundario)
        self.visibilidadTextoSecundario = visibilityTextoSecundario_tmp
        
        
        //Cargar Valores de la imagen
        if let imagenLienzo_tmp = loadImageLienzo(){
            self.imagenLienzo = imagenLienzo_tmp
        }else{
            self.imagenLienzo = UIImage(named: "nev-min")
        }
        
        let posicionImagenLienzo_tmp = UserDefaults.standard.string(forKey: LienzoModel.key_posicionImagenLienzo) ?? "izquierda"
        //case arriba, abajo, derecha, izquierda, centro
        switch posicionImagenLienzo_tmp{
            case "arriba":
            self.posicionImagenLienzo = .arriba
        case "abajo":
            self.posicionImagenLienzo = .abajo
        case "derecha":
            self.posicionImagenLienzo = .derecha
        case "izquierda":
            self.posicionImagenLienzo = .izquierda
        default:
            self.posicionImagenLienzo = .izquierda
        }
        
        let tamañoImagenLienzo_tmp = UserDefaults.standard.float(forKey: LienzoModel.key_tamañoImagen)
        if tamañoImagenLienzo_tmp == 0.0{
            self.tamañoImagenLienzo = 120.0
        }else{
            self.tamañoImagenLienzo = CGFloat(tamañoImagenLienzo_tmp)
        }
        
        let visibilityImagenLienzo_tmp = UserDefaults.standard.bool(forKey: LienzoModel.key_visibilidadImagenLienzo)
        self.visibilidadImagenLienzo = visibilityImagenLienzo_tmp
        

    }
    
    
  //------------------ Lógica para almacenar y recuperar una UIImage (alias de UIImage/NSImage en iOS/macOS) del directorio document de la app.--------------------
    
    /// Convierte UIIMage a Data (PNG) en iOS y macOS
        private func imagePNGData(from image: UIImage) -> Data? {
            #if os(iOS)
            // UIImage tiene pngData()
            return image.pngData()
            #elseif os(macOS)
            // NSImage -> NSBitmapImageRep -> pngRepresentation
            guard let tiffData = image.tiffRepresentation else { return nil }
            guard let rep = NSBitmapImageRep(data: tiffData) else { return nil }
            return rep.representation(using: .png, properties: [:])
            #endif
        }

        /// Elimina el archivo previo si existe (para asegurar que solo haya un archivo)
        private  func removeExistingFileIfNeeded() throws {
            let path = fileURLImagenLienzo.path
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(at: fileURLImagenLienzo)
            }
        }
    
    /// Guarda la imagen como PNG en Documents. Antes borra cualquier archivo previo con el mismo nombre.
        /// - Devuelve true si la operación tuvo éxito.
    private func saveImagenLienzo(_ image: UIImage) -> Bool {
            
            guard let data = imagePNGData(from: image) else {
                print("ImageStorage: no se pudo obtener data PNG de la imagen.")
                return false
            }

            do {
                // Primero eliminar el archivo previo si existe (evita acumulación)
                try removeExistingFileIfNeeded()

                // Escribe el nuevo archivo de forma atómica
                try data.write(to: fileURLImagenLienzo, options: .atomic)

                // Opcional: establecer exclusionFromBackup en iOS si quieres que no se suba a iCloud
                #if os(iOS)
                var fileURL = fileURLImagenLienzo // Copiamos a variable mutable
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try fileURL.setResourceValues(resourceValues)
                #endif

                return true
            } catch {
                print("ImageStorage: error guardando imagen: \(error)")
                return false
            }
        }
    
    
    /// Recupera la imagen previamente almacenada (si existe)
        private func loadImageLienzo() -> UIImage? {
            let path = fileURLImagenLienzo.path
            guard FileManager.default.fileExists(atPath: path) else {
                return nil
            }

            do {
                let data = try Data(contentsOf: fileURLImagenLienzo)
                #if os(iOS)
                return UIImage(data: data)
                #elseif os(macOS)
                return NSImage(data: data)
                #endif
            } catch {
                print("ImageStorage: error cargando imagen: \(error)")
                return nil
            }
        }
    
    //------------------ FIN --------------------
 
    

    
}







#if os(macOS)
extension NSImage {
    var pngRepresentation: Data? {
        guard let tiff = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif
