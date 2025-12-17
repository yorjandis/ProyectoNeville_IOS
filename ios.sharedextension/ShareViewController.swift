//
//  ShareViewController.swift
//  ios.sharedextension
//
//  Created by Yorjandis PG on 10/12/25.
//

//Shared Controller:
//
//  ShareViewController.swift
//  SharedExtensioniOS
//
//  Created by Yorjandis PG on 10/12/25.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let button = UIButton(type: .system)
        button.setTitle("Abrir en MiApp", for: .normal)
        button.addTarget(self, action: #selector(openApp), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Cargar la imagen compartida
        loadSharedImage()
    }
    
    func loadSharedImage() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = extensionItem.attachments?.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
            if let url = item as? URL {
                self.handleSharedImage(at: url)
            } else if let image = item as? UIImage {
                self.handleSharedUIImage(image)
            }
        }
    }
    
    func handleSharedImage(at url: URL) {
        let fileManager = FileManager.default
        let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ypg.nev.group")!
        let dest = container.appendingPathComponent("shared_image.jpg")
        try? fileManager.removeItem(at: dest)
        try? fileManager.copyItem(at: url, to: dest)
    }
    
    func handleSharedUIImage(_ image: UIImage) {
        // Procesar UIImage directamente
    }
    
    @objc func openApp() {
        if let url = URL(string: "laley://openshare") {
            UIApplication.shared.open(url)
        }
        self.extensionContext?.completeRequest(returningItems: nil)
    }
}
