//
//  CameraPreviewView.swift
//  Menu Crimes
//
//  SwiftUI wrapper for AVCaptureVideoPreviewLayer with proper preview display
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let captureSession: AVCaptureSession
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        print("🎥 CameraPreviewView: Creating camera preview UI view")
        
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        view.setupPreviewLayer(with: captureSession)
        view.cameraManager = cameraManager
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        print("🎥 CameraPreviewView: Updating camera preview UI view")
        // Update the capture session if it changed
        if uiView.previewLayer.session != captureSession {
            uiView.previewLayer.session = captureSession
        }
        
        // Update camera manager reference
        uiView.cameraManager = cameraManager
    }
}

// MARK: - Custom UIView for Camera Preview
class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var cameraManager: CameraManager?
    
    func setupPreviewLayer(with session: AVCaptureSession) {
        print("🎥 CameraPreviewUIView: Setting up preview layer")
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        layer.addSublayer(previewLayer)
        
        print("✅ CameraPreviewUIView: Preview layer added to view")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update preview layer frame when view bounds change
        if let previewLayer = previewLayer {
            previewLayer.frame = bounds
            print("🎥 CameraPreviewUIView: Updated preview layer frame to \(bounds)")
        }
        
        // Update camera manager with current bounds for accurate cropping
        cameraManager?.previewBounds = bounds
        print("🎯 CameraPreviewUIView: Updated camera manager preview bounds to \(bounds)")
    }
}
