//
//  CameraManager.swift
//  Menu Crimes
//
//  Camera management using @Observable for reactive SwiftUI integration
//

import SwiftUI
import AVFoundation
import Photos

@Observable
final class CameraManager: NSObject {
    // MARK: - Published Properties
    var captureSession = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
    var videoOutput = AVCaptureMovieFileOutput()
    var currentDevice: AVCaptureDevice?
    var isRecording = false
    var cameraPosition: AVCaptureDevice.Position = .back
    var permissionGranted = false
    var capturedImage: UIImage?
    var capturedVideoURL: URL?
    
    // MARK: - Private Properties
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?
    
    override init() {
        super.init()
        print("🎥 CameraManager: Initializing camera manager")
        setupCameras()
        requestPermission()
    }
    
    // MARK: - Camera Setup
    private func setupCameras() {
        print("🎥 CameraManager: Setting up cameras")
        
        // Discover available cameras
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in discoverySession.devices {
            if device.position == .back {
                backCamera = device
                print("🎥 CameraManager: Back camera found")
            } else if device.position == .front {
                frontCamera = device
                print("🎥 CameraManager: Front camera found")
            }
        }
        
        // Set default camera to back camera
        currentDevice = backCamera
    }
    
    // MARK: - Permission Management
    func requestPermission() {
        print("🎥 CameraManager: Requesting camera permission")
        
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                print("🎥 CameraManager: Camera permission granted: \(granted)")
                
                if granted {
                    self?.setupCaptureSession()
                }
            }
        }
    }
    
    // MARK: - Capture Session Setup
    func setupCaptureSession() {
        print("🎥 CameraManager: Setting up capture session")
        
        captureSession.beginConfiguration()
        
        // Set session preset for high quality
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
            print("✅ CameraManager: Session preset set to photo quality")
        }
        
        // Remove existing inputs/outputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        
        // Add camera input
        guard let device = currentDevice,
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ CameraManager: Failed to create camera input")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentInput = input
            print("✅ CameraManager: Camera input added successfully")
        } else {
            print("❌ CameraManager: Cannot add camera input to session")
            captureSession.commitConfiguration()
            return
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            // Configure photo output settings
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                print("✅ CameraManager: HEVC codec available")
            }
            
            print("✅ CameraManager: Photo output added successfully")
        } else {
            print("❌ CameraManager: Cannot add photo output to session")
        }
        
        // Add video output
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("✅ CameraManager: Video output added successfully")
        } else {
            print("❌ CameraManager: Cannot add video output to session")
        }
        
        captureSession.commitConfiguration()
        print("🎥 CameraManager: Capture session configuration completed")
        
        // Start the session automatically after setup
        startSession()
    }
    
    // MARK: - Camera Controls
    func startSession() {
        print("🎥 CameraManager: Starting capture session")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        print("🎥 CameraManager: Stopping capture session")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func flipCamera() {
        print("🎥 CameraManager: Flipping camera")
        
        cameraPosition = cameraPosition == .back ? .front : .back
        currentDevice = cameraPosition == .back ? backCamera : frontCamera
        
        setupCaptureSession()
    }
    
    // MARK: - Photo Capture
    func capturePhoto() {
        print("📸 CameraManager: Capturing photo")
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Video Recording
    func startVideoRecording() {
        print("🎬 CameraManager: Starting video recording")
        
        guard !isRecording else { return }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }
    
    func stopVideoRecording() {
        print("🎬 CameraManager: Stopping video recording")
        
        guard isRecording else { return }
        
        videoOutput.stopRecording()
        isRecording = false
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ CameraManager: Photo capture error: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ CameraManager: Failed to process photo data")
            return
        }
        
        print("✅ CameraManager: Photo captured successfully")
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("✅ CameraManager: Video recording started at: \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("❌ CameraManager: Video recording error: \(error.localizedDescription)")
            return
        }
        
        print("✅ CameraManager: Video recording finished at: \(outputFileURL)")
        DispatchQueue.main.async {
            self.capturedVideoURL = outputFileURL
        }
    }
}
