import SwiftUI
import AppKit

//Abre una ventana hija, permitiendo pasarle variables de contexto/entorno. Estas son sus características:
/*
 ✅ Apertura de ventanas hijas con contexto (EnvironmentObjects)
 ✅ Tamaño dinámico y posición recordada
 ✅ Compatibilidad total con MainActor y Swift 6
 ✅ Modo modal sin bloqueos del padre
 ✅ Código perfectamente limpio y reutilizable
 ✅ También podemos establecer si es modal (bloqueando la ventana padre) o no.
 ✅ Por último podemos ejecutar un código albritrario al cerrarse con el closure onClose.,
 
 Ejemplo de uso:

 @EnvironmentObject private var frasesModel : FrasesModel
 @EnvironmentObject private var settingModel : SettingModel
 
 Button("Abrir Configuración") {
             showWindow(
                 for: SettingsView(),
                 environmentObjects: [frasesModel, settingModel, ...],
                 title: "Configuración avanzada",
                 windowIdentifier: "settingsWindow"
             )
         }
         .padding()
 */

@discardableResult
func showWindow<V: View>(
    for view: V,
    environmentObjects: [AnyObject] = [],
    title: String = "Ventana",
    size: CGSize? = nil,
    isModal: Bool = true,
    isIAWindows: Bool = false,
    onClose: ( @Sendable () -> Void)? = nil
) -> NSWindow
{
    
    // 🔹 Clave única para TODAS las ventanas secundarias
    var sharedFrameKey : String = "sharedWindowFrame" //Guarda la posición y tamaño de las ventanas generales
    
    //Si se trata de una ventana de IA, se utilza una clave distinta. Para separar las ventanas generales de las ventanas de IA.
    if isIAWindows {
        sharedFrameKey = "sharedWindowFrameIA" //Guarda la posición y tamaño de las ventanas IA
    }
    
    
    // 1️⃣ Envolver la vista con los environmentObjects
    var wrappedView: AnyView = AnyView(view)
    for obj in environmentObjects {
        if let observable = obj as? any ObservableObject {
            wrappedView = AnyView(wrappedView.environmentObject(observable))
        }
    }
    
    // 2️⃣ Crear el hosting controller
    let hosting = NSHostingController(rootView: wrappedView)
    let window = NSWindow(contentViewController: hosting)
    window.title = title
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    
    // 3️⃣ Determinar tamaño para la ventana
    if let size = size {
        window.setContentSize(size) //Se pasa el tamaño de la ventana dado en el parámetro size
    } else {
        hosting.view.layoutSubtreeIfNeeded()
        let fittingSize = hosting.view.fittingSize
        let idealSize = CGSize(
            width: max(fittingSize.width, 300),
            height: max(fittingSize.height, 200)
        )
        window.setContentSize(idealSize)
    }
    
    // 4️⃣ Restaurar o calcular posición
    if let frameString = UserDefaults.standard.string(forKey: sharedFrameKey) {
        // Restaurar última posición global
        let frame = NSRectFromString(frameString)
        window.setFrame(frame, display: true)
        
    } else if let screen = NSScreen.main {
        
        // Primera vez: centrada y un poco más abajo
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let offsetY: CGFloat = -screenFrame.height * 0.05
        
        let origin = CGPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2 + offsetY
        )
        window.setFrameOrigin(origin)
    }
    
    // 5️⃣ Guardar posición al cerrar (compartida por todas)
    NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification,
        object: window,
        queue: .main
    ) { _ in
        Task { @MainActor in
            let frameString = NSStringFromRect(window.frame)
            UserDefaults.standard.set(frameString, forKey: sharedFrameKey)
            
            // ✅ Si era modal, detener el bucle modal
            if isModal {
                NSApp.stopModal()
            }
            
            onClose?()
        }
    }
    
    // 6️⃣ Mostrar ventana
    if isModal {
        // Simular modal sin bloquear
        if let parentWindow = NSApp.keyWindow {
            parentWindow.beginSheet(window, completionHandler: { _ in
                onClose?()
            })
        }
    } else {
        window.makeKeyAndOrderFront(nil)
    }
    //nota: El código de arriba oculta los botones de cerrar de la ventana. pero no bloquea el hilo principal.
    /*
    if isModal {
        NSApplication.shared.runModal(for: window)
    } else {
        window.makeKeyAndOrderFront(nil)
    }
     */
    
    
    
    // 🆕 Registrar la ventana en la clase WindowManager
    WindowManager.shared.register(window)

    // Cuando se cierre, eliminar de la lista
    NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification,
        object: window,
        queue: .main
    ) { _ in
        Task{ @MainActor in
            WindowManager.shared.unregister(window)
        }
        
    }
    
    
    return window
}



//Modelo que lleva un registro de las ventanas Hijas para permitir cerrarlas todas al cerrar la aplicación principal:
final class WindowManager {
    static let shared = WindowManager()
    private init() {}

    private var childWindows: [NSWindow] = []

    func register(_ window: NSWindow) {
        childWindows.append(window)
    }

    func unregister(_ window: NSWindow) {
        childWindows.removeAll { $0 == window }
    }

    //Cierra todas las ventanas Hijas
    func closeAllChildren() {
        for window in childWindows {
            window.close()
        }
        childWindows.removeAll()
    }
}

