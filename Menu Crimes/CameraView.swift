//
//  CameraView.swift
//  Menu Crimes
//
//  Main camera interface for menu photo capture and analysis
//

import SwiftUI
import AVKit

struct CameraView: View {
    let cameraManager: CameraManager
    let galleryManager: PhotoGalleryManager
    let menuAnalysisManager: MenuAnalysisManager
    let menuAnnotationManager: MenuAnnotationManager
    let currentUser: UserProfile
    
    @State private var showingPreview = false
    @State private var showingGalleryPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview background
                Color.black.ignoresSafeArea()
                
                if cameraManager.permissionGranted {
                    // Camera preview
                    CameraPreviewView(captureSession: cameraManager.captureSession, cameraManager: cameraManager)
                        .ignoresSafeArea()
                        .onAppear {
                            print("📸 CameraView: Camera preview appeared")
                            // Ensure capture session is set up and running
                            if !cameraManager.captureSession.isRunning {
                                print("📸 CameraView: Setting up and starting camera session")
                                cameraManager.setupCaptureSession()
                            } else {
                                print("📸 CameraView: Camera session already running")
                            }
                        }
                        .onDisappear {
                            print("📸 CameraView: Camera preview disappeared, stopping session")
                            cameraManager.stopSession()
                        }
                    
                    // Camera controls overlay
                    VStack {
                        // Top controls
                        HStack {
                            // Gallery access button
                            Button(action: {
                                print("📸 CameraView: Gallery button tapped")
                                showingGalleryPicker = true
                            }) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(.black.opacity(0.3)))
                            }
                            
                            Spacer()
                            
                            // Camera flip button
                            Button(action: {
                                print("📸 CameraView: Flip camera button tapped")
                                cameraManager.flipCamera()
                            }) {
                                Image(systemName: "camera.rotate")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(.black.opacity(0.3)))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Bottom controls - Simplified to photo capture only
                        HStack {
                            Spacer()
                            
                            // Photo capture button (main)
                            Button(action: {
                                print("📸 CameraView: Capture photo button tapped")
                                cameraManager.capturePhoto()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 40)
                    }
                } else {
                    // Permission denied state
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Menu Crimes needs camera access to capture and analyze menu photos.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Button(action: {
                            cameraManager.requestPermission()
                        }) {
                            Text("Enable Camera")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(.white))
                        }
                    }
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("📸 CameraView: Gallery button tapped")
                        showingGalleryPicker = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingGalleryPicker) {
                GalleryPickerView(galleryManager: galleryManager)
            }
            .sheet(isPresented: $showingPreview, onDismiss: {
                // Clear captured photo when preview is dismissed
                if cameraManager.capturedImage != nil {
                    cameraManager.capturedImage = nil
                }
                // Clear gallery-selected media when preview is dismissed
                if galleryManager.selectedImage != nil {
                    galleryManager.clearSelectedMedia()
                }
            }) {
                if let image = cameraManager.capturedImage ?? galleryManager.selectedImage {
                    PhotoPreviewView(
                        image: image,
                        menuAnalysisManager: menuAnalysisManager,
                        menuAnnotationManager: menuAnnotationManager,
                        currentUser: currentUser,
                        onDone: {
                            print("📸 CameraView: Photo preview done, dismissing")
                            showingPreview = false
                        }
                    )
                }
            }
            .onChange(of: cameraManager.capturedImage) { _, newPhoto in
                if newPhoto != nil {
                    print("📸 CameraView: Photo captured, showing preview")
                    showingPreview = true
                }
            }
            .onChange(of: galleryManager.selectedImage) { _, newImage in
                if newImage != nil {
                    print("📸 CameraView: Photo selected from gallery, showing preview")
                    showingGalleryPicker = false // Dismiss gallery picker
                    showingPreview = true
                }
            }
        }
    }
}

// MARK: - Gallery Picker View
struct GalleryPickerView: View {
    let galleryManager: PhotoGalleryManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if galleryManager.permissionGranted {
                    PhotosPicker(
                        selectedImage: Binding(
                            get: { galleryManager.selectedImage },
                            set: { galleryManager.selectedImage = $0 }
                        ),
                        selectedVideoURL: Binding(
                            get: { galleryManager.selectedVideoURL },
                            set: { galleryManager.selectedVideoURL = $0 }
                        ),
                        isPresented: .constant(true)
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Photo Library Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if galleryManager.needsSettingsRedirect {
                            Text("Photo access was previously denied. Please enable it in Settings to select photos.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Open Settings") {
                                // Open iOS Settings app
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.blue))
                        } else {
                            Text("Grant access to select existing menu photos.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Grant Permission") {
                                galleryManager.requestPhotoLibraryPermission()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.blue))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
    let image: UIImage
    let menuAnalysisManager: MenuAnalysisManager
    let menuAnnotationManager: MenuAnnotationManager
    let currentUser: UserProfile
    let onDone: () -> Void
    
    @State private var showingAnalysisResult = false
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Photo display
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
                
                // Analysis button overlay
                VStack {
                    Spacer()
                    
                    // Analysis button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            print("📊 PhotoPreviewView: Analyze menu button tapped")
                            analyzeMenu()
                        }) {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chart.bar.xaxis")
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Analyze Menu")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(isAnalyzing ? .gray : .blue))
                        }
                        .disabled(isAnalyzing)
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Photo Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") {
                        print("📸 PhotoPreviewView: Retake button tapped")
                        onDone()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("📸 PhotoPreviewView: Done button tapped")
                        onDone()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAnalysisResult) {
            MenuAnalysisResultView(
                image: image,
                menuAnalysisManager: menuAnalysisManager,
                menuAnnotationManager: menuAnnotationManager,
                currentUser: currentUser,
                onDone: {
                    showingAnalysisResult = false
                }
            )
        }
    }
    
    private func analyzeMenu() {
        isAnalyzing = true
        Task {
            await menuAnalysisManager.analyzeMenu(image: image, currentUser: currentUser)
            await MainActor.run {
                isAnalyzing = false
                showingAnalysisResult = true
            }
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(
            cameraManager: CameraManager(),
            galleryManager: PhotoGalleryManager(),
            menuAnalysisManager: MenuAnalysisManager(),
            menuAnnotationManager: MenuAnnotationManager(),
            currentUser: UserProfile(
                id: UUID(),
                username: "testuser",
                avatarUrl: nil,
                website: nil,
                updatedAt: Date()
            )
        )
    }
}
