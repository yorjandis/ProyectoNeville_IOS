//
//  QRReader.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 5/2/24.
//

// Reemplazo nativo de CodeScanner usando AVFoundation
// Mantiene las mismas firmas de funciones

import SwiftUI
import AVFoundation


// MARK: - Compatibilidad con CodeScanner original
struct ScanResult {
    let string: String
}

enum ScanError: Error {
    case badInput, badOutput
}

#if os(iOS)
// MARK: - Contenedor: reemplaza CodeScannerView
struct CodeScannerView: View {
    var codeTypes: [AVMetadataObject.ObjectType]
    var completion: (Result<ScanResult, ScanError>) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
            ScannerViewControllerRepresentable(codeTypes: codeTypes) { result in
                completion(result)
                dismiss()              // ← Cierra la vista cuando hay un resultado
            }
            .ignoresSafeArea()
        }
}


// MARK: - Representable para usar AVCaptureSession

struct ScannerViewControllerRepresentable: UIViewControllerRepresentable {
    var codeTypes: [AVMetadataObject.ObjectType]
    var completion: (Result<ScanResult, ScanError>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.codeTypes = codeTypes
        vc.captureDelegate = context.coordinator
        context.coordinator.controller = vc   // ← nuevo
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}


    class Coordinator: NSObject, @MainActor AVCaptureMetadataOutputObjectsDelegate {
        var completion: (Result<ScanResult, ScanError>) -> Void
        weak var controller: ScannerViewController?
        var didFinish = false

        init(completion: @escaping (Result<ScanResult, ScanError>) -> Void) {
            self.completion = completion
        }

        @MainActor
        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {

            guard !didFinish else { return }

            if let qr = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let value = qr.stringValue {

                didFinish = true
                        self.controller?.stopSession()          // ← Detiene cámara
                        self.completion(.success(ScanResult(string: value)))
            }
        }
    }
}

// MARK: - Vista controladora nativa

class ScannerViewController: UIViewController {

    var codeTypes: [AVMetadataObject.ObjectType] = [.qr]
    var captureDelegate: AVCaptureMetadataOutputObjectsDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(captureDelegate, queue: DispatchQueue.main)
            output.metadataObjectTypes = codeTypes
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        Task{
            self.session.startRunning()
        }
            
        
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

#endif






