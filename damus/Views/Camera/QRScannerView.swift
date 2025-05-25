//
//  QRScannerView.swift
//  damus
//
//  Created by Sanjay Siddharth on 24/05/25.
//

import SwiftUI
import AVFoundation
import Vision

enum NewScanError : Error {
    /// The camera could not be accessed.
    case badInput

    /// The camera was not capable of scanning the requested codes.
    case badOutput

    /// Initialization failed.
    case initError(_ error: Error)
  
    /// The camera permission is denied
    case permissionDenied
}

struct NewScanResult {
    /// The contents of the code.
    public let string: String

    /// The type of code that was matched.
    public let type: AVMetadataObject.ObjectType
    
    /// The image of the code that was matched
    public let image: UIImage?
  
    /// The corner coordinates of the scanned code.
    public let corners: [CGPoint]
}

struct QRScannerView: UIViewControllerRepresentable {
    
    let onScan: (Result<NewScanResult,NewScanError>) -> Void
    
    let captureSession = AVCaptureSession()
    
    // Start the UIKit View
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = UIViewController()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return viewController }
            
        captureSession.addInput(videoInput)
        let videoOutput = AVCaptureVideoDataOutput()
        
        if captureSession.canAddOutput(videoOutput){
            videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label:"videoQueue"))
            captureSession.addOutput(videoOutput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
        return viewController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func processScanResult(from payload: String) -> Result<NewScanResult,NewScanError> {
        if payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure(.badInput)
        }
        return .success(NewScanResult(string: payload,type: .qr,image: nil,corners: []))
    }
    
    // Co-ordinator for delegation and the logic
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: QRScannerView
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            self.detectQRCode(in: pixelBuffer)
        }
        
        func detectQRCode(in pixelBuffer: CVPixelBuffer){
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr]
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            do{
                try handler.perform([request])
                if let results = request.results, let payload = results.first?.payloadStringValue {
                    Task{
                        let result = await self.parent.processScanResult(from: payload)
                        await self.parent.onScan(result)
                        await self.parent.captureSession.stopRunning()
                    }
                }
            }catch {
                print("QR Code detection failed : \\(error)")
            }
        }
    }
}
