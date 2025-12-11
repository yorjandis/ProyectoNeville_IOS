import UIKit
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: UIViewController {

    // Tipos de contenidos de texto admisibles, esto es para abarcar todos los posibles formatos de texto que puedan entrar:
    let textTypes: [String] = [
        UTType.plainText.identifier,
        UTType.text.identifier,
        UTType.utf8PlainText.identifier,
        UTType.url.identifier,
        UTType.html.identifier
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            close()
            return
        }
         
        var text: String?
        var image: UIImage?

        let dispatchGroup = DispatchGroup()

        if let attachments = extensionItem.attachments {
            
            for itemProvider in attachments {
                //Cargar ek texto
                //Se valida varias clases de entrada de texto
                for type in textTypes {
                    if itemProvider.hasItemConformingToTypeIdentifier(type) {
                        dispatchGroup.enter()
                        itemProvider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in

                            if let s = item as? String {
                                text = s
                            }
                            else if let url = item as? URL {
                                text = url.absoluteString
                            }
                            else if let attr = item as? NSAttributedString {
                                text = attr.string
                            }

                            dispatchGroup.leave()
                        }
                        break
                    }
                }
                
                // Cargar imagen. Funciona incluso con captura de pantalla
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    dispatchGroup.enter()
                    
                    itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let img = object as? UIImage {
                            image = img
                        }
                        
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let img = image {
                let contentView = UIHostingController(rootView: ShareExtensionView(image: img))
                self.embed(contentView)
            } else if let txt = text {
                let contentView = UIHostingController(rootView: ShareExtensionView(texto: txt))
                self.embed(contentView)
            } else {
                //Si ninguno de los item están listos o cargados, se envia la señal de cierre a la Vista de la Extensión
                self.close()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async { self.close() }
        }
    }

    private func embed(_ controller: UIHostingController<ShareExtensionView>) {
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
