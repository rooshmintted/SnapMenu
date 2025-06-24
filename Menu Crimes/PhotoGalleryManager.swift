//
//  PhotoGalleryManager.swift
//  Menu Crimes
//
//  Manages photo gallery access and image picker functionality
//

import SwiftUI
import Photos
import PhotosUI

@Observable
final class PhotoGalleryManager {
    var selectedImage: UIImage?
    var selectedVideoURL: URL?
    var showingImagePicker = false
    var showingPhotoPicker = false
    var permissionGranted = false
    
    init() {
        print("📱 PhotoGalleryManager: Initializing photo gallery manager")
        requestPhotoLibraryPermission()
    }
    
    // MARK: - Permission Management
    func requestPhotoLibraryPermission() {
        print("📱 PhotoGalleryManager: Requesting photo library permission")
        
        // First check current authorization status
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("📱 PhotoGalleryManager: Current authorization status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .authorized, .limited:
            // Already authorized
            permissionGranted = true
            print("✅ PhotoGalleryManager: Photo library permission already granted")
            return
            
        case .denied, .restricted:
            // Previously denied - need to direct user to Settings
            permissionGranted = false
            print("❌ PhotoGalleryManager: Photo library permission previously denied - user must enable in Settings")
            return
            
        case .notDetermined:
            // Not determined - we can request permission
            print("📱 PhotoGalleryManager: Permission not determined, requesting authorization")
            break
            
        @unknown default:
            permissionGranted = false
            print("❌ PhotoGalleryManager: Unknown photo library permission status")
            return
        }
        
        // Request authorization for first time
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.permissionGranted = true
                    print("✅ PhotoGalleryManager: Photo library permission granted")
                case .denied, .restricted:
                    self?.permissionGranted = false
                    print("❌ PhotoGalleryManager: Photo library permission denied by user")
                case .notDetermined:
                    self?.permissionGranted = false
                    print("⚠️ PhotoGalleryManager: Photo library permission still not determined")
                @unknown default:
                    self?.permissionGranted = false
                    print("❌ PhotoGalleryManager: Unknown photo library permission status after request")
                }
            }
        }
    }
    
    /// Check if permission was previously denied and user needs to go to Settings
    var needsSettingsRedirect: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .denied || status == .restricted
    }
    
    // MARK: - Gallery Actions
    func showImagePicker() {
        print("📱 PhotoGalleryManager: Showing image picker")
        showingImagePicker = true
    }
    
    func showPhotoPicker() {
        print("📱 PhotoGalleryManager: Showing photo picker")
        showingPhotoPicker = true
    }
    
    // MARK: - Media Cleanup
    func clearSelectedMedia() {
        print("📱 PhotoGalleryManager: Clearing selected media")
        selectedImage = nil
        selectedVideoURL = nil
    }
}

// MARK: - UIImagePickerController Wrapper
// MARK: - PhotosPicker Configuration
struct PhotoPickerConfig {
    static let configuration: PHPickerConfiguration = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos]) // Support both photos and videos
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        return config
    }()
}

// MARK: - PhotosPicker Wrapper
struct PhotosPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        print("📱 PhotosPicker: Creating PHPickerViewController")
        
        let picker = PHPickerViewController(configuration: PhotoPickerConfig.configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotosPicker
        
        init(_ parent: PhotosPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("📱 PhotosPicker: Photo selection finished with \(results.count) results")
            
            parent.isPresented = false
            
            guard let result = results.first else {
                print("📱 PhotosPicker: No photo selected")
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error = error {
                    print("❌ PhotosPicker: Error loading image: \(error.localizedDescription)")
                    return
                }
                
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = uiImage
                        print("✅ PhotosPicker: Image loaded successfully")
                    }
                }
            }
            
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
                if let error = error {
                    print("❌ PhotosPicker: Error loading video: \(error.localizedDescription)")
                    return
                }
                
                if let tempURL = url {
                    // Copy video to a permanent location since picker URLs are temporary
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileName = "gallery_video_\(UUID().uuidString).mov"
                    let permanentURL = documentsPath.appendingPathComponent(fileName)
                    
                    do {
                        // Remove existing file if it exists
                        if FileManager.default.fileExists(atPath: permanentURL.path) {
                            try FileManager.default.removeItem(at: permanentURL)
                        }
                        
                        // Copy temp file to permanent location
                        try FileManager.default.copyItem(at: tempURL, to: permanentURL)
                        
                        DispatchQueue.main.async {
                            self?.parent.selectedVideoURL = permanentURL
                            print("✅ PhotosPicker: Video copied to permanent location: \(permanentURL.lastPathComponent)")
                        }
                    } catch {
                        print("❌ PhotosPicker: Error copying video file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
