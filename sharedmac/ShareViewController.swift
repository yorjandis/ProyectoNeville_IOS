import AppKit
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: NSViewController {

    // Tipos de texto admitidos
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
        var image: NSImage?

        let dispatchGroup = DispatchGroup()

        if let attachments = extensionItem.attachments {

            for itemProvider in attachments {

                // 1️⃣ Cargar texto en cualquiera de sus formatos
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

                // 2️⃣ Cargar imagen (incluye capturas de pantalla)
                if itemProvider.canLoadObject(ofClass: NSImage.self) {
                    dispatchGroup.enter()

                    itemProvider.loadObject(ofClass: NSImage.self) { object, _ in
                        if let img = object as? NSImage {
                            image = img
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }

        // 3️⃣ Esperar a que todo esté cargado
        dispatchGroup.notify(queue: .main) {
            if let img = image {
                let hosting = NSHostingController(
                    rootView: ShareExtensionView(image: img)
                )
                self.embed(hosting)
            }
            else if let txt = text {
                let hosting = NSHostingController(
                    rootView: ShareExtensionView(texto: txt)
                )
                self.embed(hosting)
            }
            else {
                self.close()
            }
        }

        // 4️⃣ Escuchar notificación de cierre desde SwiftUI
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("close"),
            object: nil,
            queue: nil
        ) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }

    // Incrusta SwiftUI en AppKit
    private func embed(_ controller: NSHostingController<ShareExtensionView>) {
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

    // Cierra la extensión
    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
